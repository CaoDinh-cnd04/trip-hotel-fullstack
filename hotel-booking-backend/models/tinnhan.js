const db = require('../config/db');

class TinNhan {
  static async findById(id) {
    return new Promise((resolve, reject) => {
      db.query('SELECT * FROM TINNHAN WHERE MA_TINNHAN = ?', [id], (err, results) => {
        if (err) return reject(err);
        resolve(results[0]);
      });
    });
  }

  static async create(tinnhan) {
    return new Promise((resolve, reject) => {
      db.query('INSERT INTO TINNHAN SET ?', tinnhan, (err, result) => {
        if (err) return reject(err);
        resolve(result.insertId);
      });
    });
  }

  static async update(id, tinnhan) {
    return new Promise((resolve, reject) => {
      db.query('UPDATE TINNHAN SET ? WHERE MA_TINNHAN = ?', [tinnhan, id], (err, result) => {
        if (err) return reject(err);
        resolve(result.affectedRows);
      });
    });
  }

  static async delete(id) {
    return new Promise((resolve, reject) => {
      db.query('DELETE FROM TINNHAN WHERE MA_TINNHAN = ?', [id], (err, result) => {
        if (err) return reject(err);
        resolve(result.affectedRows);
      });
    });
  }

  static async getAll() {
    return new Promise((resolve, reject) => {
      db.query('SELECT * FROM TINNHAN ORDER BY THOIGIAN DESC', (err, results) => {
        if (err) return reject(err);
        resolve(results);
      });
    });
  }
}

module.exports = TinNhan;