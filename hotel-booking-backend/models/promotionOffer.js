const { getPool } = require('../config/db');
const sql = require('mssql');

class PromotionOffer {
  constructor() {
    this.tableName = 'promotion_offers';
  }

  // Tạo ưu đãi mới
  async create(data) {
    const pool = await getPool();
    try {
      const query = `
        INSERT INTO ${this.tableName} (
          hotel_id, room_type_id, title, description, 
          original_price, discounted_price, total_rooms, available_rooms,
          start_time, end_time, conditions, is_active, created_at, updated_at
        )
        OUTPUT INSERTED.*
        VALUES (
          @hotel_id, @room_type_id, @title, @description,
          @original_price, @discounted_price, @total_rooms, @total_rooms,
          @start_time, @end_time, @conditions, 1, GETDATE(), GETDATE()
        )
      `;

      const request = pool.request();
      request.input('hotel_id', sql.Int, data.hotel_id);
      request.input('room_type_id', sql.Int, data.room_type_id);
      request.input('title', sql.NVarChar, data.title);
      request.input('description', sql.NVarChar, data.description);
      request.input('original_price', sql.Decimal(18, 2), data.original_price);
      request.input('discounted_price', sql.Decimal(18, 2), data.discounted_price);
      request.input('total_rooms', sql.Int, data.total_rooms);
      request.input('start_time', sql.DateTime, data.start_time);
      request.input('end_time', sql.DateTime, data.end_time);
      request.input('conditions', sql.NVarChar, JSON.stringify(data.conditions));

      const result = await request.query(query);
      return result.recordset[0];
    } catch (error) {
      console.error('Error creating promotion offer:', error);
      throw error;
    }
  }

  // Lấy ưu đãi đang hoạt động cho một khách sạn
  async getActiveOffersForHotel(hotelId) {
    try {
      const pool = await getPool();
      const query = `
        SELECT * FROM ${this.tableName}
        WHERE hotel_id = @hotel_id 
          AND is_active = 1 
          AND start_time <= GETDATE() 
          AND end_time > GETDATE()
          AND available_rooms > 0
        ORDER BY created_at DESC
      `;

      const request = pool.request();
      request.input('hotel_id', sql.Int, hotelId);

      const result = await request.query(query);
      return result.recordset.map(row => ({
        ...row,
        conditions: JSON.parse(row.conditions || '[]')
      }));
    } catch (error) {
      console.error('Error getting active offers:', error);
      // Trả về mảng rỗng thay vì throw error
      return [];
    }
  }

  // Lấy ưu đãi cho một loại phòng cụ thể
  async getOfferForRoom(hotelId, roomTypeId) {
    const pool = await getPool();
    try {
      const query = `
        SELECT TOP 1 * FROM ${this.tableName}
        WHERE hotel_id = @hotel_id 
          AND room_type_id = @room_type_id
          AND is_active = 1 
          AND start_time <= GETDATE() 
          AND end_time > GETDATE()
          AND available_rooms > 0
        ORDER BY created_at DESC
      `;

      const request = pool.request();
      request.input('hotel_id', sql.Int, hotelId);
      request.input('room_type_id', sql.Int, roomTypeId);

      const result = await request.query(query);
      if (result.recordset.length > 0) {
        const row = result.recordset[0];
        return {
          ...row,
          conditions: JSON.parse(row.conditions || '[]')
        };
      }
      return null;
    } catch (error) {
      console.error('Error getting offer for room:', error);
      throw error;
    }
  }

  // Cập nhật số phòng còn lại
  async updateAvailableRooms(offerId, newAvailableRooms) {
    const pool = await getPool();
    try {
      const query = `
        UPDATE ${this.tableName}
        SET available_rooms = @available_rooms,
            updated_at = GETDATE(),
            is_active = CASE 
              WHEN @available_rooms <= 0 THEN 0 
              ELSE is_active 
            END
        WHERE id = @offer_id
      `;

      const request = pool.request();
      request.input('offer_id', sql.Int, offerId);
      request.input('available_rooms', sql.Int, newAvailableRooms);

      const result = await request.query(query);
      return result.rowsAffected[0] > 0;
    } catch (error) {
      console.error('Error updating available rooms:', error);
      throw error;
    }
  }

