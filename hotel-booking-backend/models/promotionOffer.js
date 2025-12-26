const { getPool } = require('../config/db');
const sql = require('mssql');

class PromotionOffer {
  constructor() {
    // Sử dụng bảng khuyen_mai thay vì promotion_offers
    this.tableName = 'dbo.khuyen_mai';
  }

  // Tạo ưu đãi mới - chỉ dùng các cột có sẵn trong khuyen_mai
  async create(data) {
    const pool = await getPool();
    try {
      // Bảng khuyen_mai chỉ có các cột:
      // id (IDENTITY), ten, phan_tram, giam_toi_da, ngay_bat_dau, ngay_ket_thuc, 
      // khach_san_id, mo_ta, trang_thai, created_at, updated_at
      
      // Tính phan_tram từ discount_value nếu là percent
      let phanTram = 0;
      let giamToiDa = 0;
      
      if (data.discount_type === 'percent' && data.discount_value) {
        phanTram = parseFloat(data.discount_value);
        // Tính giam_toi_da từ original_price * discount_value / 100
        if (data.original_price) {
          giamToiDa = parseFloat(data.original_price) * parseFloat(data.discount_value) / 100;
        }
      } else if (data.discount_type === 'amount' && data.discount_value) {
        // Nếu là amount, tính phan_tram từ original_price và discount_value
        if (data.original_price) {
          phanTram = (parseFloat(data.discount_value) / parseFloat(data.original_price)) * 100;
          giamToiDa = parseFloat(data.discount_value);
        }
      } else if (data.original_price && data.discounted_price) {
        // Nếu có original_price và discounted_price, tính ngược lại
        const discount = parseFloat(data.original_price) - parseFloat(data.discounted_price);
        phanTram = (discount / parseFloat(data.original_price)) * 100;
        giamToiDa = discount;
      }
      
      // Round values
      phanTram = Math.round(phanTram * 100) / 100;
      giamToiDa = Math.round(giamToiDa);
      
      // trang_thai: 1 nếu approved, 0 nếu pending
      const trangThai = (data.status === 'approved' || (!data.submit_for_approval && !data.status)) ? 1 : 0;
      
      // Retry logic với việc lấy lại MAX(id) mỗi lần retry
      let retryCount = 0;
      const maxRetries = 10;
      let insertedRecord = null;
      let lastError = null;
      
      while (retryCount < maxRetries && !insertedRecord) {
        try {
          console.log(`🔄 Attempt ${retryCount + 1}/${maxRetries}: Getting next ID...`);
          
          // Mỗi lần retry, lấy lại MAX(id) mới (có thể đã có record mới)
          const getMaxIdQuery = `SELECT ISNULL(MAX(id), 0) as max_id FROM ${this.tableName} WITH (TABLOCKX, HOLDLOCK)`;
          const maxIdRequest = pool.request();
          const maxIdResult = await maxIdRequest.query(getMaxIdQuery);
          let nextId = maxIdResult.recordset[0].max_id + 1;
          
          console.log(`📊 Current MAX(id): ${maxIdResult.recordset[0].max_id}, Next ID: ${nextId}`);
          
          // Kiểm tra xem ID đã tồn tại chưa (tối đa 20 lần)
          let checkCount = 0;
          while (checkCount < 20) {
            const checkIdQuery = `SELECT COUNT(*) as count FROM ${this.tableName} WHERE id = @id`;
            const checkRequest = pool.request();
            checkRequest.input('id', sql.Int, nextId);
            const checkResult = await checkRequest.query(checkIdQuery);
            
            if (checkResult.recordset[0].count === 0) {
              // ID chưa tồn tại, có thể dùng
              console.log(`✅ ID ${nextId} is available`);
              break;
            }
            
            // ID đã tồn tại, tăng lên 1
            console.log(`⚠️ ID ${nextId} already exists, trying ${nextId + 1}...`);
            nextId++;
            checkCount++;
          }
          
          if (checkCount >= 20) {
            throw new Error('Không thể tìm ID hợp lệ sau nhiều lần kiểm tra.');
          }
          
          console.log(`📤 Attempt ${retryCount + 1}: Using ID ${nextId}`);
          
          // INSERT với ID đã tính
          const insertQuery = `
            INSERT INTO ${this.tableName} (
              id, khach_san_id, ten, mo_ta, phan_tram, giam_toi_da, 
              ngay_bat_dau, ngay_ket_thuc, trang_thai
            )
            VALUES (
              @id, @khach_san_id, @ten, @mo_ta, @phan_tram, @giam_toi_da,
              @ngay_bat_dau, @ngay_ket_thuc, @trang_thai
            );
          `;

          const insertRequest = pool.request();
          insertRequest.input('id', sql.Int, nextId);
          insertRequest.input('khach_san_id', sql.Int, data.hotel_id);
          insertRequest.input('ten', sql.NVarChar, data.title);
          insertRequest.input('mo_ta', sql.NVarChar, data.description || '');
          insertRequest.input('phan_tram', sql.Decimal(18, 2), phanTram);
          insertRequest.input('giam_toi_da', sql.Decimal(18, 2), giamToiDa);
          insertRequest.input('ngay_bat_dau', sql.DateTime, data.start_time);
          insertRequest.input('ngay_ket_thuc', sql.DateTime, data.end_time);
          insertRequest.input('trang_thai', sql.Bit, trangThai);

          console.log(`📤 Attempt ${retryCount + 1}: Executing INSERT with ID ${nextId}`);
          
          await insertRequest.query(insertQuery);
          
          // SELECT lại record vừa tạo bằng ID
          const selectQuery = `SELECT * FROM ${this.tableName} WHERE id = @id`;
          const selectRequest = pool.request();
          selectRequest.input('id', sql.Int, nextId);
          
          const selectResult = await selectRequest.query(selectQuery);
          insertedRecord = selectResult.recordset && selectResult.recordset[0];
          
          if (!insertedRecord) {
            throw new Error('Không thể lấy record vừa tạo.');
          }
          
          console.log(`✅ Successfully inserted record with ID ${nextId}:`, insertedRecord);
          return insertedRecord;
        } catch (error) {
          lastError = error;
          
          // Kiểm tra lỗi duplicate key
          const errorNumber = error.number || error.originalError?.number;
          const errorMessage = error.message || error.originalError?.message || '';
          const isDuplicateKey = errorNumber === 2627 || errorMessage.toLowerCase().includes('duplicate key') || errorMessage.toLowerCase().includes('primary key constraint');
          
          console.error(`❌ Error in attempt ${retryCount + 1}:`, {
            number: errorNumber,
            code: error.code,
            message: errorMessage,
            isDuplicateKey: isDuplicateKey,
            fullError: error
          });
          
          if (isDuplicateKey && retryCount < maxRetries - 1) {
            retryCount++;
            const delay = 300 * retryCount;
            console.warn(`⚠️ Duplicate key error detected (ID conflict), retrying in ${delay}ms... (${retryCount}/${maxRetries})`);
            // Đợi một chút trước khi retry (tăng delay mỗi lần)
            await new Promise(resolve => setTimeout(resolve, delay));
            continue;
          }
          
          // Nếu không phải duplicate key hoặc đã retry hết, throw
          console.error(`❌ Fatal error or max retries reached. Throwing error.`);
          throw error;
        }
      }
      
      // Nếu đã retry hết mà vẫn lỗi
      if (!insertedRecord && lastError) {
        console.error(`❌ Failed after ${maxRetries} attempts. Last error:`, lastError);
        throw new Error(`Không thể tạo ưu đãi sau ${maxRetries} lần thử do duplicate key. Lỗi cuối: ${lastError.message}`);
      }
      
      return insertedRecord;
    } catch (error) {
      // If table doesn't exist (error code 208)
      if (error.number === 208 || error.message.includes('Invalid object name')) {
        console.error('❌ Table khuyen_mai does not exist!');
        throw new Error('Bảng khuyen_mai chưa được tạo trong database. Vui lòng tạo bảng trước khi sử dụng tính năng này.');
      }
      
      // If columns don't exist, try with basic columns only
      if (error.message.includes('Invalid column name') || error.number === 207) {
        console.warn('⚠️ Some columns do not exist, using basic columns for khuyen_mai table');
        console.warn('⚠️ Error:', error.message);
        try {
          return await this.createBasic(data);
        } catch (basicError) {
          console.error('❌ Error in createBasic:', basicError);
          throw basicError;
        }
      }
      console.error('❌ Error creating promotion offer:', error);
      console.error('❌ Error details:', {
        message: error.message,
        number: error.number,
        code: error.code,
        originalError: error.originalError?.message
      });
      throw error;
    }
  }

