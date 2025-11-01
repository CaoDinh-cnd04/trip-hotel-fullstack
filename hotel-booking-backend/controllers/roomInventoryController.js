const RoomInventory = require('../models/room_inventory');

const roomInventoryController = {
    /**
     * Lấy availability của tất cả loại phòng trong khách sạn
     * GET /api/v2/khachsan/:ma_khach_san/availability
     */
    async getHotelAvailability(req, res) {
        try {
            const { ma_khach_san } = req.params;
            const { ngay_checkin, ngay_checkout } = req.query;

            if (!ngay_checkin || !ngay_checkout) {
                return res.status(400).json({
                    success: false,
                    message: 'Ngày checkin và checkout là bắt buộc'
                });
            }

            const roomInventory = new RoomInventory();
            const availability = await roomInventory.getHotelRoomAvailability(
                ma_khach_san,
                ngay_checkin,
                ngay_checkout
            );

            // Thêm message cảnh báo
            const warnings = [];
            availability.forEach(room => {
                if (room.is_sold_out) {
                    warnings.push(`${room.ten_loai_phong}: Đã hết phòng`);
                } else if (room.is_low_availability) {
                    warnings.push(`${room.ten_loai_phong}: Chỉ còn ${room.available_rooms} phòng!`);
                }
            });

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin phòng trống thành công',
                data: availability,
                warnings: warnings.length > 0 ? warnings : null
            });
        } catch (error) {
            console.error('Error in getHotelAvailability:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin phòng trống',
                error: error.message
            });
        }
    },

    /**
     * Lấy availability của một loại phòng cụ thể
     * GET /api/v2/khachsan/:ma_khach_san/loaiphong/:ma_loai_phong/availability
     */
    async getRoomTypeAvailability(req, res) {
        try {
            const { ma_khach_san, ma_loai_phong } = req.params;
            const { ngay_checkin, ngay_checkout } = req.query;

            if (!ngay_checkin || !ngay_checkout) {
                return res.status(400).json({
                    success: false,
                    message: 'Ngày checkin và checkout là bắt buộc'
                });
            }

            const roomInventory = new RoomInventory();
            const availability = await roomInventory.getRoomAvailability(
                ma_khach_san,
                ma_loai_phong,
                ngay_checkin,
                ngay_checkout
            );

            // Tạo message cảnh báo
            let warning = null;
            if (availability.available_rooms === 0) {
                warning = 'Đã hết phòng trong khoảng thời gian này';
            } else if (availability.available_rooms <= 2) {
                warning = `Chỉ còn ${availability.available_rooms} phòng cuối cùng!`;
            } else if (availability.available_rooms <= 5) {
                warning = `Còn ${availability.available_rooms} phòng`;
            }

            res.status(200).json({
                success: true,
                message: 'Lấy thông tin phòng trống thành công',
                data: {
                    ...availability,
                    is_low_availability: availability.available_rooms <= 2 && availability.available_rooms > 0,
                    is_sold_out: availability.available_rooms === 0,
                    warning
                }
            });
        } catch (error) {
            console.error('Error in getRoomTypeAvailability:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy thông tin phòng trống',
                error: error.message
            });
        }
    },

    /**
     * Đặt phòng với xử lý race condition
     * POST /api/v2/khachsan/book-room-safe
     */
    async bookRoomSafe(req, res) {
        try {
            const roomInventory = new RoomInventory();
            const result = await roomInventory.bookRoomWithLock(req.body);

            if (!result.success) {
                return res.status(400).json(result);
            }

            res.status(201).json(result);
        } catch (error) {
            console.error('Error in bookRoomSafe:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi đặt phòng',
                error: error.message
            });
        }
    },

    /**
     * Auto checkout - Dùng cho CRON job
     * POST /api/v2/system/auto-checkout
     */
    async autoCheckout(req, res) {
        try {
            const roomInventory = new RoomInventory();
            const count = await roomInventory.autoCheckoutExpiredBookings();

            res.status(200).json({
                success: true,
                message: `Đã tự động checkout ${count} phòng`,
                count
            });
        } catch (error) {
            console.error('Error in autoCheckout:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi khi tự động checkout',
                error: error.message
            });
        }
    },

    /**
     * Auto cancel pending - Dùng cho CRON job
     * POST /api/v2/system/auto-cancel-pending
     */
    async autoCancelPending(req, res) {
        try {
            const roomInventory = new RoomInventory();
            const count = await roomInventory.autoCancelExpiredPendingBookings();

            res.status(200).json({
                success: true,
                message: `Đã tự động hủy ${count} booking pending`,
                count
            });
        } catch (error) {
            console.error('Error in autoCancelPending:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi khi tự động hủy pending',
                error: error.message
            });
        }
    }
};

module.exports = roomInventoryController;

