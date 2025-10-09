const express = require('express');
const router = express.Router();
const QuocGia = require('../models/quocgia');

// API lấy tất cả dữ liệu tham chiếu cho app
router.get('/all', async (req, res) => {
  try {
    // Lấy danh sách quốc gia
    QuocGia.getAll((err, quocGiaResults) => {
      if (err) {
        return res.status(500).json({ 
          success: false, 
          message: 'Lỗi khi lấy danh sách quốc gia', 
          error: err 
        });
      }

      // Tạo promise array để lấy tỉnh thành cho từng quốc gia
      const promises = quocGiaResults.map(quocGia => {
        return new Promise((resolve, reject) => {
          QuocGia.getTinhThanhByQuocGia(quocGia.MA_QG, (err, tinhThanhResults) => {
            if (err) {
              reject(err);
            } else {
              resolve({
                ...quocGia,
                tinh_thanh: tinhThanhResults
              });
            }
          });
        });
      });

      // Chờ tất cả promises hoàn thành
      Promise.all(promises)
        .then(results => {
          res.json({
            success: true,
            data: {
              quoc_gia: results,
              total_countries: results.length,
              total_provinces: results.reduce((sum, qg) => sum + qg.tinh_thanh.length, 0)
            }
          });
        })
        .catch(error => {
          res.status(500).json({ 
            success: false, 
            message: 'Lỗi khi lấy dữ liệu tỉnh thành', 
            error: error 
          });
        });
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Lỗi server', 
      error: error 
    });
  }
});

// API lấy danh sách quốc gia
router.get('/countries', (req, res) => {
  QuocGia.getAll((err, results) => {
    if (err) {
      return res.status(500).json({ 
        success: false, 
        message: 'Lỗi database', 
        error: err 
      });
    }
    
    res.json({
      success: true,
      data: results,
      total: results.length
    });
  });
});

// API lấy tỉnh thành theo quốc gia
router.get('/countries/:id/provinces', (req, res) => {
  const quocGiaId = req.params.id;
  
  QuocGia.getTinhThanhByQuocGia(quocGiaId, (err, results) => {
    if (err) {
      return res.status(500).json({ 
        success: false, 
        message: 'Lỗi database', 
        error: err 
      });
    }
    
    res.json({
      success: true,
      data: results,
      total: results.length,
      quoc_gia_id: quocGiaId
    });
  });
});

// API lấy thông tin quốc gia theo ID
router.get('/countries/:id', (req, res) => {
  QuocGia.getById(req.params.id, (err, results) => {
    if (err) {
      return res.status(500).json({ 
        success: false, 
        message: 'Lỗi database', 
        error: err 
      });
    }
    
    if (results.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Không tìm thấy quốc gia' 
      });
    }
    
    res.json({
      success: true,
      data: results[0]
    });
  });
});

// API tạo quốc gia mới (chỉ dành cho Admin)
router.post('/countries', (req, res) => {
  // TODO: Thêm middleware xác thực admin
  const { TEN_QG, HINHANH_QG } = req.body;
  
  if (!TEN_QG || !HINHANH_QG) {
    return res.status(400).json({ 
      success: false, 
      message: 'Vui lòng điền đầy đủ tên và hình ảnh' 
    });
  }
  
  QuocGia.create(req.body, (err, results) => {
    if (err) {
      return res.status(500).json({ 
        success: false, 
        message: 'Lỗi khi tạo quốc gia', 
        error: err 
      });
    }
    
    res.status(201).json({
      success: true,
      message: 'Tạo quốc gia thành công',
      data: { id: results.insertId }
    });
  });
});

// API cập nhật quốc gia
router.put('/countries/:id', (req, res) => {
  // TODO: Thêm middleware xác thực admin
  QuocGia.update(req.params.id, req.body, (err, results) => {
    if (err) {
      return res.status(500).json({ 
        success: false, 
        message: 'Lỗi khi cập nhật quốc gia', 
        error: err 
      });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Không tìm thấy quốc gia để cập nhật' 
      });
    }
    
    res.json({
      success: true,
      message: 'Cập nhật quốc gia thành công'
    });
  });
});

// API xóa quốc gia
router.delete('/countries/:id', (req, res) => {
  // TODO: Thêm middleware xác thực admin
  QuocGia.delete(req.params.id, (err, results) => {
    if (err) {
      return res.status(500).json({ 
        success: false, 
        message: 'Lỗi khi xóa quốc gia', 
        error: err 
      });
    }
    
    if (results.affectedRows === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Không tìm thấy quốc gia để xóa' 
      });
    }
    
    res.json({
      success: true,
      message: 'Xóa quốc gia thành công'
    });
  });
});

module.exports = router;