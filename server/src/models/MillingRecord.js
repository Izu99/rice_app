const mongoose = require('mongoose')

const MillingRecordSchema = new mongoose.Schema({
  batchNumber: {
    type: String,
    required: [true, 'Batch number is required'],
    unique: true,
    trim: true
  },
  paddyItemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'StockItem',
    required: [true, 'Paddy item ID is required']
  },
  paddyItemName: {
    type: String,
    required: [true, 'Paddy item name is required'],
    trim: true
  },
  inputPaddyKg: {
    type: Number,
    required: [true, 'Input paddy weight is required'],
    min: [0, 'Input weight cannot be negative']
  },
  inputPaddyBags: {
    type: Number,
    required: [true, 'Input paddy bags is required'],
    min: [0, 'Input bags cannot be negative']
  },
  outputRiceKg: {
    type: Number,
    min: [0, 'Output weight cannot be negative']
  },
  outputRiceBags: {
    type: Number,
    min: [0, 'Output bags cannot be negative']
  },
  brokenRiceKg: {
    type: Number,
    default: 0,
    min: [0, 'Broken rice weight cannot be negative']
  },
  huskKg: {
    type: Number,
    default: 0,
    min: [0, 'Husk weight cannot be negative']
  },
  wastageKg: {
    type: Number,
    default: 0,
    min: [0, 'Wastage weight cannot be negative']
  },
  millingPercentage: {
    type: Number,
    min: [0, 'Percentage cannot be negative'],
    max: [100, 'Percentage cannot exceed 100']
  },
  actualPercentage: {
    type: Number,
    min: [0, 'Actual percentage cannot be negative'],
    max: [100, 'Actual percentage cannot exceed 100']
  },
  status: {
    type: String,
    enum: ['in_progress', 'completed'],
    default: 'completed'
  },
  riceItemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'StockItem'
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: [true, 'Company ID is required']
  },
  milledBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Milled by is required']
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot exceed 500 characters']
  },
  isSynced: {
    type: Boolean,
    default: true
  },
  clientId: {
    type: String,
    trim: true
  },
  millingDate: {
    type: Date,
    required: [true, 'Milling date is required'],
    default: Date.now
  }
}, {
  timestamps: true
})

// Indexes
MillingRecordSchema.index({ batchNumber: 1 }, { unique: true })
MillingRecordSchema.index({ companyId: 1 })
MillingRecordSchema.index({ paddyItemId: 1 })
MillingRecordSchema.index({ millingDate: 1 })
MillingRecordSchema.index({ clientId: 1 }, { unique: true, sparse: true })

// Pre-save middleware to calculate actual percentage
MillingRecordSchema.pre('save', function (next) {
  if (this.inputPaddyKg > 0 && (this.outputRiceKg !== undefined && this.outputRiceKg !== null)) {
    this.actualPercentage = (this.outputRiceKg / this.inputPaddyKg) * 100
  }
  next()
})

// Static method to generate batch number
MillingRecordSchema.statics.generateBatchNumber = function (date) {
  const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '')
  const timeStr = date.toTimeString().slice(0, 5).replace(':', '')
  return `ML-${dateStr}-${timeStr}`
}

// Method to get milling summary
MillingRecordSchema.methods.getSummary = function () {
  return {
    batchNumber: this.batchNumber,
    paddyProcessed: this.inputPaddyKg,
    riceProduced: this.outputRiceKg,
    brokenRice: this.brokenRiceKg,
    husk: this.huskKg,
    wastage: this.wastageKg,
    expectedPercentage: this.millingPercentage,
    actualPercentage: this.actualPercentage,
    efficiency: this.actualPercentage ? (this.actualPercentage / this.millingPercentage) * 100 : 0,
    millingDate: this.millingDate,
    milledBy: this.milledBy
  }
}

// Method to calculate total output
MillingRecordSchema.methods.getTotalOutput = function () {
  return this.outputRiceKg + this.brokenRiceKg + this.huskKg + this.wastageKg
}

// Method to get recovery details
MillingRecordSchema.methods.getRecoveryDetails = function () {
  const totalOutput = this.getTotalOutput()
  const recovery = totalOutput / this.inputPaddyKg * 100

  return {
    inputKg: this.inputPaddyKg,
    totalOutputKg: totalOutput,
    riceKg: this.outputRiceKg,
    brokenRiceKg: this.brokenRiceKg,
    huskKg: this.huskKg,
    wastageKg: this.wastageKg,
    recoveryPercentage: recovery,
    expectedRecovery: this.millingPercentage,
    efficiency: (this.outputRiceKg / this.inputPaddyKg) * 100
  }
}

module.exports = mongoose.model('MillingRecord', MillingRecordSchema)
