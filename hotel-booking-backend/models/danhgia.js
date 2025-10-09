const db = require('../config/db');

const DanhGia = {
  getAll: (callback) => {
    db.query('SELECT * FROM DANHGIA', callback);
  },
  getById: (id, callback) => {
    db.query('SELECT * FROM DANHGIA WHERE MA_DG = ?', [id], callback);
  },
  create: (data, callback) => {
    db.query('INSERT INTO DANHGIA SET ?', data, callback);
  },
  update: (id, data, callback) => {
    db.query('UPDATE DANHGIA SET ? WHERE MA_DG = ?', [data, id], callback);
  },
  delete: (id, callback) => {
    db.query('DELETE FROM DANHGIA WHERE MA_DG = ?', [id], callback);
  },
};

module.exports = DanhGia;