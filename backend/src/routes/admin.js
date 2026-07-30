const express = require('express');

module.exports = (db) => {
  const router = express.Router();

  // Admin Configuration: Set Dynamic Fee for a Merchant's Staff Member
  router.post('/staff-fee', async (req, res) => {
    const { merchantId, staffId, feePercentage } = req.body;

    if (req.user && req.user.role !== 'ADMIN' && !req.user.admin) {
      return res.status(403).json({ error: 'Forbidden: Admin access required' });
    }

    if (!merchantId || !staffId || feePercentage == null) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    try {
      const staffRef = db.collection('merchants').doc(merchantId).collection('staff_members').doc(staffId);
      
      await staffRef.set({
        feeOverride: parseFloat(feePercentage),
        updatedAt: new Date().toISOString()
      }, { merge: true });

      res.status(200).json({ status: 'SUCCESS', message: 'Staff fee override updated successfully' });
    } catch (error) {
      console.error('Admin Fee Config Error:', error);
      res.status(500).json({ error: error.message });
    }
  });

  return router;
};
