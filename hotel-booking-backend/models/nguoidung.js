// models/nguoidung.js - User model for new database schema
const BaseModel = require('./baseModel');
const bcrypt = require('bcryptjs');

class NguoiDung extends BaseModel {
  constructor() {
    super('nguoi_dung', 'id');
  }

  // Find user by email
  async findByEmail(email) {
    const query = `SELECT * FROM ${this.tableName} WHERE email = @email AND trang_thai = 1`;
    try {
      const result = await this.executeQuery(query, { email });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Find user by phone
  async findByPhone(sdt) {
    const query = `SELECT * FROM ${this.tableName} WHERE sdt = @sdt AND trang_thai = 1`;
    try {
      const result = await this.executeQuery(query, { sdt });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Create new user with password hashing
  async createUser(userData) {
    try {
      // Check if email exists
      const existingUser = await this.findByEmail(userData.email);
      if (existingUser) {
        throw new Error('Email đã tồn tại trong hệ thống');
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(userData.mat_khau, 10);
      
      // Prepare user data
      const newUser = {
        ho_ten: userData.ho_ten,
        email: userData.email,
        mat_khau: hashedPassword,
        sdt: userData.sdt,
        gioi_tinh: userData.gioi_tinh || 'Khác',
        chuc_vu: userData.chuc_vu || 'User',
        anh_dai_dien: userData.anh_dai_dien || '/images/users/default.jpg',
        trang_thai: 1
      };
      
      // Only add ngay_sinh if it's provided
      if (userData.ngay_sinh) {
        newUser.ngay_sinh = userData.ngay_sinh;
      }

      return await this.create(newUser);
    } catch (error) {
      throw error;
    }
  }

  // Update user profile
  async updateProfile(id, profileData) {
    try {
      // Remove sensitive fields that shouldn't be updated via profile
      const { mat_khau, chuc_vu, trang_thai, ...updateData } = profileData;
      
      return await this.update(id, updateData);
    } catch (error) {
      throw error;
    }
  }

  // Change password
  async changePassword(id, oldPassword, newPassword) {
    try {
      const user = await this.findById(id);
      if (!user) {
        throw new Error('Người dùng không tồn tại');
      }

      // Verify old password
      const isMatch = await bcrypt.compare(oldPassword, user.mat_khau);
      if (!isMatch) {
        throw new Error('Mật khẩu cũ không chính xác');
      }

      // Hash new password
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      
      return await this.update(id, { mat_khau: hashedPassword });
    } catch (error) {
      throw error;
    }
  }

  // Update last login
  async updateLastLogin(id) {
    try {
      const query = `
        UPDATE ${this.tableName} 
        SET last_login = GETDATE(), updated_at = GETDATE()
        WHERE id = @id
      `;
      await this.executeQuery(query, { id });
    } catch (error) {
      throw error;
    }
  }

  // Get users with role filter
  async getUsersByRole(role, options = {}) {
    const whereClause = `chuc_vu = @role AND trang_thai = 1`;
    
    return await this.findAll({
      ...options,
      where: whereClause
    });
  }

  // Get hotel managers
  async getHotelManagers(options = {}) {
    return await this.getUsersByRole('HotelManager', options);
  }

  // Get active users
  async getActiveUsers(options = {}) {
    return await this.findAll({
      ...options,
      where: 'trang_thai = 1'
    });
  }

  // Search users
  async searchUsers(searchTerm, options = {}) {
    const searchColumns = ['ho_ten', 'email', 'sdt'];
    const additionalWhere = 'trang_thai = 1';
    
    return await this.search(searchTerm, searchColumns, {
      ...options,
      additionalWhere
    });
  }

  // Get user statistics
  async getUserStats() {
    const query = `
      SELECT 
        COUNT(*) as tong_so_nguoi_dung,
        SUM(CASE WHEN trang_thai = 1 THEN 1 ELSE 0 END) as dang_hoat_dong,
        SUM(CASE WHEN chuc_vu = 'Admin' THEN 1 ELSE 0 END) as admin,
        SUM(CASE WHEN chuc_vu = 'HotelManager' THEN 1 ELSE 0 END) as quan_ly_khach_san,
        SUM(CASE WHEN chuc_vu = 'User' THEN 1 ELSE 0 END) as khach_hang,
        SUM(CASE WHEN last_login >= DATEADD(day, -30, GETDATE()) THEN 1 ELSE 0 END) as hoat_dong_30_ngay
      FROM ${this.tableName}
    `;
    
    try {
      const result = await this.executeQuery(query);
      return result.recordset[0];
    } catch (error) {
      throw error;
    }
  }

  // Activate/Deactivate user
  async toggleUserStatus(id) {
    try {
      const user = await this.findById(id);
      if (!user) {
        throw new Error('Người dùng không tồn tại');
      }

      const newStatus = user.trang_thai ? 0 : 1;
      return await this.update(id, { trang_thai: newStatus });
    } catch (error) {
      throw error;
    }
  }

  // Find user by Facebook ID
  async findByFacebookId(facebookId) {
    const query = `SELECT * FROM ${this.tableName} WHERE facebook_id = @facebookId AND trang_thai = 1`;
    try {
      const result = await this.executeQuery(query, { facebookId });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Update Facebook ID for existing user
  async updateFacebookId(userId, facebookId) {
    const query = `UPDATE ${this.tableName} SET facebook_id = @facebookId WHERE id = @userId`;
    try {
      await this.executeQuery(query, { userId, facebookId });
      return true;
    } catch (error) {
      throw error;
    }
  }

  // Create user with Facebook data
  async createWithFacebook(userData) {
    try {
      // Check if Facebook ID already exists
      if (userData.facebook_id) {
        const existingFacebookUser = await this.findByFacebookId(userData.facebook_id);
        if (existingFacebookUser) {
          throw new Error('Tài khoản Facebook đã được liên kết với tài khoản khác');
        }
      }

      // Check if email exists (if provided)
      if (userData.email) {
        const existingUser = await this.findByEmail(userData.email);
        if (existingUser) {
          throw new Error('Email đã tồn tại trong hệ thống');
        }
      }

      // Prepare user data for Facebook registration
      const newUser = {
        ho_ten: userData.ho_ten,
        email: userData.email,
        facebook_id: userData.facebook_id,
        hinh_anh: userData.hinh_anh,
        chuc_vu: userData.chuc_vu || 'khach_hang',
        trang_thai: userData.trang_thai || 1,
        ngay_tao: new Date(),
        ngay_cap_nhat: new Date()
      };

      // Insert user
      const result = await this.create(newUser);
      return await this.findById(result.insertId || result.id);
    } catch (error) {
      throw error;
    }
  }

  // Verify password for login
  async verifyPassword(email, password) {
    try {
      const user = await this.findByEmail(email);
      if (!user) {
        return { success: false, message: 'Email không tồn tại trong hệ thống' };
      }

      if (!user.trang_thai) {
        return { success: false, message: 'Tài khoản đã bị khóa' };
      }

      const isMatch = await bcrypt.compare(password, user.mat_khau);
      if (!isMatch) {
        return { success: false, message: 'Mật khẩu không chính xác' };
      }

      // Update last login
      await this.updateLastLogin(user.id);

      // Remove password from response
      const { mat_khau, ...userResponse } = user;
      
      return { 
        success: true, 
        user: userResponse 
      };
    } catch (error) {
      throw error;
    }
  }
}

module.exports = new NguoiDung();