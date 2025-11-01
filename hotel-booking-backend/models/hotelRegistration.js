const sql = require('mssql');
const { getPool } = require('../config/db');

class HotelRegistration {
  /**
   * Tạo đơn đăng ký khách sạn mới
   */
  static async create(registrationData) {
    try {
      const pool = getPool();
      const request = pool.request();
      
      const query = `
        INSERT INTO dbo.hotel_registration (
          owner_name,
          owner_email,
          owner_phone,
          hotel_name,
          hotel_type,
          address,
          province_id,
          district,
          latitude,
          longitude,
          description,
          star_rating,
          tax_id,
          business_license,
          contact_email,
          contact_phone,
          website,
          check_in_time,
          check_out_time,
          require_deposit,
          deposit_rate,
          cancellation_policy,
          total_rooms,
          rooms_data,
          hotel_images,
          room_images,
          status,
          created_at
        )
        VALUES (
          @owner_name,
          @owner_email,
          @owner_phone,
          @hotel_name,
          @hotel_type,
          @address,
          @province_id,
          @district,
          @latitude,
          @longitude,
          @description,
          @star_rating,
          @tax_id,
          @business_license,
          @contact_email,
          @contact_phone,
          @website,
          @check_in_time,
          @check_out_time,
          @require_deposit,
          @deposit_rate,
          @cancellation_policy,
          @total_rooms,
          @rooms_data,
          @hotel_images,
          @room_images,
          'pending',
          GETDATE()
        );
        SELECT SCOPE_IDENTITY() AS id;
      `;

      request.input('owner_name', sql.NVarChar, registrationData.owner_name);
      request.input('owner_email', sql.NVarChar, registrationData.owner_email);
      request.input('owner_phone', sql.NVarChar, registrationData.owner_phone);
      request.input('hotel_name', sql.NVarChar, registrationData.hotel_name);
      request.input('hotel_type', sql.NVarChar, registrationData.hotel_type);
      request.input('address', sql.NVarChar, registrationData.address);
      request.input('province_id', sql.Int, registrationData.province_id);
      request.input('district', sql.NVarChar, registrationData.district);
      request.input('latitude', sql.Decimal(10, 8), registrationData.latitude || null);
      request.input('longitude', sql.Decimal(11, 8), registrationData.longitude || null);
      request.input('description', sql.NVarChar, registrationData.description || null);
      request.input('star_rating', sql.Int, registrationData.star_rating || null);
      request.input('tax_id', sql.NVarChar, registrationData.tax_id || null);
      request.input('business_license', sql.NVarChar, registrationData.business_license || null);
      // New fields
      request.input('contact_email', sql.NVarChar, registrationData.contact_email || null);
      request.input('contact_phone', sql.NVarChar, registrationData.contact_phone || null);
      request.input('website', sql.NVarChar, registrationData.website || null);
      
      // ✅ FIX: Normalize time format to HH:MM:SS for SQL Server
      const normalizeTime = (timeStr) => {
        if (!timeStr) return null;
        
        // If already in HH:MM:SS format
        if (/^\d{2}:\d{2}:\d{2}$/.test(timeStr)) {
          return timeStr;
        }
        
        // If in HH:MM format, add :00 seconds
        if (/^\d{2}:\d{2}$/.test(timeStr)) {
          return `${timeStr}:00`;
        }
        
        // If in H:MM format, pad hour
        if (/^\d{1}:\d{2}$/.test(timeStr)) {
          return `0${timeStr}:00`;
        }
        
        // Invalid format, return null
        console.warn(`⚠️ Invalid time format: "${timeStr}". Using default.`);
        return null;
      };
      
      const checkInTime = normalizeTime(registrationData.check_in_time) || '14:00:00';
      const checkOutTime = normalizeTime(registrationData.check_out_time) || '12:00:00';
      
      console.log(`⏰ Check-in time: ${checkInTime}, Check-out time: ${checkOutTime}`);
      
      // ✅ FIX: Use VarChar instead of Time to avoid strict validation
      // SQL Server will automatically convert VARCHAR to TIME
      request.input('check_in_time', sql.VarChar(8), checkInTime);
      request.input('check_out_time', sql.VarChar(8), checkOutTime);
      request.input('require_deposit', sql.Bit, registrationData.require_deposit !== undefined ? (registrationData.require_deposit ? 1 : 0) : 1);
      request.input('deposit_rate', sql.Decimal(5, 2), registrationData.deposit_rate || 30);
      request.input('cancellation_policy', sql.NVarChar, registrationData.cancellation_policy || null);
      request.input('total_rooms', sql.Int, registrationData.total_rooms || null);
      // Lưu rooms data dưới dạng JSON string
      request.input('rooms_data', sql.NVarChar, registrationData.rooms_data || null);
      request.input('hotel_images', sql.NVarChar, registrationData.hotel_images || null);
      request.input('room_images', sql.NVarChar, registrationData.room_images || null);

      const result = await request.query(query);
      return result.recordset[0].id;
    } catch (error) {
      console.error('❌ Error creating hotel registration:', error);
      throw error;
    }
  }

  /**
   * Lấy tất cả đơn đăng ký (cho admin)
   */
  static async getAll(filters = {}) {
    try {
      const pool = getPool();
      const request = pool.request();
      
      let query = `
        SELECT 
          hr.*,
          tt.ten as province_name
        FROM dbo.hotel_registration hr
        LEFT JOIN dbo.tinh_thanh tt ON hr.province_id = tt.id
        WHERE 1=1
      `;

      // Filter by status
      if (filters.status) {
        query += ` AND hr.status = @status`;
        request.input('status', sql.NVarChar, filters.status);
      }

      query += ` ORDER BY hr.created_at DESC`;

      const result = await request.query(query);
      return result.recordset;
    } catch (error) {
      console.error('❌ Error getting hotel registrations:', error);
      throw error;
    }
  }

