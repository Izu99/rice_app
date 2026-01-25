const { body } = require('express-validator')

const validateMillingProcess = [
  body('paddyItemId').exists().withMessage('paddyItemId is required').isMongoId().withMessage('Invalid paddyItemId'),
  body('inputPaddyKg').exists().withMessage('inputPaddyKg is required').isNumeric().withMessage('inputPaddyKg must be a number'),
  body('inputPaddyBags').optional().isInt().withMessage('inputPaddyBags must be an integer'),
  body('outputRiceKg').exists().withMessage('outputRiceKg is required').isNumeric().withMessage('outputRiceKg must be a number'),
  body('outputRiceBags').optional().isInt().withMessage('outputRiceBags must be an integer'),
  body('brokenRiceKg').optional().isNumeric(),
  body('huskKg').optional().isNumeric(),
  body('wastageKg').optional().isNumeric(),
  body('millingPercentage').optional().isNumeric(),
  body('outputRiceName').exists().withMessage('outputRiceName is required').isString(),
  body('millingDate').optional().isISO8601().withMessage('millingDate must be a valid date')
]

module.exports = {
  validateMillingProcess
}