  // Tạo ưu đãi với các cột cơ bản của khuyen_mai (fallback - giống create)
  async createBasic(data) {
    try {
      const pool = await getPool();
      // Chỉ sử dụng các cột có sẵn trong khuyen_mai
      // Tính phan_tram và giam_toi_da từ discount data
      let phanTram = 0;
      let giamToiDa = 0;
      
      if (data.discount_type === 'percent' && data.discount_value) {
        phanTram = parseFloat(data.discount_value);
        if (data.original_price) {
          giamToiDa = parseFloat(data.original_price) * parseFloat(data.discount_value) / 100;
        }
      } else if (data.discount_type === 'amount' && data.discount_value) {
        if (data.original_price) {
          phanTram = (parseFloat(data.discount_value) / parseFloat(data.original_price)) * 100;
          giamToiDa = parseFloat(data.discount_value);
        }
      } else if (data.original_price && data.discounted_price) {
        const discount = parseFloat(data.original_price) - parseFloat(data.discounted_price);
        phanTram = (discount / parseFloat(data.original_price)) * 100;
        giamToiDa = discount;
      }
      
      phanTram = Math.round(phanTram * 100) / 100;
      giamToiDa = Math.round(giamToiDa);
      
      const trangThai = (data.status === 'approved' || (!data.submit_for_approval && !data.status)) ? 1 : 0;
      
      // Retry logic giống create
      let retryCount = 0;
      const maxRetries = 10;
      let insertedRecord = null;
      
      while (retryCount < maxRetries && !insertedRecord) {
        try {
          // Lấy lại MAX(id) mới mỗi lần retry
          const getMaxIdQuery = `SELECT ISNULL(MAX(id), 0) as max_id FROM ${this.tableName}`;
          const maxIdRequest = pool.request();
          const maxIdResult = await maxIdRequest.query(getMaxIdQuery);
          let nextId = maxIdResult.recordset[0].max_id + 1;
          
          // Kiểm tra xem ID đã tồn tại chưa
          let checkCount = 0;
          while (checkCount < 20) {
            const checkIdQuery = `SELECT COUNT(*) as count FROM ${this.tableName} WHERE id = @id`;
            const checkRequest = pool.request();
            checkRequest.input('id', sql.Int, nextId);
            const checkResult = await checkRequest.query(checkIdQuery);
            
            if (checkResult.recordset[0].count === 0) {
              break;
            }
            
            nextId++;
            checkCount++;
          }
          
          if (checkCount >= 20) {
            throw new Error('Không thể tìm ID hợp lệ sau nhiều lần kiểm tra.');
          }
          
          console.log('📤 Next ID (createBasic, attempt', retryCount + 1, '):', nextId);
          
          // INSERT với ID đã tính
          const insertQuery = `
            INSERT INTO ${this.tableName} (
              id, khach_san_id, ten, mo_ta, phan_tram, giam_toi_da, ngay_bat_dau, ngay_ket_thuc, trang_thai
            )
            VALUES (
              @id, @khach_san_id, @ten, @mo_ta, @phan_tram, @giam_toi_da, @ngay_bat_dau, @ngay_ket_thuc, @trang_thai
            );
          `;

          const insertRequest = pool.request();
          insertRequest.input('id', sql.Int, nextId);
          insertRequest.input('khach_san_id', sql.Int, data.hotel_id);
          insertRequest.input('ten', sql.NVarChar, data.title);
          insertRequest.input('mo_ta', sql.NVarChar, data.description || '');
          insertRequest.input('phan_tram', sql.Decimal(18, 2), phanTram);
          insertRequest.input('giam_toi_da', sql.Decimal(18, 2), giamToiDa);
          insertRequest.input('ngay_bat_dau', sql.DateTime, data.start_time);
          insertRequest.input('ngay_ket_thuc', sql.DateTime, data.end_time);
          insertRequest.input('trang_thai', sql.Bit, trangThai);

          console.log('📤 Executing createBasic query');
          await insertRequest.query(insertQuery);
          console.log('✅ createBasic query executed successfully');
          
          // SELECT lại record vừa tạo bằng ID
          const selectQuery = `SELECT * FROM ${this.tableName} WHERE id = @id`;
          const selectRequest = pool.request();
          selectRequest.input('id', sql.Int, nextId);
          
          const selectResult = await selectRequest.query(selectQuery);
          insertedRecord = selectResult.recordset && selectResult.recordset[0];
          
          if (!insertedRecord) {
            throw new Error('Không thể lấy record vừa tạo.');
          }
          
          return insertedRecord;
        } catch (error) {
          const errorNumber = error.number || error.originalError?.number;
          const errorMessage = error.message || error.originalError?.message || '';
          const isDuplicateKey = errorNumber === 2627 || errorMessage.includes('duplicate key');
          
          if (isDuplicateKey && retryCount < maxRetries - 1) {
            retryCount++;
            console.warn(`⚠️ Duplicate key error (createBasic), retrying... (${retryCount}/${maxRetries})`);
            await new Promise(resolve => setTimeout(resolve, 300 * retryCount));
            continue;
          }
          
          throw error;
        }
      }
      
      if (!insertedRecord) {
        throw new Error('Không thể tạo ưu đãi sau nhiều lần thử do duplicate key.');
      }
      
      return insertedRecord;
    } catch (error) {
      // If table doesn't exist (error code 208)
      if (error.number === 208 || error.message.includes('Invalid object name')) {
        console.error('❌ Table khuyen_mai does not exist!');
        throw new Error('Bảng khuyen_mai chưa được tạo trong database. Vui lòng tạo bảng trước khi sử dụng tính năng này.');
      }
      console.error('❌ Error in createBasic:', error);
      console.error('❌ Error details:', {
        message: error.message,
        number: error.number,
        code: error.code,
        originalError: error.originalError?.message
      });
      throw error;
    }
  }

