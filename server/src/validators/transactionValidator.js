const { body } = require('express-validator')

const validateTransactionCreation = [
  body('customerId').exists().withMessage('customerId is required'),
  body('items').isArray({ min: 1 }).withMessage('Items must be a non-empty array'),
  body('items.*.weightKg').exists().withMessage('Item weightKg is required').isNumeric().withMessage('weightKg must be numeric'),
  body('items.*.pricePerKg').exists().withMessage('Item pricePerKg is required').isNumeric().withMessage('pricePerKg must be numeric'),
  body('paidAmount').optional().isNumeric().withMessage('paidAmount must be numeric'),
  body('transactionDate').optional().isISO8601().withMessage('Invalid date')
]

const validateTransactionUpdate = [
  body('notes').optional().isString(),
  body('status').optional().isIn(['pending', 'partially_paid', 'completed', 'cancelled']).withMessage('Invalid status')
]

const validatePayment = [
  body('amount').exists().withMessage('Amount is required').isNumeric().withMessage('Amount must be numeric'),
  body('paymentMethod').optional().isString(),
  body('notes').optional().isString()
]

module.exports = {
  validateTransactionCreation,
  validateTransactionUpdate,
  validatePayment
}
