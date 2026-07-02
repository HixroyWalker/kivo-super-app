const { Sequelize, DataTypes } = require('sequelize');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const sequelize = process.env.DB_URL
  ? new Sequelize(process.env.DB_URL, {
      dialect: 'postgres',
      logging: false,
      pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
    })
  : new Sequelize({
      dialect: 'sqlite',
      storage: path.join(__dirname, '..', 'database.sqlite'),
      logging: false,
    });



// ── User ──────────────────────────────────────────────────────
const User = sequelize.define('User', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  email: { type: DataTypes.STRING, unique: true, allowNull: false },
  phone: DataTypes.STRING,
  lynk_handle: DataTypes.STRING,
  device_uuid: DataTypes.STRING,
  wallet_balance: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  balance_usd: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  balance_cad: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  balance_gbp: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  safety_net_limit: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  safety_net_used: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  unity_score: { type: DataTypes.INTEGER, defaultValue: 0 },
  role: { type: DataTypes.ENUM('USER', 'MERCHANT', 'ADMIN'), defaultValue: 'USER' },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true }
}, { tableName: 'users', underscored: true });

// ── Transaction ───────────────────────────────────────────────
const Transaction = sequelize.define('Transaction', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  sender_id: { type: DataTypes.UUID, references: { model: 'users', key: 'id' } },
  recipient_id: { type: DataTypes.UUID, references: { model: 'users', key: 'id' } },
  amount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
  fee: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  currency: { type: DataTypes.STRING(3), defaultValue: 'JMD' },
  type: { type: DataTypes.STRING(50), allowNull: false }, // P2P, TOPUP, FX, UNITY_GIFT, ORDER
  status: { type: DataTypes.ENUM('PENDING', 'COMPLETED', 'FAILED', 'REVERSED'), defaultValue: 'PENDING' },
  idempotency_key: { type: DataTypes.STRING, unique: true },
  metadata: DataTypes.JSONB
}, { tableName: 'transactions', underscored: true });

// ── Mandate ───────────────────────────────────────────────────
const Mandate = sequelize.define('Mandate', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  user_id: { type: DataTypes.UUID, allowNull: false },
  merchant_id: { type: DataTypes.UUID, allowNull: false },
  amount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
  frequency: { type: DataTypes.ENUM('WEEKLY', 'MONTHLY', 'YEARLY'), defaultValue: 'MONTHLY' },
  next_debit_date: DataTypes.DATE,
  status: { type: DataTypes.ENUM('ACTIVE', 'PAUSED', 'CANCELLED'), defaultValue: 'ACTIVE' }
}, { tableName: 'mandates', underscored: true });

// ── Merchant ──────────────────────────────────────────────────
const Merchant = sequelize.define('Merchant', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  owner_id: { type: DataTypes.UUID, allowNull: false },
  business_name: { type: DataTypes.STRING, allowNull: false },
  bridge_loan_limit: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  loyalty_rate: { type: DataTypes.INTEGER, defaultValue: 1 },
  is_approved: { type: DataTypes.BOOLEAN, defaultValue: false },
  kyc_document_url: { type: DataTypes.STRING },
  business_registration_url: { type: DataTypes.STRING },
  additional_docs_url: { type: DataTypes.STRING }
}, { tableName: 'merchants', underscored: true });

// ── MerchantStaff ─────────────────────────────────────────────
const MerchantStaff = sequelize.define('MerchantStaff', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  merchant_id: { type: DataTypes.UUID, allowNull: false },
  user_id: { type: DataTypes.UUID, allowNull: false },
  role: { type: DataTypes.ENUM('MANAGER', 'CASHIER'), defaultValue: 'CASHIER' },
  activation_pin: DataTypes.STRING(6),
  is_active: { type: DataTypes.BOOLEAN, defaultValue: false }
}, { tableName: 'merchant_staff', underscored: true });

// ── Product ───────────────────────────────────────────────────
const Product = sequelize.define('Product', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  merchant_id: { type: DataTypes.UUID, allowNull: false },
  name: { type: DataTypes.STRING, allowNull: false },
  price: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
  image_url: DataTypes.TEXT,
  barcode: DataTypes.STRING,
  stock_quantity: { type: DataTypes.INTEGER, defaultValue: 0 },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true }
}, { tableName: 'products', underscored: true });

// ── Order ─────────────────────────────────────────────────────
const Order = sequelize.define('Order', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  customer_id: { type: DataTypes.UUID, allowNull: false },
  merchant_id: { type: DataTypes.UUID, allowNull: false },
  items: { type: DataTypes.JSONB, allowNull: false },
  total_amount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
  status: { type: DataTypes.ENUM('PENDING', 'PAID', 'COLLECTED', 'CANCELLED'), defaultValue: 'PENDING' },
  pickup_code: DataTypes.STRING(4),
  shipping_address: DataTypes.TEXT,
  metadata: DataTypes.JSONB
}, { tableName: 'orders', underscored: true });

