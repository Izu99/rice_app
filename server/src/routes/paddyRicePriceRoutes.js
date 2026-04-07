const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const companyGuard = require("../middleware/companyGuard");
const roleGuard = require("../middleware/roleGuard");
const paddyRicePriceController = require("../controllers/paddyRicePriceController");

// All routes require authentication
router.use(auth);

/**
 * @route   POST /api/paddy-rice-price
 * @desc    Add a new paddy rice price (Company users only)
 * @access  Private
 */
router.post("/", companyGuard, roleGuard("company", "manager"), paddyRicePriceController.addPrice);

/**
 * @route   GET /api/paddy-rice-price/company/my-prices
 * @desc    Get prices added by current company
 * @access  Private
 */
router.get("/company/my-prices", companyGuard, paddyRicePriceController.getMyCompanyPrices);

/**
 * @route   GET /api/paddy-rice-price/admin/all
 * @desc    Get all prices (admin only)
 * @access  Private (Admin)
 */
router.get("/admin/all", roleGuard("admin"), paddyRicePriceController.getAllPricesAdmin);

/**
 * @route   GET /api/paddy-rice-price/districts/list
 * @desc    Get all districts with price listings
 * @access  Private
 */
router.get("/districts/list", paddyRicePriceController.getDistrictsList);

/**
 * @route   GET /api/paddy-rice-price/district/:district
 * @desc    Get prices for a specific district
 * @access  Private
 */
router.get("/district/:district", paddyRicePriceController.getPricesByDistrict);

/**
 * @route   GET /api/paddy-rice-price/:id
 * @desc    Get price by ID
 * @access  Private
 */
router.get("/:id", paddyRicePriceController.getPriceById);

/**
 * @route   PUT /api/paddy-rice-price/:id
 * @desc    Update a price entry (Company users only - own entries)
 * @access  Private
 */
router.put(
	"/:id",
	companyGuard,
	roleGuard("company", "manager"),
	paddyRicePriceController.updatePrice,
);

/**
 * @route   DELETE /api/paddy-rice-price/:id
 * @desc    Delete a price entry (Company users only - own entries)
 * @access  Private
 */
router.delete(
	"/:id",
	companyGuard,
	roleGuard("company", "manager"),
	paddyRicePriceController.deletePrice,
);

module.exports = router;
