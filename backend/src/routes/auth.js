const express = require('express');
const admin = require('firebase-admin');

const ADMIN_EMAILS = (process.env.ADMIN_EMAILS || 'walkerha2@icloud.com,hixroywalker@gmail.com')
  .split(',')
  .map(e => e.trim().toLowerCase());

module.exports = (db) => {
  const router = express.Router();

  // Exchange Google / Apple idToken for Custom JWT / User Session
  router.post('/login', async (req, res) => {
    const { idToken, email: clientEmail } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'Missing idToken' });
    }

    try {
      // 1. Verify the ID Token via Firebase Admin
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const uid = decodedToken.uid;
      const email = (decodedToken.email || clientEmail || '').toLowerCase();

      const isAdmin = ADMIN_EMAILS.includes(email);

      // 2. Set Custom Claims for Admin if applicable
      if (isAdmin) {
        await admin.auth().setCustomUserClaims(uid, {
          role: 'ADMIN',
          admin: true,
        });
      }

      // 3. Provision or Locate User Profile in Firestore
      const userRef = db.collection('users').doc(uid);
      const userDoc = await userRef.get();

      let isNew = false;
      if (!userDoc.exists) {
        isNew = true;
        await userRef.set({
          email: email,
          wallet_balance: 0,
          role: isAdmin ? 'ADMIN' : 'STANDARD',
          lynk_handle: email.split('@')[0],
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          is_admin: isAdmin,
        });
      } else if (isAdmin && userDoc.data().role !== 'ADMIN') {
        await userRef.update({
          role: 'ADMIN',
          is_admin: true,
        });
      }

      // 4. Hardware Device Binding Verification
      const { deviceId } = req.body;
      const userData = userDoc.exists ? userDoc.data() : {};
      
      if (userData.bound_device_id && deviceId && userData.bound_device_id !== deviceId) {
        return res.status(403).json({
          error: 'DEVICE_MISMATCH_REAUTH_REQUIRED',
          message: 'Login attempted from an unrecognized device. Mandatory Re-authentication required.'
        });
      }

      if (deviceId && !userData.bound_device_id) {
        await userRef.update({ bound_device_id: deviceId });
      }

      // 5. Generate custom token
      const sessionToken = await admin.auth().createCustomToken(uid, {
        role: isAdmin ? 'ADMIN' : 'STANDARD',
        admin: isAdmin,
      });

      res.status(200).json({
        user: { uid, email, role: isAdmin ? 'ADMIN' : 'STANDARD', isAdmin },
        isNew,
        token: sessionToken,
      });

    } catch (error) {
      console.error('Authentication Error:', error);
      res.status(401).json({ error: 'Invalid or expired token' });
    }
  });

  // Check Current Authenticated User & Admin Access
  router.get('/me', async (req, res) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized: Missing token' });
    }

    const token = authHeader.split('Bearer ')[1];
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const email = (decoded.email || '').toLowerCase();
      const isAdmin = ADMIN_EMAILS.includes(email) || decoded.admin === true || decoded.role === 'ADMIN';

      res.status(200).json({
        uid: decoded.uid,
        email,
        role: isAdmin ? 'ADMIN' : (decoded.role || 'STANDARD'),
        hasAdminAccess: isAdmin,
      });
    } catch (e) {
      res.status(401).json({ error: 'Invalid token' });
    }
  });

  // Active Device Sessions List
  router.get('/sessions', async (req, res) => {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
    
    try {
      const snapshot = await db.collection('users').doc(req.user.uid).collection('sessions').get();
      const sessions = [];
      snapshot.forEach(doc => sessions.push({ id: doc.id, ...doc.data() }));
      res.status(200).json({ sessions });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Revoke Remote Session
  router.post('/sessions/revoke', async (req, res) => {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
    const { sessionId } = req.body;

    try {
      await db.collection('users').doc(req.user.uid).collection('sessions').doc(sessionId).delete();
      res.status(200).json({ status: 'SUCCESS', message: 'Session revoked' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
