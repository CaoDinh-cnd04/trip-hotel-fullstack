import axios from 'axios'
import { API_BASE_URL } from '../../config/api'

// Create axios instance for hotel manager
const api = axios.create({
  baseURL: API_BASE_URL || 'http://localhost:5000/api',
  headers: {
    'Content-Type': 'application/json'
  },
  timeout: 10000
})

// Request interceptor - Add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token') || localStorage.getItem('token')
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
  (response) => response.data || response,
  (error) => {
    console.error('Hotel Manager API Error:', error)
    return Promise.reject(error)
  }
)

// Hotel Manager API
export const hotelManagerAPI = {
  // Dashboard
  getDashboardKpi: () => api.get('/v2/hotel-manager/dashboard'),
  
  // Hotel
  getAssignedHotel: () => api.get('/v2/hotel-manager/hotel'),
  updateHotel: (data) => api.put('/v2/hotel-manager/hotel', data),
  getHotelStats: () => api.get('/v2/hotel-manager/hotel/stats'),
  uploadHotelImage: (formData) => api.post('/v2/hotel-manager/hotel/image', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  deleteHotelImage: (imageId) => api.delete(`/v2/hotel-manager/hotel/images/${imageId}`),
  setMainHotelImage: (imageId) => api.put(`/v2/hotel-manager/hotel/images/${imageId}/set-main`),
  getAllAmenities: () => api.get('/v2/hotel-manager/amenities'),
  createAmenity: (data) => api.post('/v2/hotel-manager/amenities', data),
  getHotelAmenitiesWithPricing: () => api.get('/v2/hotel-manager/hotel/amenities'),
  updateAmenityPricing: (amenityId, data) => api.put(`/v2/hotel-manager/amenities/${amenityId}/pricing`, data),
  updateHotelAmenities: (amenities) => api.put('/v2/hotel-manager/hotel/amenities', { amenities }),
  uploadAmenityImage: (amenityId, formData) => api.post(`/v2/hotel-manager/amenities/${amenityId}/image`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  
  // Room Types
  getRoomTypes: () => api.get('/v2/hotel-manager/room-types'),
  
  // Rooms
  getHotelRooms: () => api.get('/v2/hotel-manager/hotel/rooms'),
  addRoom: (data) => api.post('/v2/hotel-manager/hotel/rooms', data),
  updateRoom: (id, data) => api.put(`/v2/hotel-manager/hotel/rooms/${id}`, data),
  updateRoomStatus: (id, data) => api.patch(`/v2/hotel-manager/hotel/rooms/${id}/status`, data),
  deleteRoom: (id) => api.delete(`/v2/hotel-manager/hotel/rooms/${id}`),
  uploadRoomImages: (id, formData) => api.post(`/v2/hotel-manager/hotel/rooms/${id}/images`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  
  // Bookings
  getHotelBookings: (params = {}) => api.get('/v2/hotel-manager/hotel/bookings', { params }),
  updateBookingStatus: (id, data) => api.put(`/v2/hotel-manager/hotel/bookings/${id}`, data),
  deleteBooking: (id) => api.delete(`/v2/hotel-manager/hotel/bookings/${id}`),
  
  // Reviews
  getHotelReviews: (params = {}) => api.get('/v2/hotel-manager/hotel/reviews', { params }),
  respondToReview: (id, response) => api.post(`/v2/hotel-manager/hotel/reviews/${id}/respond`, { phan_hoi: response }),
  reportReview: (id, data) => api.post(`/v2/hotel-manager/hotel/reviews/${id}/report`, data),
  
  // Promotions (Ưu đãi giảm giá)
  getMyPromotions: () => api.get('/promotion-offers/my-offers'),
  createPromotion: (data) => api.post('/promotion-offers', data),
  updatePromotion: (offerId, data) => api.put(`/promotion-offers/${offerId}/rooms`, data),
  deletePromotion: (offerId) => api.delete(`/promotion-offers/${offerId}`),
  togglePromotion: (offerId, isActive) => api.patch(`/promotion-offers/${offerId}/toggle`, { is_active: isActive }),
  submitForApproval: (offerId) => api.post(`/promotion-offers/${offerId}/submit-approval`),
  getActivePromotions: (hotelId) => api.get(`/promotion-offers/hotel/${hotelId}/active`),
  
  // Messages - Get customers who have booked
  getCustomers: () => api.get('/v2/hotel-manager/customers'),
  
  // Send notification to customer
  sendBookingNotification: (bookingId, data) => api.post(`/v2/hotel-manager/hotel/bookings/${bookingId}/notify`, data)
}

export default hotelManagerAPI

