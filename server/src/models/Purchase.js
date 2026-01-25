const mongoose = require('mongoose')

const PurchaseSchema = new mongoose.Schema({
  // Purchase Details
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: [true, 'Customer is required']
  },
  paddyTypeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'PaddyType',
    required: [true, 'Paddy type is required']
  },
  numberOfBags: {
    type: Number,
    required: [true, 'Number of bags is required'],
    min: [1, 'Number of bags must be at least 1']
  },
  totalWeight: {
    type: Number,
    required: [true, 'Total weight is required'],
    min: [0.1, 'Total weight must be greater than 0']
  },
  pricePerKg: {
    type: Number,
    required: [true, 'Price per kg is required'],
    min: [0, 'Price cannot be negative']
  },
  totalPrice: {
    type: Number,
    required: true
  },

  // Payment information
  paidAmount: {
    type: Number,
    default: 0,
    min: [0, 'Paid amount cannot be negative']
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'bank_transfer', 'cheque', 'credit'],
    default: 'cash'
  },
  balance: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    enum: ['pending', 'partially_paid', 'completed', 'cancelled'],
    default: 'pending'
  },

  // Reference to Company (Multi-tenant)
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: [true, 'Company ID is required']
  },

  // Reference to User who created the purchase
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Created by is required']
  },

  // Purchase Date
  purchaseDate: {
    type: Date,
    required: [true, 'Purchase date is required'],
    default: Date.now
  },

  // Optional Notes
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot exceed 500 characters']
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

// Auto-calculate total price and balance before saving
PurchaseSchema.pre('save', function (next) {
  // Calculate total price
  this.totalPrice = this.totalWeight * this.pricePerKg

  // Calculate balance
  this.balance = this.totalPrice - this.paidAmount

  // Update status based on balance
  if (this.status !== 'cancelled') {
    if (this.balance <= 0) {
      this.status = 'completed'
    } else if (this.paidAmount > 0) {
      this.status = 'partially_paid'
    } else {
      this.status = 'pending'
    }
  }

  // Update timestamp
  this.updatedAt = new Date()

  next()
})

// Indexes for efficient queries
PurchaseSchema.index({ companyId: 1, purchaseDate: -1 })
PurchaseSchema.index({ companyId: 1, customerId: 1 })
PurchaseSchema.index({ companyId: 1, paddyTypeId: 1 })
PurchaseSchema.index({ companyId: 1, status: 1 })
PurchaseSchema.index({ companyId: 1, createdBy: 1 })
PurchaseSchema.index({ clientId: 1 }, { unique: true, sparse: true })

// Method to get detailed purchase info
PurchaseSchema.methods.getDetailedInfo = function () {
  return {
    id: this._id,
    customer: this.customerId,
    paddyType: this.paddyTypeId,
    numberOfBags: this.numberOfBags,
    totalWeight: this.totalWeight,
    pricePerKg: this.pricePerKg,
    totalPrice: this.totalPrice,
    paidAmount: this.paidAmount,
    balance: this.balance,
    paymentMethod: this.paymentMethod,
    status: this.status,
    purchaseDate: this.purchaseDate,
    notes: this.notes,
    companyId: this.companyId,
    createdBy: this.createdBy,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  }
}

// Method to add payment
PurchaseSchema.methods.addPayment = async function (paymentData) {
  const { amount, paymentMethod, notes } = paymentData

  this.paidAmount += amount
  if (paymentMethod) this.paymentMethod = paymentMethod

  return this.save()
}

// Method to cancel purchase
PurchaseSchema.methods.cancelPurchase = async function () {
  this.status = 'cancelled'
  return this.save()
}

// Static method to get purchase summary for company
PurchaseSchema.statics.getPurchaseSummary = async function (companyId, startDate, endDate) {
  const match = { companyId }

  if (startDate || endDate) {
    match.purchaseDate = {}
    if (startDate) match.purchaseDate.$gte = new Date(startDate)
    if (endDate) match.purchaseDate.$lte = new Date(endDate)
  }

  return this.aggregate([
    { $match: match },
    {
      $group: {
        _id: null,
        totalPurchases: { $sum: 1 },
        totalWeight: { $sum: '$totalWeight' },
        totalAmount: { $sum: '$totalPrice' },
        totalPaid: { $sum: '$paidAmount' },
        totalBalance: { $sum: '$balance' }
      }
    }
  ])
}

module.exports = mongoose.model('Purchase', PurchaseSchema)
