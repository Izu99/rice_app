const { body, param, query } = require('express-validator')

/**
 * Authentication Validations
 */
exports.registerValidation = [
  body('name')
    .trim()
    .notEmpty().withMessage('Company name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Company name must be between 2-100 characters'),

  body('ownerName')
    .trim()
    .notEmpty().withMessage('Owner name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Owner name must be between 2-100 characters'),

  body('email')
    .optional()
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail(),

  body('phone')
    .notEmpty().withMessage('Phone number is required')
    .matches(/^\+?[\d\s\-()]+$/).withMessage('Please enter a valid phone number'),

  body('address')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Address cannot exceed 200 characters'),

  body('registrationNumber')
    .optional()
    .trim()
    .isLength({ max: 50 }).withMessage('Registration number cannot exceed 50 characters'),

  body('password')
    .notEmpty().withMessage('Password is required')
    .isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
]

exports.createAdminValidation = [
  body('companyId')
    .notEmpty().withMessage('Company ID is required')
    .isMongoId().withMessage('Invalid company ID'),

  body('name')
    .trim()
    .notEmpty().withMessage('Name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Name must be between 2-100 characters'),

  body('phone')
    .notEmpty().withMessage('Phone number is required')
    .matches(/^\+?[\d\s\-()]+$/).withMessage('Please enter a valid phone number'),

  body('email')
    .optional()
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail(),

  body('password')
    .notEmpty().withMessage('Password is required')
    .isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
]

exports.loginValidation = [
  // Either email or phone must be provided, but not both required
  body('email')
    .optional()
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail(),

  body('phone')
    .optional()
    .matches(/^\+?[\d\s\-()]+$/).withMessage('Please enter a valid phone number'),

  // Custom validation to ensure either email or phone is provided
  body().custom((value, { req }) => {
    const { email, phone } = req.body
    if (!email && !phone) {
      throw new Error('Either email or phone number is required')
    }
    return true
  }),

  body('password')
    .notEmpty().withMessage('Password is required')
    .isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
]

exports.refreshTokenValidation = [
  body('token')
    .optional()
    .notEmpty().withMessage('Token is required')
]

exports.forgotPasswordValidation = [
  body('email')
    .notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail()
]

exports.resetPasswordValidation = [
  body('token')
    .notEmpty().withMessage('Reset token is required'),

  body('newPassword')
    .notEmpty().withMessage('New password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character')
]

exports.changePasswordValidation = [
  body('currentPassword')
    .notEmpty().withMessage('Current password is required'),

  body('newPassword')
    .notEmpty().withMessage('New password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character')
]

/**
 * Company Validations
 */
exports.createCompanyValidation = [
  body('name')
    .trim()
    .notEmpty().withMessage('Company name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Company name must be between 2-100 characters'),

  body('ownerName')
    .trim()
    .notEmpty().withMessage('Owner name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Owner name must be between 2-100 characters'),

  body('email')
    .notEmpty().withMessage('Company email is required')
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail(),

  body('phone')
    .notEmpty().withMessage('Contact phone is required')
    .matches(/^\+?[\d\s\-()]+$/).withMessage('Please enter a valid phone number'),

  body('address')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Address cannot exceed 200 characters'),

  body('registrationNumber')
    .optional()
    .trim()
    .isLength({ max: 50 }).withMessage('Registration number cannot exceed 50 characters'),

  body('password')
    .notEmpty().withMessage('Admin password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character')
]

exports.updateCompanyValidation = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 }).withMessage('Company name must be between 2-100 characters'),

  body('ownerName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 }).withMessage('Owner name must be between 2-100 characters'),

  body('email')
    .optional()
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail(),

  body('phone')
    .optional()
    .matches(/^\+?[\d\s\-()]+$/).withMessage('Please enter a valid phone number'),

  body('address')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Address cannot exceed 200 characters'),

  body('registrationNumber')
    .optional()
    .trim()
    .isLength({ max: 50 }).withMessage('Registration number cannot exceed 50 characters'),

  body('status')
    .optional()
    .isIn(['pending', 'active', 'inactive', 'suspended']).withMessage('Invalid company status'),

  body('maxUsers')
    .optional()
    .isInt({ min: 1, max: 1000 }).withMessage('Max users must be between 1-1000'),

  body('settings')
    .optional()
    .isObject().withMessage('Settings must be an object')
]

/**
 * Customer Validations
 */
exports.createCustomerValidation = [
  body('name')
    .trim()
    .notEmpty().withMessage('Customer name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Customer name must be between 2-100 characters'),

  body('phone')
    .notEmpty().withMessage('Phone number is required')
    .matches(/^\+?[\d\s\-()]+$/).withMessage('Please enter a valid phone number'),

  body('email')
    .optional()
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail(),

  body('address')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Address cannot exceed 200 characters'),

  body('nic')
    .optional()
    .trim()
    .isLength({ max: 20 }).withMessage('NIC cannot exceed 20 characters'),

  body('customerType')
    .notEmpty().withMessage('Customer type is required')
    .isIn(['buyer', 'seller', 'both']).withMessage('Customer type must be buyer, seller, or both'),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters'),

  body('clientId')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Client ID cannot exceed 100 characters')
]

