const { body } = require('express-validator')

const validateStockCreation = [
  body('name').exists().withMessage('Name is required').isString(),
  body('itemType').exists().withMessage('Item type is required').isIn(['paddy', 'rice']).withMessage('Invalid item type'),
  body('totalWeightKg').optional().isNumeric().withMessage('totalWeightKg must be a number'),
  body('totalBags').optional().isInt().withMessage('totalBags must be an integer'),
  body('pricePerKg').optional().isNumeric().withMessage('pricePerKg must be a number'),
  body('clientId').optional().isString()
]

const validateStockUpdate = [
  body('name').optional().isString(),
  body('pricePerKg').optional().isNumeric().withMessage('pricePerKg must be a number'),
  body('minimumStock').optional().isNumeric().withMessage('minimumStock must be a number'),
  body('description').optional().isString(),
  body('isActive').optional().isBoolean()
]

const validateStockAdjustment = [
  body('adjustmentType').exists().withMessage('Adjustment type is required').isIn(['add', 'subtract']).withMessage('Invalid adjustment type'),
  body('weightKg').optional().isNumeric().withMessage('weightKg must be a number'),
  body('bags').optional().isInt().withMessage('bags must be an integer'),
  body('reason').optional().isString(),
  body('notes').optional().isString()
]

module.exports = {
  validateStockCreation,
  validateStockUpdate,
  validateStockAdjustment
}
