const cors = require('cors');

const corsOptions = {
  origin: function (origin, callback) {
    const envOrigins = (process.env.CORS_ORIGINS || '').split(',').map(o => o.trim()).filter(Boolean);
    const defaultAllowed = [
      'http://localhost:3000',
      'http://localhost:8080',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:8080'
    ];
    const allowedOrigins = envOrigins.length ? envOrigins : defaultAllowed;

    if (!origin) return callback(null, true);

    if (process.env.NODE_ENV === 'production' && !allowedOrigins.includes(origin)) {
      return callback(new Error('Not allowed by CORS'));
    }

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