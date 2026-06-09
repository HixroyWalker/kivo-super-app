// backend/routes/internal.js (Append poll-lynk)
const express = require('express');
const router = express.Router();
const axios = require('axios');
const { Transaction, User, sequelize } = require('../models');

router.post('/poll-lynk', async (req, res) => {
  const t = await sequelize.transaction();
  try {
    // In a real scenario, you'd call the Lynk API with an API key
    // const response = await axios.get('https://api.lynk.nz/v1/transactions', { headers: { 'Authorization': 'Bearer ...' } });
    
    // Placeholder: Simulate finding a new incoming top-up
    const mockIncoming = [
      { lynk_handle: 'hixroy', amount: 5000, external_id: 'lynk_tx_999' }
    ];

    for (const item of mockIncoming) {
      const user = await User.findOne({ where: { lynk_handle: item.lynk_handle }, lock: t.LOCK.UPDATE, transaction: t });
      if (user) {
        // Prevent double-processing via external_id in metadata
        const existing = await Transaction.findOne({ where: { 'metadata.external_id': item.external_id }, transaction: t });
        if (!existing) {
          user.wallet_balance = parseFloat(user.wallet_balance) + item.amount;
          await user.save({ transaction: t });
          
          await Transaction.create({
            recipient_id: user.id,
            amount: item.amount,
            type: 'TOPUP',
            status: 'COMPLETED',
            metadata: { external_id: item.external_id, source: 'LYNK' }
          }, { transaction: t });
        }
      }
    }

    await t.commit();
    res.json({ status: 'SUCCESS' });
  } catch (error) {
    await t.rollback();
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
