const express = require('express');
const router = express.Router();
const { sequelize, User, Transaction, Event, Ticket, AdminSetting, TransitFare } = require('../models');
const { v4: uuidv4 } = require('uuid');

// Helper to get current fee from AdminSettings
const getFee = async (key) => {
  const setting = await AdminSetting.findByPk(key);
  return setting ? parseFloat(setting.value) : 0;
};

// ── Get All Events ─────────────────────────────────────────────
router.get('/events', async (req, res) => {
  try {
    const events = await Event.findAll({
      order: [['date', 'ASC']]
    });
    
    // For each event, count available tickets
    const results = await Promise.all(events.map(async (event) => {
      const availableCount = await Ticket.count({
        where: { event_id: event.id, status: 'AVAILABLE' }
      });
      return {
        ...event.toJSON(),
        available_tickets: availableCount
      };
    }));

    res.json(results);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Create Event ──────────────────────────────────────────────
router.post('/events', async (req, res) => {
  const { title, description, image_url, price, date, ticket_count } = req.body;
  const merchant_id = req.user ? req.user.id : uuidv4(); // Mock merchant id if user is missing

  const t = await sequelize.transaction();
  try {
    const event = await Event.create({
      id: uuidv4(),
      merchant_id,
      title,
      description: description || 'No description provided.',
      image_url: image_url || 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=800&q=80',
      price: parseFloat(price) || 0.00,
      date: date || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 1 week from now
    }, { transaction: t });

    // Create ticket slots
    const count = parseInt(ticket_count, 10) || 50;
    const tickets = [];
    for (let i = 0; i < count; i++) {
      tickets.push({
        id: uuidv4(),
        event_id: event.id,
        price: event.price,
        qr_token: `tkt-${event.id}-${i}-${Math.floor(100000 + Math.random() * 900000)}`,
        status: 'AVAILABLE'
      });
    }
    await Ticket.bulkCreate(tickets, { transaction: t });

    await t.commit();
    res.status(201).json({
      status: 'SUCCESS',
      event,
      created_tickets: count
    });
  } catch (error) {
    await t.rollback();
    res.status(400).json({ error: error.message });
  }
});

// ── Edit Event/Ticket Details (Persists Price Updates) ─────────
router.put('/events/:id', async (req, res) => {
  const { id } = req.params;
  const { title, description, image_url, price, date } = req.body;

  const t = await sequelize.transaction();
  try {
    const event = await Event.findByPk(id, { transaction: t });
    if (!event) {
      throw new Error('Event not found');
    }

    if (title !== undefined) event.title = title;
    if (description !== undefined) event.description = description;
    if (image_url !== undefined) event.image_url = image_url;
    if (date !== undefined) event.date = date;
    
    if (price !== undefined) {
      const newPrice = parseFloat(price);
      event.price = newPrice;
      
      // Also update prices of all AVAILABLE tickets for this event
      await Ticket.update(
        { price: newPrice },
        { where: { event_id: id, status: 'AVAILABLE' }, transaction: t }
      );
    }

    await event.save({ transaction: t });
    await t.commit();
    
    res.json({
      status: 'SUCCESS',
      event
    });
  } catch (error) {
    await t.rollback();
    res.status(400).json({ error: error.message });
  }
});

// ── Buy a Ticket ───────────────────────────────────────────────
router.post('/buy', async (req, res) => {
  const { event_id, quantity, tier } = req.body;
  const buyer_id = req.user.id;
  const qty = parseInt(quantity, 10) || 1;

  const t = await sequelize.transaction();
  try {
    const buyer = await User.findByPk(buyer_id, { lock: t.LOCK.UPDATE, transaction: t });
    const event = await Event.findByPk(event_id, { transaction: t });
    if (!event) {
      throw new Error('Event not found');
    }

    let multiplier = 1.0;
    if (tier === 'VIP') {
      multiplier = 2.0;
    } else if (tier === 'VVIP') {
      multiplier = 3.0;
    }

    const ticketPrice = parseFloat(event.price) * multiplier;
    const serviceFeePct = await getFee('ticket_service_fee_pct');
    const itemTotal = ticketPrice * qty;
    const serviceFee = itemTotal * serviceFeePct;
    const grandTotal = itemTotal + serviceFee;

    if (parseFloat(buyer.wallet_balance) < grandTotal) {
      throw new Error('Insufficient wallet balance to purchase tickets.');
    }

    // Find available tickets
    const availableTickets = await Ticket.findAll({
      where: { event_id, status: 'AVAILABLE' },
      limit: qty,
      lock: t.LOCK.UPDATE,
      transaction: t
    });

    if (availableTickets.length < qty) {
      throw new Error(`Only ${availableTickets.length} tickets available for this event.`);
    }

    // Deduct buyer balance
    buyer.wallet_balance = parseFloat(buyer.wallet_balance) - grandTotal;
    await buyer.save({ transaction: t });

    // Update tickets with the tier-adjusted price
    for (const ticket of availableTickets) {
      ticket.owner_id = buyer.id;
      ticket.status = 'SOLD';
      ticket.price = ticketPrice;
      await ticket.save({ transaction: t });
    }

    // Pay event organizer (merchant)
    const organizer = await User.findOne({
      include: [{
        model: Merchant,
        as: 'Merchant', // Sequelize alias, fallback to standard query
        where: { id: event.merchant_id }
      }],
      transaction: t
    }) || await User.findByPk(event.merchant_id, { lock: t.LOCK.UPDATE, transaction: t }); // fallback

    if (organizer) {
      organizer.wallet_balance = parseFloat(organizer.wallet_balance) + itemTotal;
      await organizer.save({ transaction: t });
    }

    // Log transaction
    const tx = await Transaction.create({
      id: uuidv4(),
      sender_id: buyer_id,
      recipient_id: organizer ? organizer.id : null,
      amount: grandTotal,
      fee: serviceFee,
      type: 'ORDER',
      status: 'COMPLETED',
      metadata: { event_id, tier: tier || 'GA', ticket_ids: availableTickets.map(tk => tk.id) }
    }, { transaction: t });

    await t.commit();
    res.json({
      status: 'SUCCESS',
      purchased_tickets: availableTickets,
      total_paid: grandTotal
    });
  } catch (error) {
    await t.rollback();
    res.status(400).json({ error: error.message });
  }
});

// ── Get Purchased Tickets ──────────────────────────────────────
router.get('/my-tickets', async (req, res) => {
  const buyer_id = req.user.id;
  try {
    const tickets = await Ticket.findAll({
      where: { owner_id: buyer_id, status: 'SOLD' },
      include: [{
        model: Event,
        as: 'Event'
      }]
    });
    res.json(tickets);
  } catch (error) {
    console.error('[Tickets API] Error fetching my-tickets:', error);
    res.status(500).json({ error: error.message });
  }
});

// ── Get Transit Routes (With Auto Seeding) ─────────────────────
router.get('/transit', async (req, res) => {
  try {
    let routes = await TransitFare.findAll({ order: [['fare', 'ASC']] });
    
    // Seed default route passes if empty
    if (routes.length === 0) {
      await TransitFare.bulkCreate([
        { id: uuidv4(), route_name: 'Kingston Metro Express', fare: 150.00 },
        { id: uuidv4(), route_name: 'Portmore Transit Link', fare: 120.00 },
        { id: uuidv4(), route_name: 'Montego Bay Airport Shuttle', fare: 250.00 },
        { id: uuidv4(), route_name: 'Ocho Rios Coastal Cruise', fare: 400.00 }
      ]);
      routes = await TransitFare.findAll({ order: [['fare', 'ASC']] });
    }
    
    res.json(routes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Get Purchased Transit Passes ──────────────────────────────
router.get('/my-transit', async (req, res) => {
  const buyer_id = req.user.id;
  try {
    const { Order, Merchant } = require('../models');

    // Find the Transit Authority merchant
    const transitMerchant = await Merchant.findOne({ where: { business_name: 'Transit Authority' } });
    if (!transitMerchant) {
      return res.json([]);
    }

    const orders = await Order.findAll({
      where: { customer_id: buyer_id, merchant_id: transitMerchant.id, status: 'PAID' },
      order: [['createdAt', 'DESC']]
    });

    const passes = [];
    orders.forEach(order => {
      let items = order.items;
      if (typeof items === 'string') {
        try {
          items = JSON.parse(items);
        } catch (e) {
          items = [];
        }
      }
      if (items && Array.isArray(items)) {
        items.forEach(item => {
          passes.push({
            order_id: order.id,
            pickup_code: order.pickup_code,
            route_name: item.name || 'Transit Route Pass',
            price: item.price,
            quantity: item.quantity,
            purchased_at: order.created_at,
            qr_token: `transit-pass-${order.id}-${item.product_id}`
          });
        });
      }
    });

    res.json(passes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
