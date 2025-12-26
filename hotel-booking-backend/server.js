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

// Smart room image fallback: try rooms/, then hotels/, then default
app.get('/images/rooms/:file', (req, res, next) => {
  try {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    
    const file = req.params.file;
    const rootImages = path.join(__dirname, '..', 'images');
    const roomsPath = path.join(rootImages, 'rooms', file);
    const hotelsPath = path.join(rootImages, 'hotels', file);
    const defaultPath = path.join(rootImages, 'Defaut.jpg');

    const fs = require('fs');
    if (fs.existsSync(roomsPath)) {
      return res.sendFile(roomsPath);
    }
    if (fs.existsSync(hotelsPath)) {
      return res.sendFile(hotelsPath);
    }
    if (fs.existsSync(defaultPath)) {
      return res.sendFile(defaultPath);
    }
    return res.status(404).json({ success: false, message: 'Image not found' });
  } catch (e) {
    return next(e);
  }
});

// Serve images from parent directory (root project) with CORS headers
app.use('/images', (req, res, next) => {
  // Set CORS headers for images - MUST be set before sending file
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  
  // Handle OPTIONS preflight
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  
  next();
}, express.static(path.join(__dirname, '..', 'images'), {
  setHeaders: (res, path) => {
    // Also set CORS headers in static file handler
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  }
}));

// Public API Routes - Không cần authentication
app.use('/api/public', require('./routes/public'));
app.use('/api/promotion-offers', require('./routes/promotionOffers'));
app.use('/api/v2/inventory', require('./routes/roomInventory'));

// API Routes - Version 2 (New Structure)
app.use('/api/v2/auth', require('./routes/auth'));
app.use('/api/v2/otp', require('./routes/otp'));
app.use('/api/v2/quocgia', require('./routes/quocgia'));
app.use('/api/v2/khachsan', require('./routes/khachsan'));
app.use('/api/v2/tinhthanh', require('./routes/tinhthanh'));
app.use('/api/v2/vitri', require('./routes/vitri'));
app.use('/api/v2/loaiphong', require('./routes/loaiphong'));
app.use('/api/v2/phong', require('./routes/phong'));
app.use('/api/v2/phieudatphong', require('./routes/phieudatphg'));
app.use('/api/v2/nguoidung', require('./routes/nguoidung_v2'));
app.use('/api/v2/tiennghi', require('./routes/tiennghi'));

// Admin API Routes
app.use('/api/v2/admin', require('./routes/admin'));
app.use('/api/admin/roles', require('./routes/adminRole')); // Admin role management
app.use('/api/v2/feedback', require('./routes/feedback')); // Feedback management
app.use('/api/notifications', require('./routes/notifications')); // Notification system
app.use('/api/chat-sync', require('./routes/chatSync')); // Chat history sync (Firestore → SQL Server)
app.use('/api/room-status', require('./routes/roomStatus')); // Room status auto-update

// Hotel Manager API Routes
app.use('/api/v2/hotel-manager', require('./routes/hotelManager'));

// User API Routes
app.use('/api/user', require('./routes/user'));
app.use('/api/user', require('./routes/userProfile')); // User profile & VIP status routes

// Hotel Owner API Routes
app.use('/api/hotel-owner', require('./routes/hotelOwner'));
app.use('/api/v2/khuyenmai', require('./routes/khuyenmai_v2'));
app.use('/api/v2/magiamgia', require('./routes/magiamgia_v2'));
app.use('/api/v2/discount', require('./routes/discount')); // Discount validation API
app.use('/api/v2/danhgia', require('./routes/danhgia_v2'));
app.use('/api/v2/tinnhan', require('./routes/tinnhan_v2'));
app.use('/api/v2/hoso', require('./routes/hoso_v2'));

// ==================== PAYMENT ROUTES ====================
// Common payment routes (for all payment methods)
app.use('/api/v2/payment', require('./routes/payment'));
// VNPay routes
app.use('/api/v2/vnpay', require('./routes/vnpay'));
// Bank Transfer routes (mock/test)
app.use('/api/v2/bank-transfer', require('./routes/bankTransfer'));
app.use('/api/bank-transfer', require('./routes/bankTransfer'));

// VNPay callback routes (public endpoints)
// These routes need to be at root level to match VNPay's callback URLs
const vnpayController = require('./controllers/vnpayController');

