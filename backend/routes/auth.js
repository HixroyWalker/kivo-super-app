// backend/routes/auth.js
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const { User, sequelize } = require('../models');
const authMiddleware = require('../middleware/auth');

const JWT_SECRET = process.env.JWT_SECRET || 'kivo-super-secret-development-key';

// Helper to verify Firebase ID Token (handles development mock bypass)
const verifyGoogleToken = async (idToken) => {
  if (process.env.MOCK_AUTH === 'true' || process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) {
    if (idToken.startsWith('mock_token_')) {
      const email = idToken.replace('mock_token_', '');
      return { email, email_verified: true, name: email.split('@')[0] };
    }
  }

  // Real Firebase Admin authentication
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    throw new Error('Firebase token verification failed: ' + error.message);
  }
};

// ── 1. Google Token Exchange & Register ─────────────────────────
router.post('/login-or-register', async (req, res) => {
  const { idToken, device_uuid } = req.body;

  if (!idToken) {
    return res.status(400).json({ error: 'Google idToken is required.' });
  }

  try {
    const verified = await verifyGoogleToken(idToken);
    const email = verified.email;

    if (!email) {
      return res.status(400).json({ error: 'Token does not contain a valid email address.' });
    }

    const t = await sequelize.transaction();
    try {
      let user = await User.findOne({ where: { email }, lock: t.LOCK.UPDATE, transaction: t });

      if (!user) {
        // Generate a clean default lynk handle from email prefix
        const defaultHandle = email.split('@')[0].toLowerCase().replace(/[^a-z0-9]/g, '');
        user = await User.create({
          email,
          lynk_handle: defaultHandle,
          device_uuid: device_uuid || null,
          wallet_balance: 1000.00, // Seed initial balance for dev convenience
          role: 'USER',
          is_active: true
        }, { transaction: t });
      } else if (device_uuid && user.device_uuid !== device_uuid) {
        // Enforce hardware binding update or block depending on security policy.
        user.device_uuid = device_uuid;
        await user.save({ transaction: t });
      }

      await t.commit();

      // Issue long-lived 30-day session token
      const sessionToken = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });

      res.status(200).json({
        token: sessionToken,
        user: {
          id: user.id,
          email: user.email,
          phone: user.phone,
          lynk_handle: user.lynk_handle,
          device_uuid: user.device_uuid,
          wallet_balance: user.wallet_balance
        }
      });
    } catch (err) {
      await t.rollback();
      throw err;
    }
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

// ── 2. Phone Linking & SMS Bypass ──────────────────────────────
router.post('/phone/start', authMiddleware, async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Phone number is required.' });
  }

  try {
    // Check if another account has already bound this number
    const existing = await User.findOne({ where: { phone } });
    if (existing && existing.id !== req.user.id) {
      return res.status(400).json({ error: 'PHONE_ALREADY_USED' });
    }

    // Check if SMS verification is disabled administratively
    // Default to bypass mode in development unless strictly set to require SMS
    const disableSMS = process.env.DISABLE_SMS_VERIFICATION === 'true' || process.env.NODE_ENV === 'development' || !process.env.NODE_ENV;

    if (disableSMS) {
      // SMS verification is turned off: link immediately
      const user = await User.findByPk(req.user.id);
      user.phone = phone;
      await user.save();

      return res.status(200).json({
        smsRequired: false,
        status: 'SUCCESS',
        phone: user.phone
      });
    } else {
      // SMS verification is active: generate SMS trigger simulation
      return res.status(200).json({
        smsRequired: true,
        status: 'PENDING',
        message: 'SMS verification code sent.'
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── 3. Session User Recovery (/me) ─────────────────────────────
router.get('/me', authMiddleware, (req, res) => {
  res.status(200).json({
    user: {
      id: req.user.id,
      email: req.user.email,
      phone: req.user.phone,
      lynk_handle: req.user.lynk_handle,
      device_uuid: req.user.device_uuid,
      wallet_balance: req.user.wallet_balance,
      role: req.user.role
    }
  });
});

module.exports = router;
