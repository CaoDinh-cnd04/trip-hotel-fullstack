// controllers/khachsanController.js - Hotel controller
const { check, validationResult } = require('express-validator');
const KhachSan = require('../models/khachsan');

// Get all hotels
exports.getAllHotels = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10, 
      search,
      vi_tri_id,
      so_sao_min,
      so_sao_max,
      gia_min,
      gia_max,
      available_from,
      available_to
    } = req.query;

    // Ensure page and limit are integers
    const pageInt = parseInt(page) || 1;
    const limitInt = parseInt(limit) || 10;

    let result;

    if (search || vi_tri_id || so_sao_min || so_sao_max || gia_min || gia_max) {
      // Search with filters
      result = await KhachSan.searchHotels(search, {
        page: pageInt,
        limit: limitInt,
        vi_tri_id,
        so_sao_min,
        so_sao_max,
        gia_min,
        gia_max
      });
    } else {
      // Get all active hotels
      result = await KhachSan.getActiveHotels({ page: pageInt, limit: limitInt });
    }

    res.json({
      success: true,
      message: 'Lấy danh sách khách sạn thành công',
      data: result.data,
      pagination: result.pagination
    });

  } catch (error) {
    console.error('Get hotels error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách khách sạn',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get hotel by ID
exports.getHotelById = async (req, res) => {
  try {
    const { id } = req.params;
    const { with_amenities, with_rooms, available_from, available_to } = req.query;

    const hotel = await KhachSan.getHotelWithDetails(id);

    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    // Get amenities if requested
    if (with_amenities === 'true') {
      hotel.tien_nghi = await KhachSan.getHotelAmenities(id);
    }

    // Get rooms if requested
    if (with_rooms === 'true') {
      hotel.phong = await KhachSan.getHotelRooms(id, {
        available_from,
        available_to
      });
    }

    res.json({
      success: true,
      message: 'Lấy thông tin khách sạn thành công',
      data: hotel
    });

  } catch (error) {
    console.error('Get hotel by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thông tin khách sạn'
    });
  }
};

// Get hotel rooms
exports.getHotelRooms = async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      page = 1, 
      limit = 20, 
      available_from, 
      available_to 
    } = req.query;

    // Check if hotel exists
    const hotel = await KhachSan.findById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    const rooms = await KhachSan.getHotelRooms(id, {
      page,
      limit,
      available_from,
      available_to
    });

    res.json({
      success: true,
      message: 'Lấy danh sách phòng thành công',
      data: rooms
    });

  } catch (error) {
    console.error('Get hotel rooms error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách phòng'
    });
  }
};

// Get hotel amenities
exports.getHotelAmenities = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if hotel exists
    const hotel = await KhachSan.findById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    const amenities = await KhachSan.getHotelAmenities(id);

    res.json({
      success: true,
      message: 'Lấy danh sách tiện nghi thành công',
      data: amenities
    });

  } catch (error) {
    console.error('Get hotel amenities error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách tiện nghi'
    });
  }
};

// Get hotel statistics
exports.getHotelStats = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if hotel exists
    const hotel = await KhachSan.findById(id);
    if (!hotel) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    const stats = await KhachSan.getHotelStats(id);

    res.json({
      success: true,
      message: 'Lấy thống kê khách sạn thành công',
      data: stats
    });

  } catch (error) {
    console.error('Get hotel stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thống kê khách sạn'
    });
  }
};

// Create new hotel
exports.createHotel = [
  // Validation rules
  check('ten')
    .notEmpty()
    .withMessage('Tên khách sạn không được để trống')
    .isLength({ min: 2, max: 100 })
    .withMessage('Tên khách sạn phải từ 2-100 ký tự'),
  
  check('mo_ta')
    .notEmpty()
    .withMessage('Mô tả không được để trống'),
  
  check('hinh_anh')
    .notEmpty()
    .withMessage('Hình ảnh không được để trống'),
  
  check('so_sao')
    .isInt({ min: 1, max: 5 })
    .withMessage('Số sao phải từ 1-5'),
  
  check('dia_chi')
    .notEmpty()
    .withMessage('Địa chỉ không được để trống'),
  
  check('vi_tri_id')
    .isInt({ min: 1 })
    .withMessage('Vị trí không hợp lệ'),
  
  check('ti_le_coc')
    .optional()
    .isFloat({ min: 0, max: 100 })
    .withMessage('Tỷ lệ cọc phải từ 0-100%'),

  async (req, res) => {
    try {
      // Check validation errors
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Dữ liệu không hợp lệ',
          errors: errors.array()
        });
      }

      const hotel = await KhachSan.createHotel(req.body);

      res.status(201).json({
        success: true,
        message: 'Tạo khách sạn thành công',
        data: hotel
      });

    } catch (error) {
      console.error('Create hotel error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi tạo khách sạn'
      });
    }
  }
];

// Update hotel
exports.updateHotel = [
  // Validation rules
  check('ten')
    .optional()
    .isLength({ min: 2, max: 100 })
    .withMessage('Tên khách sạn phải từ 2-100 ký tự'),
  
  check('so_sao')
    .optional()
    .isInt({ min: 1, max: 5 })
    .withMessage('Số sao phải từ 1-5'),
  
  check('ti_le_coc')
    .optional()
    .isFloat({ min: 0, max: 100 })
    .withMessage('Tỷ lệ cọc phải từ 0-100%'),

  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Dữ liệu không hợp lệ',
          errors: errors.array()
        });
      }

      const { id } = req.params;
      const hotel = await KhachSan.updateHotel(id, req.body);

      if (!hotel) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy khách sạn'
        });
      }

      res.json({
        success: true,
        message: 'Cập nhật khách sạn thành công',
        data: hotel
      });

    } catch (error) {
      console.error('Update hotel error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi cập nhật khách sạn'
      });
    }
  }
];

// Delete hotel (soft delete)
exports.deleteHotel = async (req, res) => {
  try {
    const { id } = req.params;

    const success = await KhachSan.update(id, { trang_thai: 'Ngừng hoạt động' });

    if (!success) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy khách sạn'
      });
    }

    res.json({
      success: true,
      message: 'Xóa khách sạn thành công'
    });

  } catch (error) {
    console.error('Delete hotel error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa khách sạn'
    });
  }
};

// Get hotels by manager (for hotel managers)
exports.getMyHotels = async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const managerId = req.user.id;

    const result = await KhachSan.getHotelsByManager(managerId, { page, limit });

    res.json({
      success: true,
      message: 'Lấy danh sách khách sạn của tôi thành công',
      data: result.data,
      pagination: result.pagination
    });

  } catch (error) {
    console.error('Get my hotels error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách khách sạn'
    });
  }
};

module.exports = exports;