exports.updateCustomerValidation = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 }).withMessage('Customer name must be between 2-100 characters'),

  body('phone')
    .optional()
    .matches(/^\+?[\d\s\-()]+$/).withMessage('Please enter a valid phone number'),

  body('email')
    .optional()
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail(),

  body('address')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Address cannot exceed 200 characters'),

  body('nic')
    .optional()
    .trim()
    .isLength({ max: 20 }).withMessage('NIC cannot exceed 20 characters'),

  body('customerType')
    .optional()
    .isIn(['buyer', 'seller', 'both']).withMessage('Customer type must be buyer, seller, or both'),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters'),

  body('isActive')
    .optional()
    .isBoolean().withMessage('isActive must be a boolean')
]

/**
 * Stock Validations
 */
exports.createStockValidation = [
  body('name')
    .trim()
    .notEmpty().withMessage('Item name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Item name must be between 2-100 characters'),

  body('itemType')
    .notEmpty().withMessage('Item type is required')
    .isIn(['paddy', 'rice']).withMessage('Item type must be paddy or rice'),

  body('totalWeightKg')
    .notEmpty().withMessage('Total weight is required')
    .isFloat({ min: 0 }).withMessage('Total weight must be a positive number'),

  body('totalBags')
    .notEmpty().withMessage('Total bags is required')
    .isInt({ min: 0 }).withMessage('Total bags must be a non-negative integer'),

  body('pricePerKg')
    .notEmpty().withMessage('Price per kg is required')
    .isFloat({ min: 0 }).withMessage('Price must be a positive number'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Description cannot exceed 500 characters'),

  body('minimumStock')
    .optional()
    .isFloat({ min: 0 }).withMessage('Minimum stock must be a positive number'),

  body('clientId')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Client ID cannot exceed 100 characters')
]

exports.updateStockValidation = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 }).withMessage('Item name must be between 2-100 characters'),

  body('pricePerKg')
    .optional()
    .isFloat({ min: 0 }).withMessage('Price must be a positive number'),

  body('minimumStock')
    .optional()
    .isFloat({ min: 0 }).withMessage('Minimum stock must be a positive number'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Description cannot exceed 500 characters'),

  body('isActive')
    .optional()
    .isBoolean().withMessage('isActive must be a boolean')
]

exports.adjustStockValidation = [
  body('adjustmentType')
    .notEmpty().withMessage('Adjustment type is required')
    .isIn(['add', 'subtract']).withMessage('Adjustment type must be add or subtract'),

  body('weightKg')
    .optional()
    .isFloat({ min: 0 }).withMessage('Weight must be a positive number'),

  body('bags')
    .optional()
    .isInt({ min: 0 }).withMessage('Bags must be a non-negative integer'),

  body('reason')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Reason cannot exceed 200 characters'),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters')
]

/**
 * Transaction Validations
 */
exports.createBuyTransactionValidation = [
  body('customerId')
    .notEmpty().withMessage('Customer ID is required')
    .isMongoId().withMessage('Invalid customer ID'),

  body('items')
    .isArray({ min: 1 }).withMessage('At least one item is required'),

  body('items.*.name')
    .trim()
    .notEmpty().withMessage('Item name is required')
    .isLength({ max: 100 }).withMessage('Item name cannot exceed 100 characters'),

  body('items.*.itemType')
    .isIn(['paddy', 'rice']).withMessage('Item type must be paddy or rice'),

  body('items.*.weightKg')
    .isFloat({ min: 0.01 }).withMessage('Weight must be greater than 0'),

  body('items.*.bags')
    .optional()
    .isInt({ min: 0 }).withMessage('Bags must be a non-negative integer'),

  body('items.*.pricePerKg')
    .isFloat({ min: 0 }).withMessage('Price per kg must be a positive number'),

  body('paidAmount')
    .optional()
    .isFloat({ min: 0 }).withMessage('Paid amount must be a positive number'),

  body('paymentMethod')
    .notEmpty().withMessage('Payment method is required')
    .isIn(['cash', 'bank_transfer', 'cheque', 'credit']).withMessage('Invalid payment method'),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters'),

  body('transactionDate')
    .notEmpty().withMessage('Transaction date is required')
    .isISO8601().withMessage('Invalid date format'),

  body('clientId')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Client ID cannot exceed 100 characters')
]

