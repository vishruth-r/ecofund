const db = require('../config/db');
const pool = require('../models/db');
const { v4: uuidv4 } = require('uuid');

exports.getAvailableInvestments = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT 
        p.property_id,
        p.address,
        p.city,
        p.pincode,
        p.panel_size,
        p.quote_amount,
        p.created_at,
        COALESCE(SUM(i.units_purchased), 0) AS funded_units
      FROM properties p
      LEFT JOIN investments i ON p.property_id = i.property_id
      WHERE p.status IN ('quoted', 'funded')
      GROUP BY p.property_id, p.address, p.pincode, p.panel_size, p.quote_amount`
    );

    const properties = result.rows.map(p => {
      const unit_price = Number(p.quote_amount) / 1000;
      const funded_units = parseInt(p.funded_units, 10);
      const units_available = 1000 - funded_units;
      const status = funded_units === 1000 ? 'funded' : 'quoted';  // Update status
      
      return {
        property_id: p.property_id,
        address: p.address,
        pincode: p.pincode,
        city: p.city,
        panel_size: p.panel_size,
        created_at: p.created_at,
        quote_amount: Number(p.quote_amount),
        unit_price,
        funded_units,
        units_available,
        funded_amount: funded_units * unit_price,
        remaining_amount: units_available * unit_price,
        status, // Include status in the response
      };
    });

    res.json(properties);
  } catch (err) {
    console.error('Error fetching investments:', err);
    res.status(500).json({ error: 'Failed to fetch investments' });
  }
};

exports.submitInvestment = async (req, res) => {
    const investor_id = req.user.user_id;
    const { property_id, units_purchased } = req.body;
  
    try {
      // Fetch property quote to determine unit price
      const prop = await pool.query(`SELECT quote_amount, status FROM properties WHERE property_id = $1`, [property_id]);
  
      if (prop.rows.length === 0) return res.status(404).json({ error: 'Property not found' });
  
      const unit_price = parseFloat(prop.rows[0].quote_amount) / 1000;
      const propertyStatus = prop.rows[0].status;
  
      // Ensure the property is still in "quoted" status
      if (propertyStatus !== 'quoted') {
        return res.status(400).json({ error: 'Property is already funded or not available for investment.' });
      }
  
      const investment_id = uuidv4();
  
      // Insert investment
      await pool.query(
        `INSERT INTO investments (investment_id, investor_id, property_id, units_purchased, unit_price)
         VALUES ($1, $2, $3, $4, $5)`,
        [investment_id, investor_id, property_id, units_purchased, unit_price]
      );
  
      // Check if the property has reached 1000 funded units and update status if fully funded
      const fundedUnitsResult = await pool.query(
        `SELECT COALESCE(SUM(units_purchased), 0) AS funded_units
         FROM investments
         WHERE property_id = $1`,
        [property_id]
      );
  
      const funded_units = fundedUnitsResult.rows[0].funded_units;
  
      if (funded_units >= 1000) {
        // Update the property status to 'funded'
        await pool.query(
          `UPDATE properties SET status = 'funded' WHERE property_id = $1`,
          [property_id]
        );
      }
  
      res.status(201).json({ message: 'Investment successful' });
    } catch (err) {
      console.error('Error submitting investment:', err);
      res.status(500).json({ error: 'Investment failed' });
    }
};

exports.getMyInvestments = async (req, res) => {
  const investor_id = req.user.user_id;

  try {
    const result = await pool.query(
      `
      WITH investor_investments AS (
        SELECT 
          i.property_id,
          SUM(i.units_purchased) AS total_units_purchased,
          SUM(i.units_purchased * i.unit_price) AS total_amount_invested,
          MIN(i.created_at) AS first_investment_at
        FROM investments i
        WHERE i.investor_id = $1
        GROUP BY i.property_id
      ),
      payouts AS (
        SELECT 
          p.property_id,
          SUM(ip.amount) AS total_paid_out
        FROM investor_payouts ip
        JOIN payments p ON ip.payment_id = p.payment_id
        WHERE ip.investor_id = $1
        GROUP BY p.property_id
      ),
      logs AS (
        SELECT 
          el.property_id,
          json_agg(
            json_build_object(
              'log_id', el.log_id,
              'month', el.month,
              'units_produced', el.units_produced,
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
          ) AS energy_logs
        FROM energy_logs el
        LEFT JOIN payments pay ON pay.log_id = el.log_id
        GROUP BY el.property_id
      )

      SELECT 
        p.property_id,
        p.address,
        p.pincode,
        p.city,
        p.energy_consumption,
        p.panel_size,
        p.quote_amount,
        p.status AS status,
        p.created_at AS property_created_at,

        ii.total_units_purchased,
        ii.total_amount_invested,
        ii.first_investment_at,

        COALESCE(po.total_paid_out, 0) AS total_paid_out,
        COALESCE(lg.energy_logs, '[]') AS energy_logs

      FROM investor_investments ii
      JOIN properties p ON p.property_id = ii.property_id
      LEFT JOIN payouts po ON po.property_id = p.property_id
      LEFT JOIN logs lg ON lg.property_id = p.property_id
      ORDER BY p.created_at DESC
      `,
      [investor_id]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching investor investments:', err);
    res.status(500).json({ error: 'Failed to fetch your investments' });
  }
};
