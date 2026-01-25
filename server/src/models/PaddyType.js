const mongoose = require('mongoose')

const PaddyTypeSchema = new mongoose.Schema({
  // Paddy Type Details
  name: {
    type: String,
    required: [true, 'Paddy type name is required'],
    trim: true,
    maxlength: [50, 'Paddy type name cannot exceed 50 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [200, 'Description cannot exceed 200 characters']
  },

  // Milling characteristics
  averageYieldPercentage: {
    type: Number,
    min: [0, 'Yield percentage cannot be negative'],
    max: [100, 'Yield percentage cannot exceed 100'],
    default: 65
  },
  averageMoistureContent: {
    type: Number,
    min: [0, 'Moisture content cannot be negative'],
    max: [100, 'Moisture content cannot exceed 100']
  },
  qualityGrade: {
    type: String,
    enum: ['premium', 'standard', 'basic'],
    default: 'standard'
  },

  // Reference to Company (Multi-tenant)
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: [true, 'Company ID is required']
  },

  // Status
  isActive: {
    type: Boolean,
    default: true
  },

  // Offline sync support
  clientId: {
    type: String,
    trim: true
  },

  // Metadata
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
})

// Compound index to ensure unique paddy type names per company
PaddyTypeSchema.index({ companyId: 1, name: 1 }, { unique: true })

// Additional indexes
PaddyTypeSchema.index({ companyId: 1, isActive: 1 })
PaddyTypeSchema.index({ companyId: 1, qualityGrade: 1 })
PaddyTypeSchema.index({ clientId: 1 }, { unique: true, sparse: true })

// Pre-save middleware to update timestamps
PaddyTypeSchema.pre('save', function (next) {
  this.updatedAt = new Date()
  next()
})

// Method to get public profile
PaddyTypeSchema.methods.getPublicProfile = function () {
  return {
    id: this._id,
    name: this.name,
    description: this.description,
    averageYieldPercentage: this.averageYieldPercentage,
    averageMoistureContent: this.averageMoistureContent,
    qualityGrade: this.qualityGrade,
    isActive: this.isActive,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  }
}

// Method to get detailed info
PaddyTypeSchema.methods.getDetailedInfo = function () {
  return {
    ...this.getPublicProfile(),
    companyId: this.companyId,
    clientId: this.clientId
  }
}

// Static method to get paddy types for a company
PaddyTypeSchema.statics.getActiveForCompany = function (companyId) {
  return this.find({
    companyId,
    isActive: true
  }).sort({ name: 1 })
}

module.exports = mongoose.model('PaddyType', PaddyTypeSchema)
