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

      // 3. Generate a custom long-lived session token (per the KI architecture)
      // Note: In a pure Firebase setup, the client usually just uses the idToken.
      // But if we want to honor the "long-lived JWT" architecture:
      const sessionToken = await admin.auth().createCustomToken(uid);

      res.status(200).json({
        user: { uid, email },
        isNew,
        token: sessionToken // The client will use this to authenticate future requests
      });

    } catch (error) {
      console.error('Authentication Error:', error);
      res.status(401).json({ error: 'Invalid or expired token' });
    }
  });

  return router;
};
