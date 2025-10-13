const PhieuDatPhong = require('../models/phieudatphg');
const Phong = require('../models/phong');
const { validationResult } = require('express-validator');
const nodemailer = require('nodemailer');

const phieudatphgController = {
    // Lấy tất cả phiếu đặt phòng (Admin only)
    async getAllPhieuDatPhg(req, res) {
        try {
            const { ma_khach_san, trang_thai, tu_ngay, den_ngay, page = 1, limit = 10 } = req.query;
            
            const phieuDatPhong = new PhieuDatPhong();
            let results;

            if (ma_khach_san) {
                results = await phieuDatPhong.getBookingsByHotel(ma_khach_san, trang_thai, tu_ngay, den_ngay);
            } else {
                results = await phieuDatPhong.findAll({}, parseInt(page), parseInt(limit));
            }

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách phiếu đặt phòng thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getAllPhieuDatPhg:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách phiếu đặt phòng',
                error: error.message
            });
        }
    },

    // Lấy phiếu đặt phòng theo ID
    async getPhieuDatPhgById(req, res) {
        try {
            const { id } = req.params;
            const phieuDatPhong = new PhieuDatPhong();
            
            const result = await phieuDatPhong.getBookingDetails(id);
            
            if (!result) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy phiếu đặt phòng'
                });
            }

            // Kiểm tra quyền truy cập
            const userRole = req.user?.vai_tro?.toLowerCase();
            const userId = req.user?.ma_nguoi_dung;
            
            if (userRole !== 'admin' && userId !== result.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền xem phiếu đặt phòng này'
                });
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin phiếu đặt phòng thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getPhieuDatPhgById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin phiếu đặt phòng',
                error: error.message
            });
        }
    },

    // Lấy phiếu đặt phòng của user hiện tại
    async getMyBookings(req, res) {
        try {
            const { trang_thai } = req.query;
            const userId = req.user.ma_nguoi_dung;
            
            const phieuDatPhong = new PhieuDatPhong();
            const results = await phieuDatPhong.getBookingsByUser(userId, trang_thai);

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách đặt phòng thành công',
                data: results
            });
        } catch (error) {
            console.error('Error in getMyBookings:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách đặt phòng',
                error: error.message
            });
        }
    },

    // Tạo phiếu đặt phòng mới
    async createPhieuDatPhg(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const bookingData = {
                ...req.body,
                ma_nguoi_dung: req.user.ma_nguoi_dung
            };

            // Kiểm tra xung đột đặt phòng
            const phieuDatPhong = new PhieuDatPhong();
            const hasConflict = await phieuDatPhong.checkBookingConflict(
                bookingData.ma_phong, 
                bookingData.ngay_checkin, 
                bookingData.ngay_checkout
            );

            if (hasConflict) {
                return res.status(400).json({
                    success: false,
                    message: 'Phòng đã được đặt trong khoảng thời gian này'
                });
            }

            const newBooking = await phieuDatPhong.createBooking(bookingData);

            // Gửi email thông báo (không chặn response nếu lỗi email)
            (async () => {
                try {
                    if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS) {
                        const transporter = nodemailer.createTransport({
                            host: process.env.SMTP_HOST,
                            port: parseInt(process.env.SMTP_PORT || '587'),
                            secure: process.env.SMTP_SECURE === 'true',
                            auth: {
                                user: process.env.SMTP_USER,
                                pass: process.env.SMTP_PASS
                            }
                        });

                        const toEmail = req.user?.email || bookingData.email; // fallback nếu gửi từ body
                        if (toEmail) {
                            await transporter.sendMail({
                                from: process.env.SMTP_FROM || 'no-reply@trip-hotel.local',
                                to: toEmail,
                                subject: 'Xác nhận đặt phòng thành công',
                                html: `
                                    <h2>Đặt phòng thành công</h2>
                                    <p>Mã phiếu: <b>${newBooking.ma_phieu_dat_phong || newBooking.id}</b></p>
                                    <p>Phòng: ${bookingData.ma_phong}</p>
                                    <p>Nhận phòng: ${bookingData.ngay_checkin}</p>
                                    <p>Trả phòng: ${bookingData.ngay_checkout}</p>
                                    <p>Số khách: ${bookingData.so_khach}</p>
                                    <p>Tổng tiền: ${bookingData.tong_tien}</p>
                                    <hr/>
                                    <p>Cảm ơn bạn đã đặt phòng tại Trip Hotel.</p>
                                `
                            });
                        }
                    }
                } catch (mailErr) {
                    console.error('Email booking notification error:', mailErr);
                }
            })();

            res.status(201).json({
                success: true,
                message: 'Đặt phòng thành công',
                data: newBooking
            });
        } catch (error) {
            console.error('Error in createPhieuDatPhg:', error);
            res.status(500).json({
                success: false,
                message: error.message || 'Lỗi server khi đặt phòng',
                error: error.message
            });
        }
    },

    // Cập nhật trạng thái phiếu đặt phòng
    async updateBookingStatus(req, res) {
        try {
            const { id } = req.params;
            const { trang_thai, ghi_chu } = req.body;

            if (!trang_thai) {
                return res.status(400).json({
                    success: false,
                    message: 'Trạng thái là bắt buộc'
                });
            }

            const phieuDatPhong = new PhieuDatPhong();
            
            // Kiểm tra phiếu đặt phòng tồn tại
            const booking = await phieuDatPhong.findById(id);
            if (!booking) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy phiếu đặt phòng'
                });
            }

            // Kiểm tra quyền
            const userRole = req.user?.vai_tro?.toLowerCase();
            const userId = req.user?.ma_nguoi_dung;
            
            if (userRole !== 'admin' && userId !== booking.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền cập nhật phiếu đặt phòng này'
                });
            }

            const updated = await phieuDatPhong.updateBookingStatus(id, trang_thai, ghi_chu);

            res.status(200).json({
                success: true,
                message: 'Cập nhật trạng thái thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updateBookingStatus:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật trạng thái',
                error: error.message
            });
        }
    },

    // Cập nhật phiếu đặt phòng
    async updatePhieuDatPhg(req, res) {
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
            const phieuDatPhong = new PhieuDatPhong();
            
            // Kiểm tra phiếu đặt phòng tồn tại
            const booking = await phieuDatPhong.findById(id);
            if (!booking) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy phiếu đặt phòng'
                });
            }

            // Kiểm tra quyền
            const userRole = req.user?.vai_tro?.toLowerCase();
            const userId = req.user?.ma_nguoi_dung;
            
            if (userRole !== 'admin' && userId !== booking.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền cập nhật phiếu đặt phòng này'
                });
            }

            const updated = await phieuDatPhong.update(id, req.body);

            res.status(200).json({
                success: true,
                message: 'Cập nhật phiếu đặt phòng thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in updatePhieuDatPhg:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi cập nhật phiếu đặt phòng',
                error: error.message
            });
        }
    },

    // Hủy phiếu đặt phòng
    async cancelBooking(req, res) {
        try {
            const { id } = req.params;
            const { ly_do_huy } = req.body;

            const phieuDatPhong = new PhieuDatPhong();
            
            // Kiểm tra phiếu đặt phòng tồn tại
            const booking = await phieuDatPhong.findById(id);
            if (!booking) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy phiếu đặt phòng'
                });
            }

            // Kiểm tra quyền
            const userRole = req.user?.vai_tro?.toLowerCase();
            const userId = req.user?.ma_nguoi_dung;
            
            if (userRole !== 'admin' && userId !== booking.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền hủy phiếu đặt phòng này'
                });
            }

            // Kiểm tra trạng thái có thể hủy
            if (!['pending', 'confirmed'].includes(booking.trang_thai)) {
                return res.status(400).json({
                    success: false,
                    message: 'Không thể hủy phiếu đặt phòng ở trạng thái này'
                });
            }

            const updated = await phieuDatPhong.updateBookingStatus(id, 'cancelled', ly_do_huy);

            res.status(200).json({
                success: true,
                message: 'Hủy đặt phòng thành công',
                data: updated
            });
        } catch (error) {
            console.error('Error in cancelBooking:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi hủy đặt phòng',
                error: error.message
            });
        }
    },

    // Lấy thống kê đặt phòng
    async getBookingStats(req, res) {
        try {
            const { tu_ngay, den_ngay, ma_khach_san } = req.query;

            if (!tu_ngay || !den_ngay) {
                return res.status(400).json({
                    success: false,
                    message: 'Từ ngày và đến ngày là bắt buộc'
                });
            }

            const phieuDatPhong = new PhieuDatPhong();
            const stats = await phieuDatPhong.getBookingStats(tu_ngay, den_ngay, ma_khach_san);

            res.status(200).json({
                success: true,
                message: 'Lấy thống kê đặt phòng thành công',
                data: stats
            });
        } catch (error) {
            console.error('Error in getBookingStats:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thống kê',
                error: error.message
            });
        }
    }
};

module.exports = phieudatphgController;