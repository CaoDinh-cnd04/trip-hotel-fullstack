const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ✅ Tạo thư mục images/hotels nếu chưa tồn tại
// Server serve từ ../images (root project từ server.js)
// Middleware ở hotel-booking-backend/middleware/, nên cần ../../images/hotels để đến baocao/images/hotels
const hotelsDir = path.join(__dirname, '../../images/hotels');
if (!fs.existsSync(hotelsDir)) {
  fs.mkdirSync(hotelsDir, { recursive: true });
  console.log('✅ Created directory:', hotelsDir);
}
console.log('📁 Hotels images directory:', hotelsDir);

// Cấu hình storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, hotelsDir);
  },
  filename: function (req, file, cb) {
    // Tạo tên file unique: hotel-{timestamp}-{random}.{ext}
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, 'hotel-' + uniqueSuffix + ext);
  }
});

// File filter để chỉ chấp nhận ảnh
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Chỉ chấp nhận file ảnh!'), false);
  }
};

// Cấu hình multer
const uploadHotelImage = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  },
  fileFilter: fileFilter
});

module.exports = uploadHotelImage;

