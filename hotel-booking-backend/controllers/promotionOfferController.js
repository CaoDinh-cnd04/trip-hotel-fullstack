const promotionOfferModel = require('../models/promotionOffer');

// Lấy ưu đãi đang hoạt động cho một khách sạn
const getActiveOffersForHotel = async (req, res) => {
  try {
    const { hotelId } = req.params;
    let offers = []; // Mặc định là mảng rỗng
    
    // Sử dụng giá gốc thật của khách sạn (từ màn hình chọn phòng)
    const roomPrices = [
      { loai_phong_id: 1, ten_loai_phong: 'Standard Room', gia_phong: 500000 }, // Giá gốc thật
      { loai_phong_id: 2, ten_loai_phong: 'Deluxe Room', gia_phong: 750000 }    // Giá gốc thật
    ];
    
    const mockOffers = [];
    
    // Tạo ưu đãi cho Standard Room (room_type_id = 1)
    const standardRoom = roomPrices.find(room => room.loai_phong_id === 1);
    if (standardRoom && standardRoom.gia_phong) {
      const originalPrice = standardRoom.gia_phong;
      const discountPercent = 40; // Giảm 40%
      const discountedPrice = Math.round(originalPrice * (1 - discountPercent / 100));
      
      mockOffers.push({
        id: '1',
        hotel_id: parseInt(hotelId),
        room_type_id: 1,
        title: 'Ưu đãi cuối ngày - Standard Room',
        description: `Giảm giá ${discountPercent}% cho phòng Standard trong 2 giờ tới`,
        original_price: originalPrice,
        discounted_price: discountedPrice,
        total_rooms: 3,
        available_rooms: 2,
        start_time: new Date().toISOString(),
        end_time: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(), // 2 giờ
        conditions: ['Không hủy', 'Không hoàn tiền', 'Áp dụng trong ngày'],
        is_active: 1,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });
    }
    
    // Tạo ưu đãi cho Deluxe Room (room_type_id = 2)
    const deluxeRoom = roomPrices.find(room => room.loai_phong_id === 2);
    if (deluxeRoom && deluxeRoom.gia_phong) {
      const originalPrice = deluxeRoom.gia_phong;
      const discountPercent = 35; // Giảm 35%
      const discountedPrice = Math.round(originalPrice * (1 - discountPercent / 100));
      
      mockOffers.push({
        id: '2',
        hotel_id: parseInt(hotelId),
        room_type_id: 2,
        title: 'Ưu đãi cuối ngày - Deluxe Room',
        description: `Giảm giá ${discountPercent}% cho phòng Deluxe trong 1.5 giờ tới`,
        original_price: originalPrice,
        discounted_price: discountedPrice,
        total_rooms: 2,
        available_rooms: 1,
        start_time: new Date().toISOString(),
        end_time: new Date(Date.now() + 1.5 * 60 * 60 * 1000).toISOString(), // 1.5 giờ
        conditions: ['Không hủy', 'Không hoàn tiền', 'Áp dụng trong ngày'],
        is_active: 1,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });
    }
    
    return res.json({
      success: true,
      data: mockOffers,
      message: 'Lấy danh sách ưu đãi thành công (dữ liệu mẫu)'
    });
  } catch (error) {
    console.error('Error getting active offers:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách ưu đãi'
    });
  }
};

// Lấy ưu đãi cho một loại phòng cụ thể
const getOfferForRoom = async (req, res) => {
  try {
    const { hotelId, roomTypeId } = req.params;
    const offer = await promotionOfferModel.getOfferForRoom(hotelId, roomTypeId);
    
    if (offer) {
      res.json({
        success: true,
        data: offer,
        message: 'Lấy ưu đãi thành công'
      });
    } else {
      res.json({
        success: true,
        data: null,
        message: 'Không có ưu đãi cho phòng này'
      });
    }
  } catch (error) {
    console.error('Error getting offer for room:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy ưu đãi'
    });
  }
};

// Đặt phòng với ưu đãi
const bookWithOffer = async (req, res) => {
  try {
    const userId = req.user.ma_nguoi_dung;
    const { offerId, check_in_date, check_out_date, adults, children } = req.body;
    
    const bookingData = {
      check_in_date,
      check_out_date,
      adults,
      children
    };
    
    const result = await promotionOfferModel.bookWithOffer(offerId, userId, bookingData);
    
    res.json({
      success: true,
      data: {
        booking_id: result.booking.id,
        offer: result.offer,
        total_amount: result.booking.tong_tien,
        savings: result.offer.original_price - result.offer.discounted_price
      },
      message: 'Đặt phòng thành công với ưu đãi'
    });
  } catch (error) {
    console.error('Error booking with offer:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Lỗi khi đặt phòng với ưu đãi'
    });
  }
};

