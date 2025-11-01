const { getPool, sql } = require('../config/db');

const MaGiamGia = {
  getAll: async (callback) => {
    try {
      const pool = getPool();
      const result = await pool.request().query('SELECT * FROM ma_giam_gia');
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
        .query('SELECT * FROM ma_giam_gia WHERE ma_mgg = @id');
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
        INSERT INTO ma_giam_gia (${Object.keys(data).join(', ')})
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
        UPDATE ma_giam_gia SET ${setClause} WHERE ma_mgg = @id
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
        .query('DELETE FROM ma_giam_gia WHERE ma_mgg = @id');
      callback(null, result);
    } catch (error) {
      callback(error, null);
    }
  },
};

module.exports = MaGiamGia;