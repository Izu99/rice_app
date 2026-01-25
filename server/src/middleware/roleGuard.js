const { errorResponse } = require('../utils/responseHandler')

/**
 * Role-based access control middleware
 * Creates a function that returns middleware for role checking
 *
 * @param {...string} allowedRoles - Array of allowed role names
 * @returns {Function} Middleware function
 */
const roleGuard = (...allowedRoles) => {
  return (req, res, next) => {
    // Ensure user is authenticated
    if (!req.user) {
      return errorResponse(res, 'Authentication required.', 401)
    }

    // Check if user's role is in the allowed roles
    if (!allowedRoles.includes(req.user.role)) {
      return errorResponse(res, 'Access denied. Insufficient permissions.', 403)
    }

    next()
  }
}

module.exports = roleGuard
