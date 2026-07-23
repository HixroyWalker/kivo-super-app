const admin = require('firebase-admin');

const requireAuth = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: Missing or invalid token format' });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    // Verify the custom Kivo session JWT (or standard Firebase ID token)
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Attach the user identity to the request object for downstream routes
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      // If custom claims were added to the JWT (like roles), they are accessible here
      role: decodedToken.role || 'STANDARD'
    };

    next();
  } catch (error) {
    console.error('Auth Middleware Error:', error);
    return res.status(401).json({ error: 'Unauthorized: Token expired or invalid' });
  }
};

module.exports = requireAuth;
