const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Tạo thư mục images/rooms nếu chưa tồn tại
const imagesDir = path.join(__dirname, '../../images');
const roomsDir = path.join(imagesDir, 'rooms');

if (!fs.existsSync(imagesDir)) {
  fs.mkdirSync(imagesDir, { recursive: true });
}
if (!fs.existsSync(roomsDir)) {
  fs.mkdirSync(roomsDir, { recursive: true });
}

// Cấu hình storage - lưu vào images/rooms
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, roomsDir);
  },
  filename: function (req, file, cb) {
    // Tạo tên file unique
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const baseName = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9]/g, '_');
    cb(null, `room_${baseName}_${uniqueSuffix}${ext}`);
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

// Cấu hình multer cho room images
const uploadRoomImages = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  },
  fileFilter: fileFilter
});

module.exports = uploadRoomImages;

