require('dotenv').config();
const express = require('express');
const { sequelize } = require('./models');
const authRouter = require('./routes/auth');
const walletRouter = require('./routes/wallet');
const internalRouter = require('./routes/internal');
const ticketsRouter = require('./routes/tickets');
const adminRouter = require('./routes/admin');
const authMiddleware = require('./middleware/auth');

const app = express();
app.use(express.json());

// Routes
app.use('/auth', authRouter);
app.use('/api/wallet', authMiddleware, walletRouter);
app.use('/internal', internalRouter);
app.use('/api/tickets', authMiddleware, ticketsRouter);
app.use('/api/admin', adminRouter);

app.get('/', (req, res) => {
  res.send('KIVO Backend API is running.');
});

const PORT = process.env.PORT || 8080;

const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log('Database connected.');
    
    // Sync schemas using alter: true to preserve data in persistent sqlite
    if (sequelize.options.dialect === 'sqlite') {
      await sequelize.query("PRAGMA foreign_keys = OFF;");
    }
    await sequelize.sync({ alter: true });
    if (sequelize.options.dialect === 'sqlite') {
      await sequelize.query("PRAGMA foreign_keys = ON;");
    }
    console.log('Database schema synchronized.');
    
    // Seed initial admin settings and fallback user if SQLite or database is empty
    const { AdminSetting, User, TransitFare } = require('./models');
    
    // Seed admin settings
    const settings = [
      { key: 'merchant_fee_pct', value: '0.025' },
      { key: 'merchant_mdr_pct', value: '0.025' },
      { key: 'merchant_flat_fee', value: '10' },
      { key: 'instant_settlement_fee', value: '150' },
      { key: 'safety_net_service_fee', value: '50' },
      { key: 'ticket_service_fee_pct', value: '0.05' },
      { key: 'transit_tech_fee', value: '20' },
      { key: 'p2p_transfer_fee', value: '0' },
      { key: 'p2p_fee_pct', value: '0.01' },
      { key: 'unity_gift_commission_pct', value: '0.01' },
      { key: 'promoted_post_cpc', value: '5' }
    ];
    for (const s of settings) {
      await AdminSetting.findOrCreate({ where: { key: s.key }, defaults: s });
    }
    console.log('Admin settings verified.');

    // Seed default users if empty
    const userCount = await User.count();
    if (userCount === 0) {
      const defaultUser = await User.create({
        id: '11111111-1111-1111-1111-111111111111',
        email: 'user@kivo.app',
        phone: '18765550100',
        lynk_handle: 'hixroy',
        wallet_balance: 10000.00,
        role: 'ADMIN'
      });
      console.log('Default user seeded:', defaultUser.lynk_handle);
      
      const defaultMerchant = await User.create({
        id: '22222222-2222-2222-2222-222222222222',
        email: 'merchant@kivo.app',
        phone: '18765550200',
        lynk_handle: 'merchant_bob',
        wallet_balance: 50000.00,
        role: 'MERCHANT'
      });
      console.log('Default merchant seeded:', defaultMerchant.lynk_handle);

      await TransitFare.create({
        id: '33333333-3333-3333-3333-333333333333',
        route_name: 'Downtown to Half Way Tree',
        fare: 150.00
      });
      console.log('Default transit fare seeded.');
    } else {
      // Upgrade existing dev user to ADMIN for testing
      const existingUser = await User.findOne({ where: { email: 'user@kivo.app' } });
      if (existingUser && existingUser.role !== 'ADMIN') {
        existingUser.role = 'ADMIN';
        await existingUser.save();
        console.log('Upgraded dev user to ADMIN');
      }
    }
  } catch (error) {
    console.error('Unable to connect to the database or sync:', error);
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
  });
};

startServer();
