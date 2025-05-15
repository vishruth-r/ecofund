const jwt = require('jsonwebtoken');

// ✅ Authentication Middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // Save decoded token to request
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// ✅ Authorization Middleware (Role-Based)
function authorizeRoles(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Access denied' });
    }
    next();
  };
}

module.exports = {
  authenticateToken,
  authorizeRoles,
};
