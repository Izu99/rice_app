// Application Constants
const constants = {
  // User Roles
  ROLES: {
    ADMIN: 'admin',
    COMPANY: 'company',
    USER: 'user'
  },

  // Company Status
  COMPANY_STATUS: {
    PENDING: 'pending',
    ACTIVE: 'active',
    INACTIVE: 'inactive',
    SUSPENDED: 'suspended'
  },

  // Company Plans
  COMPANY_PLANS: {
    FREE: 'free',
    BASIC: 'basic',
    PREMIUM: 'premium',
    ENTERPRISE: 'enterprise'
  },

  // Transaction Types
  TRANSACTION_TYPES: {
    BUY: 'buy',
    SELL: 'sell'
  },

  // Transaction Status
  TRANSACTION_STATUS: {
    PENDING: 'pending',
    PARTIALLY_PAID: 'partially_paid',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled'
  },

  // Stock Item Types
  INVENTORY_TYPES: {
    PADDY: 'paddy',
    RICE: 'rice'
  },

  // Payment Methods
  PAYMENT_METHODS: {
    CASH: 'cash',
    CARD: 'card',
    BANK_TRANSFER: 'bank_transfer',
    CHEQUE: 'cheque',
    CREDIT: 'credit'
  },

  // Milling Status
  MILLING_STATUS: {
    PENDING: 'pending',
    IN_PROGRESS: 'in_progress',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled'
  },

  // Sync Operations
  SYNC_OPERATIONS: {
    CREATE: 'create',
    UPDATE: 'update',
    DELETE: 'delete'
  },

  // HTTP Status Codes
  HTTP_STATUS: {
    OK: 200,
    CREATED: 201,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    CONFLICT: 409,
    INTERNAL_SERVER_ERROR: 500
  },

  // Error Messages
  ERROR_MESSAGES: {
    UNAUTHORIZED: 'Unauthorized access',
    FORBIDDEN: 'Access forbidden',
    NOT_FOUND: 'Resource not found',
    VALIDATION_FAILED: 'Validation failed',
    INTERNAL_ERROR: 'Internal server error',
    INVALID_CREDENTIALS: 'Invalid credentials',
    USER_NOT_FOUND: 'User not found',
    COMPANY_NOT_FOUND: 'Company not found',
    INSUFFICIENT_STOCK: 'Insufficient stock',
    INVALID_REQUEST: 'Invalid request'
  },

  // Success Messages
  SUCCESS_MESSAGES: {
    LOGIN_SUCCESS: 'Login successful',
    LOGOUT_SUCCESS: 'Logout successful',
    USER_CREATED: 'User created successfully',
    COMPANY_CREATED: 'Company created successfully',
    TRANSACTION_CREATED: 'Transaction created successfully',
    INVENTORY_UPDATED: 'Stock updated successfully',
    PASSWORD_CHANGED: 'Password changed successfully'
  },

  // File Types
  ALLOWED_FILE_TYPES: {
    IMAGES: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    DOCUMENTS: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    SPREADSHEETS: ['application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
  },

  // Default Values
  DEFAULTS: {
    COMPANY_MAX_USERS: 5,
    LOW_STOCK_THRESHOLD: 10,
    TRANSACTION_NUMBER_PREFIX: 'TXN',
    BATCH_NUMBER_PREFIX: 'BATCH',
    PAGINATION_LIMIT: 20
  },

  // Time Constants (in milliseconds)
  TIME: {
    ONE_MINUTE: 60 * 1000,
    ONE_HOUR: 60 * 60 * 1000,
    ONE_DAY: 24 * 60 * 60 * 1000,
    ONE_WEEK: 7 * 24 * 60 * 60 * 1000,
    ONE_MONTH: 30 * 24 * 60 * 60 * 1000
  },

  // Regular Expressions
  REGEX: {
    EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    PHONE: /^\+?[\d\s\-()]+$/,
    PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    ALPHANUMERIC: /^[a-zA-Z0-9]+$/,
    ALPHA_ONLY: /^[a-zA-Z\s]+$/,
    NUMERIC_ONLY: /^\d+$/
  },

  // API Rate Limits
  RATE_LIMITS: {
    AUTH: {
      windowMs: process.env.NODE_ENV === 'development' ? 60 * 1000 : 15 * 60 * 1000, // 1 min dev, 15 min prod
      max: process.env.NODE_ENV === 'development' ? 100 : 50 // Increased from 20/5
    },
    GENERAL: { windowMs: 15 * 60 * 1000, max: 1000 }, // Increased from 100
    UPLOAD: { windowMs: 60 * 60 * 1000, max: 100 } // Increased from 10
  }
}

module.exports = constants
