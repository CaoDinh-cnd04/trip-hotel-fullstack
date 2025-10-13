// server_new.js - Updated server with new API structure
const express = require('express');
const dotenv = require('dotenv');
const cors = require('./middleware/cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
const { connect } = require('./config/db');

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();

// Middleware
app.use(helmet());
app.use(cors);
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api', apiLimiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/images', express.static(path.join(__dirname, 'images')));

// API Routes - Version 2 (New Structure)
app.use('/api/v2/auth', require('./routes/auth'));
app.use('/api/v2/quocgia', require('./routes/quocgia'));
app.use('/api/v2/khachsan', require('./routes/khachsan'));
app.use('/api/v2/tinhthanh', require('./routes/tinhthanh'));
app.use('/api/v2/vitri', require('./routes/vitri'));
app.use('/api/v2/loaiphong', require('./routes/loaiphong'));
app.use('/api/v2/phong', require('./routes/phong'));
app.use('/api/v2/phieudatphong', require('./routes/phieudatphg'));
app.use('/api/v2/nguoidung', require('./routes/nguoidung_v2'));
app.use('/api/v2/tiennghi', require('./routes/tiennghi'));
app.use('/api/v2/khuyenmai', require('./routes/khuyenmai_v2'));
app.use('/api/v2/magiamgia', require('./routes/magiamgia_v2'));
app.use('/api/v2/danhgia', require('./routes/danhgia_v2'));
app.use('/api/v2/tinnhan', require('./routes/tinnhan_v2'));
app.use('/api/v2/hoso', require('./routes/hoso_v2'));
app.use('/api/v2/vnpay', require('./routes/vnpay'));

// Legacy API Routes - Version 1 (Keep for backward compatibility) - TEMPORARY DISABLED
// app.use('/api/nguoidung', require('./routes/nguoidung'));
// app.use('/api/quocgia', require('./routes/quocgia'));
// app.use('/api/tinhthanh', require('./routes/tinhthanh'));
// app.use('/api/vitri', require('./routes/vitri'));
// app.use('/api/loaiphong', require('./routes/loaiphong'));
// app.use('/api/hoso', require('./routes/hoso'));
// app.use('/api/khachsan', require('./routes/khachsan'));
// app.use('/api/tiennghi', require('./routes/tiennghi'));
// app.use('/api/khuyenmai', require('./routes/khuyenmai'));
// app.use('/api/magiamgia', require('./routes/magiamgia'));
// app.use('/api/phong', require('./routes/phong'));
// app.use('/api/phieudatphg', require('./routes/phieudatphg'));
// app.use('/api/danhgia', require('./routes/danhgia'));
// app.use('/api/tinnhan', require('./routes/tinnhan'));
// app.use('/api/auth', require('./routes/auth'));
// app.use('/api/vnpay', require('./routes/vnpay'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    version: '2.0.0'
  });
});

// API documentation endpoint
app.get('/api', (req, res) => {
  res.json({
    message: 'Hotel Booking API',
    version: '2.0.0',
    endpoints: {
      v2: {
        auth: '/api/v2/auth',
        countries: '/api/v2/quocgia',
        hotels: '/api/v2/khachsan',
        provinces: '/api/v2/tinhthanh',
        locations: '/api/v2/vitri',
        roomTypes: '/api/v2/loaiphong',
        rooms: '/api/v2/phong',
        bookings: '/api/v2/phieudatphong',
        users: '/api/v2/nguoidung',
        amenities: '/api/v2/tiennghi',
        promotions: '/api/v2/khuyenmai',
        vouchers: '/api/v2/magiamgia',
        reviews: '/api/v2/danhgia',
        messages: '/api/v2/tinnhan',
        profiles: '/api/v2/hoso',
        payment: '/api/v2/vnpay'
      },
      v1: {
        users: '/api/nguoidung',
        countries: '/api/quocgia',
        provinces: '/api/tinhthanh',
        locations: '/api/vitri',
        roomTypes: '/api/loaiphong',
        profiles: '/api/hoso',
        hotels: '/api/khachsan',
        amenities: '/api/tiennghi',
        promotions: '/api/khuyenmai',
        vouchers: '/api/magiamgia',
        rooms: '/api/phong',
        bookings: '/api/phieudatphg',
        reviews: '/api/danhgia',
        messages: '/api/tinnhan',
        auth: '/api/auth',
        payment: '/api/vnpay'
      }
    },
    documentation: 'https://documenter.getpostman.com/view/hotel-booking-api',
    features: [
      'User authentication & authorization',
      'Hotel management',
      'Room booking system',
      'Payment integration (VNPay)',
      'Review system',
      'Real-time messaging',
      'File upload support',
      'Advanced search & filtering'
    ]
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint không tồn tại',
    availableEndpoints: '/api'
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  
  res.status(error.status || 500).json({
    success: false,
    message: error.message || 'Lỗi server không xác định',
    error: process.env.NODE_ENV === 'development' ? {
      stack: error.stack,
      details: error
    } : undefined
  });
});

// Start the server
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Initialize database connection
    await connect();
    console.log('✅ Database connected successfully!');
    
    // Start the Express server
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📍 API V2 available at: http://localhost:${PORT}/api/v2`);
      console.log(`📍 API V1 available at: http://localhost:${PORT}/api`);
      console.log(`📋 API Documentation: http://localhost:${PORT}/api`);
      console.log(`❤️  Health Check: http://localhost:${PORT}/api/health`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');
  const { close } = require('./config/db');
  await close();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully...');
  const { close } = require('./config/db');
  await close();
  process.exit(0);
});

startServer();