// ── Post ──────────────────────────────────────────────────────
const Post = sequelize.define('Post', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  user_id: { type: DataTypes.UUID, allowNull: false },
  content: DataTypes.TEXT,
  media_url: DataTypes.TEXT,
  youtube_link: DataTypes.TEXT,
  post_type: { type: DataTypes.ENUM('TEXT', 'IMAGE', 'VIDEO', 'PRODUCT', 'AD'), defaultValue: 'TEXT' },
  product_id: DataTypes.UUID,
  is_pinned: { type: DataTypes.BOOLEAN, defaultValue: false }
}, { tableName: 'posts', underscored: true });

// ── MerchantAd ────────────────────────────────────────────────
const MerchantAd = sequelize.define('MerchantAd', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  merchant_id: { type: DataTypes.UUID, allowNull: false },
  post_id: { type: DataTypes.UUID, allowNull: false },
  budget: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
  impressions: { type: DataTypes.INTEGER, defaultValue: 0 },
  conversions: { type: DataTypes.INTEGER, defaultValue: 0 }
}, { tableName: 'merchant_ads', underscored: true });

// ── Message ───────────────────────────────────────────────────
const Message = sequelize.define('Message', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  sender_id: { type: DataTypes.UUID, allowNull: false },
  recipient_id: { type: DataTypes.UUID, allowNull: false },
  content: DataTypes.TEXT,
  media_url: DataTypes.TEXT,
  message_type: { type: DataTypes.ENUM('TEXT', 'IMAGE', 'PAYMENT'), defaultValue: 'TEXT' }
}, { tableName: 'messages', underscored: true });

// ── Manifest ──────────────────────────────────────────────────
const Manifest = sequelize.define('Manifest', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  supplier_id: { type: DataTypes.UUID, allowNull: false },
  store_id: { type: DataTypes.UUID, allowNull: false },
  items: { type: DataTypes.JSONB, allowNull: false },
  total_amount: { type: DataTypes.DECIMAL(15, 2), allowNull: false },
  payment_terms: { type: DataTypes.ENUM('IMMEDIATE', 'CREDIT'), defaultValue: 'IMMEDIATE' },
  credit_days: { type: DataTypes.INTEGER, defaultValue: 30 },
  due_date: DataTypes.DATE,
  status: { type: DataTypes.ENUM('PENDING', 'ACCEPTED', 'DISPUTED', 'CANCELLED'), defaultValue: 'PENDING' }
}, { tableName: 'manifests', underscored: true });

// ── Ticket & Event & Transit ──────────────────────────────────
const Event = sequelize.define('Event', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  merchant_id: { type: DataTypes.UUID, allowNull: false },
  title: { type: DataTypes.STRING, allowNull: false },
  description: DataTypes.TEXT,
  image_url: DataTypes.TEXT,
  price: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  date: DataTypes.DATE
}, { tableName: 'events', underscored: true });

const Ticket = sequelize.define('Ticket', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  event_id: { type: DataTypes.UUID, allowNull: false },
  owner_id: DataTypes.UUID,
  price: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0.00 },
  qr_token: { type: DataTypes.STRING, unique: true },
  status: { type: DataTypes.ENUM('AVAILABLE', 'SOLD', 'USED'), defaultValue: 'AVAILABLE' }
}, { tableName: 'tickets', underscored: true });

const TransitFare = sequelize.define('TransitFare', {
  id: { type: DataTypes.UUID, primaryKey: true, defaultValue: DataTypes.UUIDV4 },
  route_name: { type: DataTypes.STRING, allowNull: false },
  fare: { type: DataTypes.DECIMAL(10, 2), allowNull: false }
}, { tableName: 'transit_fares', underscored: true });

// ── LivenessToken ─────────────────────────────────────────────
const LivenessToken = sequelize.define('LivenessToken', {
  token: { type: DataTypes.STRING, primaryKey: true },
  user_id: { type: DataTypes.UUID, allowNull: false },
  expires_at: DataTypes.DATE,
  used_at: DataTypes.DATE
}, { tableName: 'liveness_tokens', underscored: true });

// ── AdminSetting ──────────────────────────────────────────────
const AdminSetting = sequelize.define('AdminSetting', {
  key: { type: DataTypes.STRING, primaryKey: true },
  value: { type: DataTypes.STRING, allowNull: false }
}, { tableName: 'admin_settings', underscored: true });

// ── Associations ──────────────────────────────────────────────
Ticket.belongsTo(Event, { foreignKey: 'event_id', as: 'Event' });
Event.hasMany(Ticket, { foreignKey: 'event_id' });

Order.belongsTo(Merchant, { foreignKey: 'merchant_id' });
Merchant.hasMany(Order, { foreignKey: 'merchant_id' });

Merchant.belongsTo(User, { as: 'owner', foreignKey: 'owner_id' });
User.hasMany(Merchant, { foreignKey: 'owner_id', as: 'merchants' });

module.exports = {
  sequelize,
  User, Transaction, Mandate, Merchant, MerchantStaff,
  Product, Order, Post, MerchantAd, Message,
  Manifest, Event, Ticket, TransitFare, LivenessToken, AdminSetting
};
