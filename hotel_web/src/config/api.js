// API Configuration
// Backend server runs on port 5000 by default
// Can be overridden with VITE_API_BASE_URL environment variable

// Base URL for API requests
// Format: http://localhost:5000/api (includes /api prefix)
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000/api'

// Base URL without /api prefix (for special routes like /feedback, /notifications)
export const API_ROOT_URL = import.meta.env.VITE_API_ROOT_URL || 'http://localhost:5000'

// Images base URL
export const IMAGES_BASE_URL = import.meta.env.VITE_IMAGES_BASE_URL || 'http://localhost:5000/images'

// API Endpoints - V2 (Preferred)
export const API_ENDPOINTS = {
  // Authentication
  auth: {
    login: '/v2/auth/login',
    register: '/v2/auth/register',
    logout: '/v2/auth/logout',
    refresh: '/v2/auth/refresh',
    forgotPassword: '/v2/auth/forgot-password',
    resetPassword: '/v2/auth/reset-password',
    verifyEmail: '/v2/auth/verify-email'
  },

  // OTP
  otp: {
    send: '/v2/otp/send',
    verify: '/v2/otp/verify'
  },

  // Hotels
  hotels: '/v2/khachsan',
  hotelsLegacy: '/khachsan',
  hotelsSearch: '/v2/khachsan/search',
  
  // Rooms
  rooms: '/v2/phong',
  roomsLegacy: '/phong',
  roomsByHotel: '/v2/phong/khachsan',
  roomInventory: '/v2/inventory',
  
  // Users
  users: '/v2/nguoidung',
  usersLegacy: '/nguoidung',
  usersStats: '/v2/nguoidung/stats',
  
  // Bookings
  bookings: '/v2/phieudatphong',
  bookingsLegacy: '/phieudatphg',
  bookingsStats: '/v2/phieudatphong/stats',
  
  // Discounts / Vouchers
  discounts: '/v2/magiamgia',
  discountsLegacy: '/magiamgia',
  
  // Promotions
  promotions: '/v2/khuyenmai',
  promotionsLegacy: '/khuyenmai',
  promotionsActive: '/v2/khuyenmai/active',
  
  // Reviews
  reviews: '/v2/danhgia',
  reviewsLegacy: '/danhgia',
  reviewsStats: '/v2/danhgia/stats',
  
  // Admin
  admin: {
    stats: '/v2/admin/stats',
    dashboard: '/v2/admin/dashboard'
  },
  
  // Hotel Manager
  hotelManager: {
    dashboard: '/v2/hotel-manager/dashboard',
    hotel: '/v2/hotel-manager/hotel',
    rooms: '/v2/hotel-manager/hotel/rooms',
    bookings: '/v2/hotel-manager/hotel/bookings',
    reviews: '/v2/hotel-manager/hotel/reviews'
  },
  
  // Hotel Registration
  hotelRegistration: {
    all: '/v2/hotel-registration/admin/all',
    byId: '/v2/hotel-registration',
    updateStatus: '/v2/hotel-registration',
    approve: '/v2/hotel-registration',
    reject: '/v2/hotel-registration'
  },
  
  // Countries, Provinces, Locations
  countries: '/v2/quocgia',
  provinces: '/v2/tinhthanh',
  locations: '/v2/vitri',
  
  // Room Types
  roomTypes: '/v2/loaiphong',
  
  // Amenities
  amenities: '/v2/tiennghi',
  
  // Payment
  payment: {
    vnpay: '/v2/vnpay',
    createPayment: '/v2/vnpay/create-payment',
    return: '/api/payment/vnpay-return',
    ipn: '/api/payment/vnpay-ipn'
  },
  
  // Messages
  messages: '/v2/tinnhan',
  
  // Profiles
  profiles: '/v2/hoso',
  
  // Public API
  public: '/api/public',
  
  // Promotion Offers (Hotel Manager)
  promotionOffers: '/api/promotion-offers',
  
  // Stats
  stats: '/v2/admin/stats'
}

// Special Routes (not under /api/v2)
// These routes are mounted at different paths in the backend
export const SPECIAL_ROUTES = {
  // Feedback - mounted at root level: /feedback
  feedback: {
    base: '/feedback',
    getAll: '/feedback',
    getById: '/feedback',
    statistics: '/feedback/statistics',
    updateStatus: '/feedback',
    respond: '/feedback',
    delete: '/feedback'
  },
  
  // Notifications - mounted at /api/notifications (not /api/v2/notifications)
  notifications: {
    base: '/api/notifications',
    getAll: '/api/notifications/all',
    getById: '/api/notifications',
    create: '/api/notifications',
    update: '/api/notifications',
    delete: '/api/notifications',
    markAsRead: '/api/notifications',
    unreadCount: '/api/notifications/unread-count'
  },
  
  // Chat Sync
  chatSync: '/api/chat-sync',
  
  // Room Status
  roomStatus: '/api/room-status',
  
  // Admin Roles
  adminRoles: '/api/admin/roles',
  
  // User API (not v2)
  user: {
    base: '/api/user',
    profile: '/api/user/profile',
    vip: '/api/user/vip'
  },
  
  // Hotel Owner
  hotelOwner: '/api/hotel-owner'
}

