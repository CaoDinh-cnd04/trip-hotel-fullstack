import axios from 'axios'
import { API_BASE_URL, API_ROOT_URL, getSpecialRouteUrl } from '../../config/api'

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL || 'http://localhost:5000/api',
  headers: {
    'Content-Type': 'application/json'
  },
  timeout: 10000,
  withCredentials: false
})

// Request interceptor - Add auth token if available
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('admin_token') || localStorage.getItem('token') || localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor - Handle errors
api.interceptors.response.use(
  (response) => {
    // Handle different response formats
    if (response.data) {
      return response.data
    }
    return response
  },
  (error) => {
    console.error('API Error:', {
      message: error.message,
      response: error.response?.data,
      status: error.response?.status,
      config: {
        url: error.config?.url,
        method: error.config?.method
      }
    })

    if (error.code === 'ECONNABORTED') {
      return Promise.reject(new Error('Request timeout - Server không phản hồi'))
    }

    if (error.response) {
      // Server responded with error
      const status = error.response.status
      let message = error.response.data?.message || error.response.data?.error || 'Có lỗi xảy ra'
      
      if (status === 401) {
        message = 'Chưa đăng nhập hoặc token hết hạn'
      } else if (status === 403) {
        message = 'Không có quyền truy cập'
      } else if (status === 404) {
        message = 'Không tìm thấy dữ liệu'
      } else if (status >= 500) {
        message = 'Lỗi server - Vui lòng thử lại sau'
      }
      
      return Promise.reject(new Error(message))
    } else if (error.request) {
      // Request made but no response - likely CORS or server down
      const isNetworkError = error.message.includes('Network Error') || 
                            error.message.includes('Failed to fetch') ||
                            error.code === 'ERR_NETWORK'
      
      if (isNetworkError) {
        return Promise.reject(new Error('Không thể kết nối đến server. Kiểm tra:\n- Backend có đang chạy tại http://localhost:5000?\n- CORS đã được cấu hình đúng chưa?'))
      }
      
      return Promise.reject(new Error('Không thể kết nối đến server'))
    } else {
      // Something else happened
      return Promise.reject(new Error(error.message || 'Có lỗi xảy ra'))
    }
  }
)

// API functions
export const hotelAPI = {
  getAll: (params = {}) => {
    // Add admin_view=true for admin to see all hotels
    return api.get('/v2/khachsan', { params: { ...params, admin_view: 'true' } });
  },
  getById: (id) => api.get(`/v2/khachsan/${id}`),
  create: (data) => api.post('/v2/khachsan', data),
  update: (id, data) => api.put(`/v2/khachsan/${id}`, data),
  toggleStatus: (id, action) => api.put(`/v2/khachsan/${id}/toggle-status`, { action }),
  delete: (id) => api.delete(`/v2/khachsan/${id}`)
}

export const roomAPI = {
  getAll: (params = {}) => api.get('/v2/phong', { params }),
  getById: (id) => api.get(`/v2/phong/${id}`),
  create: (data) => api.post('/v2/phong', data),
  update: (id, data) => api.put(`/v2/phong/${id}`, data),
  delete: (id) => api.delete(`/v2/phong/${id}`)
}

export const userAPI = {
  getAll: (params = {}) => api.get('/v2/nguoidung', { params }),
  getById: (id, params = {}) => api.get(`/v2/nguoidung/${id}`, { params }),
  getStats: () => api.get('/v2/nguoidung/stats'),
  update: (id, data) => api.put(`/v2/nguoidung/${id}`, data),
  delete: (id) => api.delete(`/v2/nguoidung/${id}`),
  approve: (id) => api.put(`/v2/nguoidung/${id}/approve`),
  block: (id) => api.put(`/v2/nguoidung/${id}/block`),
  resetPassword: (id, newPassword) => api.put(`/v2/nguoidung/${id}/reset-password`, { new_password: newPassword }),
  updateRole: (id, role) => api.put(`/v2/nguoidung/${id}/role`, { chuc_vu: role }),
  getActivityLogs: (id, params = {}) => api.get(`/v2/nguoidung/${id}/activity-logs`, { params })
}

export const bookingAPI = {
  getAll: (params = {}) => api.get('/v2/phieudatphong', { params }),
  getById: (id) => api.get(`/v2/phieudatphong/${id}`),
  getStats: () => api.get('/v2/phieudatphong/stats'),
  updateStatus: (id, status) => api.put(`/v2/phieudatphong/${id}`, { trang_thai: status }),
  cancel: (id) => api.post(`/v2/phieudatphong/${id}/cancel`)
}

export const discountAPI = {
  getAll: (params = {}) => api.get('/v2/magiamgia', { params }),
  getById: (id) => api.get(`/v2/magiamgia/${id}`),
  getByCode: (code) => api.get(`/v2/magiamgia/${code}/details`),
  getActive: () => api.get('/v2/magiamgia/active'),
  create: (data) => api.post('/v2/magiamgia', data),
  update: (id, data) => api.put(`/v2/magiamgia/${id}`, data),
  delete: (id) => api.delete(`/v2/magiamgia/${id}`),
  toggle: (id) => api.put(`/v2/magiamgia/${id}/toggle`),
  validate: (data) => api.post('/v2/magiamgia/validate', data)
}

