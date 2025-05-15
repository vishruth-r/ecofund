const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const propertyRoutes = require('./routes/propertyRoutes'); 
const investmentRoutes = require('./routes/investmentRoutes');
const paymentRoutes = require('./routes/paymentRoutes');

const app = express();
app.use(morgan('combined')); 

app.use(cors());
app.use(express.json());

app.use('/api/users', authRoutes);
app.use('/api/properties', propertyRoutes);
app.use('/api/investments', investmentRoutes);
app.use('/api/payments',paymentRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
