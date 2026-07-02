const express = require('express');
const router = express.Router();
const { User, Merchant, Transaction, AdminSetting } = require('../models');
const authMiddleware = require('../middleware/auth');

// Simple Admin Authorization Middleware
const adminAuth = (req, res, next) => {
  if (req.user.role !== 'ADMIN') {
    return res.status(403).json({ error: 'Forbidden: Admin access required' });
  }
  next();
};

// All admin routes require authentication and ADMIN role
router.use(authMiddleware, adminAuth);

// ── GET Platform Stats ───────────────────────────────────────────────────────
router.get('/stats', async (req, res) => {
  try {
    const userCount = await User.count();
    const merchantCount = await Merchant.count();
    const txCount = await Transaction.count({ where: { status: 'COMPLETED' } });
    const txVolume = await Transaction.sum('amount', { where: { status: 'COMPLETED' } }) || 0;

    res.json({
      users: userCount,
      merchants: merchantCount,
      transactionCount: txCount,
      transactionVolume: txVolume
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── GET Admin Settings ───────────────────────────────────────────────────────
router.get('/settings', async (req, res) => {
  try {
    const settings = await AdminSetting.findAll();
    res.json(settings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── POST Update Admin Setting ────────────────────────────────────────────────
router.post('/settings', async (req, res) => {
  try {
    const { key, value } = req.body;
    if (!key || value === undefined) {
      return res.status(400).json({ error: 'Key and value are required' });
    }

    let setting = await AdminSetting.findByPk(key);
    if (!setting) {
      setting = await AdminSetting.create({ key, value });
    } else {
      setting.value = value;
      await setting.save();
    }
    res.json({ status: 'SUCCESS', setting });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── GET Pending Merchants ────────────────────────────────────────────────────
router.get('/merchants/pending', async (req, res) => {
  try {
    const merchants = await Merchant.findAll({
      where: { is_approved: false },
      include: [{ model: User, as: 'owner', attributes: ['email', 'phone', 'lynk_handle'] }]
    });
    res.json(merchants);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── POST Approve Merchant ────────────────────────────────────────────────────
router.post('/merchants/:id/approve', async (req, res) => {
  try {
    const merchant = await Merchant.findByPk(req.params.id);
    if (!merchant) {
      return res.status(404).json({ error: 'Merchant not found' });
    }

    merchant.is_approved = true;
    await merchant.save();
    res.json({ status: 'SUCCESS', merchant });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
