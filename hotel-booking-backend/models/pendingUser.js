const BaseModel = require('./baseModel');

class PendingUser extends BaseModel {
  constructor() {
    super('pending_users', 'id');
  }

  // Tạo pending user
  async createPendingUser(email, userData) {
    try {
      // Xóa pending user cũ của email này
      await this.deleteByEmail(email);

      const data = {
        email: email.toLowerCase(),
        user_data: JSON.stringify(userData)
      };

      return await this.create(data);
    } catch (error) {
      throw error;
    }
  }

  // Lấy pending user theo email
  async findByEmail(email) {
    const query = `SELECT * FROM ${this.tableName} WHERE email = @email`;
    try {
      const result = await this.executeQuery(query, { email: email.toLowerCase() });
      const user = result.recordset[0];
      if (user && user.user_data) {
        user.user_data = JSON.parse(user.user_data);
      }
      return user;
    } catch (error) {
      throw error;
    }
  }

  // Xóa pending user theo email
  async deleteByEmail(email) {
    const query = `DELETE FROM ${this.tableName} WHERE email = @email`;
    try {
      await this.executeQuery(query, { email: email.toLowerCase() });
    } catch (error) {
      throw error;
    }
  }

  // Xóa tất cả pending users cũ (hơn 10 phút)
  async cleanExpired() {
    const query = `DELETE FROM ${this.tableName} WHERE created_at < DATEADD(MINUTE, -10, GETDATE())`;
    try {
      const result = await this.executeQuery(query);
      return result.rowsAffected[0] || 0;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = new PendingUser();
