// backend/middleware/hwBinding.js
const hwBinding = (req, res, next) => {
  const deviceUuid = req.headers['x-device-uuid'];
  if (!deviceUuid) {
    return res.status(403).json({ error: 'Device UUID missing' });
  }
  // In a real app, you would check if req.user.device_uuid === deviceUuid
  if (req.user && req.user.device_uuid && req.user.device_uuid !== deviceUuid) {
    return res.status(403).json({ error: 'Hardware binding mismatch. Access denied.' });
  }
  next();
};

module.exports = hwBinding;
