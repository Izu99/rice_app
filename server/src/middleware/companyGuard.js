const { errorResponse } = require('../utils/responseHandler')

/**
 * Company data isolation middleware
 * Ensures users can only access data from their own company
 * Super admins can access any company data (with optional companyId filter)
 */
const companyGuard = (req, res, next) => {
  // Ensure user is authenticated
  if (!req.user) {
    return errorResponse(res, 'Authentication required.', 401)
  }

  const { role, companyId } = req.user

  // Super admin logic
  if (role === 'super_admin') {
    // If companyId provided in query params, filter by that company
    if (req.query.companyId) {
      req.companyFilter = { companyId: req.query.companyId }
      req.companyId = req.query.companyId
    } else {
      // No filter - super admin can see all data
      req.companyFilter = {}
      req.companyId = null
    }
    return next()
  }

  // Company user logic
  if (!companyId) {
    return errorResponse(res, 'Company association not found. Please contact support.', 403)
  }

  // Set company filter for company-level data isolation
  req.companyFilter = { companyId }
  req.companyId = companyId

  // For GET requests: automatically apply company filter
  // For POST/PUT requests: ensure data belongs to user's company
  // For route params with IDs: controllers should verify ownership

  next()
}

module.exports = companyGuard
