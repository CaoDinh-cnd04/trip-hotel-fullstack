// controllers/quocgiaController.js - Country controller
const { check, validationResult } = require('express-validator');
const QuocGia = require('../models/quocgia');

// Get all countries
exports.getAllCountries = async (req, res) => {
  try {
    const { page = 1, limit = 10, search, with_stats } = req.query;
    
    let result;
    
    if (search) {
      result = await QuocGia.searchByName(search, { page, limit });
    } else if (with_stats === 'true') {
      const countries = await QuocGia.getCountriesWithStats();
      result = {
        data: countries,
        pagination: {
          page: 1,
          limit: countries.length,
          total: countries.length,
          totalPages: 1
        }
      };
    } else {
      result = await QuocGia.getActiveCountries({ page, limit });
    }

    res.json({
      success: true,
      message: 'Lấy danh sách quốc gia thành công',
      data: result.data,
      pagination: result.pagination
    });

  } catch (error) {
    console.error('Get countries error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách quốc gia',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get country by ID
exports.getCountryById = async (req, res) => {
  try {
    const { id } = req.params;
    const { with_provinces } = req.query;

    let country;
    
    if (with_provinces === 'true') {
      country = await QuocGia.getCountryWithProvinces(id);
    } else {
      country = await QuocGia.findById(id);
    }

    if (!country) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy quốc gia'
      });
    }

    res.json({
      success: true,
      message: 'Lấy thông tin quốc gia thành công',
      data: country
    });

  } catch (error) {
    console.error('Get country by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy thông tin quốc gia'
    });
  }
};

// Create new country
exports.createCountry = [
  // Validation rules
  check('ten')
    .notEmpty()
    .withMessage('Tên quốc gia không được để trống')
    .isLength({ min: 2, max: 100 })
    .withMessage('Tên quốc gia phải từ 2-100 ký tự'),
  
  check('hinh_anh')
    .notEmpty()
    .withMessage('Hình ảnh không được để trống'),
  
  check('mo_ta')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Mô tả không được quá 1000 ký tự'),

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

      const country = await QuocGia.createCountry(req.body);

      res.status(201).json({
        success: true,
        message: 'Tạo quốc gia thành công',
        data: country
      });

    } catch (error) {
      console.error('Create country error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi tạo quốc gia'
      });
    }
  }
];

// Update country
exports.updateCountry = [
  // Validation rules
  check('ten')
    .optional()
    .isLength({ min: 2, max: 100 })
    .withMessage('Tên quốc gia phải từ 2-100 ký tự'),
  
  check('mo_ta')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Mô tả không được quá 1000 ký tự'),

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
      const country = await QuocGia.updateCountry(id, req.body);

      if (!country) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy quốc gia'
        });
      }

      res.json({
        success: true,
        message: 'Cập nhật quốc gia thành công',
        data: country
      });

    } catch (error) {
      console.error('Update country error:', error);
      res.status(500).json({
        success: false,
        message: 'Lỗi server khi cập nhật quốc gia'
      });
    }
  }
];

// Delete country (soft delete)
exports.deleteCountry = async (req, res) => {
  try {
    const { id } = req.params;

    const success = await QuocGia.softDelete(id);

    if (!success) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy quốc gia'
      });
    }

    res.json({
      success: true,
      message: 'Xóa quốc gia thành công'
    });

  } catch (error) {
    console.error('Delete country error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi xóa quốc gia'
    });
  }
};

// Toggle country status
exports.toggleCountryStatus = async (req, res) => {
  try {
    const { id } = req.params;

    const country = await QuocGia.toggleStatus(id);

    if (!country) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy quốc gia'
      });
    }

    res.json({
      success: true,
      message: 'Cập nhật trạng thái quốc gia thành công',
      data: country
    });

  } catch (error) {
    console.error('Toggle country status error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật trạng thái quốc gia'
    });
  }
};

module.exports = exports;