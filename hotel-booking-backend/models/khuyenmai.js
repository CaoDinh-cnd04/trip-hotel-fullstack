const { getPool, sql } = require('../config/db');

const KhuyenMai = {
  getAll: async (callback) => {
    try {
      const pool = getPool();
      const result = await pool.request().query('SELECT * FROM khuyen_mai');
      callback(null, result.recordset);
    } catch (error) {
      callback(error, null);
    }
  },
  getById: async (id, callback) => {
    try {
      const pool = getPool();
      const result = await pool.request()
        .input('id', sql.Int, id)
        .query('SELECT * FROM khuyen_mai WHERE id = @id');
      callback(null, result.recordset);
    } catch (error) {
      callback(error, null);
    }
  },
  create: async (data, callback) => {
    try {
      const pool = getPool();
      const request = pool.request();
      
      // Add input parameters
      Object.keys(data).forEach(key => {
        request.input(key, sql.VarChar, data[key]);
      });
      
      const result = await request.query(`
        INSERT INTO khuyen_mai (${Object.keys(data).join(', ')})
        VALUES (${Object.keys(data).map(key => `@${key}`).join(', ')})
      `);
      callback(null, result);
    } catch (error) {
      callback(error, null);
    }
  },
  update: async (id, data, callback) => {
    try {
      const pool = getPool();
      const request = pool.request().input('id', sql.Int, id);
      
      // Add input parameters - xử lý đúng kiểu dữ liệu
      Object.keys(data).forEach(key => {
        if (key === 'trang_thai') {
          // trang_thai là BIT, cần dùng sql.Bit
          const bitValue = data[key] === true || data[key] === 1 || data[key] === '1' ? 1 : 0;
          request.input(key, sql.Bit, bitValue);
        } else if (key === 'ngay_cap_nhat' || key === 'ngay_bat_dau' || key === 'ngay_ket_thuc' || key === 'created_at' || key === 'updated_at') {
          // Date fields
          request.input(key, sql.DateTime2, data[key]);
        } else if (typeof data[key] === 'number') {
          // Number fields
          request.input(key, sql.Decimal(18, 2), data[key]);
        } else {
          // String fields
          request.input(key, sql.NVarChar(sql.MAX), data[key]);
        }
      });
      
      const setClause = Object.keys(data).map(key => {
        if (key === 'trang_thai') {
          return `${key} = CAST(@${key} AS BIT)`;
        }
        return `${key} = @${key}`;
      }).join(', ');
      
      const result = await request.query(`
        UPDATE dbo.khuyen_mai SET ${setClause} WHERE id = @id
      `);
      callback(null, result);
    } catch (error) {
      callback(error, null);
    }
  },
  delete: async (id, callback) => {
    try {
      const pool = getPool();
      const result = await pool.request()
        .input('id', sql.Int, id)
        .query('DELETE FROM khuyen_mai WHERE id = @id');
      callback(null, result);
    } catch (error) {
      callback(error, null);
    }
  },
};

module.exports = KhuyenMai;