  // Đặt phòng với ưu đãi
  async bookWithOffer(offerId, userId, bookingData) {
    const pool = await getPool();
    const transaction = pool.transaction();
    
    try {
      await transaction.begin();

      // 1. Kiểm tra ưu đãi còn hiệu lực không
      const checkOfferQuery = `
        SELECT * FROM ${this.tableName}
        WHERE id = @offer_id 
          AND is_active = 1 
          AND start_time <= GETDATE() 
          AND end_time > GETDATE()
          AND available_rooms > 0
      `;

      const checkRequest = transaction.request();
      checkRequest.input('offer_id', sql.Int, offerId);
      const offerResult = await checkRequest.query(checkOfferQuery);

      if (offerResult.recordset.length === 0) {
        throw new Error('Ưu đãi không còn hiệu lực hoặc đã hết phòng');
      }

      const offer = offerResult.recordset[0];

      // 2. Tạo booking
      const bookingQuery = `
        INSERT INTO phieu_dat_phong (
          ma_nguoi_dung, ma_khach_san, ma_loai_phong,
          ngay_den, ngay_di, so_phong, so_nguoi_lon, so_tre_em,
          gia_phong, tong_tien, trang_thai, 
          promotion_offer_id, ngay_tao, ngay_cap_nhat
        )
        OUTPUT INSERTED.*
        VALUES (
          @nguoi_dung_id, @khach_san_id, @room_type_id,
          @ngay_den, @ngay_di, 1, @so_nguoi_lon, @so_tre_em,
          @discounted_price, @discounted_price, 'confirmed',
          @offer_id, GETDATE(), GETDATE()
        )
      `;

      const bookingRequest = transaction.request();
      bookingRequest.input('nguoi_dung_id', sql.Int, userId);
      bookingRequest.input('khach_san_id', sql.Int, offer.hotel_id);
      bookingRequest.input('room_type_id', sql.Int, offer.room_type_id);
      bookingRequest.input('ngay_den', sql.Date, bookingData.check_in_date);
      bookingRequest.input('ngay_di', sql.Date, bookingData.check_out_date);
      bookingRequest.input('so_nguoi_lon', sql.Int, bookingData.adults);
      bookingRequest.input('so_tre_em', sql.Int, bookingData.children);
      bookingRequest.input('discounted_price', sql.Decimal(18, 2), offer.discounted_price);
      bookingRequest.input('offer_id', sql.Int, offerId);

      const bookingResult = await bookingRequest.query(bookingQuery);
      const booking = bookingResult.recordset[0];

      // 3. Giảm số phòng còn lại
      const updateRoomsQuery = `
        UPDATE ${this.tableName}
        SET available_rooms = available_rooms - 1,
            updated_at = GETDATE(),
            is_active = CASE 
              WHEN available_rooms - 1 <= 0 THEN 0 
              ELSE is_active 
            END
        WHERE id = @offer_id
      `;

      const updateRequest = transaction.request();
      updateRequest.input('offer_id', sql.Int, offerId);
      await updateRequest.query(updateRoomsQuery);

      await transaction.commit();

      return {
        booking: booking,
        offer: {
          ...offer,
          conditions: JSON.parse(offer.conditions || '[]')
        }
      };
    } catch (error) {
      await transaction.rollback();
      console.error('Error booking with offer:', error);
      throw error;
    }
  }

  // Hủy ưu đãi
  async cancelOffer(offerId) {
    const pool = await getPool();
    try {
      const query = `
        UPDATE ${this.tableName}
        SET is_active = 0, updated_at = GETDATE()
        WHERE id = @offer_id
      `;

      const request = pool.request();
      request.input('offer_id', sql.Int, offerId);

      const result = await request.query(query);
      return result.rowsAffected[0] > 0;
    } catch (error) {
      console.error('Error canceling offer:', error);
      throw error;
    }
  }

