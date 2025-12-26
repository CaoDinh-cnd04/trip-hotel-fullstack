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
    const managerId = req.user.id || req.user.ma_nguoi_dung;
    
    console.log('📥 Received request body:', JSON.stringify(req.body, null, 2));
    console.log('📥 Manager ID:', managerId);
    
    if (!managerId) {
      return res.status(401).json({
        success: false,
        message: 'Không tìm thấy thông tin người dùng'
      });
    }
    
    const {
      hotel_id,
      room_type_id,
      title,
      description,
      original_price,
      discount_type, // 'percent' or 'amount'
      discount_value, // % or amount in VND
      total_rooms,
      start_time,
      end_time,
      conditions,
      submit_for_approval = false // Gửi admin duyệt
    } = req.body;
    
    console.log('📥 Parsed fields:', {
      hotel_id,
      room_type_id,
      title,
      original_price,
      total_rooms,
      start_time,
      end_time,
      discount_type,
      discount_value
    });
    
    // Validation
    // room_type_id có thể là null (áp dụng cho tất cả phòng)
    // total_rooms có thể là 0 hoặc không có (bảng khuyen_mai không có cột này)
    const missingFields = [];
    if (!hotel_id) missingFields.push('hotel_id');
    if (!title) missingFields.push('title');
    if (!original_price) missingFields.push('original_price');
    if (total_rooms === undefined || total_rooms === null || total_rooms === '') {
      // Cho phép total_rooms = 0 hoặc không có
      // Nếu không có, set mặc định là 0
      if (total_rooms === undefined || total_rooms === null) {
        total_rooms = 0;
      }
    }
    if (!start_time) missingFields.push('start_time');
    if (!end_time) missingFields.push('end_time');
    
    if (missingFields.length > 0) {
      console.error('❌ Missing required fields:', missingFields);
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc: ' + missingFields.join(', ')
      });
    }
    
    // room_type_id có thể là null (0 hoặc null = áp dụng cho tất cả phòng)
    // Không cần validate room_type_id vì nó có thể là null
    
    if (!discount_type || !discount_value) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin: discount_type, discount_value'
      });
    }
    
    const { getPool } = require('../config/db');
    const sql = require('mssql');
    const pool = await getPool();
    
    // Kiểm tra quyền quản lý khách sạn
    const checkQuery = `
      SELECT id FROM dbo.khach_san 
      WHERE id = @hotel_id AND nguoi_quan_ly_id = @manager_id
    `;
    
    const checkResult = await pool.request()
      .input('hotel_id', sql.Int, parseInt(hotel_id))
      .input('manager_id', sql.Int, parseInt(managerId))
      .query(checkQuery);
    
    if (checkResult.recordset.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền tạo ưu đãi cho khách sạn này'
      });
    }
    
    // Parse và validate giá
    const parsedOriginalPrice = parseFloat(original_price);
    const parsedDiscountValue = parseFloat(discount_value);
    
    if (isNaN(parsedOriginalPrice) || parsedOriginalPrice <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Giá gốc không hợp lệ'
      });
    }
    
    if (isNaN(parsedDiscountValue) || parsedDiscountValue <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Giá trị giảm giá không hợp lệ'
      });
    }
    
    // Tính discounted_price dựa trên discount_type
    let discounted_price = parsedOriginalPrice;
    if (discount_type === 'percent') {
      if (parsedDiscountValue > 100) {
        return res.status(400).json({
          success: false,
          message: 'Phần trăm giảm giá không được vượt quá 100%'
        });
      }
      discounted_price = parsedOriginalPrice * (1 - parsedDiscountValue / 100);
    } else if (discount_type === 'amount') {
      if (parsedDiscountValue >= parsedOriginalPrice) {
        return res.status(400).json({
          success: false,
          message: 'Số tiền giảm không được lớn hơn hoặc bằng giá gốc'
        });
      }
      discounted_price = parsedOriginalPrice - parsedDiscountValue;
    } else {
      return res.status(400).json({
        success: false,
        message: 'Loại giảm giá không hợp lệ (phải là "percent" hoặc "amount")'
      });
    }
    
    // Đảm bảo giá không âm
    if (discounted_price < 0) {
      discounted_price = 0;
    }
    
    // Round to 2 decimal places
    discounted_price = Math.round(discounted_price * 100) / 100;
    
    // Validate dates
    const startDate = new Date(start_time);
    const endDate = new Date(end_time);
    
    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Thời gian không hợp lệ'
      });
    }
    
    if (startDate >= endDate) {
      return res.status(400).json({
        success: false,
        message: 'Thời gian kết thúc phải sau thời gian bắt đầu'
      });
    }
    
    // Status: pending nếu submit_for_approval, approved nếu không
    const status = submit_for_approval ? 'pending' : 'approved';
    
    // room_type_id = null = áp dụng cho tất cả phòng
    // Cho phép null, 0, '', undefined đều được coi là null
    let parsedRoomTypeId = null;
    if (room_type_id !== null && room_type_id !== undefined && room_type_id !== '' && room_type_id !== 0) {
      parsedRoomTypeId = parseInt(room_type_id);
      if (isNaN(parsedRoomTypeId)) {
        parsedRoomTypeId = null;
      }
    }
    
    const offerData = {
      hotel_id: parseInt(hotel_id),
      room_type_id: parsedRoomTypeId, // NULL = áp dụng cho tất cả phòng
      title: title.trim(),
      description: (description || '').trim(),
      original_price: parsedOriginalPrice,
      discounted_price: discounted_price,
      discount_type: discount_type,
      discount_value: parsedDiscountValue,
      total_rooms: parseInt(total_rooms),
      start_time: startDate,
      end_time: endDate,
      conditions: Array.isArray(conditions) ? conditions : [],
      status,
      is_active: status === 'approved' ? 1 : 0 // Chỉ active nếu approved
    };
    
    console.log('📤 Creating offer with data:', JSON.stringify(offerData, null, 2));
    console.log('📤 Room type ID:', parsedRoomTypeId, '(null = all rooms)');
    
    const offer = await promotionOfferModel.create(offerData);
    
    console.log('✅ Offer created successfully:', offer);
    
    res.status(201).json({
      success: true,
      data: offer,
      message: submit_for_approval 
        ? 'Đã gửi ưu đãi chờ Admin duyệt' 
        : 'Tạo ưu đãi thành công'
    });
  } catch (error) {
    console.error('❌ Error creating offer:', error);
    console.error('❌ Error stack:', error.stack);
    console.error('❌ Error details:', {
      message: error.message,
      number: error.number,
      code: error.code,
      originalError: error.originalError?.message
    });
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi tạo ưu đãi: ' + error.message,
      error: process.env.NODE_ENV === 'development' ? {
        message: error.message,
        stack: error.stack,
        number: error.number,
        code: error.code
      } : undefined
    });
  }
};

