/**
 * Standard success response format
 * @param {Object} res - Express response object
 * @param {String} message - Success message
 * @param {Object} data - Response data
 * @param {Number} statusCode - HTTP status code (default: 200)
 */
exports.successResponse = (res, message, data = null, statusCode = 200) => {
  const response = {
    success: true,
    message,
    timestamp: new Date().toISOString()
  }

  if (data !== null) {
    response.data = data
  }

  return res.status(statusCode).json(response)
}

/**
 * Standard error response format
 * @param {Object} res - Express response object
 * @param {String} message - Error message
 * @param {Number} statusCode - HTTP status code (default: 500)
 * @param {Object|Array} errors - Detailed error information
 */
exports.errorResponse = (res, message, statusCode = 500, errors = null) => {
  const response = {
    success: false,
    message,
    timestamp: new Date().toISOString()
  }

  if (errors !== null) {
    response.errors = errors
  }

  return res.status(statusCode).json(response)
}

/**
 * Paginated response format
 * @param {Object} res - Express response object
 * @param {String} message - Success message
 * @param {Array} data - Array of items
 * @param {Number} page - Current page
 * @param {Number} limit - Items per page
 * @param {Number} total - Total items
 */
exports.paginatedResponse = (res, message, data, page, limit, total) => {
  const response = {
    success: true,
    message,
    data,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      pages: Math.ceil(total / limit),
      hasNext: page * limit < total,
      hasPrev: page > 1
    },
    timestamp: new Date().toISOString()
  }

  return res.status(200).json(response)
}