  // Lấy ưu đãi đang hoạt động cho một khách sạn
  async getActiveOffersForHotel(hotelId) {
    try {
      const pool = await getPool();
      const query = `
        SELECT * FROM ${this.tableName}
        WHERE khach_san_id = @hotel_id 
          AND trang_thai = 1 
          AND ngay_bat_dau <= GETDATE() 
          AND ngay_ket_thuc > GETDATE()
      `;

      const request = pool.request();
      request.input('hotel_id', sql.Int, hotelId);

      const result = await request.query(query);
      return result.recordset || [];
    } catch (error) {
      console.error('Error getting active offers:', error);
      return [];
    }
  }

  // Lấy ưu đãi cho một loại phòng cụ thể
  async getOfferForRoom(hotelId, roomTypeId) {
    try {
      const pool = await getPool();
      const query = `
        SELECT * FROM ${this.tableName}
        WHERE khach_san_id = @hotel_id 
          AND trang_thai = 1 
          AND ngay_bat_dau <= GETDATE() 
          AND ngay_ket_thuc > GETDATE()
        ORDER BY phan_tram DESC
      `;

      const request = pool.request();
      request.input('hotel_id', sql.Int, hotelId);

      const result = await request.query(query);
      return result.recordset[0] || null;
    } catch (error) {
      console.error('Error getting offer for room:', error);
      return null;
    }
  }

