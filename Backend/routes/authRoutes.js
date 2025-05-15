const express = require('express');
const router = express.Router();
const { register, login, getMyProfile } = require('../controllers/authController');
const { authenticateToken, authorizeRoles } = require('../middleware/authMiddleware');


router.post('/register', register);
router.post('/login', login);
router.get('/me', authenticateToken, getMyProfile);


module.exports = router;
