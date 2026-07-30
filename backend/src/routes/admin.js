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
      console.error('Admin Staff Fee Error:', error);
      res.status(500).json({ error: error.message });
    }
  });
  router.post('/fees/p2p', async (req, res) => {
    if (req.user && req.user.role !== 'ADMIN' && !req.user.admin) {
      return res.status(403).json({ error: 'Forbidden: Admin access required' });
    }
    const { flatFee, percentageFee, minThreshold } = req.body;

    try {
      await db.collection('platform_config').doc('fees').set({
        p2p: {
          flatFee: parseFloat(flatFee || 0),
          percentageFee: parseFloat(percentageFee || 0),
          minThreshold: parseFloat(minThreshold || 0),
          updatedAt: new Date().toISOString()
        }
      }, { merge: true });

      res.status(200).json({ status: 'SUCCESS', message: 'P2P transaction fee config updated' });
    } catch (error) {
      console.error('P2P Fee Config Error:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Configure Per-Staff/User Billing Under Merchant Account
  router.post('/fees/merchant-staff', async (req, res) => {
    if (req.user && req.user.role !== 'ADMIN' && !req.user.admin) {
      return res.status(403).json({ error: 'Forbidden: Admin access required' });
    }
    const { merchantId, staffId, monthlySeatFee, staffCommissionPct } = req.body;

    try {
      await db.collection('merchants').doc(merchantId).collection('staff_members').doc(staffId).set({
        billing: {
          monthlySeatFee: parseFloat(monthlySeatFee || 0),
          staffCommissionPct: parseFloat(staffCommissionPct || 0),
          updatedAt: new Date().toISOString()
        }
      }, { merge: true });

      res.status(200).json({ status: 'SUCCESS', message: 'Merchant staff sub-account billing updated' });
    } catch (error) {
      console.error('Merchant Staff Fee Config Error:', error);
      res.status(500).json({ error: error.message });
    }
  });

  // Merchant Business KYC Review & Approval
  router.get('/kyc/pending', async (req, res) => {
    if (req.user && req.user.role !== 'ADMIN' && !req.user.admin) {
      return res.status(403).json({ error: 'Forbidden: Admin access required' });
    }

    try {
      const snapshot = await db.collection('merchant_kyc').where('status', '==', 'PENDING_VERIFICATION').get();
      const list = [];
      snapshot.forEach(doc => list.push({ id: doc.id, ...doc.data() }));
      res.status(200).json({ pendingKYC: list });
    } catch (error) {
      console.error('Fetch KYC Error:', error);
      res.status(500).json({ error: error.message });
    }
  });

  router.post('/kyc/review', async (req, res) => {
    if (req.user && req.user.role !== 'ADMIN' && !req.user.admin) {
      return res.status(403).json({ error: 'Forbidden: Admin access required' });
    }
    const { merchantId, action, notes } = req.body; // action: APPROVED or REJECTED

    try {
      await db.collection('merchant_kyc').doc(merchantId).update({
        status: action === 'APPROVED' ? 'VERIFIED' : 'REJECTED',
        reviewNotes: notes || '',
        reviewedAt: new Date().toISOString()
      });

      res.status(200).json({ status: 'SUCCESS', merchantId, action });
    } catch (error) {
      console.error('KYC Review Error:', error);
      res.status(500).json({ error: error.message });
    }
  });
};
