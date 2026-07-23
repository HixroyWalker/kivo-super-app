const express = require('express');

module.exports = (db) => {
  const router = express.Router();

  // Fetch Ledger History and Analytics for a User/Merchant
  router.get('/ledger', async (req, res) => {
    // req.user is populated by the requireAuth middleware
    const userId = req.user.uid;

    try {
      // 1. Fetch recent transactions where user is sender OR receiver
      const sentRef = db.collection('transactions').where('senderId', '==', userId).limit(50);
      const receivedRef = db.collection('transactions').where('recipientId', '==', userId).limit(50);
      
      const [sentSnapshot, receivedSnapshot] = await Promise.all([
        sentRef.get(),
        receivedRef.get()
      ]);

      const transactions = [];
      let totalInflow = 0;
      let totalOutflow = 0;

      sentSnapshot.forEach(doc => {
        const data = doc.data();
        transactions.push({ id: doc.id, type: 'SENT', ...data });
        totalOutflow += data.amount || 0;
      });

      receivedSnapshot.forEach(doc => {
        const data = doc.data();
        transactions.push({ id: doc.id, type: 'RECEIVED', ...data });
        totalInflow += data.amount || 0;
      });

      // Sort by timestamp descending
      transactions.sort((a, b) => b.timestamp - a.timestamp);

      // 2. Mock Analytics calculation (In production, this might aggregate over time periods)
      const analytics = {
        totalInflow,
        totalOutflow,
        netBalance: totalInflow - totalOutflow,
        transactionCount: transactions.length
      };

      res.status(200).json({
        analytics,
        ledger: transactions
      });

    } catch (error) {
      console.error('Accounting Error:', error);
      res.status(500).json({ error: 'Failed to fetch ledger data' });
    }
  });

  return router;
};
