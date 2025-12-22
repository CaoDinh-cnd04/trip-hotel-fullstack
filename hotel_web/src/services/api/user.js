import axios from 'axios'
import toast from 'react-hot-toast'
import { API_BASE_URL, getSpecialRouteUrl } from '../../config/api'

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL || 'http://localhost:5000/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor
api.interceptors.response.use(
  (response) => {
    return response
  },
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('auth_token')
      window.location.href = '/login'
    }
    
    const message = error.response?.data?.message || 'Có lỗi xảy ra'
    toast.error(message)
    
    return Promise.reject(error)
  }
)

// Auth API
export const authAPI = {
  login: (credentials) => api.post('/v2/auth/login', credentials),
  register: (userData) => api.post('/v2/auth/register', userData),
  logout: () => api.post('/v2/auth/logout'),
  refreshToken: () => api.post('/v2/auth/refresh'),
  forgotPassword: (email) => api.post('/v2/auth/forgot-password', { email }),
  resetPassword: (token, password) => api.post('/v2/auth/reset-password', { token, password }),
  
  // OTP Login
  sendOTP: (email) => {
    const token = localStorage.getItem('auth_token')
    return axios.post(`${API_BASE_URL || 'http://localhost:5000/api'}/v2/otp/send-otp`, 
      { email },
      {
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      }
    )
  },
  verifyOTP: (email, otp) => {
    const token = localStorage.getItem('auth_token')
    return axios.post(`${API_BASE_URL || 'http://localhost:5000/api'}/v2/otp/verify-otp`, 
      { email, otp_code: otp },
      {
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      }
    )
  },
  
  // Social Login
  facebookLogin: (accessToken) => api.post('/v2/auth/facebook-login', { accessToken }),
  firebaseSocialLogin: (userData) => api.post('/v2/auth/firebase-social-login', userData),
}

// Hotels API
export const hotelsAPI = {
  getAll: (params) => api.get('/v2/khachsan', { params }),
  getById: (id) => api.get(`/v2/khachsan/${id}`),
  search: (searchParams) => api.post('/v2/khachsan/search', searchParams),
  getReviews: (hotelId) => api.get(`/v2/khachsan/${hotelId}/reviews`),
  addReview: (hotelId, review) => api.post(`/v2/khachsan/${hotelId}/reviews`, review),
  getFeatured: () => api.get('/v2/khachsan/featured'),
  getNearby: (lat, lng, radius) => api.get(`/v2/khachsan/nearby?lat=${lat}&lng=${lng}&radius=${radius}`),
}

// Rooms API
export const roomsAPI = {
  getByHotel: (hotelId) => api.get(`/v2/phong?ma_khach_san=${hotelId}`),
  getById: (id) => api.get(`/v2/phong/${id}`),
  checkAvailability: (data) => api.post('/v2/phong/check-availability', data),
  getRoomTypes: () => api.get('/v2/loaiphong'),
}

// Bookings API
export const bookingsAPI = {
  create: (bookingData) => api.post('/v2/phieudatphong', bookingData),
  getById: (id) => api.get(`/v2/phieudatphong/${id}`),
  getUserBookings: (userId) => api.get(`/v2/phieudatphong/user/${userId}`),
  cancel: (id) => api.patch(`/v2/phieudatphong/${id}/cancel`),
  update: (id, data) => api.patch(`/v2/phieudatphong/${id}`, data),
}

// User API
export const userAPI = {
  getProfile: () => api.get('/v2/nguoidung/profile'),
  updateProfile: (data) => api.patch('/v2/nguoidung/profile', data),
  changePassword: (data) => api.patch('/v2/nguoidung/change-password', data),
  getUserStats: () => api.get('/v2/nguoidung/my-stats'),
  getBookings: (params) => api.get('/v2/nguoidung/bookings', { params }),
  getFavorites: () => api.get('/v2/nguoidung/favorites'),
  addFavorite: (hotelId) => api.post('/v2/nguoidung/favorites', { hotelId }),
  removeFavorite: (hotelId) => api.delete(`/v2/nguoidung/favorites/${hotelId}`),
  getVipStatus: () => api.get('/v2/nguoidung/vip-status'),
  
  // Update email notification preference
  updateNotificationPreference: (enabled) => {
    const token = localStorage.getItem('auth_token') || localStorage.getItem('token')
    return axios.put(`${API_BASE_URL}/v2/nguoidung/email-notification-preference`, 
      { nhan_thong_bao_email: enabled },
      {
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      }
    )
  },
}

// Locations API
export const locationsAPI = {
  getCountries: () => api.get('/v2/quocgia'),
  getProvinces: (countryId) => api.get(`/v2/tinhthanh?quocgia_id=${countryId}`),
  getPositions: (provinceId) => api.get(`/v2/vitri?tinhthanh_id=${provinceId}`),
  searchLocations: (query) => api.get(`/v2/vitri/search?q=${query}`),
}

// Amenities API
export const amenitiesAPI = {
  getAll: () => api.get('/v2/tiennghi'),
  getByHotel: (hotelId) => api.get(`/v2/tiennghi/khachsan/${hotelId}`),
}

// Reviews API
export const reviewAPI = {
  getAll: (params) => api.get('/v2/danhgia', { params }),
  getById: (id) => api.get(`/v2/danhgia/${id}`),
  getByHotel: (hotelId) => api.get('/v2/danhgia', { params: { ma_khach_san: hotelId } }),
  getMyReviews: () => api.get('/v2/danhgia/my-reviews'),
  create: (data) => api.post('/v2/danhgia', data),
  update: (id, data) => api.put(`/v2/danhgia/${id}`, data),
  delete: (id) => api.delete(`/v2/danhgia/${id}`),
}

// Notifications API (for users)
export const notificationAPI = {
  getAll: (params = {}) => {
    const token = localStorage.getItem('auth_token') || localStorage.getItem('token')
    return axios.get(getSpecialRouteUrl('/api/notifications'), {
      params,
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
  },
  getUnreadCount: () => {
    const token = localStorage.getItem('auth_token') || localStorage.getItem('token')
    return axios.get(getSpecialRouteUrl('/api/notifications/unread-count'), {
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
  },
  markAsRead: (id) => {
    const token = localStorage.getItem('auth_token') || localStorage.getItem('token')
    return axios.post(getSpecialRouteUrl(`/api/notifications/${id}/read`), {}, {
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
  }
}

// Public API (không cần auth)
export const publicAPI = {
  getHotels: (params) => api.get('/public/hotels', { params }),
  getHotelById: (id) => api.get(`/public/hotels/${id}`),
  searchHotels: (params) => api.get('/public/search', { params }),
  getLocations: () => api.get('/public/locations'),
  getPromotions: () => api.get('/v2/khuyenmai'),
}

export default api