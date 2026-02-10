const express = require('express')
const router = express.Router()
const expenseController = require('../controllers/expenseController')
const auth = require('../middleware/auth')
const companyGuard = require('../middleware/companyGuard')

// Apply authentication and company isolation to all routes
router.use(auth)
router.use(companyGuard)

router.route('/')
  .get(expenseController.getExpenses)
  .post(expenseController.createExpense)

router.get('/summary', expenseController.getExpenseSummary)

router.route('/:id')
  .put(expenseController.updateExpense)
  .delete(expenseController.deleteExpense)

module.exports = router