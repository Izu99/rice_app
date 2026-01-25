const { body } = require('express-validator')

const validateSyncOperations = [
  body('operations').isArray({ min: 1 }).withMessage('operations must be a non-empty array'),
  body('operations.*.clientId').exists().withMessage('operation.clientId is required').isString(),
  body('operations.*.entityType').exists().withMessage('operation.entityType is required').isString(),
  body('operations.*.operation').exists().withMessage('operation.operation is required').isIn(['create', 'update', 'delete']).withMessage('Invalid operation type'),
  body('operations.*.data').exists().withMessage('operation.data is required'),
  body('operations.*.clientCreatedAt').exists().withMessage('operation.clientCreatedAt is required').isISO8601().withMessage('clientCreatedAt must be a valid date')
]

module.exports = {
  validateSyncOperations
}