// Tạo ưu đãi mới (cho hotel owner)
const createOffer = async (req, res) => {
  try {
    const userId = req.user.ma_nguoi_dung;
    const {
      hotel_id,
      room_type_id,
      title,
      description,
      original_price,
      discounted_price,
      total_rooms,
      duration_hours,
      conditions
    } = req.body;
    
    // Kiểm tra quyền sở hữu khách sạn
    const { getPool } = require('../config/db');
    const pool = await getPool();
    const checkQuery = `
      SELECT ma_khach_san FROM khach_san 
      WHERE ma_khach_san = @hotel_id AND chu_khach_san_id = @user_id
    `;
    
    const checkResult = await pool.request()
      .input('hotel_id', require('mssql').Int, hotel_id)
      .input('user_id', require('mssql').Int, userId)
      .query(checkQuery);
    
    if (checkResult.recordset.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền tạo ưu đãi cho khách sạn này'
      });
    }
    
    const now = new Date();
    const endTime = new Date(now.getTime() + duration_hours * 60 * 60 * 1000);
    
    const offerData = {
      hotel_id,
      room_type_id,
      title,
      description,
      original_price,
      discounted_price,
      total_rooms,
      start_time: now,
      end_time: endTime,
      conditions: conditions || [
        'Không thể hủy phòng',
        'Không hoàn tiền',
        `Áp dụng trong vòng ${duration_hours} tiếng`
      ]
    };
    
    const offer = await promotionOfferModel.create(offerData);
    
    res.status(201).json({
      success: true,
      data: offer,
      message: 'Tạo ưu đãi thành công'
    });
  } catch (error) {
    console.error('Error creating offer:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi tạo ưu đãi'
    });
  }
};

// Cập nhật số phòng còn lại
const updateAvailableRooms = async (req, res) => {
  try {
    const { offerId } = req.params;
    const { available_rooms } = req.body;
    
    const success = await promotionOfferModel.updateAvailableRooms(offerId, available_rooms);
    
    if (success) {
      res.json({
        success: true,
        message: 'Cập nhật số phòng thành công'
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'Không tìm thấy ưu đãi'
      });
    }
  } catch (error) {
    console.error('Error updating available rooms:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi cập nhật số phòng'
    });
  }
};

// Hủy ưu đãi
const cancelOffer = async (req, res) => {
  try {
    const { offerId } = req.params;
    const userId = req.user.ma_nguoi_dung;
    
    // Kiểm tra quyền sở hữu
    const { getPool } = require('../config/db');
    const pool = await getPool();
    const checkQuery = `
      SELECT po.id FROM promotion_offers po
      INNER JOIN khach_san ks ON po.hotel_id = ks.ma_khach_san
      WHERE po.id = @offer_id AND ks.chu_khach_san_id = @user_id
    `;
    
    const checkResult = await pool.request()
      .input('offer_id', require('mssql').Int, offerId)
      .input('user_id', require('mssql').Int, userId)
      .query(checkQuery);
    
    if (checkResult.recordset.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền hủy ưu đãi này'
      });
    }
    
    const success = await promotionOfferModel.cancelOffer(offerId);
    
    if (success) {
      res.json({
        success: true,
        message: 'Hủy ưu đãi thành công'
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'Không tìm thấy ưu đãi'
      });
    }
  } catch (error) {
    console.error('Error canceling offer:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi hủy ưu đãi'
    });
  }
};

// Lấy tất cả ưu đãi của hotel owner
const getOffersByHotelOwner = async (req, res) => {
  try {
    const userId = req.user.ma_nguoi_dung;
    const offers = await promotionOfferModel.getOffersByHotelOwner(userId);
    
    res.json({
      success: true,
      data: offers,
      message: 'Lấy danh sách ưu đãi thành công'
    });
  } catch (error) {
    console.error('Error getting offers by hotel owner:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách ưu đãi'
    });
  }
};

// Tạo ưu đãi cuối ngày tự động
const createEndOfDayOffers = async (req, res) => {
  try {
    const offers = await promotionOfferModel.createEndOfDayOffers();
    
    res.json({
      success: true,
      data: offers,
      message: `Đã tạo ${offers.length} ưu đãi cuối ngày`
    });
  } catch (error) {
    console.error('Error creating end of day offers:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi tạo ưu đãi cuối ngày'
    });
  }
};

module.exports = {
  getActiveOffersForHotel,
  getOfferForRoom,
  bookWithOffer,
  createOffer,
  updateAvailableRooms,
  cancelOffer,
  getOffersByHotelOwner,
  createEndOfDayOffers
};