  // Cập nhật số phòng còn lại
  async updateAvailableRooms(offerId, availableRooms) {
    const pool = await getPool();
    try {
      // Bảng khuyen_mai không có cột available_rooms
      // Không thể cập nhật, chỉ return success
      console.warn('⚠️ Bảng khuyen_mai không có cột available_rooms, không thể cập nhật');
      return true;
    } catch (error) {
      console.error('Error updating available rooms:', error);
      throw error;
    }
  }

  // Hủy ưu đãi
  async cancelOffer(offerId) {
    const pool = await getPool();
    try {
      // Kiểm tra xem cột updated_at có tồn tại không
      let query = `
        UPDATE ${this.tableName}
        SET trang_thai = 0
        WHERE id = @offer_id
      `;
      
      // Thử update với updated_at trước
      try {
        const testQuery = `
          UPDATE ${this.tableName}
          SET trang_thai = 0, updated_at = GETDATE()
          WHERE id = @offer_id
        `;
        const request = pool.request();
        request.input('offer_id', sql.Int, offerId);
        const result = await request.query(testQuery);
        return result.rowsAffected[0] > 0;
      } catch (updateError) {
        // Nếu lỗi là do cột updated_at không tồn tại, thử lại không có updated_at
        if (updateError.number === 207 || updateError.message?.includes('Invalid column name')) {
          console.warn('⚠️ Column updated_at not found, updating without it');
          const request = pool.request();
          request.input('offer_id', sql.Int, offerId);
          const result = await request.query(query);
          return result.rowsAffected[0] > 0;
        }
        throw updateError;
      }
    } catch (error) {
      console.error('❌ Error canceling offer:', error);
      console.error('❌ Error details:', {
        message: error.message,
        number: error.number,
        code: error.code,
        originalError: error.originalError?.message
      });
      throw error;
    }
  }

