const express = require('express');
const admin = require('firebase-admin');

module.exports = (db) => {
  const router = express.Router();

  // P2P Transfer with Admin Fee Deduction
  router.post('/transfer', async (req, res) => {
    const { senderId, recipientId, amount, note, staffId } = req.body;

    if (!senderId || !recipientId || !amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid transfer details' });
    }

    try {
      await db.runTransaction(async (t) => {
        const senderRef = db.collection('users').doc(senderId);
        const recipientRef = db.collection('users').doc(recipientId);
        const adminRef = db.collection('users').doc('admin_revenue_account');

        const [senderDoc, recipientDoc, adminDoc] = await Promise.all([
          t.get(senderRef),
          t.get(recipientRef),
          t.get(adminRef)
        ]);

        if (!senderDoc.exists || !recipientDoc.exists) {
          throw new Error('Sender or Recipient not found');
        }

        const senderData = senderDoc.data();
        if ((senderData.wallet_balance || 0) < amount) {
          throw new Error('Insufficient funds');
        }

        // 1. Calculate Admin Fee (Default 2%, overridden by Staff Settings if staffId is provided)
        let feePercentage = 0.02; 
        
        if (staffId && recipientData.merchantId) {
          const staffRef = db.collection('merchants').doc(recipientData.merchantId)
                             .collection('staff_members').doc(staffId);
          const staffDoc = await t.get(staffRef);
          if (staffDoc.exists && staffDoc.data().feeOverride) {
            feePercentage = staffDoc.data().feeOverride; // Dynamic Staff Fee Routing
          }
        }

        const adminFee = amount * feePercentage;
        const netAmount = amount - adminFee;

        // 2. Perform Atomic Balance Updates
        t.update(senderRef, { wallet_balance: admin.firestore.FieldValue.increment(-amount) });
        t.update(recipientRef, { wallet_balance: admin.firestore.FieldValue.increment(netAmount) });
        
        if (adminDoc.exists) {
            t.update(adminRef, { wallet_balance: admin.firestore.FieldValue.increment(adminFee) });
        }

        // 3. Log the Transaction (Social Feed enabled)
        const txRef = db.collection('transactions').doc();
        t.set(txRef, {
          sender_id: senderId,
          recipient_id: recipientId,
          amount: amount,
          admin_fee: adminFee,
          net_amount: netAmount,
          note: note || '',
          type: 'P2P_TRANSFER',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          is_public: true // For the social feed
        });
      });

      res.status(200).json({ status: 'SUCCESS' });
    } catch (error) {
      console.error('Transfer Error:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
