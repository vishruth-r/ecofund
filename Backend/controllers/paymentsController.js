const pool = require('../models/db');
const { v4: uuidv4 } = require('uuid');

// Get all payments for a homeowner
exports.getHomeownerPayments = async (req, res) => {
  const homeownerId = req.user.user_id;

  try {
    const result = await pool.query(
      `SELECT * FROM payments
       WHERE homeowner_id = $1
       ORDER BY created_at DESC`,
      [homeownerId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching payments:', err);
    res.status(500).json({ error: 'Failed to fetch payments' });
  }
};

// Confirm payment & distribute investor payouts
exports.confirmPayment = async (req, res) => {
  const { payment_id } = req.body;

  try {
    // Get payment & property info
    const paymentRes = await pool.query(
      `SELECT * FROM payments WHERE payment_id = $1 AND status = 'due'`,
      [payment_id]
    );

    if (paymentRes.rows.length === 0) {
      return res.status(404).json({ error: 'Payment not found or already confirmed.' });
    }

    const payment = paymentRes.rows[0];

    // Fetch all investments for that property
    const investmentsRes = await pool.query(
      `SELECT investor_id, units_purchased FROM investments
       WHERE property_id = $1`,
      [payment.property_id]
    );

    const totalUnits = 1000;
    const payouts = investmentsRes.rows.map(inv => {
      const share = inv.units_purchased / totalUnits;
      const amount = share * payment.amount_due;

      return {
        payout_id: uuidv4(),
        payment_id: payment.payment_id,
        investor_id: inv.investor_id,
        amount
      };
    });

    // Insert payouts
    for (const payout of payouts) {
      await pool.query(
        `INSERT INTO investor_payouts (payout_id, payment_id, investor_id, amount)
         VALUES ($1, $2, $3, $4)`,
        [payout.payout_id, payout.payment_id, payout.investor_id, payout.amount]
      );
    }

    // Update payment status
    await pool.query(
      `UPDATE payments
       SET status = 'paid', confirmed_at = NOW()
       WHERE payment_id = $1`,
      [payment_id]
    );

    res.json({ message: 'Payment confirmed and investor payouts distributed.' });
  } catch (err) {
    console.error('Error confirming payment:', err);
    res.status(500).json({ error: 'Payment confirmation failed' });
  }
};

// Get investor payout history



exports.getInvestorPayouts = async (req, res) => {
    const investorId = req.user.user_id;
  
    try {
      const result = await pool.query(
        `SELECT ip.*, p.amount_due, pr.address, el.month
         FROM investor_payouts ip
         JOIN payments p ON ip.payment_id = p.payment_id
         JOIN energy_logs el ON p.log_id = el.log_id
         JOIN properties pr ON p.property_id = pr.property_id
         WHERE ip.investor_id = $1
         ORDER BY ip.created_at DESC`,
        [investorId]
      );
  
      res.json(result.rows);
    } catch (err) {
      console.error('Error fetching investor payouts:', err);
      res.status(500).json({ error: 'Failed to fetch payout history' });
    }
  };
  