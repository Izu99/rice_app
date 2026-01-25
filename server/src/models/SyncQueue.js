const mongoose = require('mongoose')

const SyncQueueSchema = new mongoose.Schema({
  clientId: {
    type: String,
    required: [true, 'Client ID is required'],
    unique: true,
    trim: true
  },
  entityType: {
    type: String,
    enum: ['customer', 'stock_item', 'transaction', 'milling_record'],
    required: [true, 'Entity type is required']
  },
  operation: {
    type: String,
    enum: ['create', 'update', 'delete'],
    required: [true, 'Operation is required']
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    required: [true, 'Data is required']
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: [true, 'Company ID is required']
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed', 'conflict'],
    default: 'pending'
  },
  errorMessage: {
    type: String,
    trim: true
  },
  retryCount: {
    type: Number,
    default: 0,
    min: [0, 'Retry count cannot be negative']
  },
  processedAt: {
    type: Date
  },
  clientCreatedAt: {
    type: Date,
    required: [true, 'Client created at is required']
  }
}, {
  timestamps: true
})

// Indexes
SyncQueueSchema.index({ clientId: 1 }, { unique: true })
SyncQueueSchema.index({ companyId: 1 })
SyncQueueSchema.index({ status: 1, createdAt: 1 }) // For processing queue
SyncQueueSchema.index({ status: 1 })

// Pre-save middleware
SyncQueueSchema.pre('save', function (next) {
  // Set processedAt when status changes to completed
  if (this.isModified('status') && this.status === 'completed' && !this.processedAt) {
    this.processedAt = new Date()
  }
  next()
})

// Method to mark as completed
SyncQueueSchema.methods.markAsCompleted = async function () {
  this.status = 'completed'
  this.processedAt = new Date()
  return this.save()
}

// Method to mark as failed
SyncQueueSchema.methods.markAsFailed = async function (errorMessage) {
  this.status = 'failed'
  this.errorMessage = errorMessage
  this.retryCount += 1
  return this.save()
}

// Method to mark as conflict
SyncQueueSchema.methods.markAsConflict = async function () {
  this.status = 'conflict'
  return this.save()
}

// Static method to get pending operations for company
SyncQueueSchema.statics.getPendingOperations = function (companyId, limit = 50) {
  return this.find({
    companyId,
    status: 'pending'
  })
    .sort({ clientCreatedAt: 1 }) // Process in chronological order
    .limit(limit)
}

// Static method to get failed operations for retry
SyncQueueSchema.statics.getFailedOperations = function (companyId, maxRetries = 3) {
  return this.find({
    companyId,
    status: 'failed',
    retryCount: { $lt: maxRetries }
  })
    .sort({ updatedAt: 1 }) // Process oldest first
    .limit(20)
}

// Static method to get operations since timestamp
SyncQueueSchema.statics.getOperationsSince = function (companyId, sinceTimestamp) {
  return this.find({
    companyId,
    clientCreatedAt: { $gte: new Date(sinceTimestamp) }
  })
    .sort({ clientCreatedAt: 1 })
}

// Method to get operation details
SyncQueueSchema.methods.getDetails = function () {
  return {
    clientId: this.clientId,
    entityType: this.entityType,
    operation: this.operation,
    data: this.data,
    status: this.status,
    errorMessage: this.errorMessage,
    retryCount: this.retryCount,
    clientCreatedAt: this.clientCreatedAt,
    processedAt: this.processedAt
  }
}

module.exports = mongoose.model('SyncQueue', SyncQueueSchema)