// Cập nhật số phòng còn lại
const updateAvailableRooms = async (req, res) => {
  try {
    let { offerId } = req.params;
    const { available_rooms } = req.body;
    
    // ✅ Fix: Parse và validate offerId (có thể có format "52,52" do duplicate)
    if (offerId && offerId.includes(',')) {
      offerId = offerId.split(',')[0].trim();
      console.log(`⚠️ Detected duplicate ID in URL, using first part: ${offerId}`);
    }
    
    const parsedOfferId = parseInt(offerId, 10);
    
    if (isNaN(parsedOfferId) || parsedOfferId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID ưu đãi không hợp lệ'
      });
    }
    
    const success = await promotionOfferModel.updateAvailableRooms(parsedOfferId, available_rooms);
    
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
    let { offerId } = req.params;
    
    // ✅ Fix: Parse và validate offerId (có thể có format "52,52" do duplicate)
    // Lấy phần đầu tiên nếu có comma
    if (offerId && offerId.includes(',')) {
      offerId = offerId.split(',')[0].trim();
      console.log(`⚠️ Detected duplicate ID in URL, using first part: ${offerId}`);
    }
    
    // Parse to integer
    const parsedOfferId = parseInt(offerId, 10);
    
    if (isNaN(parsedOfferId) || parsedOfferId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID ưu đãi không hợp lệ'
      });
    }
    
    const managerId = req.user.id || req.user.ma_nguoi_dung;
    
    console.log(`🗑️ Attempting to delete promotion offer ${parsedOfferId} by manager ${managerId}`);
    
    // Kiểm tra quyền quản lý
    const { getPool } = require('../config/db');
    const sql = require('mssql');
    const pool = await getPool();
    const checkQuery = `
      SELECT km.id FROM dbo.khuyen_mai km
      INNER JOIN dbo.khach_san ks ON km.khach_san_id = ks.id
      WHERE km.id = @offer_id AND ks.nguoi_quan_ly_id = @manager_id
    `;
    
    const checkResult = await pool.request()
      .input('offer_id', sql.Int, parsedOfferId)
      .input('manager_id', sql.Int, managerId)
      .query(checkQuery);
    
    if (checkResult.recordset.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền hủy ưu đãi này'
      });
    }
    
    const success = await promotionOfferModel.cancelOffer(parsedOfferId);
    
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

