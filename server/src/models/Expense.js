const mongoose = require('mongoose')

const ExpenseSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Expense title is required'],
    trim: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  category: {
    type: String,
    required: [true, 'Category is required'],
    enum: [
      'electricity',
      'water',
      'fuel',
      'transport',
      'labor',
      'maintenance',
      'rent',
      'taxes',
      'other'
    ]
  },
  amount: {
    type: Number,
    required: [true, 'Amount is required'],
    min: [0, 'Amount cannot be negative']
  },
  expenseDate: {
    type: Date,
    default: Date.now,
    required: [true, 'Date is required']
  },
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
    required: [true, 'User ID is required']
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
})

// Indexes
ExpenseSchema.index({ companyId: 1 })
ExpenseSchema.index({ expenseDate: -1 })
ExpenseSchema.index({ category: 1 })

module.exports = mongoose.model('Expense', ExpenseSchema)
