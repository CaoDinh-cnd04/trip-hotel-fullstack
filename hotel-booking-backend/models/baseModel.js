// baseModel.js - Base model for SQL Server operations
const { sql } = require('../config/db');

class BaseModel {
  constructor(tableName, primaryKey = 'id') {
    // Add dbo. prefix if not already present
    this.tableName = tableName.startsWith('dbo.') ? tableName : `dbo.${tableName}`;
    this.primaryKey = primaryKey;
  }

  // Execute query with parameters
  async executeQuery(query, params = {}) {
    try {
      const { getPool } = require('../config/db');
      const pool = getPool();
      const request = pool.request();
      
      // Add parameters to request
      Object.keys(params).forEach(key => {
        const value = params[key];
        if (value !== null && value !== undefined && value !== '') {
          request.input(key, value);
        }
      });
      
      const result = await request.query(query);
      return result;
    } catch (error) {
      console.error('Database query error:', error);
      throw error;
    }
  }

  // Get all records with pagination and filtering
  async findAll(options = {}) {
    const { 
      page = 1, 
      limit = 10, 
      where = '', 
      orderBy = `${this.primaryKey} DESC`,
      includes = '*'
    } = options;
    
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT ${includes} 
      FROM ${this.tableName}
      ${where ? `WHERE ${where}` : ''}
      ORDER BY ${orderBy}
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `;
    
    const countQuery = `
      SELECT COUNT(*) as total 
      FROM ${this.tableName}
      ${where ? `WHERE ${where}` : ''}
    `;
    
    try {
      const [data, count] = await Promise.all([
        this.executeQuery(query, { offset, limit }),
        this.executeQuery(countQuery)
      ]);
      
      return {
        data: data.recordset,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count.recordset[0].total,
          totalPages: Math.ceil(count.recordset[0].total / limit)
        }
      };
    } catch (error) {
      throw error;
    }
  }

  // Find by ID
  async findById(id) {
    const query = `SELECT * FROM ${this.tableName} WHERE ${this.primaryKey} = @id`;
    try {
      const result = await this.executeQuery(query, { id });
      return result.recordset[0] || null;
    } catch (error) {
      throw error;
    }
  }

  // Create new record
  async create(data) {
    const columns = Object.keys(data);
    const values = columns.map(col => `@${col}`).join(', ');
    const columnList = columns.join(', ');
    
    const query = `
      INSERT INTO ${this.tableName} (${columnList})
      OUTPUT INSERTED.*
      VALUES (${values})
    `;
    
    try {
      const result = await this.executeQuery(query, data);
      return result.recordset[0];
    } catch (error) {
      throw error;
    }
  }

  // Update record
  async update(id, data) {
    const updates = Object.keys(data)
      .filter(key => key !== this.primaryKey)
      .map(key => `${key} = @${key}`)
      .join(', ');
    
    const query = `
      UPDATE ${this.tableName} 
      SET ${updates}, updated_at = GETDATE()
      OUTPUT INSERTED.*
      WHERE ${this.primaryKey} = @id
    `;
    
    const params = { ...data, id };
    
    try {
      const result = await this.executeQuery(query, params);
      return result.recordset[0];
    } catch (error) {
      throw error;
    }
  }

  // Delete record
  async delete(id) {
    const query = `DELETE FROM ${this.tableName} WHERE ${this.primaryKey} = @id`;
    try {
      const result = await this.executeQuery(query, { id });
      return result.rowsAffected[0] > 0;
    } catch (error) {
      throw error;
    }
  }

  // Soft delete (update trang_thai)
  async softDelete(id) {
    const query = `
      UPDATE ${this.tableName} 
      SET trang_thai = 0, updated_at = GETDATE()
      WHERE ${this.primaryKey} = @id
    `;
    try {
      const result = await this.executeQuery(query, { id });
      return result.rowsAffected[0] > 0;
    } catch (error) {
      throw error;
    }
  }

  // Search with LIKE operator
  async search(searchTerm, columns = ['ten'], options = {}) {
    const { page = 1, limit = 10, additionalWhere = '' } = options;
    const offset = (page - 1) * limit;
    
    const searchConditions = columns
      .map(col => `${col} LIKE @searchTerm`)
      .join(' OR ');
    
    const whereClause = additionalWhere 
      ? `(${searchConditions}) AND ${additionalWhere}`
      : searchConditions;
    
    const query = `
      SELECT * FROM ${this.tableName}
      WHERE ${whereClause}
      ORDER BY ${this.primaryKey} DESC
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `;
    
    const countQuery = `
      SELECT COUNT(*) as total FROM ${this.tableName}
      WHERE ${whereClause}
    `;
    
    const searchParam = `%${searchTerm}%`;
    
    try {
      const [data, count] = await Promise.all([
        this.executeQuery(query, { searchTerm: searchParam, offset, limit }),
        this.executeQuery(countQuery, { searchTerm: searchParam })
      ]);
      
      return {
        data: data.recordset,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count.recordset[0].total,
          totalPages: Math.ceil(count.recordset[0].total / limit)
        }
      };
    } catch (error) {
      throw error;
    }
  }

  // Execute custom query
  async customQuery(query, params = {}) {
    try {
      const result = await this.executeQuery(query, params);
      return result.recordset;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = BaseModel;