const express = require('express');

module.exports = (db) => {
  const router = express.Router();

  // Webhook for Lynk Top-Ups
  router.post('/webhook/lynk', async (req, res) => {
    // In production, verify Lynk signature here
    const { lynk_handle, amount, external_id } = req.body;

    if (!lynk_handle || !amount || !external_id) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    try {
      await db.runTransaction(async (t) => {
        // 1. Find user by lynk_handle (Requires a collection group query or index in production)
        const usersRef = db.collection('users');
        const querySnapshot = await t.get(usersRef.where('lynk_handle', '==', lynk_handle).limit(1));
        
        if (querySnapshot.empty) {
          throw new Error('User not found');
        }

        const userDoc = querySnapshot.docs[0];
        const userRef = userDoc.ref;
        const userData = userDoc.data();

        // 2. Prevent double processing
        const txRef = db.collection('transactions').doc(external_id);
        const txDoc = await t.get(txRef);
        if (txDoc.exists) {
          throw new Error('Transaction already processed');
        }

        // 3. Update Balance (Atomic)
        const currentBalance = userData.wallet_balance || 0;
        t.update(userRef, { wallet_balance: currentBalance + amount });

        // 4. Create Transaction Record
        t.set(txRef, {
          recipient_id: userDoc.id,
          amount: amount,
          type: 'TOPUP',
          status: 'COMPLETED',
          source: 'LYNK',
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      res.status(200).json({ status: 'SUCCESS' });
    } catch (error) {
      console.error('Lynk Webhook Error:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
