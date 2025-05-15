const db = require('../config/db');
const pool = require('../models/db');
const { v4: uuidv4 } = require('uuid');
const { sendNotification } = require('../services/notificationService'); // Import the notification service


exports.submitProperty = async (req, res) => {
  const { address, pincode, city, energy_consumption } = req.body;
  const homeowner_id = req.user.user_id;

  if (!address || !pincode || !city || !energy_consumption) {
    return res.status(400).json({ message: 'All fields are required.' });
  }

  try {
    // 1. Find a vendor that services the given city
    const vendorRes = await db.query(
      `SELECT user_id, fcm_token 
       FROM users 
       WHERE role = 'vendor' AND $1 = ANY (serviceable_cities)`,
      [city]
    );

    if (vendorRes.rows.length === 0) {
      return res.status(404).json({ message: 'No vendor available for this city.' });
    }

    const assigned_vendor = vendorRes.rows[0].user_id;
    const vendor_token = vendorRes.rows[0].fcm_token; // Assuming vendor has an FCM token
    const property_id = uuidv4();

    // 2. Insert the property
    await db.query(
      `INSERT INTO properties (
         property_id, homeowner_id, address, pincode, city, 
         energy_consumption, assigned_vendor, status, created_at
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', NOW())`,
      [
        property_id,
        homeowner_id,
        address,
        pincode,
        city,
        energy_consumption,
        assigned_vendor
      ]
    );

    // Send notification to the assigned vendor
    const notificationTitle = "New Property Assignment";
    const notificationBody = `A new property has been submitted in ${city}. Please review the details.`;
    await sendNotification(vendor_token, notificationTitle, notificationBody);

    res.status(201).json({
      message: 'Property submitted successfully.',
      property_id,
      assigned_vendor
    });

  } catch (err) {
    console.error('Error submitting property:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// controllers/propertyController.js
exports.getAssignedProperties = async (req, res) => {
    const vendor_id = req.user.user_id;
  
    try {
      const result = await pool.query(
        `SELECT * FROM properties WHERE assigned_vendor = $1`,
        [vendor_id]
      );
  
      res.json(result.rows);
    } catch (err) {
      console.error('Error fetching assigned properties:', err);
      res.status(500).json({ error: 'Failed to fetch properties' });
    }
  };

  exports.submitQuote = async (req, res) => {
    const vendorId = req.user.user_id;
    const propertyId = req.params.id;
    const { panel_size, quote_amount } = req.body;
  
    try {
      await pool.query(
        `UPDATE properties 
         SET panel_size = $1, quote_amount = $2, status = 'quoted' 
         WHERE property_id = $3 AND assigned_vendor = $4`,
        [panel_size, quote_amount, propertyId, vendorId]
      );
  
      res.json({ message: 'Quote submitted successfully' });
  
      // Fetch homeowner token
      const homeownerRes = await pool.query(
        `SELECT u.fcm_token 
         FROM properties p 
         JOIN users u ON p.homeowner_id = u.user_id 
         WHERE p.property_id = $1`,
        [propertyId]
      );
  
      if (homeownerRes.rows.length) {
        const token = homeownerRes.rows[0].fcm_token;
        if (token) {
          await sendNotification(
            token,
            "Quote Received",
            "A vendor has submitted a quote for your property."
          );
        }
      }
  
      // Notify all investors about new investment opportunity
      const investorRes = await pool.query(
        `SELECT DISTINCT fcm_token 
         FROM users 
         WHERE role = 'investor' AND fcm_token IS NOT NULL`
      );
  
      for (const row of investorRes.rows) {
        await sendNotification(
          row.fcm_token,
          "New Investment Opportunity",
          "A new solar project is now open for investment."
        );
      }
  
    } catch (err) {
      console.error('Error submitting quote:', err);
      res.status(500).json({ error: 'Failed to submit quote' });
    }
  };
  

  exports.getMyProperties = async (req, res) => {
    const homeowner_id = req.user.user_id;
  
    try {
      const result = await pool.query(
        `
        SELECT 
          p.property_id,
          p.address,
          p.pincode,
          p.energy_consumption,
          p.panel_size,
          p.quote_amount,
          p.assigned_vendor,
          p.status,
          p.city,
          p.created_at,
  
          -- Subquery for total units bought
          (
            SELECT COALESCE(SUM(i.units_purchased), 0)
            FROM investments i
            WHERE i.property_id = p.property_id
          ) AS total_units_bought,
  
          -- Energy logs and their associated payments
          COALESCE(json_agg(
            json_build_object(
              'log_id', el.log_id,
              'energy_output', el.units_produced,
              'month', el.month,
              'created_at', el.created_at,
              'payment', json_build_object(
                'payment_id', pay.payment_id,
                'unit_price', pay.unit_price,
                'amount_due', pay.amount_due,
                'status', pay.status,
                'created_at', pay.created_at
              )
            )
            ORDER BY el.created_at DESC
          ) FILTER (WHERE el.log_id IS NOT NULL), '[]') AS energy_logs
  
        FROM properties p
        LEFT JOIN energy_logs el ON p.property_id = el.property_id
        LEFT JOIN payments pay ON el.log_id = pay.log_id
        WHERE p.homeowner_id = $1
        GROUP BY 
          p.property_id, p.address, p.pincode, p.energy_consumption,
          p.panel_size, p.quote_amount, p.assigned_vendor, 
          p.status, p.city, p.created_at
        ORDER BY p.created_at DESC
        `,
        [homeowner_id]
      );
  
      res.json(result.rows);
    } catch (err) {
      console.error('Error fetching user properties:', err);
      res.status(500).json({ error: 'Failed to fetch your properties' });
    }
  };
  
  exports.getEnergyLogs = async (req, res) => {
    const propertyId = req.params.id;
  
    try {
      const result = await pool.query(
        `SELECT month, units_produced, created_at
         FROM energy_logs
         WHERE property_id = $1
         ORDER BY month DESC`,
        [propertyId]
      );
  
      res.json(result.rows);
    } catch (err) {
      console.error('Error fetching energy logs:', err);
      res.status(500).json({ error: 'Failed to fetch energy logs' });
    }
  };
  exports.submitEnergyLog = async (req, res) => {
    const vendorId = req.user.user_id;
    const { property_id, month, units_produced } = req.body;
  
    try {
      const grid_unit_price = 10;
  
      const propertyRes = await pool.query(
        `SELECT p.*, u.fcm_token 
         FROM properties p
         JOIN users u ON p.homeowner_id = u.user_id
         WHERE p.property_id = $1 AND p.assigned_vendor = $2`,
        [property_id, vendorId]
      );
  
      if (propertyRes.rows.length === 0) {
        return res.status(403).json({ error: 'Unauthorized or invalid property' });
      }
  
      const property = propertyRes.rows[0];
      const log_id = uuidv4();
  
      await pool.query(
        `INSERT INTO energy_logs (log_id, property_id, vendor_id, month, units_produced, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())`,
        [log_id, property_id, vendorId, month, units_produced]
      );
  
      const discounted_price = grid_unit_price * 0.85;
      const amount_due = discounted_price * units_produced;
  
      await pool.query(
        `INSERT INTO payments (
           payment_id, log_id, property_id, homeowner_id,
           units_logged, unit_price, amount_due, created_at
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
        [
          uuidv4(),
          log_id,
          property_id,
          property.homeowner_id,
          units_produced,
          discounted_price,
          amount_due
        ]
      );
  
      res.status(201).json({ message: 'Energy log submitted, payment created.' });
  
      // Notify homeowner to pay
      if (property.fcm_token) {
        await sendNotification(
          property.fcm_token,
          "Monthly Payment Due",
          `Your solar energy bill for ${month} is ₹${amount_due.toFixed(2)}. Please pay soon.`
        );
      }
  
    } catch (err) {
      console.error('Error submitting energy log:', err);
      res.status(500).json({ error: 'Failed to submit energy data or assign payment' });
    }
  };
  
  exports.getPropertyDetails = async (req, res) => {
    const propertyId = req.params.id;
    const investorId = req.user.user_id;  // assuming middleware sets req.user
  
    try {
      const propertyQuery = `
        SELECT 
          p.property_id,
          p.address,
          p.pincode,
          p.city,
          p.energy_consumption,
          p.panel_size,
          p.quote_amount,
          p.status AS property_status,
          
          -- Vendor details
          v.user_id AS vendor_id,
          v.name AS vendor_name,
          v.email AS vendor_contact,
          
          -- Homeowner details
          h.user_id AS homeowner_id,
          h.name AS homeowner_name,
          h.email AS homeowner_contact,
  
          p.created_at AS property_created_at,
  
          -- Energy logs subquery
          (
              SELECT COALESCE(json_agg(
                  json_build_object(
                      'log_id', el.log_id,
                      'month', el.month,
                      'energy_output', el.units_produced,
                      'created_at', el.created_at
                  ) ORDER BY el.created_at DESC
              ), '[]')
              FROM energy_logs el
              WHERE el.property_id = p.property_id
          ) AS energy_logs,
  
          -- Payments subquery (linked via energy_logs)
          (
              SELECT COALESCE(json_agg(
                  json_build_object(
                      'payment_id', pay.payment_id,
                      'amount_due', pay.amount_due,
                      'status', pay.status,
                      'created_at', pay.created_at
                  ) ORDER BY pay.created_at DESC
              ), '[]')
              FROM payments pay
              INNER JOIN energy_logs el ON pay.log_id = el.log_id
              WHERE el.property_id = p.property_id
          ) AS payments,
  
          -- Investments subquery
          (
              SELECT COALESCE(json_agg(
                  json_build_object(
                      'investor_id', i.investor_id,
                      'units_purchased', i.units_purchased,
                      'investment_amount', i.units_purchased * (p.quote_amount::decimal / 1000)
                  ) ORDER BY i.investor_id
              ), '[]')
              FROM investments i
              WHERE i.property_id = p.property_id
          ) AS investments,
  
          -- Investor payouts subquery (for current logged-in investor and specific property)
          (
            SELECT COALESCE(json_agg(
              json_build_object(
                'payout_id', ip.payout_id,
                'amount', ip.amount,
                'status', p.status,
                'payout_date', ip.created_at,
                'amount_due', p.amount_due,
                'property_address', pr.address,
                'month', el.month
              ) ORDER BY ip.created_at DESC
            ), '[]')
            FROM investor_payouts ip
            JOIN payments p ON ip.payment_id = p.payment_id
            JOIN energy_logs el ON p.log_id = el.log_id
            JOIN properties pr ON p.property_id = pr.property_id
            WHERE ip.investor_id = $2 
            AND pr.property_id = p.property_id
            AND pr.property_id = $1  -- Ensures that payouts are for the given property only
          ) AS investor_payouts
  
        FROM properties p
        LEFT JOIN users v ON p.assigned_vendor = v.user_id AND v.role = 'vendor'
        LEFT JOIN users h ON p.homeowner_id = h.user_id AND h.role = 'homeowner'
        WHERE p.property_id = $1
        GROUP BY p.property_id, v.user_id, h.user_id
      `;
  
      const result = await pool.query(propertyQuery, [propertyId, investorId]);
  
      if (result.rows.length === 0) {
        return res.status(404).json({ message: 'Property not found' });
      }
  
      res.json(result.rows[0]);
    } catch (err) {
      console.error('Error fetching property details:', err);
      res.status(500).json({ error: 'Failed to fetch property details' });
    }
  };
  


exports.getServiceableCities = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT DISTINCT UNNEST(serviceable_cities) AS city    
      FROM users
      WHERE role = 'vendor'
    `);

    const cities = result.rows.map(row => row.city);

    res.status(200).json({ cities });
  } catch (err) {
    console.error('Error fetching serviceable cities:', err);
    res.status(500).json({ message: 'Failed to fetch serviceable cities' });
  }
};
