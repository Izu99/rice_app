const mongoose = require('mongoose')

const TransactionSchema = new mongoose.Schema({
  transactionNumber: {
    type: String,
    required: [true, 'Transaction number is required'],
    unique: true,
    trim: true
  },
  type: {
    type: String,
    enum: ['buy', 'sell'],
    required: [true, 'Transaction type is required']
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: [true, 'Customer ID is required']
  },
  customerName: {
    type: String,
    required: [true, 'Customer name is required'],
    trim: true
  },
  items: [{
    stockItemId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'StockItem'
    },
    itemName: {
      type: String,
      required: true,
      trim: true
    },
    itemType: {
      type: String,
      enum: ['paddy', 'rice'],
      required: true
    },
    weightKg: {
      type: Number,
      required: true,
      min: [0, 'Weight cannot be negative']
    },
    bags: {
      type: Number,
      default: 0,
      min: [0, 'Bags cannot be negative']
    },
    pricePerKg: {
      type: Number,
      required: true,
      min: [0, 'Price cannot be negative']
    },
    totalPrice: {
      type: Number,
      required: true,
      min: [0, 'Total price cannot be negative']
    }
  }],
  totalWeightKg: {
    type: Number,
    required: true,
    default: 0,
    min: [0, 'Total weight cannot be negative']
  },
  totalBags: {
    type: Number,
    required: true,
    default: 0,
    min: [0, 'Total bags cannot be negative']
  },
  totalAmount: {
    type: Number,
    required: true,
    default: 0,
    min: [0, 'Total amount cannot be negative']
  },
  paidAmount: {
    type: Number,
    required: true,
    default: 0,
    min: [0, 'Paid amount cannot be negative']
  },
  balance: {
    type: Number,
    required: true,
    default: 0
  },
  status: {
    type: String,
    enum: ['pending', 'partially_paid', 'completed', 'cancelled'],
    default: 'pending'
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'bank_transfer', 'cheque', 'credit'],
    required: [true, 'Payment method is required']
  },
  paymentHistory: [{
    amount: {
      type: Number,
      required: true,
      min: [0, 'Payment amount cannot be negative']
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'bank_transfer', 'cheque', 'credit'],
      required: true
    },
    paidAt: {
      type: Date,
      default: Date.now
    },
    receivedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    notes: {
      type: String,
      trim: true
    }
  }],
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot exceed 500 characters']
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: [true, 'Company ID is required']
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Created by is required']
  },
  isSynced: {
    type: Boolean,
    default: true
  },
  clientId: {
    type: String,
    trim: true
  },
  transactionDate: {
    type: Date,
    required: [true, 'Transaction date is required'],
    default: Date.now
  }
}, {
  timestamps: true
})

// Indexes
TransactionSchema.index({ transactionNumber: 1 }, { unique: true })
TransactionSchema.index({ companyId: 1 })
TransactionSchema.index({ customerId: 1 })
TransactionSchema.index({ type: 1 })
TransactionSchema.index({ status: 1 })
TransactionSchema.index({ transactionDate: 1 })
TransactionSchema.index({ clientId: 1 }, { unique: true, sparse: true })

// Pre-save middleware to calculate totals and balance
TransactionSchema.pre('save', function (next) {
  // Calculate totals from items
  this.totalWeightKg = this.items.reduce((sum, item) => sum + item.weightKg, 0)
  this.totalBags = this.items.reduce((sum, item) => sum + (item.bags || 0), 0)
  this.totalAmount = this.items.reduce((sum, item) => sum + item.totalPrice, 0)

  // Calculate balance
  this.balance = this.totalAmount - this.paidAmount

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

  next()
})

// Static method to generate transaction number
TransactionSchema.statics.generateTransactionNumber = function (type, date) {
  const prefix = type.toUpperCase()
  const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '')
  const timestamp = Date.now().toString().slice(-4)
  return `${prefix}-${dateStr}-${timestamp}`
}

// Method to add payment
TransactionSchema.methods.addPayment = async function (paymentData) {
  const { amount, paymentMethod, receivedBy, notes } = paymentData

  // Add to payment history
  this.paymentHistory.push({
    amount,
    paymentMethod,
    receivedBy,
    notes
  })

  // Update paid amount
  this.paidAmount += amount

  return this.save()
}

// Method to get payment summary
TransactionSchema.methods.getPaymentSummary = function () {
  const totalPaid = this.paymentHistory.reduce((sum, payment) => sum + payment.amount, 0)
  const lastPayment = this.paymentHistory.length > 0
    ? this.paymentHistory[this.paymentHistory.length - 1]
    : null

  return {
    totalPaid,
    balance: this.balance,
    paymentCount: this.paymentHistory.length,
    lastPayment: lastPayment
      ? {
          amount: lastPayment.amount,
          paymentMethod: lastPayment.paymentMethod,
          paidAt: lastPayment.paidAt,
          receivedBy: lastPayment.receivedBy
        }
      : null
  }
}

// Method to cancel transaction
TransactionSchema.methods.cancelTransaction = async function () {
  this.status = 'cancelled'
  return this.save()
}

module.exports = mongoose.model('Transaction', TransactionSchema)
