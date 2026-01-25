const express = require('express')
const router = express.Router()
const setupController = require('../controllers/setupController')

// One-time setup route
router.post('/admin', setupController.setupSuperAdmin)

module.exports = router
