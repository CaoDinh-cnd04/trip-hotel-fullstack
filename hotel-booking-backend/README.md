# Hotel Booking Backend API

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Start production server
npm start
```

## 📁 Project Structure

```
hotel-booking-backend/
├── config/           # Database configuration
├── controllers/      # API route handlers
├── middleware/       # Authentication, CORS, upload middleware
├── models/          # Database models
├── routes/          # API route definitions
├── uploads/         # File uploads directory
├── server.js        # Main server file
└── package.json     # Dependencies and scripts
```

## 🔗 API Endpoints

### Base URLs
- **V2 API**: `http://localhost:5000/api/v2`
- **V1 API**: `http://localhost:5000/api` (backward compatibility)

### Main Endpoints
- `GET /api/health` - Health check
- `GET /api` - API documentation
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/khachsan` - Hotels list
- `GET /api/phong` - Rooms list
- `GET /api/khuyenmai` - Promotions
- `GET /api/magiamgia` - Discount codes

## 🛠️ Environment Variables

Create `.env` file:
```env
DB_SERVER=localhost
DB_PORT=1433
DB_DATABASE=khach_san
DB_USER=sa
DB_PASSWORD=123
JWT_SECRET=your_jwt_secret_key
```

## 📚 Documentation

- [Setup Guide](SETUP_GUIDE.md) - Detailed setup instructions
- [API Documentation](README_v2.md) - Complete API reference

## 🔧 Development

```bash
# Run with auto-reload
npm run dev

# Run tests
npm test

# Check database connection
node -e "require('./config/db').connect().then(() => console.log('✅ DB Connected')).catch(console.error)"
```