exports.createSellTransactionValidation = [
  body('customerId')
    .notEmpty().withMessage('Customer ID is required')
    .isMongoId().withMessage('Invalid customer ID'),

  body('items')
    .isArray({ min: 1 }).withMessage('At least one item is required'),

  body('items.*.stockItemId')
    .notEmpty().withMessage('Stock item ID is required')
    .isMongoId().withMessage('Invalid stock item ID'),

  body('items.*.itemName')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Item name cannot exceed 100 characters'),

  body('items.*.itemType')
    .optional()
    .isIn(['paddy', 'rice']).withMessage('Item type must be paddy or rice'),

  body('items.*.weightKg')
    .isFloat({ min: 0.01 }).withMessage('Weight must be greater than 0'),

  body('items.*.bags')
    .optional()
    .isInt({ min: 0 }).withMessage('Bags must be a non-negative integer'),

  body('items.*.pricePerKg')
    .isFloat({ min: 0 }).withMessage('Price per kg must be a positive number'),

  body('paidAmount')
    .optional()
    .isFloat({ min: 0 }).withMessage('Paid amount must be a positive number'),

  body('paymentMethod')
    .notEmpty().withMessage('Payment method is required')
    .isIn(['cash', 'bank_transfer', 'cheque', 'credit']).withMessage('Invalid payment method'),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters'),

  body('transactionDate')
    .notEmpty().withMessage('Transaction date is required')
    .isISO8601().withMessage('Invalid date format'),

  body('clientId')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Client ID cannot exceed 100 characters')
]

exports.updateTransactionValidation = [
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters'),

  body('status')
    .optional()
    .isIn(['cancelled']).withMessage('Only cancelled status is allowed for updates')
]

exports.addPaymentValidation = [
  body('amount')
    .notEmpty().withMessage('Payment amount is required')
    .isFloat({ min: 0.01 }).withMessage('Payment amount must be greater than 0'),

  body('paymentMethod')
    .notEmpty().withMessage('Payment method is required')
    .isIn(['cash', 'bank_transfer', 'cheque', 'credit']).withMessage('Invalid payment method'),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 200 }).withMessage('Payment notes cannot exceed 200 characters')
]

/**
 * Milling Validations
 */
exports.createMillingValidation = [
  body('paddyItemId')
    .notEmpty().withMessage('Paddy item ID is required')
    .isMongoId().withMessage('Invalid paddy item ID'),

  body('inputPaddyKg')
    .notEmpty().withMessage('Input paddy weight is required')
    .isFloat({ min: 0.01 }).withMessage('Input weight must be greater than 0'),

  body('inputPaddyBags')
    .optional()
    .isInt({ min: 0 }).withMessage('Input bags must be a non-negative integer'),

  body('outputRiceKg')
    .notEmpty().withMessage('Output rice weight is required')
    .isFloat({ min: 0 }).withMessage('Output weight must be a positive number'),

  body('outputRiceBags')
    .optional()
    .isInt({ min: 0 }).withMessage('Output bags must be a non-negative integer'),

  body('brokenRiceKg')
    .optional()
    .isFloat({ min: 0 }).withMessage('Broken rice weight must be a positive number'),

  body('huskKg')
    .optional()
    .isFloat({ min: 0 }).withMessage('Husk weight must be a positive number'),

  body('millingPercentage')
    .notEmpty().withMessage('Milling percentage is required')
    .isFloat({ min: 0, max: 100 }).withMessage('Milling percentage must be between 0-100'),

  body('outputRiceName')
    .trim()
    .notEmpty().withMessage('Output rice name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Rice name must be between 2-100 characters'),

  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 }).withMessage('Notes cannot exceed 500 characters'),

  body('millingDate')
    .notEmpty().withMessage('Milling date is required')
    .isISO8601().withMessage('Invalid date format'),

  body('clientId')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Client ID cannot exceed 100 characters')
]

/**
 * Sync Validations
 */
exports.pushSyncValidation = [
  body('operations')
    .isArray({ min: 1 }).withMessage('At least one operation is required'),

  body('operations.*.clientId')
    .notEmpty().withMessage('Client ID is required for each operation'),

  body('operations.*.entityType')
    .isIn(['customer', 'stock_item', 'transaction', 'milling_record'])
    .withMessage('Invalid entity type'),

  body('operations.*.operation')
    .isIn(['create', 'update', 'delete']).withMessage('Invalid operation type'),

  body('operations.*.data')
    .isObject().withMessage('Operation data must be an object'),

  body('operations.*.clientCreatedAt')
    .isISO8601().withMessage('Invalid client created at timestamp')
]

exports.resolveConflictValidation = [
  body('clientId')
    .notEmpty().withMessage('Client ID is required'),

  body('resolution')
    .isIn(['keep_server', 'keep_client', 'merge']).withMessage('Invalid resolution type'),

  body('mergedData')
    .optional()
    .isObject().withMessage('Merged data must be an object')
]