// Toggle ưu đãi (bật/tắt)
const toggleOffer = async (req, res) => {
  try {
    let { offerId } = req.params;
    const { is_active } = req.body;
    const managerId = req.user.id || req.user.ma_nguoi_dung;
    
    // ✅ Fix: Parse và validate offerId
    if (offerId && offerId.includes(',')) {
      offerId = offerId.split(',')[0].trim();
    }
    const parsedOfferId = parseInt(offerId, 10);
    if (isNaN(parsedOfferId) || parsedOfferId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID ưu đãi không hợp lệ'
      });
    }
    
    const { getPool } = require('../config/db');
    const sql = require('mssql');
    const pool = await getPool();
    
    // Kiểm tra quyền và trạng thái
    const checkQuery = `
      SELECT km.id, km.trang_thai FROM dbo.khuyen_mai km
      INNER JOIN dbo.khach_san ks ON km.khach_san_id = ks.id
      WHERE km.id = @offer_id AND ks.nguoi_quan_ly_id = @manager_id
    `;
    
    const checkResult = await pool.request()
      .input('offer_id', sql.Int, parsedOfferId)
      .input('manager_id', sql.Int, managerId)
      .query(checkQuery);
    
    if (checkResult.recordset.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền thay đổi ưu đãi này'
      });
    }
    
    const offer = checkResult.recordset[0];
    
    // Chỉ cho phép bật nếu đã được approved (trang_thai = 1)
    if (is_active && offer.trang_thai !== 1) {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể bật ưu đãi đã được Admin duyệt'
      });
    }
    
    // Update trang_thai (sử dụng model thay vì query trực tiếp)
    await promotionOfferModel.toggleActive(parsedOfferId, is_active);
    
    res.json({
      success: true,
      message: is_active ? 'Đã bật ưu đãi' : 'Đã tắt ưu đãi'
    });
  } catch (error) {
    console.error('Error toggling offer:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi thay đổi trạng thái ưu đãi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Gửi ưu đãi chờ Admin duyệt
const submitForApproval = async (req, res) => {
  try {
    let { offerId } = req.params;
    
    // ✅ Fix: Parse và validate offerId
    if (offerId && offerId.includes(',')) {
      offerId = offerId.split(',')[0].trim();
    }
    const parsedOfferId = parseInt(offerId, 10);
    if (isNaN(parsedOfferId) || parsedOfferId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID ưu đãi không hợp lệ'
      });
    }
    
    const managerId = req.user.id || req.user.ma_nguoi_dung;
    
    const { getPool } = require('../config/db');
    const sql = require('mssql');
    const pool = await getPool();
    
    // Kiểm tra quyền
    const checkQuery = `
      SELECT km.id FROM dbo.khuyen_mai km
      INNER JOIN dbo.khach_san ks ON km.khach_san_id = ks.id
      WHERE km.id = @offer_id AND ks.nguoi_quan_ly_id = @manager_id
    `;
    
    const checkResult = await pool.request()
      .input('offer_id', sql.Int, parsedOfferId)
      .input('manager_id', sql.Int, managerId)
      .query(checkQuery);
    
    if (checkResult.recordset.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền gửi ưu đãi này'
      });
    }
    
    // Update trang_thai to pending (0)
    await promotionOfferModel.updateStatus(parsedOfferId, 'pending');
    
    res.json({
      success: true,
      message: 'Đã gửi ưu đãi chờ Admin duyệt'
    });
  } catch (error) {
    console.error('Error submitting for approval:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi gửi ưu đãi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Lấy tất cả ưu đãi của hotel owner
const getOffersByHotelOwner = async (req, res) => {
  try {
    // Use req.user.id (same as other hotel manager controllers)
    const managerId = req.user.id || req.user.ma_nguoi_dung;
    
    if (!managerId) {
      return res.status(401).json({
        success: false,
        message: 'Không tìm thấy thông tin người dùng'
      });
    }
    
    console.log('🔍 Getting offers for manager ID:', managerId);
    const offers = await promotionOfferModel.getOffersByHotelOwner(managerId);
    
    console.log(`✅ Found ${offers.length} offers for manager ${managerId}`);
    
    res.json({
      success: true,
      data: offers,
      message: 'Lấy danh sách ưu đãi thành công'
    });
  } catch (error) {
    console.error('❌ Error getting offers by hotel owner:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách ưu đãi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
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

// Admin: Lấy tất cả ưu đãi từ tất cả hotel managers
const getAllPromotionOffers = async (req, res) => {
  try {
    const { status, hotel_id } = req.query;
    console.log('📋 Getting all promotion offers with params:', { status, hotel_id });
    
    const { getPool } = require('../config/db');
    const sql = require('mssql');
    const pool = await getPool();
    
    // Chỉ SELECT các cột chắc chắn có trong bảng khuyen_mai
    // Theo comment: id, ten, phan_tram, giam_toi_da, ngay_bat_dau, ngay_ket_thuc, 
    // khach_san_id, mo_ta, trang_thai, created_at, updated_at
    // Sử dụng DISTINCT để tránh duplicate do JOIN
    let query = `
      SELECT DISTINCT
        km.id,
        km.khach_san_id as hotel_id,
        km.ten as title,
        km.mo_ta as description,
        km.ngay_bat_dau as start_time,
        km.ngay_ket_thuc as end_time,
        km.trang_thai as is_active,
        km.phan_tram as discount_value,
        km.giam_toi_da,
        ks.ten as ten_khach_san,
        nd.ho_ten as ten_nguoi_quan_ly,
        nd.email as email_nguoi_quan_ly,
        -- Tính giá gốc từ giá sau giảm và phần trăm giảm
        CASE 
          WHEN km.phan_tram > 0 AND km.phan_tram < 100 
          THEN CAST(km.giam_toi_da / (km.phan_tram / 100.0) AS DECIMAL(18,2))
          ELSE NULL 
        END as original_price,
        -- Tính giá sau giảm
        CASE 
          WHEN km.phan_tram > 0 AND km.phan_tram < 100 
          THEN CAST(km.giam_toi_da / (km.phan_tram / 100.0) - km.giam_toi_da AS DECIMAL(18,2))
          ELSE NULL 
        END as discounted_price,
        -- Bảng khuyen_mai không có so_luong_phong và loai_phong_id
        -- Trả về NULL cho các trường này
        CAST(0 AS INT) as total_rooms,
        CAST(0 AS INT) as available_rooms,
        CAST(NULL AS INT) as loai_phong_id,
        CAST(NULL AS NVARCHAR(255)) as ten_loai_phong
      FROM dbo.khuyen_mai km
      LEFT JOIN dbo.khach_san ks ON km.khach_san_id = ks.id
      LEFT JOIN dbo.nguoi_dung nd ON ks.nguoi_quan_ly_id = nd.id
      WHERE 1=1
    `;
    
    const request = pool.request();
    
    // Bảng khuyen_mai không có cột status, chỉ có trang_thai (BIT type)
    // Map status: 'approved' = trang_thai = 1, 'pending' = trang_thai = 0
    // Lưu ý: trang_thai = 0 có thể là pending, rejected, hoặc đã bị xóa
    // Vì không có cột deleted_at, nên chúng ta sẽ chỉ hiển thị các ưu đãi còn tồn tại
    // (không filter theo trang_thai = 0 vì nó cũng là pending/rejected)
    
    if (status) {
      if (status === 'approved') {
        query += ' AND km.trang_thai = CAST(1 AS BIT)';
      } else if (status === 'pending') {
        query += ' AND km.trang_thai = CAST(0 AS BIT)';
      } else if (status === 'rejected') {
        query += ' AND km.trang_thai = CAST(0 AS BIT)'; // Rejected cũng là trang_thai = 0
      }
    }
    
    if (hotel_id) {
      query += ' AND km.khach_san_id = @hotel_id';
      request.input('hotel_id', sql.Int, parseInt(hotel_id));
    }
    
    // Không ORDER BY created_at nếu cột không tồn tại, dùng id thay thế
    query += ' ORDER BY km.id DESC';
    
    console.log('🔍 Executing query:', query);
    const result = await request.query(query);
    
    console.log(`✅ Found ${result.recordset.length} promotion offers`);
    
    // Loại bỏ duplicate dựa trên id (nếu có)
    const uniqueOffers = []
    const seenIds = new Set()
    
    for (const offer of result.recordset) {
      const offerId = parseInt(offer.id)
      if (!seenIds.has(offerId)) {
        seenIds.add(offerId)
        uniqueOffers.push(offer)
      } else {
        console.warn(`⚠️ [Backend] Duplicate offer ID found: ${offerId}`)
      }
    }
    
    console.log(`📊 After deduplication: ${uniqueOffers.length} unique offers`)
    console.log(`📊 Offer IDs:`, uniqueOffers.map(o => o.id))
    
    res.json({
      success: true,
      data: uniqueOffers,
      message: 'Lấy danh sách ưu đãi thành công'
    });
  } catch (error) {
    console.error('❌ Error getting all promotion offers:', error);
    console.error('❌ Error details:', {
      message: error.message,
      number: error.number,
      code: error.code,
      lineNumber: error.lineNumber,
      originalError: error.originalError?.message
    });
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi lấy danh sách ưu đãi',
      error: process.env.NODE_ENV === 'development' ? {
        message: error.message,
        number: error.number,
        code: error.code,
        lineNumber: error.lineNumber
      } : undefined
    });
  }
};

// Admin: Duyệt ưu đãi
const approvePromotionOffer = async (req, res) => {
  try {
    let { offerId } = req.params;
    const { admin_note } = req.body;
    
    // ✅ Fix: Parse và validate offerId (có thể có format "52,52" do duplicate)
    if (offerId && offerId.includes(',')) {
      offerId = offerId.split(',')[0].trim();
    }
    const id = parseInt(offerId, 10);
    if (isNaN(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID ưu đãi không hợp lệ'
      });
    }
    
    console.log('📤 Approving promotion offer with ID:', id);
    
    const { getPool } = require('../config/db');
    const sql = require('mssql');
    const pool = await getPool();
    
    // Kiểm tra xem ưu đãi có tồn tại không
    const checkQuery = `SELECT id, trang_thai FROM dbo.khuyen_mai WHERE id = @offerId`;
    const checkResult = await pool.request()
      .input('offerId', sql.Int, id)
      .query(checkQuery);
    
    if (!checkResult.recordset || checkResult.recordset.length === 0) {
      console.log(`❌ Promotion offer ${id} not found`);
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy ưu đãi'
      });
    }
    
    const currentOffer = checkResult.recordset[0];
    console.log(`✅ Found offer ${id}, current status: ${currentOffer.trang_thai}`);
    
    // Bảng khuyen_mai có trang_thai là BIT, cần CAST
    // Kiểm tra xem có cột updated_at không, nếu không thì bỏ qua
    const updateQuery = `
      UPDATE dbo.khuyen_mai
      SET trang_thai = CAST(1 AS BIT)
      WHERE id = @offerId
    `;
    
    const updateResult = await pool.request()
      .input('offerId', sql.Int, id)
      .query(updateQuery);
    
    console.log(`📊 Update result - rowsAffected:`, updateResult.rowsAffected);
    
    // Kiểm tra xem có bản ghi nào được update không
    if (updateResult.rowsAffected[0] === 0) {
      console.log(`⚠️ No rows affected for offer ${id}`);
      return res.status(400).json({
        success: false,
        message: 'Không thể cập nhật ưu đãi. Có thể ưu đãi không tồn tại hoặc đã được cập nhật.'
      });
    }
    
    // Verify update
    const verifyQuery = `SELECT id, trang_thai FROM dbo.khuyen_mai WHERE id = @offerId`;
    const verifyResult = await pool.request()
      .input('offerId', sql.Int, id)
      .query(verifyQuery);
    
    const updatedOffer = verifyResult.recordset[0];
    console.log(`✅ Verified - Offer ${id} status updated to: ${updatedOffer.trang_thai}`);
    
    res.json({
      success: true,
      message: 'Đã duyệt ưu đãi thành công',
      data: {
        id: id,
        trang_thai: updatedOffer.trang_thai
      }
    });
  } catch (error) {
    console.error('Error approving promotion offer:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi duyệt ưu đãi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Admin: Từ chối ưu đãi
const rejectPromotionOffer = async (req, res) => {
  try {
    let { offerId } = req.params;
    const { admin_note } = req.body;
    
    // ✅ Fix: Parse và validate offerId (có thể có format "52,52" do duplicate)
    if (offerId && offerId.includes(',')) {
      offerId = offerId.split(',')[0].trim();
    }
    const id = parseInt(offerId, 10);
    if (isNaN(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID ưu đãi không hợp lệ'
      });
    }
    
    console.log('📤 Rejecting promotion offer with ID:', id);
    
    const { getPool } = require('../config/db');
    const sql = require('mssql');
    const pool = await getPool();
    
    // Kiểm tra xem ưu đãi có tồn tại không
    const checkQuery = `SELECT id, trang_thai FROM dbo.khuyen_mai WHERE id = @offerId`;
    const checkResult = await pool.request()
      .input('offerId', sql.Int, id)
      .query(checkQuery);
    
    if (!checkResult.recordset || checkResult.recordset.length === 0) {
      console.log(`❌ Promotion offer ${id} not found`);
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy ưu đãi'
      });
    }
    
    const currentOffer = checkResult.recordset[0];
    console.log(`✅ Found offer ${id}, current status: ${currentOffer.trang_thai}`);
    
    // Bảng khuyen_mai có trang_thai là BIT, cần CAST
    // Kiểm tra xem có cột updated_at không, nếu không thì bỏ qua
    const updateQuery = `
      UPDATE dbo.khuyen_mai
      SET trang_thai = CAST(0 AS BIT)
      WHERE id = @offerId
    `;
    
    const updateResult = await pool.request()
      .input('offerId', sql.Int, id)
      .query(updateQuery);
    
    console.log(`📊 Update result - rowsAffected:`, updateResult.rowsAffected);
    
    // Kiểm tra xem có bản ghi nào được update không
    if (updateResult.rowsAffected[0] === 0) {
      console.log(`⚠️ No rows affected for offer ${id}`);
      return res.status(400).json({
        success: false,
        message: 'Không thể cập nhật ưu đãi. Có thể ưu đãi không tồn tại hoặc đã được cập nhật.'
      });
    }
    
    // Verify update
    const verifyQuery = `SELECT id, trang_thai FROM dbo.khuyen_mai WHERE id = @offerId`;
    const verifyResult = await pool.request()
      .input('offerId', sql.Int, id)
      .query(verifyQuery);
    
    const updatedOffer = verifyResult.recordset[0];
    console.log(`✅ Verified - Offer ${id} status updated to: ${updatedOffer.trang_thai}`);
    
    res.json({
      success: true,
      message: 'Đã từ chối ưu đãi'
    });
  } catch (error) {
    console.error('Error rejecting promotion offer:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server khi từ chối ưu đãi',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
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
  createEndOfDayOffers,
  toggleOffer,
  submitForApproval,
  getAllPromotionOffers,
  approvePromotionOffer,
  rejectPromotionOffer
};
