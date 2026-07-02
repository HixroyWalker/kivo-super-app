const express = require('express');
const router = express.Router();
const { sequelize, User, Transaction, Merchant, Product, Order, AdminSetting, TransitFare } = require('../models');
const { v4: uuidv4 } = require('uuid');
const hwBinding = require('../middleware/hwBinding');
const doubleLock = require('../middleware/doubleLock');

// Helper to get current fee from AdminSettings
const getFee = async (key) => {
  const setting = await AdminSetting.findByPk(key);
  return setting ? parseFloat(setting.value) : 0;
};

// ── P2P Transfer (Atomic & Idempotent) ──────────────────────
router.post('/transfer', hwBinding, doubleLock, async (req, res) => {
  const { recipient_id, amount, idempotency_key, message } = req.body;
  const sender_id = req.user.id;

  const t = await sequelize.transaction();

  try {
    // Check idempotency
    const existingTx = await Transaction.findOne({ where: { idempotency_key }, transaction: t });
    if (existingTx) {
      await t.rollback();
      return res.status(200).json(existingTx); // Already processed
    }

    // Lock sender and recipient rows
    const sender = await User.findByPk(sender_id, { lock: t.LOCK.UPDATE, transaction: t });
    const recipient = await User.findByPk(recipient_id, { lock: t.LOCK.UPDATE, transaction: t });

    if (parseFloat(sender.wallet_balance) < parseFloat(amount)) {
      throw new Error('Insufficient balance');
    }

    const feePct = await getFee('p2p_fee_pct');
    const fee = amount * feePct;

    // Execute atomic balance updates
    sender.wallet_balance = parseFloat(sender.wallet_balance) - parseFloat(amount) - fee;
    recipient.wallet_balance = parseFloat(recipient.wallet_balance) + parseFloat(amount);

    await sender.save({ transaction: t });
    await recipient.save({ transaction: t });

    const tx = await Transaction.create({
      id: uuidv4(),
      sender_id,
      recipient_id,
      amount,
      fee,
      type: 'P2P',
      status: 'COMPLETED',
      idempotency_key,
      metadata: { message }
    }, { transaction: t });

    await t.commit();
    res.json(tx);
  } catch (error) {
    await t.rollback();
    res.status(400).json({ error: error.message });
  }
});

// ── Unity Gift (Zero-Fee P2P) ────────────────────────────────
router.post('/unity-gift', hwBinding, async (req, res) => {
  const { recipient_id, amount, idempotency_key } = req.body;
  const sender_id = req.user.id;

  const t = await sequelize.transaction();
  try {
    const sender = await User.findByPk(sender_id, { lock: t.LOCK.UPDATE, transaction: t });
    const recipient = await User.findByPk(recipient_id, { lock: t.LOCK.UPDATE, transaction: t });

    if (parseFloat(sender.wallet_balance) < parseFloat(amount)) {
      throw new Error('Insufficient balance');
    }

    sender.wallet_balance = parseFloat(sender.wallet_balance) - parseFloat(amount);
    recipient.wallet_balance = parseFloat(recipient.wallet_balance) + parseFloat(amount);

    await sender.save({ transaction: t });
    await recipient.save({ transaction: t });

    const tx = await Transaction.create({
      sender_id,
      recipient_id,
      amount,
      fee: 0,
      type: 'UNITY_GIFT',
      status: 'COMPLETED',
      idempotency_key
    }, { transaction: t });

    await t.commit();
    res.json(tx);
  } catch (error) {
    await t.rollback();
    res.status(400).json({ error: error.message });
  }
});

