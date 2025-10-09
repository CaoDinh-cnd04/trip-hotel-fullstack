const db = require('../config/db');

const MaGiamGia = {
  getAll: (callback) => {
    db.query('SELECT * FROM MAGIAMGIA', callback);
  },
  getById: (id, callback) => {
    db.query('SELECT * FROM MAGIAMGIA WHERE MA_MGG = ?', [id], callback);
  },
  create: (data, callback) => {
    db.query('INSERT INTO MAGIAMGIA SET ?', data, callback);
  },
  update: (id, data, callback) => {
    db.query('UPDATE MAGIAMGIA SET ? WHERE MA_MGG = ?', [data, id], callback);
  },
  delete: (id, callback) => {
    db.query('DELETE FROM MAGIAMGIA WHERE MA_MGG = ?', [id], callback);
  },
};

module.exports = MaGiamGia;