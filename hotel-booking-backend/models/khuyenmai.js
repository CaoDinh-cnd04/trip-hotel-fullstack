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
      
      // Add input parameters
      Object.keys(data).forEach(key => {
        request.input(key, sql.VarChar, data[key]);
      });
      
      const setClause = Object.keys(data).map(key => `${key} = @${key}`).join(', ');
      const result = await request.query(`
        UPDATE khuyen_mai SET ${setClause} WHERE id = @id
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