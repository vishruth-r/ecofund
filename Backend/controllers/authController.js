const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const pool = require('../models/db');
const generateToken = require('../utils/generateToken');

exports.register = async (req, res) => {
  const {
    name,
    email,
    password,
    role,
    upi_id,
    pan_card,
    fcm_token,
    serviceable_cities // <-- updated here
  } = req.body;

  try {
    const result = await pool.query(`SELECT * FROM users WHERE email = $1`, [email]);

    if (result.rows.length > 0) {
      return res.status(400).json({ error: 'Email already in use. Please use a different email.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user_id = uuidv4();

    if (role === 'vendor') {
      await pool.query(
        `INSERT INTO users (
          user_id, name, email, password, role, upi_id, pan_card, fcm_token, serviceable_cities, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())`,
        [user_id, name, email, hashedPassword, role, upi_id, pan_card, fcm_token, serviceable_cities]
      );
    } else {
      await pool.query(
        `INSERT INTO users (
          user_id, name, email, password, role, upi_id, pan_card, fcm_token, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())`,
        [user_id, name, email, hashedPassword, role, upi_id, pan_card, fcm_token]
      );
    }

    const token = generateToken({ user_id, role });

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        user_id,
        name,
        email,
        role,
        upi_id,
        pan_card,
        fcm_token
      }
    });

  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Internal server error during registration.' });
  }
};

exports.login = async (req, res) => {
  const { email, password, fcm_token } = req.body;  // Add fcm_token to the request body

  try {
    const result = await pool.query(`SELECT * FROM users WHERE email = $1`, [email]);

    // Check if user exists
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found. Please register first.' });
    }

    const user = result.rows[0];

    // Compare password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Incorrect password. Please try again.' });
    }

    // If an FCM token is provided, update the user's record
    if (fcm_token) {
      await pool.query(
        `UPDATE users SET fcm_token = $1 WHERE user_id = $2`,
        [fcm_token, user.user_id]
      );
    }

    // Generate token with user_id and role
    const token = generateToken({ user_id: user.user_id, role: user.role });

    // Return success response
    res.json({
      message: 'Login successful',
      token,
      user: {
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        role: user.role,
        upi_id: user.upi_id,
        pan_card: user.pan_card,
        fcm_token: user.fcm_token
      }
    });

  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error during login.' });
  }
};



// In userController.js
exports.getMyProfile = async (req, res) => {
  const user_id = req.user.user_id;

  try {
    const result = await pool.query('SELECT * FROM users WHERE user_id = $1', [user_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = result.rows[0];

    res.json({
      message: 'User profile fetched',
      user: {
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        role: user.role,
        upi_id: user.upi_id,
        pan_card: user.pan_card,
        fcm_token: user.fcm_token,
        serviceable_cities: user.serviceable_cities,
        created_at: user.created_at
      }
    });
  } catch (err) {
    console.error('Error fetching profile:', err);
    res.status(500).json({ error: 'Server error while fetching profile' });
  }
};
