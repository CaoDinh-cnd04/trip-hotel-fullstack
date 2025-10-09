const db = require('../config/db');

const HoSo = {
  getAll: (callback) => {
    db.query('SELECT * FROM HOSO', callback);
  },
  getById: (id, callback) => {
    db.query('SELECT * FROM HOSO WHERE MA_HS = ?', [id], callback);
  },
  create: (data, callback) => {
    db.query('INSERT INTO HOSO SET ?', data, callback);
  },
  update: (id, data, callback) => {
    db.query('UPDATE HOSO SET ? WHERE MA_HS = ?', [data, id], callback);
  },
  delete: (id, callback) => {
    db.query('DELETE FROM HOSO WHERE MA_HS = ?', [id], callback);
  },
};

module.exports = HoSo;