  /**
   * Lấy đơn đăng ký theo ID
   */
  static async getById(id) {
    try {
      const pool = getPool();
      const request = pool.request();
      request.input('id', sql.Int, id);

      const query = `
        SELECT 
          hr.*,
          tt.ten as province_name
        FROM dbo.hotel_registration hr
        LEFT JOIN dbo.tinh_thanh tt ON hr.province_id = tt.id
        WHERE hr.id = @id
      `;

      const result = await request.query(query);
      return result.recordset[0] || null;
    } catch (error) {
      console.error('❌ Error getting hotel registration by ID:', error);
      throw error;
    }
  }

  /**
   * Lấy đơn đăng ký theo email
   */
  static async getByEmail(email) {
    try {
      const pool = getPool();
      const request = pool.request();
      request.input('email', sql.NVarChar, email);

      const query = `
        SELECT * FROM dbo.hotel_registration
        WHERE owner_email = @email
        ORDER BY created_at DESC
      `;

      const result = await request.query(query);
      return result.recordset;
    } catch (error) {
      console.error('❌ Error getting hotel registration by email:', error);
      throw error;
    }
  }

  /**
   * Cập nhật trạng thái đơn đăng ký
   */
  static async updateStatus(id, status, adminNote = null) {
    try {
      const pool = getPool();
      const request = pool.request();
      request.input('id', sql.Int, id);
      request.input('status', sql.NVarChar, status);
      request.input('admin_note', sql.NVarChar, adminNote);
      request.input('updated_at', sql.DateTime, new Date());

      const query = `
        UPDATE dbo.hotel_registration
        SET 
          status = @status,
          admin_note = @admin_note,
          updated_at = @updated_at,
          reviewed_at = CASE WHEN @status IN ('approved', 'rejected') THEN GETDATE() ELSE reviewed_at END
        WHERE id = @id
      `;

      await request.query(query);
      return true;
    } catch (error) {
      console.error('❌ Error updating hotel registration status:', error);
      throw error;
    }
  }

  /**
   * Xóa đơn đăng ký
   */
  static async delete(id) {
    try {
      const pool = getPool();
      const request = pool.request();
      request.input('id', sql.Int, id);

      await request.query('DELETE FROM dbo.hotel_registration WHERE id = @id');
      return true;
    } catch (error) {
      console.error('❌ Error deleting hotel registration:', error);
      throw error;
    }
  }

  /**
   * Cập nhật thông tin đơn đăng ký
   */
  static async update(id, updateData) {
    try {
      const pool = getPool();
      const request = pool.request();
      request.input('id', sql.Int, id);

      const fields = [];
      const allowedFields = [
        'owner_name', 'owner_phone', 'hotel_name', 'hotel_type',
        'address', 'province_id', 'district', 'latitude', 'longitude',
        'description', 'star_rating', 'tax_id', 'business_license'
      ];

      allowedFields.forEach(field => {
        if (updateData[field] !== undefined) {
          fields.push(`${field} = @${field}`);
          
          // Determine SQL type based on field
          if (field === 'province_id' || field === 'star_rating') {
            request.input(field, sql.Int, updateData[field]);
          } else if (field === 'latitude' || field === 'longitude') {
            request.input(field, sql.Decimal(10, 8), updateData[field]);
          } else {
            request.input(field, sql.NVarChar, updateData[field]);
          }
        }
      });

      if (fields.length === 0) {
        return false;
      }

      fields.push('updated_at = GETDATE()');

      const query = `
        UPDATE dbo.hotel_registration
        SET ${fields.join(', ')}
        WHERE id = @id
      `;

      await request.query(query);
      return true;
    } catch (error) {
      console.error('❌ Error updating hotel registration:', error);
      throw error;
    }
  }

  /**
   * Get all registrations with pagination and filters
   */
  static async findAll(options = {}) {
    try {
      const { page = 1, limit = 20, where = '', orderBy = 'created_at DESC' } = options;
      const offset = (page - 1) * limit;
      
      const { getPool } = require('../config/db');
      const pool = getPool();
      const request = pool.request();
      
      let query = `
        SELECT * FROM dbo.hotel_registration
        ${where ? `WHERE ${where}` : ''}
        ORDER BY ${orderBy}
        OFFSET @offset ROWS
        FETCH NEXT @limit ROWS ONLY
      `;
      
      request.input('offset', sql.Int, offset);
      request.input('limit', sql.Int, limit);
      
      const result = await request.query(query);
      return result.recordset;
    } catch (error) {
      console.error('❌ Error finding registrations:', error);
      throw error;
    }
  }

  /**
   * Count total registrations
   */
  static async count(whereClause = '') {
    try {
      const { getPool } = require('../config/db');
      const pool = getPool();
      const request = pool.request();
      
      const query = `
        SELECT COUNT(*) as total 
        FROM dbo.hotel_registration
        ${whereClause}
      `;
      
      const result = await request.query(query);
      return result.recordset[0].total;
    } catch (error) {
      console.error('❌ Error counting registrations:', error);
      throw error;
    }
  }

  /**
   * Find registration by ID
   */
  static async findById(id) {
    try {
      const { getPool } = require('../config/db');
      const pool = getPool();
      const request = pool.request();
      
      request.input('id', sql.Int, id);
      
      const query = `
        SELECT * FROM dbo.hotel_registration
        WHERE id = @id
      `;
      
      const result = await request.query(query);
      return result.recordset[0] || null;
    } catch (error) {
      console.error('❌ Error finding registration by ID:', error);
      throw error;
    }
  }
}

module.exports = HotelRegistration;

