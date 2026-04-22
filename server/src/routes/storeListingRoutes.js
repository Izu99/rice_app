const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const companyGuard = require('../middleware/companyGuard');
const roleGuard = require('../middleware/roleGuard');
const ctrl = require('../controllers/storeListingController');

router.use(auth);
router.use(companyGuard);

router.get('/listings/stats', ctrl.getStats);
router.get('/listings/my', roleGuard('company', 'manager', 'operator'), ctrl.getMyListings);
router.get('/listings', ctrl.getListings);
router.post('/listings', roleGuard('company', 'manager'), ctrl.createListing);
router.put('/listings/:id', roleGuard('company', 'manager'), ctrl.updateListing);
router.delete('/listings/:id', roleGuard('company', 'manager'), ctrl.deleteListing);

module.exports = router;
