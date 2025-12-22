// models/nguoidung.js - User model for new database schema
const BaseModel = require('./baseModel');
const bcrypt = require('bcryptjs');

class NguoiDung extends BaseModel {
  constructor() {
    super('nguoi_dung', 'id');
  }

  // Override findById to only return active users
  async findById(id) {
    const query = `SELECT * FROM ${this.tableName} WHERE ${this.primaryKey} = @id AND trang_thai = CAST(1 AS BIT)`;
    try {
      const result = await this.executeQuery(query, { id });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Find user by email (active only)
  async findByEmail(email) {
    const query = `SELECT * FROM ${this.tableName} WHERE email = @email AND trang_thai = CAST(1 AS BIT)`;
    try {
      const result = await this.executeQuery(query, { email });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Find user by email (any status - for OTP login)
  async findByEmailAny(email) {
    const query = `SELECT * FROM ${this.tableName} WHERE email = @email`;
    try {
      const result = await this.executeQuery(query, { email });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Find user by phone
  async findByPhone(sdt) {
    const query = `SELECT * FROM ${this.tableName} WHERE sdt = @sdt AND trang_thai = CAST(1 AS BIT)`;
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
        trang_thai: 1,
        nhan_thong_bao_email: userData.nhan_thong_bao_email !== undefined ? (userData.nhan_thong_bao_email ? 1 : 0) : 1 // Default to enabled
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
    const whereClause = `chuc_vu = @role AND trang_thai = CAST(1 AS BIT)`;
    
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
      where: 'trang_thai = CAST(1 AS BIT)'
    });
  }

  // Search users
  async searchUsers(searchTerm, options = {}) {
    const searchColumns = ['ho_ten', 'email', 'sdt'];
    const additionalWhere = 'trang_thai = CAST(1 AS BIT)';
    
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
        SUM(CASE WHEN trang_thai = CAST(1 AS BIT) THEN 1 ELSE 0 END) as dang_hoat_dong,
        SUM(CASE WHEN chuc_vu = N'Admin' THEN 1 ELSE 0 END) as admin,
        SUM(CASE WHEN chuc_vu = N'HotelManager' THEN 1 ELSE 0 END) as quan_ly_khach_san,
        SUM(CASE WHEN chuc_vu = N'User' THEN 1 ELSE 0 END) as khach_hang,
        SUM(CASE WHEN last_login >= DATEADD(day, -30, GETDATE()) THEN 1 ELSE 0 END) as hoat_dong_30_ngay
      FROM ${this.tableName}
    `;
    
    try {
      const result = await this.executeQuery(query);
      return result.recordset[0] || {};
    } catch (error) {
      throw error;
    }
  }

  // Get personal stats for a specific user
  async getMyStats(userId) {
    const query = `
      SELECT 
        COALESCE(SUM(CASE WHEN pdp.trang_thai = N'Đã xác nhận' THEN 1 ELSE 0 END), 0) as totalBookings,
        COALESCE(COUNT(DISTINCT yth.ma_khach_san), 0) as favoriteHotels,
        COALESCE(SUM(CASE WHEN pdp.trang_thai = N'Đã xác nhận' THEN pdp.tong_tien ELSE 0 END), 0) as totalSpent,
        COALESCE(nd.diem_tich_luy, 0) as points
      FROM nguoi_dung nd
      LEFT JOIN phieu_dat_phong pdp ON nd.id = pdp.ma_nguoi_dung
      LEFT JOIN yeu_thich_khach_san yth ON nd.id = yth.ma_nguoi_dung
      WHERE nd.id = @userId
      GROUP BY nd.id, nd.diem_tich_luy
    `;
    
    try {
      const result = await this.executeQuery(query, { userId });
      const stats = result.recordset[0] || {
        totalBookings: 0,
        favoriteHotels: 0,
        totalSpent: 0,
        points: 0
      };
      return stats;
    } catch (error) {
      console.error('Get my stats error:', error);
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
    const query = `SELECT * FROM ${this.tableName} WHERE facebook_id = @facebookId AND trang_thai = CAST(1 AS BIT)`;
    try {
      const result = await this.executeQuery(query, { facebookId });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Find user by Google ID
  async findByGoogleId(googleId) {
    const query = `SELECT * FROM ${this.tableName} WHERE google_id = @googleId AND trang_thai = CAST(1 AS BIT)`;
    try {
      const result = await this.executeQuery(query, { googleId });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Find user by Firebase UID
  async findByFirebaseUid(firebaseUid) {
    const query = `SELECT * FROM ${this.tableName} WHERE firebase_uid = @firebaseUid AND trang_thai = CAST(1 AS BIT)`;
    try {
      const result = await this.executeQuery(query, { firebaseUid });
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
        nhan_thong_bao_email: userData.nhan_thong_bao_email !== undefined ? (userData.nhan_thong_bao_email ? 1 : 0) : 1, // Default to enabled
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

  // Create user with Firebase data (Google/Facebook)
  async createWithFirebase(userData) {
    try {
      // Check if Firebase UID already exists
      if (userData.firebase_uid) {
        const existingFirebaseUser = await this.findByFirebaseUid(userData.firebase_uid);
        if (existingFirebaseUser) {
          throw new Error('Tài khoản Firebase đã được liên kết với tài khoản khác');
        }
      }

      // Check if Google ID already exists
      if (userData.google_id) {
        const existingGoogleUser = await this.findByGoogleId(userData.google_id);
        if (existingGoogleUser) {
          throw new Error('Tài khoản Google đã được liên kết với tài khoản khác');
        }
      }

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

      // Prepare user data for Firebase registration
      const newUser = {
        ho_ten: userData.ho_ten,
        email: userData.email,
        mat_khau: 'firebase_user_no_password', // Firebase users don't have passwords
        sdt: userData.sdt || '0000000000', // Default phone for Firebase users
        firebase_uid: userData.firebase_uid,
        anh_dai_dien: userData.anh_dai_dien,
        chuc_vu: userData.chuc_vu || 'User',
        trang_thai: userData.trang_thai || 1,
        nhan_thong_bao_email: userData.nhan_thong_bao_email !== undefined ? (userData.nhan_thong_bao_email ? 1 : 0) : 1, // Default to enabled
        ngay_dang_ky: new Date(),
        created_at: new Date()
      };

      // Only add google_id and facebook_id if they have values (avoid SQL parameter errors)
      if (userData.google_id) {
        newUser.google_id = userData.google_id;
      }
      if (userData.facebook_id) {
        newUser.facebook_id = userData.facebook_id;
      }

      // Insert user
      const result = await this.create(newUser);
      return await this.findById(result.insertId || result.id);
    } catch (error) {
      throw error;
    }
  }

  // Sync Firebase user to database
  async syncFirebaseUser(userData) {
    try {
      // First check by Firebase UID (ignore trang_thai for sync)
      let existingUser = null;
      if (userData.firebase_uid) {
        const query = `SELECT * FROM ${this.tableName} WHERE firebase_uid = @firebaseUid`;
        const result = await this.executeQuery(query, { firebaseUid: userData.firebase_uid });
        existingUser = result.recordset[0] || null;
      }

      // If not found by Firebase UID, check by email (ignore trang_thai for sync)
      if (!existingUser && userData.email) {
        const query = `SELECT * FROM ${this.tableName} WHERE email = @email`;
        const result = await this.executeQuery(query, { email: userData.email });
        existingUser = result.recordset[0] || null;
      }

      if (existingUser) {
        // Update existing user with Firebase data
        const updateData = {};
        
        // Only add fields that have values to avoid SQL parameter errors
        if (userData.firebase_uid) {
          updateData.firebase_uid = userData.firebase_uid;
        }
        if (userData.google_id) {
          updateData.google_id = userData.google_id;
        }
        if (userData.facebook_id) {
          updateData.facebook_id = userData.facebook_id;
        }
        if (userData.anh_dai_dien) {
          updateData.anh_dai_dien = userData.anh_dai_dien;
        }
        
        // If account was inactive, activate it when they login via Firebase
        if (!existingUser.trang_thai) {
          console.log(`🔓 Activating inactive account: ${existingUser.email}`);
          updateData.trang_thai = 1;
        }

        // Only update if there's data to update
        if (Object.keys(updateData).length > 0) {
          await this.update(existingUser.id, updateData);
        }
        
        return await this.findById(existingUser.id);
      } else {
        // Create new user
        return await this.createWithFirebase(userData);
      }
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

  // Get user statistics for admin dashboard
  async getStats() {
    try {
      const query = `
        SELECT 
          COUNT(*) as totalUsers,
          SUM(CASE WHEN trang_thai = CAST(1 AS BIT) THEN 1 ELSE 0 END) as activeUsers,
          SUM(CASE WHEN COALESCE(created_at, ngay_dang_ky, GETDATE()) >= DATEADD(month, -1, GETDATE()) THEN 1 ELSE 0 END) as newUsersThisMonth
        FROM ${this.tableName}
      `;
      
      const result = await this.executeQuery(query);
      const stats = result.recordset[0] || {};
      
      // Get role distribution
      const roleQuery = `
        SELECT 
          chuc_vu,
          COUNT(*) as count
        FROM ${this.tableName}
        WHERE chuc_vu IS NOT NULL
        GROUP BY chuc_vu
      `;
      
      const roleResult = await this.executeQuery(roleQuery);
      const roleDistribution = roleResult.recordset.map(row => ({
        role: row.chuc_vu,
        count: parseInt(row.count) || 0
      }));
      
      // Convert SQL Server types to JavaScript numbers
      return {
        totalUsers: parseInt(stats.totalUsers) || 0,
        activeUsers: parseInt(stats.activeUsers) || 0,
        newUsersThisMonth: parseInt(stats.newUsersThisMonth) || 0,
        roleDistribution,
        monthlyGrowth: 0 // Placeholder - can be calculated later
      };
    } catch (error) {
      console.error('Get user stats error:', error);
      throw error;
    }
  }

  // Count total users
  async count() {
    try {
      const query = `SELECT COUNT(*) as total FROM ${this.tableName}`;
      const result = await this.executeQuery(query);
      return result.recordset[0].total;
    } catch (error) {
      console.error('Count users error:', error);
      throw error;
    }
  }

  // ✅ NEW: Update user role (for hotel registration approval)
  async updateRole(userId, newRole) {
    try {
      const query = `
        UPDATE ${this.tableName} 
        SET chuc_vu = @newRole, updated_at = GETDATE()
        WHERE id = @userId
      `;
      await this.executeQuery(query, { userId, newRole });
      console.log(`✅ Updated user ${userId} role to: ${newRole}`);
      return true;
    } catch (error) {
      console.error('Update user role error:', error);
      throw error;
    }
  }
}

module.exports = NguoiDung;