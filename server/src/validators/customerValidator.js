const { body } = require('express-validator')

const validateCustomerCreation = [
  body('name').exists().withMessage('Name is required').isString(),
  body('phone').exists().withMessage('Phone is required').isString(),
  body('secondaryPhone').optional().isString(),
  body('email').optional().isEmail().withMessage('Invalid email'),
  body('address').optional().isString(),
  body('city').optional().isString(),
  body('nic').optional().isString(),
  body('customer_type').optional().isString().isIn(['buyer', 'seller']).withMessage('Customer type must be either buyer or seller'),
  body('notes').optional().isString(),
  body('clientId').optional().isString()
]

const validateCustomerUpdate = [
  body('name').optional().isString(),
  body('phone').optional().isString(),
  body('secondaryPhone').optional().isString(),
  body('email').optional().isEmail().withMessage('Invalid email'),
  body('address').optional().isString(),
  body('city').optional().isString(),
  body('nic').optional().isString(),
  body('customer_type').optional().isString().isIn(['buyer', 'seller']).withMessage('Customer type must be either buyer or seller'),
  body('notes').optional().isString(),
  body('isActive').optional().isBoolean()
]

module.exports = {
  validateCustomerCreation,
  validateCustomerUpdate
}