  // Lấy tất cả ưu đãi của hotel owner
  async getOffersByHotelOwner(hotelOwnerId) {
    const pool = await getPool();
    try {
      const query = `
        SELECT po.*, ks.ten_khach_san as hotel_name, lp.ten_loai_phong as room_type_name
        FROM ${this.tableName} po
        INNER JOIN khach_san ks ON po.hotel_id = ks.ma_khach_san
        INNER JOIN loai_phong lp ON po.room_type_id = lp.ma_loai_phong
        WHERE ks.chu_khach_san_id = @hotel_owner_id
        ORDER BY po.created_at DESC
      `;

      const request = pool.request();
      request.input('hotel_owner_id', sql.Int, hotelOwnerId);

      const result = await request.query(query);
      return result.recordset.map(row => ({
        ...row,
        conditions: JSON.parse(row.conditions || '[]')
      }));
    } catch (error) {
      console.error('Error getting offers by hotel owner:', error);
      throw error;
    }
  }

  // Tự động tạo ưu đãi cuối ngày (có thể gọi từ cron job)
  async createEndOfDayOffers() {
    const pool = await getPool();
    try {
      // Lấy danh sách khách sạn có phòng trống
      const hotelsQuery = `
        SELECT DISTINCT ks.id as hotel_id, ks.ten as hotel_name
        FROM khach_san ks
        INNER JOIN phong p ON ks.id = p.khach_san_id
        WHERE p.tinh_trang = 1
          AND ks.id NOT IN (
            SELECT DISTINCT hotel_id 
            FROM ${this.tableName} 
            WHERE is_active = 1 
              AND start_time <= GETDATE() 
              AND end_time > GETDATE()
          )
      `;

      const hotelsResult = await pool.request().query(hotelsQuery);
      
      const offers = [];
      const now = new Date();
      const endTime = new Date(now.getTime() + 3 * 60 * 60 * 1000); // 3 tiếng sau

      for (const hotel of hotelsResult.recordset) {
        // Tạo ưu đãi cho mỗi loại phòng
        const roomTypesQuery = `
          SELECT DISTINCT lp.id, lp.ten, lp.gia_co_ban
          FROM loai_phong lp
          INNER JOIN phong p ON lp.id = p.loai_phong_id
          WHERE p.khach_san_id = @hotel_id AND p.tinh_trang = 1
        `;

        const roomTypesResult = await pool.request()
          .input('hotel_id', sql.Int, hotel.hotel_id)
          .query(roomTypesQuery);

        for (const roomType of roomTypesResult.recordset) {
          const originalPrice = roomType.gia_co_ban || 2000000;
          const discountedPrice = originalPrice * 0.6; // Giảm 40%

          const offerData = {
            hotel_id: hotel.hotel_id,
            room_type_id: roomType.id,
            title: `Ưu đãi cuối ngày - ${roomType.ten}`,
            description: `Giảm giá 40% cho ${roomType.ten} - Chỉ còn 2 phòng!`,
            original_price: originalPrice,
            discounted_price: discountedPrice,
            total_rooms: 2,
            start_time: now,
            end_time: endTime,
            conditions: [
              'Không thể hủy phòng',
              'Không hoàn tiền',
              'Áp dụng trong vòng 3 tiếng',
            ]
          };

          const offer = await this.create(offerData);
          offers.push(offer);
        }
      }

      return offers;
    } catch (error) {
      console.error('Error creating end of day offers:', error);
      throw error;
    }
  }

  // Lấy giá phòng thật của một khách sạn
  async getRoomPricesForHotel(hotelId) {
    const pool = await getPool();
    try {
      const query = `
        SELECT DISTINCT 
          lp.ma_loai_phong as loai_phong_id,
          lp.ten_loai_phong,
          p.gia_phong
        FROM phong p
        INNER JOIN loai_phong lp ON p.loai_phong_id = lp.ma_loai_phong
        WHERE p.khach_san_id = @hotelId
          AND p.gia_phong IS NOT NULL
          AND p.gia_phong > 0
        ORDER BY lp.ma_loai_phong
      `;

      const request = pool.request();
      request.input('hotelId', sql.Int, hotelId);

      const result = await request.query(query);
      console.log('Room prices query result:', result.recordset);
      return result.recordset;
    } catch (error) {
      console.error('Error getting room prices for hotel:', error);
      // Trả về dữ liệu mẫu nếu có lỗi
      return [
        { loai_phong_id: 1, ten_loai_phong: 'Standard Room', gia_phong: 500000 },
        { loai_phong_id: 2, ten_loai_phong: 'Deluxe Room', gia_phong: 750000 }
      ];
    }
  }
}

module.exports = new PromotionOffer();
