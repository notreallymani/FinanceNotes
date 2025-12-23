const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const config = require('./config');
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const paymentRoutes = require('./routes/payment');
const aadharRoutes = require('./routes/aadhar');
const chatRoutes = require('./routes/chat');

const app = express();

// CORS Configuration - Allow all origins in development for mobile apps
if (config.env === 'development') {
  // Development: Allow all origins (mobile apps don't use CORS, but this helps with debugging)
  app.use(cors({ 
    origin: true,  // Allow all origins in development
    credentials: true 
  }));
} else if (config.clientOrigin) {
  // Production: Use specific origin
  app.use(cors({ origin: config.clientOrigin }));
} else {
  app.use(cors());
}

app.use(express.json());
app.use(morgan('dev'));

// Request logging middleware for debugging
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} from ${req.ip}`);
  next();
});

app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/aadhar', aadharRoutes);
app.use('/api/chat', chatRoutes);

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, env: config.env });
});

// 404 handler
app.use((req, res) => {
  console.log(`[404] Route not found: ${req.method} ${req.path}`);
  res.status(404).json({ message: 'Route not found', path: req.path });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(`[ERROR] ${req.method} ${req.path}:`, err);
  res.status(err.status || 500).json({
    message: err.message || 'Internal server error',
    error: config.env === 'development' ? err.stack : undefined
  });
});

module.exports = app;