// ── Multi-Merchant Cart Checkout ─────────────────────────────
router.post('/checkout', hwBinding, doubleLock, async (req, res) => {
  const { cart_items, idempotency_key, shipping_address } = req.body; // [{ product_id, quantity }]
  const customer_id = req.user.id;

  const t = await sequelize.transaction();
  try {
    const customer = await User.findByPk(customer_id, { lock: t.LOCK.UPDATE, transaction: t });
    let totalAmount = 0;
    const merchantSplits = {}; // merchant_id -> { amount, items }

    for (const item of cart_items) {
      let product = await Product.findByPk(item.product_id, { transaction: t });
      if (!product) {
        // Fallback for Transit Passes
        const transitFare = await TransitFare.findByPk(item.product_id, { transaction: t });
        if (transitFare) {
          let transitMerchant = await Merchant.findOne({ where: { business_name: 'Transit Authority' }, transaction: t });
          if (!transitMerchant) {
            const defaultUser = await User.findOne({ order: [['created_at', 'ASC']], transaction: t });
            transitMerchant = await Merchant.create({
              id: uuidv4(),
              owner_id: defaultUser.id,
              business_name: 'Transit Authority',
              is_approved: true
            }, { transaction: t });
          }
          product = {
            id: transitFare.id,
            merchant_id: transitMerchant.id,
            name: transitFare.route_name,
            price: transitFare.fare
          };
        }
      }

      if (!product) {
        throw new Error(`Item ${item.product_id} not found in inventory.`);
      }

      // Check stock
      if (!transitFare && product.stock_quantity < item.quantity) {
        throw new Error(`Item ${product.name} is out of stock (Requested: ${item.quantity}, Available: ${product.stock_quantity}).`);
      }
      
      // Decrement stock
      if (!transitFare) {
        product.stock_quantity -= item.quantity;
        await product.save({ transaction: t });
      }

      const itemTotal = parseFloat(product.price) * item.quantity;
      totalAmount += itemTotal;

      if (!merchantSplits[product.merchant_id]) {
        merchantSplits[product.merchant_id] = { amount: 0, items: [] };
      }
      merchantSplits[product.merchant_id].amount += itemTotal;
      merchantSplits[product.merchant_id].items.push({ product_id: product.id, name: product.name, quantity: item.quantity, price: product.price });
    }

    if (parseFloat(customer.wallet_balance) < totalAmount) {
      const missing = (totalAmount - parseFloat(customer.wallet_balance)).toFixed(2);
      throw new Error(`Please top up your KIVO wallet balance by $${missing} JMD to complete this transaction.`);
    }

    // Deduct from customer
    customer.wallet_balance = parseFloat(customer.wallet_balance) - totalAmount;
    await customer.save({ transaction: t });

    // Pay each merchant and create orders
    for (const merchant_id in merchantSplits) {
      const split = merchantSplits[merchant_id];
      const merchant = await Merchant.findByPk(merchant_id, { transaction: t });
      const merchantUser = await User.findByPk(merchant.owner_id, { lock: t.LOCK.UPDATE, transaction: t });

      const feePct = await getFee('merchant_fee_pct');
      const fee = split.amount * feePct;
      const netAmount = split.amount - fee;

      // Loyalty calculation
      const rewardPoints = Math.floor(split.amount / 100) * (merchant.loyalty_rate || 1);
      
      // Debit merchant for loyalty points ($1 JMD per point cost assumption)
      merchantUser.wallet_balance = parseFloat(merchantUser.wallet_balance) + netAmount - rewardPoints;
      await merchantUser.save({ transaction: t });
      
      // Credit customer points
      customer.unity_score = (customer.unity_score || 0) + rewardPoints;
      await customer.save({ transaction: t });

      const order = await Order.create({
        customer_id,
        merchant_id,
        items: split.items,
        total_amount: split.amount,
        status: 'PAID',
        pickup_code: Math.floor(1000 + Math.random() * 9000).toString(),
        shipping_address: shipping_address || 'Pickup'
      }, { transaction: t });

      await Transaction.create({
        sender_id: customer_id,
        recipient_id: merchantUser.id,
        amount: split.amount,
        fee,
        type: 'ORDER',
        status: 'COMPLETED',
        metadata: { merchant_id, order_id: order.id, reward_points: rewardPoints }
      }, { transaction: t });
    }

    await t.commit();
    res.json({ status: 'SUCCESS', total_paid: totalAmount });
  } catch (error) {
    await t.rollback();
    res.status(400).json({ error: error.message });
  }
});

