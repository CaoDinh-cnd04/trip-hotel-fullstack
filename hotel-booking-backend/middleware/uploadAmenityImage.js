const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Tạo thư mục images/amenities nếu chưa tồn tại
const amenitiesDir = path.join(__dirname, '../images/amenities');
if (!fs.existsSync(amenitiesDir)) {
  fs.mkdirSync(amenitiesDir, { recursive: true });
}

// Cấu hình storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, amenitiesDir);
  },
  filename: function (req, file, cb) {
    // Tạo tên file unique: amenity-{timestamp}-{random}.{ext}
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, 'amenity-' + uniqueSuffix + ext);
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
const uploadAmenityImage = multer({
  storage: storage,
  limits: {
    fileSize: 2 * 1024 * 1024 // 2MB (amenity icons are smaller)
  },
  fileFilter: fileFilter
});

module.exports = uploadAmenityImage;

