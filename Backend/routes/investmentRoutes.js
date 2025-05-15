const express = require('express');
const router = express.Router();
const {
  submitInvestment,
  getAvailableInvestments,
  getMyInvestments,
} = require('../controllers/investmentController');
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');

router.get('/', authenticateToken, authorizeRoles('investor'), getAvailableInvestments);

router.post('/', authenticateToken, authorizeRoles('investor'), submitInvestment);

router.get('/mine', authenticateToken, authorizeRoles('investor'), getMyInvestments);


module.exports = router;