  // Lấy tất cả ưu đãi của hotel owner (manager)
  async getOffersByHotelOwner(managerId) {
    const pool = await getPool();
    try {
      // Use nguoi_quan_ly_id (same as other hotel manager queries)
      // Map với bảng khuyen_mai - chỉ dùng các cột có sẵn
      const query = `
        SELECT 
          km.*, 
          km.id,
          km.khach_san_id as hotel_id,
          km.ten as title,
          km.mo_ta as description,
          km.ngay_bat_dau as start_time,
          km.ngay_ket_thuc as end_time,
          km.trang_thai as is_active,
          km.phan_tram as discount_value,
          km.giam_toi_da,
          ks.ten as hotel_name, 
          ks.id as hotel_id
        FROM dbo.khuyen_mai km
        INNER JOIN dbo.khach_san ks ON km.khach_san_id = ks.id
        WHERE ks.nguoi_quan_ly_id = @manager_id
        ORDER BY km.created_at DESC
      `;

      const request = pool.request();
      request.input('manager_id', sql.Int, managerId);

      console.log('🔍 Executing query for manager:', managerId);
      const result = await request.query(query);
      
      const offers = result.recordset.map(row => {
        // Map dữ liệu để frontend hiểu
        return {
          ...row,
          discount_type: 'percent', // Mặc định là percent vì có phan_tram
          original_price: row.giam_toi_da ? (row.giam_toi_da / (row.phan_tram / 100)) : null,
          discounted_price: row.giam_toi_da ? (row.giam_toi_da / (row.phan_tram / 100) - row.giam_toi_da) : null,
          status: row.trang_thai === 1 ? 'approved' : 'pending',
          room_type_id: null, // Không có trong bảng
          room_type_name: null,
          total_rooms: null,
          available_rooms: null
        };
      });
      
      console.log(`✅ Found ${offers.length} offers`);
      return offers;
    } catch (error) {
      // Check if table doesn't exist (error code 208)
      if (error.number === 208 || error.message.includes('Invalid object name')) {
        console.warn('⚠️ Table khuyen_mai does not exist, returning empty array');
        return [];
      }
      
      console.error('❌ Error getting offers by hotel owner:', error);
      console.error('❌ Error details:', {
        message: error.message,
        code: error.code,
        number: error.number,
        originalError: error.originalError?.message
      });
      throw error;
    }
  }

