const mongoose = require('mongoose')

const AuditLogSchema = new mongoose.Schema({
  // Who performed the action
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },

  // What company this action belongs to (null for super admin actions)
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company'
  },

  // Action details
  action: {
    type: String,
    required: [true, 'Action is required'],
    enum: [
      // Authentication actions
      'login', 'logout', 'password_change', 'password_reset',

      // User management
      'user_create', 'user_update', 'user_delete', 'user_activate', 'user_deactivate',

      // Company management
      'company_create', 'company_update', 'company_delete', 'company_activate', 'company_suspend',

      // Customer management
      'customer_create', 'customer_update', 'customer_delete',

      // Stock management
      'stock_create', 'stock_update', 'stock_delete', 'stock_adjustment',

      // Transaction management
      'transaction_create', 'transaction_update', 'transaction_cancel', 'payment_add',

      // Milling operations
      'milling_create', 'milling_update',

      // System actions
      'settings_update', 'backup_create', 'data_export',

      // Sync operations
      'sync_push', 'sync_pull', 'conflict_resolve'
    ]
  },

  // Resource that was affected
  resourceType: {
    type: String,
    required: [true, 'Resource type is required'],
    enum: [
      'user', 'company', 'customer', 'stock_item', 'transaction',
      'milling_record', 'paddy_type', 'purchase', 'settings', 'system'
    ]
  },

  // ID of the resource that was affected
  resourceId: {
    type: mongoose.Schema.Types.ObjectId
  },

  // Details about what changed
  details: {
    type: mongoose.Schema.Types.Mixed,
    required: [true, 'Details are required']
  },

  // Old values (for updates)
  oldValues: {
    type: mongoose.Schema.Types.Mixed
  },

  // New values (for updates/creates)
  newValues: {
    type: mongoose.Schema.Types.Mixed
  },

  // IP address of the user
  ipAddress: {
    type: String,
    trim: true
  },

  // User agent string
  userAgent: {
    type: String,
    trim: true
  },

  // Location information (optional)
  location: {
    country: String,
    region: String,
    city: String
  },

  // Risk level of the action
  riskLevel: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'low'
  },

  // Success status
  success: {
    type: Boolean,
    default: true
  },

  // Error message if failed
  errorMessage: {
    type: String,
    trim: true
  },

  // Additional metadata
  metadata: {
    type: mongoose.Schema.Types.Mixed
  },

  // Timestamp
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  }
}, {
  timestamps: false // We use timestamp field instead
})

// Indexes for efficient querying
AuditLogSchema.index({ userId: 1, timestamp: -1 })
AuditLogSchema.index({ companyId: 1, timestamp: -1 })
AuditLogSchema.index({ action: 1, timestamp: -1 })
AuditLogSchema.index({ resourceType: 1, resourceId: 1, timestamp: -1 })
AuditLogSchema.index({ riskLevel: 1, timestamp: -1 })
AuditLogSchema.index({ success: 1, timestamp: -1 })

// Compound indexes for common queries
AuditLogSchema.index({ companyId: 1, action: 1, timestamp: -1 })
AuditLogSchema.index({ userId: 1, resourceType: 1, timestamp: -1 })

// TTL index to automatically delete old logs (90 days)
AuditLogSchema.index({ timestamp: 1 }, { expireAfterSeconds: 90 * 24 * 60 * 60 })

// Virtual for formatted timestamp
AuditLogSchema.virtual('formattedTimestamp').get(function () {
  return this.timestamp.toISOString()
})

// Method to get audit log entry details
AuditLogSchema.methods.getDetails = function () {
  return {
    id: this._id,
    userId: this.userId,
    companyId: this.companyId,
    action: this.action,
    resourceType: this.resourceType,
    resourceId: this.resourceId,
    details: this.details,
    oldValues: this.oldValues,
    newValues: this.newValues,
    ipAddress: this.ipAddress,
    userAgent: this.userAgent,
    location: this.location,
    riskLevel: this.riskLevel,
    success: this.success,
    errorMessage: this.errorMessage,
    metadata: this.metadata,
    timestamp: this.timestamp,
    formattedTimestamp: this.formattedTimestamp
  }
}

// Static method to log an action
AuditLogSchema.statics.logAction = async function (logData) {
  try {
    const log = new this(logData)
    await log.save()
    return log
  } catch (error) {
    console.error('Failed to log audit action:', error)
    // Don't throw error to avoid breaking main functionality
    return null
  }
}

// Static method to get audit logs for a company
AuditLogSchema.statics.getCompanyLogs = function (companyId, options = {}) {
  const {
    startDate,
    endDate,
    action,
    resourceType,
    userId,
    riskLevel,
    limit = 50,
    skip = 0
  } = options

  const query = { companyId }

  if (startDate || endDate) {
    query.timestamp = {}
    if (startDate) query.timestamp.$gte = new Date(startDate)
    if (endDate) query.timestamp.$lte = new Date(endDate)
  }

  if (action) query.action = action
  if (resourceType) query.resourceType = resourceType
  if (userId) query.userId = userId
  if (riskLevel) query.riskLevel = riskLevel

  return this.find(query)
    .populate('userId', 'name email')
    .sort({ timestamp: -1 })
    .limit(limit)
    .skip(skip)
}

// Static method to get user activity logs
AuditLogSchema.statics.getUserActivity = function (userId, options = {}) {
  const { startDate, endDate, limit = 100 } = options

  const query = { userId }

  if (startDate || endDate) {
    query.timestamp = {}
    if (startDate) query.timestamp.$gte = new Date(startDate)
    if (endDate) query.timestamp.$lte = new Date(endDate)
  }

  return this.find(query)
    .sort({ timestamp: -1 })
    .limit(limit)
}

// Static method to get security alerts (high-risk actions)
AuditLogSchema.statics.getSecurityAlerts = function (companyId, hours = 24) {
  const since = new Date(Date.now() - hours * 60 * 60 * 1000)

  return this.find({
    companyId,
    riskLevel: { $in: ['high', 'critical'] },
    timestamp: { $gte: since }
  })
    .populate('userId', 'name email')
    .sort({ timestamp: -1 })
}

// Static method to get failed actions
AuditLogSchema.statics.getFailedActions = function (companyId, options = {}) {
  const { startDate, endDate, limit = 50 } = options

  const query = {
    companyId,
    success: false
  }

  if (startDate || endDate) {
    query.timestamp = {}
    if (startDate) query.timestamp.$gte = new Date(startDate)
    if (endDate) query.timestamp.$lte = new Date(endDate)
  }

  return this.find(query)
    .populate('userId', 'name email')
    .sort({ timestamp: -1 })
    .limit(limit)
}

// Pre-save middleware to set risk level based on action
AuditLogSchema.pre('save', function (next) {
  const highRiskActions = [
    'company_delete', 'user_delete', 'password_reset',
    'settings_update', 'backup_create', 'data_export'
  ]

  const criticalActions = [
    'user_create', 'company_create', 'system_config_change'
  ]

  if (criticalActions.includes(this.action)) {
    this.riskLevel = 'critical'
  } else if (highRiskActions.includes(this.action)) {
    this.riskLevel = 'high'
  } else if (this.action.includes('delete') || this.action.includes('suspend')) {
    this.riskLevel = 'medium'
  } else {
    this.riskLevel = 'low'
  }

  next()
})

module.exports = mongoose.model('AuditLog', AuditLogSchema)
