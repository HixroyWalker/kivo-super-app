// backend/middleware/auth.js
const jwt = require('jsonwebtoken');
const { User } = require('../models');

const JWT_SECRET = process.env.JWT_SECRET || 'kivo-super-secret-development-key';

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // In development mode, check for user seeding and bypass auth if no header is present
      if (process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) {
        const user = await User.findOne({ order: [['created_at', 'ASC']] });
        if (user) {
          user.role = 'ADMIN'; // Force admin for local development testing
          req.user = user;
          return next();
        }
      }
      return res.status(401).json({ error: 'Access denied. No session token provided.' });
    }

    const token = authHeader.split(' ')[1];
    
    // In development mode, check for mock user headers to simplify local workflow testing
    if ((process.env.MOCK_AUTH === 'true' || process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) && token.startsWith('mock_')) {
      const email = token.replace('mock_', '');
      const [user] = await User.findOrCreate({
        where: { email },
        defaults: {
          wallet_balance: 100000.00, // Seed mock balance for testing
          role: 'ADMIN',
          is_active: true
        }
      });
      req.user = user;
      return next();
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findByPk(decoded.id);

    if (!user) {
      return res.status(401).json({ error: 'Session user no longer exists.' });
    }

    if (!user.is_active) {
      return res.status(403).json({ error: 'This user account is suspended.' });
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Session token has expired.' });
    }
    res.status(401).json({ error: 'Invalid session token.' });
  }
};

module.exports = authMiddleware;