  // Tự động tạo ưu đãi cuối ngày (có thể gọi từ cron job)
  async createEndOfDayOffers() {
    const pool = await getPool();
    try {
      // Logic tạo ưu đãi cuối ngày
      // Tạm thời return empty array
      return [];
    } catch (error) {
      console.error('Error creating end of day offers:', error);
      throw error;
    }
  }

  // Toggle active status
  async toggleActive(offerId, isActive) {
    const pool = await getPool();
    try {
      // Thử với updated_at trước
      try {
        const queryWithUpdate = `
          UPDATE ${this.tableName}
          SET trang_thai = @is_active, updated_at = GETDATE()
          WHERE id = @offer_id
        `;
        const request = pool.request();
        request.input('offer_id', sql.Int, offerId);
        request.input('is_active', sql.Bit, isActive ? 1 : 0);
        const result = await request.query(queryWithUpdate);
        return result.rowsAffected[0] > 0;
      } catch (updateError) {
        // Nếu lỗi là do cột updated_at không tồn tại
        if (updateError.number === 207 || updateError.message?.includes('Invalid column name')) {
          console.warn('⚠️ Column updated_at not found, updating without it');
          const query = `
            UPDATE ${this.tableName}
            SET trang_thai = @is_active
            WHERE id = @offer_id
          `;
          const request = pool.request();
          request.input('offer_id', sql.Int, offerId);
          request.input('is_active', sql.Bit, isActive ? 1 : 0);
          const result = await request.query(query);
          return result.rowsAffected[0] > 0;
        }
        throw updateError;
      }
    } catch (error) {
      console.error('Error toggling active status:', error);
      throw error;
    }
  }

  // Update status
  async updateStatus(offerId, status) {
    const pool = await getPool();
    try {
      // Map status to trang_thai: 'approved' = 1, 'pending'/'rejected' = 0
      const trangThai = status === 'approved' ? 1 : 0;
      
      // Thử với updated_at trước
      try {
        const queryWithUpdate = `
          UPDATE ${this.tableName}
          SET trang_thai = @trang_thai, updated_at = GETDATE()
          WHERE id = @offer_id
        `;
        const request = pool.request();
        request.input('offer_id', sql.Int, offerId);
        request.input('trang_thai', sql.Bit, trangThai);
        const result = await request.query(queryWithUpdate);
        return result.rowsAffected[0] > 0;
      } catch (updateError) {
        // Nếu lỗi là do cột updated_at không tồn tại
        if (updateError.number === 207 || updateError.message?.includes('Invalid column name')) {
          console.warn('⚠️ Column updated_at not found, updating without it');
          const query = `
            UPDATE ${this.tableName}
            SET trang_thai = @trang_thai
            WHERE id = @offer_id
          `;
          const request = pool.request();
          request.input('offer_id', sql.Int, offerId);
          request.input('trang_thai', sql.Bit, trangThai);
          const result = await request.query(query);
          return result.rowsAffected[0] > 0;
        }
        throw updateError;
      }
    } catch (error) {
      console.error('Error updating status:', error);
      throw error;
    }
  }
}

module.exports = new PromotionOffer();
