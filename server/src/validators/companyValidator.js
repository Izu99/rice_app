const { body } = require('express-validator')

const validateCompanyUpdate = [
  body('name').optional().isString().withMessage('Name must be a string'),
  body('phone').optional().isString().withMessage('Phone must be a string'),
  body('address').optional().isString().withMessage('Address must be a string'),
  body('registrationNumber').optional().isString().withMessage('Registration number must be a string')
]

const validatePasswordChange = [
  body('currentPassword')
    .exists().withMessage('Current password is required')
    .isString()
    .isLength({ min: 6 }).withMessage('Current password must be at least 6 characters'),
  body('newPassword')
    .exists().withMessage('New password is required')
    .isString()
    .isLength({ min: 6 }).withMessage('New password must be at least 6 characters')
]

module.exports = {
  validateCompanyUpdate,
  validatePasswordChange
}
