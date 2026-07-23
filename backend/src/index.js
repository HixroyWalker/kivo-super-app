const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const admin = require('firebase-admin');

// Initialize Firebase Admin (uses Application Default Credentials on GCP)
admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

const authRoutes = require('./routes/auth');
const transactionRoutes = require('./routes/transactions');
const walletRoutes = require('./routes/wallet');
const adminRoutes = require('./routes/admin');
const marketplaceRoutes = require('./routes/marketplace');

app.use('/api/auth', authRoutes(db)); // Public
app.use('/api/transactions', transactionRoutes(db)); // Public (Webhook verification handles auth internally)
app.use('/api/marketplace', marketplaceRoutes(db)); // Public (Catalog view)

// Protected Routes
const requireAuth = require('./middleware/authMiddleware');
const messagingRoutes = require('./routes/messaging');
const accountingRoutes = require('./routes/accounting');
const adsRoutes = require('./routes/ads');
const notificationRoutes = require('./routes/notifications');

app.use('/api/wallet', requireAuth, walletRoutes(db));
app.use('/api/admin', requireAuth, adminRoutes(db));
app.use('/api/messaging', requireAuth, messagingRoutes(db));
app.use('/api/accounting', requireAuth, accountingRoutes(db));
app.use('/api/ads', requireAuth, adsRoutes(db));
app.use('/api/notifications', requireAuth, notificationRoutes(db));

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Kivo backend listening on port ${PORT}`);
});
