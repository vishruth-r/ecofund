const express = require('express');
const router = express.Router();

const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');
const {
  submitProperty,
  getAssignedProperties,
  submitQuote,
  getMyProperties,
  submitEnergyLog,
  getEnergyLogs,
  getPropertyDetails,
  getServiceableCities,

} = require('../controllers/propertyController');

// Homeowner submits a new property
router.post('/', authenticateToken, authorizeRoles('homeowner'), submitProperty);

// Vendor views properties assigned to them
router.get('/vendor/assigned', authenticateToken, authorizeRoles('vendor'), getAssignedProperties);

// Vendor submits a quote for a property
router.post('/:id/quote', authenticateToken, authorizeRoles('vendor'), submitQuote);

// Homeowner fetches their submitted properties
router.get('/my-properties', authenticateToken, authorizeRoles('homeowner'), getMyProperties);

// ✅ Vendor logs monthly energy production
router.post('/log-energy', authenticateToken, authorizeRoles('vendor'), submitEnergyLog);

// ✅ Homeowner/investor fetches energy logs for a property
router.get('/:id/energy-logs', authenticateToken, getEnergyLogs);

router.get('/serviceable-cities', authenticateToken, authorizeRoles('homeowner'), getServiceableCities);

router.get('/:id/details', authenticateToken, getPropertyDetails);



module.exports = router;