// Helper function to get full URL for special routes
export const getSpecialRouteUrl = (route) => {
  if (route.startsWith('/api/')) {
    // Route already includes /api, use API_ROOT_URL
    return `${API_ROOT_URL}${route}`
  } else {
    // Route doesn't include /api, use API_ROOT_URL directly
    return `${API_ROOT_URL}${route}`
  }
}

// Helper function to get full URL for V2 API routes
export const getApiUrl = (endpoint) => {
  // If endpoint already starts with /api, use API_ROOT_URL
  if (endpoint.startsWith('/api/')) {
    return `${API_ROOT_URL}${endpoint}`
  }
  // Otherwise, use API_BASE_URL (which includes /api)
  return `${API_BASE_URL}${endpoint}`
}

// Helper function to get image URL (similar to mobile app's ImageUrlHelper)
export const getImageUrl = (imagePath) => {
  if (!imagePath || imagePath === 'null' || imagePath === 'undefined' || imagePath.trim() === '') {
    return getDefaultImageUrl()
  }
  
  // If already a full URL, return as is
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  
  // If path starts with /, use it directly with API_ROOT_URL
  if (imagePath.startsWith('/')) {
    return `${API_ROOT_URL}${imagePath}`
  }
  
  // Otherwise, add /images/ prefix for static images
  return `${API_ROOT_URL}/images/${imagePath}`
}

// Helper functions for specific image types (matching mobile app logic)
export const getHotelImageUrl = (imagePath) => {
  if (!imagePath || imagePath === 'null' || imagePath === 'undefined' || imagePath.trim() === '') {
    return getDefaultHotelImageUrl()
  }
  
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  
  // For hotel images, they are usually in /images/hotels/
  if (imagePath.startsWith('/')) {
    return `${API_ROOT_URL}${imagePath}`
  }
  
  return `${API_ROOT_URL}/images/hotels/${imagePath}`
}

export const getRoomImageUrl = (imagePath) => {
  if (!imagePath || imagePath === 'null' || imagePath === 'undefined' || imagePath.trim() === '') {
    return getDefaultRoomImageUrl()
  }
  
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  
  // For room images, they are usually in /images/rooms/
  if (imagePath.startsWith('/')) {
    return `${API_ROOT_URL}${imagePath}`
  }
  
  return `${API_ROOT_URL}/images/rooms/${imagePath}`
}

export const getLocationImageUrl = (imagePath) => {
  if (!imagePath || imagePath === 'null' || imagePath === 'undefined' || imagePath.trim() === '') {
    return getDefaultLocationImageUrl()
  }
  
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  
  // For location images, they are usually in /images/locations/
  if (imagePath.startsWith('/')) {
    return `${API_ROOT_URL}${imagePath}`
  }
  
  return `${API_ROOT_URL}/images/locations/${imagePath}`
}

export const getProvinceImageUrl = (imagePath) => {
  if (!imagePath || imagePath === 'null' || imagePath === 'undefined' || imagePath.trim() === '') {
    return getDefaultProvinceImageUrl()
  }
  
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  
  // For province images, they are usually in /images/provinces/
  if (imagePath.startsWith('/')) {
    return `${API_ROOT_URL}${imagePath}`
  }
  
  return `${API_ROOT_URL}/images/provinces/${imagePath}`
}

export const getCountryImageUrl = (imagePath) => {
  if (!imagePath || imagePath === 'null' || imagePath === 'undefined' || imagePath.trim() === '') {
    return getDefaultCountryImageUrl()
  }
  
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  
  // For country images, they are usually in /images/countries/
  if (imagePath.startsWith('/')) {
    return `${API_ROOT_URL}${imagePath}`
  }
  
  return `${API_ROOT_URL}/images/countries/${imagePath}`
}

// Default image URLs (matching mobile app)
export const getDefaultImageUrl = () => {
  return `${API_ROOT_URL}/images/Defaut.jpg`
}

export const getDefaultHotelImageUrl = () => {
  return `${API_ROOT_URL}/images/Defaut.jpg`
}

export const getDefaultRoomImageUrl = () => {
  return `${API_ROOT_URL}/images/Defaut.jpg`
}

export const getDefaultLocationImageUrl = () => {
  return `${API_ROOT_URL}/images/Defaut.jpg`
}

export const getDefaultProvinceImageUrl = () => {
  return `${API_ROOT_URL}/images/Defaut.jpg`
}

export const getDefaultCountryImageUrl = () => {
  return `${API_ROOT_URL}/images/Defaut.jpg`
}

// Helper for hero banner
export const getHeroBannerUrl = () => {
  return `${API_ROOT_URL}/images/hero-banner.jpg`
}

// Helper for logo
export const getLogoUrl = () => {
  return `${API_ROOT_URL}/images/logo.png`
}

// Export default API_BASE_URL for backward compatibility
export default API_BASE_URL
