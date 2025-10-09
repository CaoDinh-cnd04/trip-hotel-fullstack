const Phong = require('../models/phong');
const { validationResult } = require('express-validator');

const phongController = {
    // Lấy tất cả phòng
    async getAllPhong(req, res) {
        try {
            const { ma_khach_san, ma_loai_phong, keyword, page = 1, limit = 10 } = req.query;
            
            const phong = new Phong();
            let results;

            if (keyword) {
                results = await phong.searchPhong(keyword, ma_khach_san, ma_loai_phong);
            } else if (ma_khach_san) {
                results = await phong.getPhongByKhachSan(ma_khach_san);
            } else {
                results = await phong.findAll({
                    trang_thai: 1
                }, parseInt(page), parseInt(limit));
            }

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách phòng thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllPhong:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách phòng',
                error: error.message
            });
        }
    },

    // Lấy phòng theo ID với chi tiết
    async getPhongById(req, res) {
        try {
            const { id } = req.params;
            const phong = new Phong();
            
            const result = await phong.getPhongWithDetails(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy phòng'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin phòng thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getPhongById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin phòng',
                error: error.message
            });
        }
    },

    // Lấy phòng trống
    async getAvailableRooms(req, res) {
        try {
            const { ma_khach_san, ngay_checkin, ngay_checkout, ma_loai_phong } = req.query;
            
            if (!ma_khach_san || !ngay_checkin || !ngay_checkout) {
                return res.status(400).json({
                    success: false,
                    message: 'Mã khách sạn, ngày checkin và checkout là bắt buộc'
                });
            }

            const phong = new Phong();
            const results = await phong.getAvailableRooms(ma_khach_san, ngay_checkin, ngay_checkout, ma_loai_phong);

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách phòng trống thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAvailableRooms:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy phòng trống',
                error: error.message
            });
        }
    },

    // Kiểm tra phòng có sẵn
    async checkRoomAvailability(req, res) {
        try {
            const { ma_phong } = req.params;
            const { ngay_checkin, ngay_checkout } = req.query;
            
            if (!ngay_checkin || !ngay_checkout) {
                return res.status(400).json({
                    success: false,
                    message: 'Ngày checkin và checkout là bắt buộc'
                });
            }

            const phong = new Phong();
            const isAvailable = await phong.isRoomAvailable(ma_phong, ngay_checkin, ngay_checkout);

            res.status(200).json({
                success: true,
                message: 'Kiểm tra tình trạng phòng thành công',
                data: {
                    ma_phong,
                    available: isAvailable,
                    ngay_checkin,
                    ngay_checkout
                }
            });
        } catch (error) {
            console.error('Error in checkRoomAvailability:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi kiểm tra tình trạng phòng',
                error: error.message
            });
        }
    },

    // Lấy lịch đặt phòng
    async getRoomSchedule(req, res) {
        try {
            const { ma_phong } = req.params;
            const { tu_ngay, den_ngay } = req.query;
            
            if (!tu_ngay || !den_ngay) {
                return res.status(400).json({
                    success: false,
                    message: 'Từ ngày và đến ngày là bắt buộc'
                });
            }

            const phong = new Phong();
            const results = await phong.getRoomBookingSchedule(ma_phong, tu_ngay, den_ngay);

            res.status(200).json({
                success: true,
                message: 'Lấy lịch đặt phòng thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getRoomSchedule:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy lịch đặt phòng',
                error: error.message
            });
        }
    },

    // Tạo phòng mới
    async createPhong(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const phong = new Phong();
            const newPhong = await phong.create(req.body);

            res.status(201).json({
                success: true,
                message: 'Tạo phòng thành công',
                data: newPhong
            });
        } catch (error) {
            console.error('Error in createPhong:', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi server khi tạo phòng',
                error: error.message
            });
        }
    },

    // Cập nhật phòng
    async updatePhong(req, res) {
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
            const phong = new Phong();
            
            const updated = await phong.update(id, req.body);
            
            if (!updated) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy phòng để cập nhật'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Cập nhật phòng thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updatePhong:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật phòng',
                error: error.message
            });
        }
    },

    // Xóa phòng
    async deletePhong(req, res) {
        try {
            const { id } = req.params;
            const phong = new Phong();
            
            const deleted = await phong.update(id, { trang_thai: 0 });
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy phòng để xóa'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Xóa phòng thành công'
            });
        } catch (error) {
            console.error('Error in deletePhong:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa phòng',
                error: error.message
            });
        }
    }
};

module.exports = phongController;