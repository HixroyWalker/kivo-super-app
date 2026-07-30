const express = require('express');
const admin = require('firebase-admin');

module.exports = (db) => {
  const router = express.Router();

  // Exchange Google idToken for Custom JWT / User Session
  router.post('/login', async (req, res) => {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'Missing idToken' });
    }

    try {
      // 1. Verify the Google ID Token via Firebase Admin
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const uid = decodedToken.uid;
      const email = decodedToken.email;

      // 2. Provision or Locate User Profile in Firestore
      const userRef = db.collection('users').doc(uid);
      const userDoc = await userRef.get();

      let isNew = false;
      if (!userDoc.exists) {
        isNew = true;
        await userRef.set({
          email: email,
          wallet_balance: 0,
          role: 'STANDARD',
          lynk_handle: email.split('@')[0], // Default handle
          created_at: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      // 3. Hardware Device Binding Verification
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

      // 4. Generate custom token
      const sessionToken = await admin.auth().createCustomToken(uid);

      res.status(200).json({
        user: { uid, email },
        isNew,
        token: sessionToken
      });

    } catch (error) {
      console.error('Authentication Error:', error);
      res.status(401).json({ error: 'Invalid or expired token' });
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