export const reviewAPI = {
  getByHotel: (hotelId) => api.get('/v2/danhgia', { params: { ma_khach_san: hotelId } }),
  getAll: (params = {}) => api.get('/v2/danhgia', { params }),
  // Admin endpoints
  getAllAdmin: (params = {}) => api.get('/v2/danhgia', { params }),
  getById: (id) => api.get(`/v2/danhgia/${id}`),
  delete: (id) => api.delete(`/v2/danhgia/${id}`),
  getStats: () => api.get('/v2/danhgia/stats').catch(() => ({ data: null })),
  getHotels: () => api.get('/v2/khachsan').then(res => ({ data: res.data || res || [] })),
  updateStatus: (id, status) => api.put(`/v2/danhgia/${id}/status`, { trang_thai: status }),
  respond: (id, response) => api.post(`/v2/danhgia/${id}/respond`, { response })
}

export const statsAPI = {
  getOverview: () => api.get('/v2/admin/dashboard/kpi').catch(() => {
    // Fallback if admin stats endpoint doesn't exist
    return Promise.resolve({ data: null })
  }),
  getUserStats: () => api.get('/v2/admin/stats/users').catch(() => {
    return Promise.resolve({ data: null })
  }),
  getHotelStats: () => api.get('/v2/admin/stats/hotels').catch(() => {
    return Promise.resolve({ data: null })
  }),
  getBookingStats: () => api.get('/v2/admin/stats/bookings').catch(() => {
    return Promise.resolve({ data: null })
  })
}

// Hotel Registration API
export const hotelRegistrationAPI = {
  getAll: (params = {}) => api.get('/v2/hotel-registration/admin/all', { params }),
  getById: (id) => api.get(`/v2/hotel-registration/${id}`),
  updateStatus: (id, status, adminNote) => api.put(`/v2/hotel-registration/${id}/status`, { 
    status, 
    admin_note: adminNote 
  }),
  approve: (id, adminNote) => api.put(`/v2/hotel-registration/${id}/status`, { 
    status: 'approved', 
    admin_note: adminNote 
  }),
  reject: (id, adminNote) => api.put(`/v2/hotel-registration/${id}/status`, { 
    status: 'rejected', 
    admin_note: adminNote 
  }),
  delete: (id) => api.delete(`/v2/hotel-registration/${id}`)
}

// Notification API - mounted at /api/notifications (not /api/v2/notifications)
export const notificationAPI = {
  getAll: (params = {}) => {
    const token = localStorage.getItem('admin_token') || localStorage.getItem('token') || localStorage.getItem('auth_token')
    return axios.get(getSpecialRouteUrl('/api/notifications/all'), {
      params,
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
  },
  create: (data) => {
    const token = localStorage.getItem('admin_token') || localStorage.getItem('token') || localStorage.getItem('auth_token')
    return axios.post(getSpecialRouteUrl('/api/notifications'), data, {
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
  },
  update: (id, data) => {
    const token = localStorage.getItem('admin_token') || localStorage.getItem('token') || localStorage.getItem('auth_token')
    return axios.put(getSpecialRouteUrl(`/api/notifications/${id}`), data, {
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
  },
  delete: (id) => {
    const token = localStorage.getItem('admin_token') || localStorage.getItem('token') || localStorage.getItem('auth_token')
    return axios.delete(getSpecialRouteUrl(`/api/notifications/${id}`), {
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
  }
}

// Promotion API
export const promotionAPI = {
  getAll: (params = {}) => api.get('/v2/khuyenmai', { params }),
  getById: (id) => api.get(`/v2/khuyenmai/${id}`),
  create: (data) => api.post('/v2/khuyenmai', data),
  update: (id, data) => api.put(`/v2/khuyenmai/${id}`, data),
  delete: (id) => api.delete(`/v2/khuyenmai/${id}`),
  toggle: (id) => api.put(`/v2/khuyenmai/${id}/toggle`),
  getActive: () => api.get('/v2/khuyenmai/active')
}

// Promotion Offers API (for admin to manage hotel manager promotions)
export const promotionOfferAPI = {
  getAll: (params = {}) => api.get('/promotion-offers/admin/all', { params }),
  approve: (offerId, adminNote) => api.put(`/promotion-offers/admin/${offerId}/approve`, { admin_note: adminNote }),
  reject: (offerId, adminNote) => api.put(`/promotion-offers/admin/${offerId}/reject`, { admin_note: adminNote })
}

// Feedback API - Backend route is mounted at /api/v2/feedback
export const feedbackAPI = {
  getAll: (params = {}) => api.get('/v2/feedback', { params }),
  getById: (id) => api.get(`/v2/feedback/${id}`),
  getStatistics: () => api.get('/v2/feedback/statistics'),
  updateStatus: (id, status) => api.put(`/v2/feedback/${id}/status`, { status }),
  respond: (id, response) => api.put(`/v2/feedback/${id}/respond`, { admin_response: response }),
  delete: (id) => api.delete(`/v2/feedback/${id}`)
}

export const reportAPI = {
  getSystemStatistics: (params = {}) => api.get('/v2/admin/stats/system', { params })
}

export default api

