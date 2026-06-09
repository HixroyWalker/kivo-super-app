// backend/scripts/init-settings.js
const { AdminSetting } = require('../models');

const initSettings = async () => {
  const settings = [
    { key: 'merchant_mdr_pct', value: '0.025', description: 'Merchant Discount Rate (2.5%)' },
    { key: 'merchant_flat_fee', value: '10', description: 'Flat fee per merchant transaction (JMD)' },
    { key: 'instant_settlement_fee', value: '150', description: 'Fee for instant bank settlement (JMD)' },
    { key: 'safety_net_service_fee', value: '50', description: 'Fixed service fee for Safety Net usage' },
    { key: 'ticket_service_fee_pct', value: '0.05', description: 'Service fee percentage for event tickets' },
    { key: 'transit_tech_fee', value: '20', description: 'Flat tech fee per taxi fare processed' },
    { key: 'p2p_transfer_fee', value: '0', description: 'Standard P2P transfer fee (usually free)' },
    { key: 'unity_gift_commission_pct', value: '0.01', description: 'Commission on social Unity Gifts' },
    { key: 'promoted_post_cpc', value: '5', description: 'Cost per click for promoted social posts' }
  ];

  for (const s of settings) {
    await AdminSetting.upsert(s);
  }
  console.log('Admin settings initialized.');
};

initSettings();
