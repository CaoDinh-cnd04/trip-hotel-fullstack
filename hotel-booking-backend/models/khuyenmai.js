const db = require('../config/db');

const KhuyenMai = {
  getAll: (callback) => {
    db.query('SELECT * FROM KHUYENMAI', callback);
  },
  getById: (id, callback) => {
    db.query('SELECT * FROM KHUYENMAI WHERE MA_KM = ?', [id], callback);
  },
  create: (data, callback) => {
    db.query('INSERT INTO KHUYENMAI SET ?', data, callback);
  },
  update: (id, data, callback) => {
    db.query('UPDATE KHUYENMAI SET ? WHERE MA_KM = ?', [data, id], callback);
  },
  delete: (id, callback) => {
    db.query('DELETE FROM KHUYENMAI WHERE MA_KM = ?', [id], callback);
  },
};

module.exports = KhuyenMai;