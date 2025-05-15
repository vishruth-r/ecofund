const express = require('express');
const router = express.Router();
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');
const {
  getHomeownerPayments,
  confirmPayment
,
  getInvestorPayouts
} = require('../controllers/paymentsController');

// Homeowner views their payments
router.get('/homeowner', authenticateToken, authorizeRoles('homeowner'), getHomeownerPayments);

// Homeowner confirms a payment
router.post('/confirm', authenticateToken, authorizeRoles('homeowner'), confirmPayment);

// Investor views payout history
router.get('/investor/payouts', authenticateToken, authorizeRoles('investor'), getInvestorPayouts);


module.exports = router;
