const cors = require('cors');

const corsOptions = {
  origin: function (origin, callback) {
    // Cho phép tất cả origins để hỗ trợ mobile app và web
    // Trong production, bạn nên giới hạn origins cụ thể
    const allowedOrigins = [
      'http://localhost:3000',    // React app
      'http://localhost:8080',    // Vue app
      'http://127.0.0.1:3000',
      'http://127.0.0.1:8080',
      'http://192.168.1.1:3000',  // Local network access
      'http://10.0.0.1:3000',     // Local network access
      // Thêm IP addresses khác nếu cần cho mobile testing
    ];
    
    // Cho phép requests không có origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    // Cho phép tất cả origins cho development
    // Trong production, uncomment dòng dưới để kiểm tra
    // if (!allowedOrigins.includes(origin)) {
    //   return callback(new Error('Not allowed by CORS'));
    // }
    
    callback(null, true);
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type', 
    'Authorization', 
    'X-Requested-With',
    'Accept',
    'Origin'
  ],
  credentials: true, // Cho phép cookies và authentication headers
  optionsSuccessStatus: 200 // Support legacy browsers
};

module.exports = cors(corsOptions);