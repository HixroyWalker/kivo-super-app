const express = require('express');
const crypto = require('crypto');

module.exports = (db) => {
  const router = express.Router();
  const SECRET_SALT = 'Kivo_Offline_Mesh_Secret_2026_Secure_Key';

  // Process and Settle Queued Offline Transactions
  router.post('/sync-offline', async (req, res) => {
    const { offlinePayloads } = req.body; // Array of offline transaction payloads

    if (!Array.isArray(offlinePayloads) || offlinePayloads.length === 0) {
      return res.status(400).json({ error: 'No offline payloads provided' });
    }

    const settledCount = 0;
    const errors = [];

    try {
      for (const payload of offlinePayloads) {
        const { mId, amt, cur, ts, sig } = payload;

        // 1. Verify Cryptographic HMAC Signature
        const nonce = (ts % 10000).toString();
        const rawData = `${mId}:${amt}:${cur}:${ts}:${nonce}`;
        const hmac = crypto.createHmac('sha256', SECRET_SALT).update(rawData).digest('hex');
        const expectedSig = hmac.substring(0, 16);

        if (sig !== expectedSig) {
          errors.push({ payload, error: 'INVALID_OFFLINE_SIGNATURE' });
          continue;
        }

        // 2. Perform Atomic Settlement in Firestore
        await db.runTransaction(async (t) => {
          const merchantRef = db.collection('users').doc(mId);
          const merchantDoc = await t.get(merchantRef);

          if (!merchantDoc.exists) {
            throw new Error('Merchant account not found');
          }

          // Credit merchant wallet balance
          t.update(merchantRef, {
            wallet_balance: require('firebase-admin').firestore.FieldValue.increment(parseFloat(amt))
          });

          // Record settlement log
          const logRef = db.collection('transactions').doc();
          t.set(logRef, {
            merchant_id: mId,
            amount: parseFloat(amt),
            currency: cur,
            type: 'OFFLINE_SETTLEMENT',
            offline_timestamp: ts,
            settled_at: new Date().toISOString()
          });
        });

        settledCount++;
      }

      res.status(200).json({
        status: 'SUCCESS',
        totalProcessed: offlinePayloads.length,
        settledCount,
        errors
      });
    } catch (error) {
      console.error('Offline Sync Error:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
