const express = require('express');
const admin = require('firebase-admin');

module.exports = (db) => {
  const router = express.Router();

  // Log an ad impression and issue a micro-reward to the user
  router.post('/reward', async (req, res) => {
    const userId = req.user.uid;
    const { adId } = req.body;
    
    // Hardcoded micro-reward amount for watching an ad (e.g., 5 JMD)
    const REWARD_AMOUNT = 5.00;

    try {
      await db.runTransaction(async (t) => {
        const walletRef = db.collection('wallets').doc(userId);
        const walletDoc = await t.get(walletRef);

        let currentBalance = 0;
        if (walletDoc.exists) {
            currentBalance = walletDoc.data().balance || 0;
        }

        // 1. Update User Balance
        t.set(walletRef, {
            balance: currentBalance + REWARD_AMOUNT,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // 2. Log the Ad Impression Transaction
        const transactionRef = db.collection('transactions').doc();
        t.set(transactionRef, {
            type: 'AD_REWARD',
            recipientId: userId,
            adId: adId,
            amount: REWARD_AMOUNT,
            currency: 'JMD',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      res.status(200).json({ status: 'SUCCESS', message: `Rewarded ${REWARD_AMOUNT} JMD` });
    } catch (error) {
      console.error('Ad Reward Error:', error);
      res.status(500).json({ error: 'Failed to process ad reward' });
    }
  });

  return router;
};
