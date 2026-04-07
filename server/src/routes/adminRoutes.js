const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const roleGuard = require("../middleware/roleGuard");
const adminController = require("../controllers/adminController");

// Apply authentication and admin role check to all routes
router.use(auth);
router.use(roleGuard("admin"));

/**
 * @route   GET /api/admin/dashboard
 * @desc    Get Super Admin dashboard statistics
 * @access  Private (Super Admin only)
 */
router.get("/dashboard", adminController.getDashboard);

/**
 * @route   GET /api/admin/companies
 * @desc    Get all companies with filtering and pagination
 * @access  Private (Super Admin only)
 */
router.get("/companies", adminController.getCompanies);

/**
 * @route   GET /api/admin/companies/:id
 * @desc    Get single company details with statistics
 * @access  Private (Super Admin only)
 */
router.get("/companies/:id", adminController.getCompanyById);

/**
 * @route   POST /api/admin/companies
 * @desc    Create new company and admin user
 * @access  Private (Super Admin only)
 */
router.post("/companies", adminController.createCompany);

/**
 * @route   PUT /api/admin/companies/:id
 * @desc    Update company details
 * @access  Private (Super Admin only)
 */
router.put("/companies/:id", adminController.updateCompany);

/**
 * @route   PATCH /api/admin/companies/:id/status
 * @desc    Change company status
 * @access  Private (Super Admin only)
 */
router.patch("/companies/:id/status", adminController.updateCompanyStatus);

/**
 * @route   DELETE /api/admin/companies/:id
 * @desc    Delete company (soft delete)
 * @access  Private (Super Admin only)
 */
router.delete("/companies/:id", adminController.deleteCompany);

/**
 * @route   POST /api/admin/companies/:id/reset-password
 * @desc    Reset company admin password
 * @access  Private (Super Admin only)
 */
router.post("/companies/:id/reset-password", adminController.resetCompanyPassword);

module.exports = router;
