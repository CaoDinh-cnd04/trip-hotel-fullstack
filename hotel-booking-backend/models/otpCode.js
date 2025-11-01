const BaseModel = require('./baseModel');

class OTPCode extends BaseModel {
  constructor() {
    super('otp_codes', 'id');
  }

  // Tạo mã OTP mới
  async createOTP(email, otpCode, expiresAt) {
    try {
      console.log('💾 Creating OTP:', {
        email: email.toLowerCase(),
        otp_code: otpCode,
        expires_at: expiresAt
      });
      
      // Xóa tất cả OTP cũ của email này
      await this.deleteByEmail(email);

      const data = {
        email: email.toLowerCase(),
        otp_code: otpCode,
        expires_at: expiresAt,
        is_used: 0,
        attempts: 0
      };

      const result = await this.create(data);
      console.log('✅ OTP created successfully:', result);
      return result;
    } catch (error) {
      console.error('❌ Error creating OTP:', error);
      throw error;
    }
  }

  // Tìm OTP theo email
  async findByEmail(email) {
    const query = `
      SELECT * FROM ${this.tableName} 
      WHERE email = @email 
      AND expires_at > GETUTCDATE() 
      AND is_used = 0
      ORDER BY created_at DESC
    `;
    
    try {
      const result = await this.executeQuery(query, { 
        email: email.toLowerCase()
      });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Tìm OTP theo email và mã
  async findByEmailAndCode(email, otpCode) {
    const query = `
      SELECT * FROM ${this.tableName} 
      WHERE email = @email 
      AND otp_code = @otp_code 
      AND expires_at > GETUTCDATE() 
      AND is_used = 0
    `;
    
    try {
      console.log('🔍 Executing OTP query:', {
        tableName: this.tableName,
        email: email.toLowerCase(),
        otp_code: otpCode,
        query
      });
      
      const result = await this.executeQuery(query, { 
        email: email.toLowerCase(), 
        otp_code: otpCode 
      });
      
      console.log('📦 Query result:', {
        found: result.recordset.length > 0,
        records: result.recordset
      });
      
      return result.recordset[0] || null;
    } catch (error) {
      console.error('❌ Query error:', error);
      throw error;
    }
  }

  // Xóa OTP theo email
  async deleteByEmail(email) {
    const query = `DELETE FROM ${this.tableName} WHERE email = @email`;
    try {
      await this.executeQuery(query, { email: email.toLowerCase() });
    } catch (error) {
      throw error;
    }
  }

  // Đánh dấu OTP đã sử dụng
  async markAsUsed(id) {
    const query = `
      UPDATE ${this.tableName} 
      SET is_used = 1
      WHERE id = @id
    `;
    try {
      await this.executeQuery(query, { id });
    } catch (error) {
      throw error;
    }
  }

  // Tăng số lần thử
  async incrementAttempts(id) {
    const query = `
      UPDATE ${this.tableName} 
      SET attempts = attempts + 1
      WHERE id = @id
    `;
    try {
      await this.executeQuery(query, { id });
    } catch (error) {
      throw error;
    }
  }

  // Kiểm tra số lần thử
  async getAttempts(id) {
    const query = `SELECT attempts FROM ${this.tableName} WHERE id = @id`;
    try {
      const result = await this.executeQuery(query, { id });
      return result.recordset[0]?.attempts || 0;
    } catch (error) {
      throw error;
    }
  }

  // Xóa tất cả OTP hết hạn
  async cleanExpired() {
    const query = `DELETE FROM ${this.tableName} WHERE expires_at < GETUTCDATE() AND is_used = 0`;
    try {
      const result = await this.executeQuery(query);
      return result.rowsAffected[0] || 0;
    } catch (error) {
      throw error;
    }
  }

  // Kiểm tra xem email có OTP chưa hết hạn không
  async hasActiveOTP(email) {
    const query = `
      SELECT COUNT(*) as count FROM ${this.tableName} 
      WHERE email = @email 
      AND expires_at > GETUTCDATE() 
      AND is_used = 0
    `;
    
    try {
      const result = await this.executeQuery(query, { email: email.toLowerCase() });
      return result.recordset[0].count > 0;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = new OTPCode();