// Return URL callback (sau khi thanh toán)
app.get('/api/payment/vnpay-return', vnpayController.vnpayReturn);
// IPN endpoint (server-to-server callback from VNPay)
app.post('/api/payment/vnpay-ipn', vnpayController.vnpayIPN);
app.get('/api/payment/vnpay-ipn', vnpayController.vnpayIPN);
app.use('/api/bookings', require('./routes/bookings')); // Booking management
app.use('/api/v2/hotel-registration', require('./routes/hotelRegistration'));

// Legacy API Routes - Version 1 (Keep for backward compatibility)
app.use('/api/nguoidung', require('./routes/nguoidung_v2'));
app.use('/api/quocgia', require('./routes/quocgia'));
app.use('/api/tinhthanh', require('./routes/tinhthanh'));
app.use('/api/vitri', require('./routes/vitri'));
app.use('/api/loaiphong', require('./routes/loaiphong'));
app.use('/api/hoso', require('./routes/hoso_v2'));
app.use('/api/khachsan', require('./routes/khachsan'));
app.use('/api/hotels', require('./routes/roomAvailability')); // Room availability status
app.use('/api/chat', require('./routes/chatNotification')); // Chat email notifications
app.use('/api/tiennghi', require('./routes/tiennghi'));
app.use('/api/khuyenmai', require('./routes/khuyenmai_v2'));
app.use('/api/magiamgia', require('./routes/magiamgia_v2'));
app.use('/api/phong', require('./routes/phong'));
app.use('/api/phieudatphg', require('./routes/phieudatphg'));
app.use('/api/danhgia', require('./routes/danhgia_v2'));
app.use('/api/tinnhan', require('./routes/tinnhan_v2'));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/vnpay', require('./routes/vnpay'));

// Test images endpoint
app.get('/api/test/images', (req, res) => {
  const fs = require('fs');
  const imagesPath = path.join(__dirname, '..', 'images');
  
  // Check if images directory exists
  if (!fs.existsSync(imagesPath)) {
    return res.json({
      success: false,
      message: 'Images directory not found',
      path: imagesPath
    });
  }
  
  // List some sample images
  const sampleImages = {
    hotels: fs.existsSync(path.join(imagesPath, 'hotels')) ? 
      fs.readdirSync(path.join(imagesPath, 'hotels')).slice(0, 5) : [],
    rooms: fs.existsSync(path.join(imagesPath, 'rooms')) ? 
      fs.readdirSync(path.join(imagesPath, 'rooms')).slice(0, 5) : [],
    locations: fs.existsSync(path.join(imagesPath, 'locations')) ? 
      fs.readdirSync(path.join(imagesPath, 'locations')).slice(0, 5) : []
  };
  
  res.json({
    success: true,
    message: 'Images directory found',
    path: imagesPath,
    sampleImages,
    testUrls: {
      hotel: 'http://localhost:5000/images/hotels/saigon_star.jpg',
      room: 'http://localhost:5000/images/rooms/hanoi_deluxe_1.jpg',
      location: 'http://localhost:5000/images/locations/hoankiem.jpg'
    }
  });
});

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

// Debug endpoint to check environment variables
app.get('/api/debug/env', (req, res) => {
  res.json({
    BASE_URL: process.env.BASE_URL || 'NOT SET',
    NODE_ENV: process.env.NODE_ENV || 'NOT SET',
    PORT: process.env.PORT || 'NOT SET',
    allEnvKeys: Object.keys(process.env).filter(key => 
      key.startsWith('BASE_') || key.startsWith('DB_') || key.startsWith('VNP_')
    )
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
    
    // Initialize Firebase Admin SDK
    const { initializeFirebaseAdmin } = require('./services/firebaseAdmin');
    initializeFirebaseAdmin();
    
    // Start room status scheduler
    const { startRoomStatusScheduler } = require('./services/roomStatusScheduler');
    startRoomStatusScheduler();
    
    // Auto-update booking status (confirmed → in_progress → completed)
    const { runAllBookingUpdates } = require('./services/bookingStatusScheduler');
    runAllBookingUpdates(); // Chạy ngay khi khởi động
    setInterval(runAllBookingUpdates, 5 * 60 * 1000); // Chạy mỗi 5 phút (tự động hoàn thành booking)
    console.log('✅ Booking status scheduler started (runs every 5 minutes)');
    
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