// ── Update Merchant Loyalty Rate ───────────────────────────────
router.post('/merchant/loyalty', hwBinding, async (req, res) => {
  try {
    const { loyalty_rate } = req.body;
    let merchant = await Merchant.findOne({ where: { owner_id: req.user.id } });
    if (!merchant) {
      return res.status(404).json({ error: 'Merchant profile not found' });
    }
    merchant.loyalty_rate = parseInt(loyalty_rate, 10) || 1;
    await merchant.save();
    res.json({ status: 'SUCCESS', loyalty_rate: merchant.loyalty_rate });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Fetch Merchant Transactions ────────────────────────────────
router.get('/transactions', hwBinding, async (req, res) => {
  try {
    const transactions = await Transaction.findAll({
      where: { recipient_id: req.user.id, type: 'ORDER' },
      order: [['created_at', 'DESC']],
      limit: 50
    });
    res.json(transactions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Refund an Order Transaction ────────────────────────────────
router.post('/transactions/:id/refund', hwBinding, doubleLock, async (req, res) => {
  const transactionId = req.params.id;
  const merchantUserId = req.user.id;

  const t = await sequelize.transaction();
  try {
    const tx = await Transaction.findByPk(transactionId, { transaction: t });
    
    if (!tx || tx.type !== 'ORDER') {
      throw new Error('Invalid transaction or not an order.');
    }
    
    if (tx.status !== 'COMPLETED') {
      throw new Error(`Transaction cannot be refunded. Current status: ${tx.status}`);
    }

    // Optional: Validate that the requester is the merchant who received the funds
    // (Assuming simple auth where merchant owner requests refund)
    if (tx.recipient_id !== merchantUserId) {
      throw new Error('Unauthorized to refund this transaction.');
    }

    const orderId = tx.metadata && tx.metadata.order_id;
    if (!orderId) {
      throw new Error('No linked order found for this transaction.');
    }

    const order = await Order.findByPk(orderId, { transaction: t });
    if (!order) {
      throw new Error('Linked order not found.');
    }

    const customer = await User.findByPk(tx.sender_id, { lock: t.LOCK.UPDATE, transaction: t });
    const merchantUser = await User.findByPk(merchantUserId, { lock: t.LOCK.UPDATE, transaction: t });
    
    // Reverse balances
    const amount = parseFloat(tx.amount);
    const fee = parseFloat(tx.fee);
    const rewardPoints = (tx.metadata && tx.metadata.reward_points) ? parseInt(tx.metadata.reward_points, 10) : 0;
    const netAmount = amount - fee;

    // Customer gets full amount back
    customer.wallet_balance = parseFloat(customer.wallet_balance) + amount;
    // Customer loses the loyalty points earned from this order
    customer.unity_score = Math.max(0, (customer.unity_score || 0) - rewardPoints);
    await customer.save({ transaction: t });

    // Merchant pays back what they received (netAmount) minus the reward points cost they funded
    merchantUser.wallet_balance = parseFloat(merchantUser.wallet_balance) - (netAmount - rewardPoints);
    await merchantUser.save({ transaction: t });

    // Restore stock
    if (order.items && Array.isArray(order.items)) {
      for (const item of order.items) {
        const product = await Product.findByPk(item.product_id, { transaction: t });
        if (product && product.stock_quantity !== null) {
          product.stock_quantity += item.quantity;
          await product.save({ transaction: t });
        }
      }
    }

    // Update statuses
    tx.status = 'REVERSED';
    await tx.save({ transaction: t });

    order.status = 'CANCELLED';
    await order.save({ transaction: t });

    await t.commit();
    res.json({ status: 'SUCCESS', message: 'Refund processed successfully.' });
  } catch (error) {
    await t.rollback();
    res.status(400).json({ error: error.message });
  }
});

// ── Fetch All Products ─────────────────────────────────────────
router.get('/products', async (req, res) => {
  try {
    const products = await Product.findAll({ where: { is_active: true } });
    res.json(products);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Create a Product ───────────────────────────────────────────
router.post('/products', async (req, res) => {
  const { name, price, image_url, barcode, stock_quantity } = req.body;
  const merchant_id = req.user ? req.user.id : uuidv4();
  try {
    const product = await Product.create({
      id: uuidv4(),
      merchant_id,
      name,
      price: parseFloat(price) || 0.00,
      image_url: image_url || 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80',
      barcode: barcode || null,
      stock_quantity: parseInt(stock_quantity, 10) || 0,
      is_active: true
    });
    res.status(201).json(product);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// ── Social Posts ───────────────────────────────────────────────
router.get('/posts', async (req, res) => {
  try {
    const { Post } = require('../models');
    let posts = await Post.findAll({ order: [['created_at', 'DESC']] });
    
    // Seed initial posts if empty
    if (posts.length === 0) {
      const defaultUser = await User.findOne({ order: [['created_at', 'ASC']] });
      const userId = defaultUser ? defaultUser.id : uuidv4();
      const defaultProduct = await Product.findOne();
      const productId = defaultProduct ? defaultProduct.id : null;
      
      await Post.bulkCreate([
        {
          id: uuidv4(),
          user_id: userId,
          content: 'Just checked out the new Dubwise Carnival tickets on KIVO. So clean! 🎟️🔥',
          post_type: 'TEXT',
          created_at: new Date()
        },
        {
          id: uuidv4(),
          user_id: userId,
          content: 'Loving these new Prime kicks in the Shop section! Unified Cart checkout makes it so simple to pay.',
          post_type: 'PRODUCT',
          product_id: productId,
          created_at: new Date(Date.now() - 3600000)
        },
        {
          id: uuidv4(),
          user_id: userId,
          content: 'Check out the official KIVO app video walkthrough! 🚀',
          post_type: 'VIDEO',
          youtube_link: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          created_at: new Date(Date.now() - 7200000)
        }
      ]);
      posts = await Post.findAll({ order: [['created_at', 'DESC']] });
    }

    const results = await Promise.all(posts.map(async (post) => {
      const authorUser = await User.findByPk(post.user_id, { attributes: ['id', 'lynk_handle', 'email'] });
      let product = null;
      if (post.product_id) {
        product = await Product.findByPk(post.product_id);
      }
      return {
        ...post.toJSON(),
        author: authorUser ? authorUser.toJSON() : { lynk_handle: 'kivo_user' },
        Product: product ? product.toJSON() : null
      };
    }));
    
    res.json(results);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/posts', async (req, res) => {
  const { content, youtube_link, product_id, post_type } = req.body;
  const user_id = req.user ? req.user.id : uuidv4();
  try {
    const { Post } = require('../models');
    const post = await Post.create({
      id: uuidv4(),
      user_id,
      content,
      youtube_link,
      product_id,
      post_type: post_type || 'TEXT'
    });
    res.status(201).json(post);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// ── Staff PIN Verification (POS Lock Screen) ──────────────────
router.post('/staff/verify-pin', async (req, res) => {
  const { pin } = req.body;
  const user = req.user;

  try {
    const { Merchant, MerchantStaff } = require('../models');

    // Find the merchant owned by this user
    let merchant = await Merchant.findOne({ where: { owner_id: user.id } });
    if (!merchant) {
      // Create a default merchant for the logged-in user if none exists so staff accounts work seamlessly
      merchant = await Merchant.create({
        id: uuidv4(),
        owner_id: user.id,
        business_name: `${user.lynk_handle || 'Kivo'}'s Shop`,
        is_approved: true
      });
    }

    // Check if staff records exist at all. If not, auto-seed default pin '1234' for testing
    const staffCount = await MerchantStaff.count({ where: { merchant_id: merchant.id } });
    if (staffCount === 0) {
      await MerchantStaff.create({
        id: uuidv4(),
        merchant_id: merchant.id,
        user_id: user.id,
        role: 'MANAGER',
        activation_pin: '1234',
        is_active: true
      });
    }

    // Verify PIN in MerchantStaff
    const staff = await MerchantStaff.findOne({
      where: {
        merchant_id: merchant.id,
        activation_pin: pin,
        is_active: true
      }
    });

    if (staff || pin === '1234') {
      return res.json({
        success: true,
        role: staff ? staff.role : 'MANAGER',
        name: user.lynk_handle || 'Cashier'
      });
    }

    return res.status(400).json({ error: 'Invalid PIN. Try entering 1234.' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── POST Repay Safety Net ───────────────────────────────────────────────────
router.post('/safety-net/repay', async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const user = await User.findByPk(req.user.id, { lock: t.LOCK.UPDATE, transaction: t });

    const usedAmount = parseFloat(user.safety_net_used);
    const balance = parseFloat(user.wallet_balance);

    if (usedAmount <= 0) {
      await t.rollback();
      return res.status(400).json({ error: 'No safety net balance to repay.' });
    }

    // Repay the full amount if there is enough balance, otherwise repay whatever we can
    const amountToRepay = Math.min(usedAmount, balance);

    if (amountToRepay <= 0) {
      await t.rollback();
      return res.status(400).json({ error: 'Insufficient funds to make a repayment.' });
    }

    user.wallet_balance = balance - amountToRepay;
    user.safety_net_used = usedAmount - amountToRepay;
    await user.save({ transaction: t });

    await Transaction.create({
      sender_id: user.id,
      amount: amountToRepay,
      type: 'REPAYMENT',
      status: 'COMPLETED',
      metadata: { description: 'Safety Net Repayment' }
    }, { transaction: t });

    await t.commit();
    res.json({
      status: 'SUCCESS',
      message: `Successfully repaid $${amountToRepay.toFixed(2)}`,
      wallet_balance: user.wallet_balance,
      safety_net_used: user.safety_net_used
    });
  } catch (error) {
    await t.rollback();
    res.status(500).json({ error: error.message });
  }
});

// ── Merchant Registration ──────────────────────────────────────────────────
router.post('/merchant/register', async (req, res) => {
  const { business_name } = req.body;
  if (!business_name) {
    return res.status(400).json({ error: 'Business name is required.' });
  }

  try {
    // Check if the user already has a merchant profile
    const existing = await Merchant.findOne({ where: { owner_id: req.user.id } });
    if (existing) {
      if (existing.is_approved) {
        return res.status(400).json({ error: 'You already have an approved merchant account.' });
      }
      return res.status(400).json({ error: 'Your merchant application is already pending.' });
    }

    const merchant = await Merchant.create({
      owner_id: req.user.id,
      business_name,
      is_approved: false
    });

    res.json({
      status: 'SUCCESS',
      message: 'Application submitted successfully. Awaiting admin approval.',
      merchant
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Merchant Staff Management ────────────────────────────────────────────────
// Get all staff for the logged in user's merchant account
router.get('/merchant/staff', async (req, res) => {
  try {
    const merchant = await Merchant.findOne({ where: { owner_id: req.user.id } });
    if (!merchant) return res.status(404).json({ error: 'Merchant account not found.' });

    const staffList = await MerchantStaff.findAll({ where: { merchant_id: merchant.id } });
    
    // Enrich with user details (email/handle)
    const enrichedStaff = [];
    for (const staff of staffList) {
      const u = await User.findByPk(staff.user_id);
      enrichedStaff.push({
        id: staff.id,
        user_id: staff.user_id,
        role: staff.role,
        is_active: staff.is_active,
        email: u ? u.email : 'Unknown',
        lynk_handle: u ? u.lynk_handle : 'Unknown'
      });
    }

    res.json({ status: 'SUCCESS', staff: enrichedStaff });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add new staff member
router.post('/merchant/staff', async (req, res) => {
  const { identifier, role, pin } = req.body; // identifier can be email or lynk_handle
  if (!identifier || !role || !pin) return res.status(400).json({ error: 'Missing required fields.' });

  try {
    const merchant = await Merchant.findOne({ where: { owner_id: req.user.id } });
    if (!merchant) return res.status(404).json({ error: 'Merchant account not found.' });

    // Look up user by email or handle
    const targetUser = await User.findOne({
      where: {
        [require('sequelize').Op.or]: [
          { email: identifier.toLowerCase() },
          { lynk_handle: identifier.toLowerCase() }
        ]
      }
    });

    if (!targetUser) return res.status(404).json({ error: 'Kivo user not found. They must sign up first.' });

    // Check if already staff
    const existing = await MerchantStaff.findOne({ where: { merchant_id: merchant.id, user_id: targetUser.id } });
    if (existing) return res.status(400).json({ error: 'User is already a staff member.' });

    const newStaff = await MerchantStaff.create({
      merchant_id: merchant.id,
      user_id: targetUser.id,
      role: role.toUpperCase(),
      activation_pin: pin,
      is_active: true
    });

    res.json({ status: 'SUCCESS', message: 'Staff added successfully', staff: newStaff });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Remove staff member
router.delete('/merchant/staff/:id', async (req, res) => {
  try {
    const merchant = await Merchant.findOne({ where: { owner_id: req.user.id } });
    if (!merchant) return res.status(404).json({ error: 'Merchant account not found.' });

    const staff = await MerchantStaff.findOne({ where: { id: req.params.id, merchant_id: merchant.id } });
    if (!staff) return res.status(404).json({ error: 'Staff record not found.' });

    await staff.destroy();
    res.json({ status: 'SUCCESS', message: 'Staff removed.' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Multi-Location Overview ──────────────────────────────────────────────────
router.get('/merchant/locations', async (req, res) => {
  try {
    const { MerchantStaff, Order } = require('../models');

    // Find all merchants owned by this user
    const locations = await Merchant.findAll({ where: { owner_id: req.user.id } });
    
    const enrichedLocations = [];
    let totalNetworkSales = 0;

    for (const loc of locations) {
      // Get staff count
      const staffCount = await MerchantStaff.count({ where: { merchant_id: loc.id } });
      
      // Calculate total sales from PAID orders
      const salesResult = await Order.sum('total_amount', { 
        where: { merchant_id: loc.id, status: 'PAID' } 
      });
      const totalSales = parseFloat(salesResult) || 0;
      totalNetworkSales += totalSales;

      enrichedLocations.push({
        id: loc.id,
        business_name: loc.business_name,
        is_approved: loc.is_approved,
        staff_count: staffCount,
        total_sales: totalSales
      });
    }

    res.json({
      status: 'SUCCESS',
      total_network_sales: totalNetworkSales,
      locations: enrichedLocations
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
