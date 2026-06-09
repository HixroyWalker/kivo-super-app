// backend/middleware/doubleLock.js
const doubleLock = (req, res, next) => {
  const biometricAuth = req.headers['x-biometric-auth'];
  const biometricTimestamp = req.headers['x-biometric-timestamp'];

  if (!biometricAuth || !biometricTimestamp) {
    return res.status(401).json({ error: 'Secondary biometric authentication required.' });
  }

  // Check if authentication happened within the last 30 seconds
  const now = Date.now();
  const authTime = parseInt(biometricTimestamp, 10);
  if (now - authTime > 30000) {
    return res.status(401).json({ error: 'Biometric authentication expired. Please re-authenticate.' });
  }

  next();
};

module.exports = doubleLock;
