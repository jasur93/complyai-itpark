const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

const authMiddleware = (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.header('Authorization');

    if (!authHeader) {
      return res.status(401).json({
        error: 'Access denied',
        message: 'No token provided'
      });
    }

    // Check if token starts with 'Bearer '
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Access denied',
        message: 'Invalid token format'
      });
    }

    // Extract token
    const token = authHeader.substring(7);

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');

    // Add user info to request
    req.user = decoded;

    logger.debug(`User ${decoded.id} authenticated for ${req.method} ${req.path}`);

    next();
  } catch (error) {
    logger.warn(`Authentication failed: ${error.message}`);

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Access denied',
        message: 'Token expired'
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Access denied',
        message: 'Invalid token'
      });
    }

    return res.status(500).json({
      error: 'Server error',
      message: 'Authentication service error'
    });
  }
};

// Middleware to check if user has specific role
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Access denied',
        message: 'Authentication required'
      });
    }

    const userRole = req.user.role;
    const allowedRoles = Array.isArray(roles) ? roles : [roles];

    if (!allowedRoles.includes(userRole)) {
      logger.warn(`User ${req.user.id} with role ${userRole} attempted to access ${req.path} requiring roles: ${allowedRoles.join(', ')}`);
      return res.status(403).json({
        error: 'Access denied',
        message: 'Insufficient permissions'
      });
    }

    next();
  };
};

// Middleware to check if user belongs to the company
const requireCompanyAccess = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      error: 'Access denied',
      message: 'Authentication required'
    });
  }

  const companyId = req.params.companyId || req.body.companyId || req.query.companyId;

  // IT Park admins can access any company
  if (req.user.userType === 'it_park_admin') {
    return next();
  }

  // Regular users can only access their own company
  if (req.user.companyId !== companyId) {
    logger.warn(`User ${req.user.id} attempted to access company ${companyId} but belongs to ${req.user.companyId}`);
    return res.status(403).json({
      error: 'Access denied',
      message: 'Cannot access other company data'
    });
  }

  next();
};

module.exports = {
  authMiddleware,
  requireRole,
  requireCompanyAccess
};