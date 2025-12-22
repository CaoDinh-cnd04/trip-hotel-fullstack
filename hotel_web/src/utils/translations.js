// Từ điển đa ngôn ngữ
export const translations = {
  vi: {
    // Header Navigation
    home: 'Trang chủ',
    hotels: 'Khách sạn',
    promotions: 'Khuyến mãi',
    booked: 'Đã đặt',
    favorites: 'Yêu thích',
    contact: 'Liên hệ',
    notifications: 'Thông báo',
    
    // Auth
    login: 'Đăng nhập',
    register: 'Đăng ký',
    logout: 'Đăng xuất',
    profile: 'Hồ sơ của tôi',
    myBookings: 'Đặt phòng của tôi',
    
    // Common
    search: 'Tìm kiếm',
    filter: 'Lọc',
    sort: 'Sắp xếp',
    price: 'Giá',
    location: 'Địa điểm',
    checkIn: 'Nhận phòng',
    checkOut: 'Trả phòng',
    guests: 'Khách',
    rooms: 'Phòng',
    night: 'đêm',
    nights: 'đêm',
    
    // Hotel
    hotelDetails: 'Chi tiết khách sạn',
    amenities: 'Tiện nghi',
    reviews: 'Đánh giá',
    availability: 'Tình trạng phòng',
    bookNow: 'Đặt ngay',
    pricePerNight: 'Giá/đêm',
    totalPrice: 'Tổng tiền',
    
    // Booking
    bookingConfirmation: 'Xác nhận đặt phòng',
    customerInfo: 'Thông tin khách hàng',
    fullName: 'Họ và tên',
    email: 'Email',
    phone: 'Số điện thoại',
    specialRequests: 'Yêu cầu đặc biệt',
    
    // Booking Status
    pending: 'Chờ xác nhận',
    confirmed: 'Đã xác nhận',
    cancelled: 'Đã hủy',
    completed: 'Hoàn thành',
    
    // Payment
    payment: 'Thanh toán',
    paymentMethod: 'Phương thức thanh toán',
    creditCard: 'Thẻ tín dụng',
    bankTransfer: 'Chuyển khoản',
    eWallet: 'Ví điện tử',
    paymentSuccess: 'Thanh toán thành công',
    paymentFailed: 'Thanh toán thất bại',
    
    // Notifications
    newBooking: 'Đặt phòng mới',
    bookingSuccess: 'Đặt phòng thành công',
    paymentReminder: 'Nhắc nhở thanh toán',
    checkInReminder: 'Nhắc nhở check-in',
    newPromotion: 'Khuyến mãi mới',
    markAllRead: 'Đánh dấu tất cả',
    viewAllNotifications: 'Xem tất cả thông báo',
    noNotifications: 'Không có thông báo nào',
    
    // Profile
    personalInfo: 'Thông tin cá nhân',
    changePassword: 'Đổi mật khẩu',
    avatar: 'Ảnh đại diện',
    birthDate: 'Ngày sinh',
    gender: 'Giới tính',
    male: 'Nam',
    female: 'Nữ',
    other: 'Khác',
    
    // Buttons
    save: 'Lưu',
    cancel: 'Hủy',
    edit: 'Chỉnh sửa',
    delete: 'Xóa',
    update: 'Cập nhật',
    confirm: 'Xác nhận',
    
    // Messages
    success: 'Thành công',
    error: 'Lỗi',
    warning: 'Cảnh báo',
    loading: 'Đang tải...',
    
    // Footer
    aboutUs: 'Về chúng tôi',
    termsOfService: 'Điều khoản dịch vụ',
    privacyPolicy: 'Chính sách bảo mật',
    
    // Search
    searchHotels: 'Tìm kiếm khách sạn',
    destination: 'Điểm đến',
    noResultsFound: 'Không tìm thấy kết quả nào',
    
    // Language
    language: 'Ngôn ngữ',
    vietnamese: 'Tiếng Việt',
    english: 'English',
    
    // HomePage
    heroTitle: 'Khám Phá Thế Giới Cùng',
    heroSubtitle: 'Đặt phòng khách sạn tốt nhất với giá ưu đãi nhất. Trải nghiệm dịch vụ đẳng cấp thế giới.',
    heroSearchPlaceholder: 'Tìm kiếm điểm đến...',
    heroSearchButton: 'Tìm kiếm khách sạn',
    heroDestination: 'Điểm đến',
    heroCheckin: 'Nhận phòng',
    heroCheckout: 'Trả phòng',
    heroGuests: 'Số khách',
    
    // Features
    featuresTitle: 'Tại sao chọn TripHotel?',
    feature1Title: 'Giá tốt nhất',
    feature1Desc: 'Cam kết giá tốt nhất thị trường với nhiều ưu đãi hấp dẫn',
    feature2Title: 'Dịch vụ 24/7',
    feature2Desc: 'Hỗ trợ khách hàng tận tình 24/7 mọi lúc mọi nơi',
    feature3Title: 'Đặt phòng dễ dàng',
    feature3Desc: 'Giao diện đơn giản, đặt phòng nhanh chóng chỉ với vài cú click',
    
    // Popular destinations
    popularDestinationsTitle: 'Điểm đến phổ biến',
    popularDestinationsSubtitle: 'Khám phá những địa điểm du lịch hàng đầu',
    
    // Profile Page
    updateProfile: 'Cập nhật thông tin',
    uploadAvatar: 'Tải ảnh đại diện',
    changeAvatar: 'Đổi ảnh đại diện',
    removeAvatar: 'Xóa ảnh đại diện',
    profileUpdated: 'Cập nhật thông tin thành công',
    fillRequiredInfo: 'Vui lòng điền đầy đủ thông tin bắt buộc',
    invalidBirthDate: 'Ngày sinh không hợp lệ',
    invalidEmail: 'Định dạng email không hợp lệ',
    invalidPhone: 'Số điện thoại phải có 10-11 chữ số',
    ageRestriction: 'Tuổi phải từ 13 trở lên',
    
    // Hotel Detail
    customerReviews: 'Đánh giá của khách hàng',
    reviews: 'đánh giá',
    allReviews: 'Tất cả đánh giá',
    averageRating: 'Điểm trung bình',
    basedOnReviews: 'dựa trên {count} đánh giá',
    roomsList: 'Danh sách phòng',
    filterRooms: 'Lọc phòng',
    roomType: 'Loại phòng',
    priceRange: 'Khoảng giá',
    allRoomTypes: 'Tất cả loại phòng',
    standardRoom: 'Phòng tiêu chuẩn',
    deluxeRoom: 'Phòng deluxe',
    suiteRoom: 'Phòng suite',
    available: 'Có sẵn',
    unavailable: 'Hết phòng',
    selectRoom: 'Chọn phòng',
    viewDetails: 'Xem chi tiết'
  },
  
  en: {
    // Header Navigation
    home: 'Home',
    hotels: 'Hotels',
    promotions: 'Promotions',
    booked: 'Bookings',
    favorites: 'Favorites',
    contact: 'Contact',
    notifications: 'Notifications',
    
    // Auth
    login: 'Login',
    register: 'Register',
    logout: 'Logout',
    profile: 'My Profile',
    myBookings: 'My Bookings',
    
    // Common
    search: 'Search',
    filter: 'Filter',
    sort: 'Sort',
    price: 'Price',
    location: 'Location',
    checkIn: 'Check-in',
    checkOut: 'Check-out',
    guests: 'Guests',
    rooms: 'Rooms',
    night: 'night',
    nights: 'nights',
    
    // Hotel
    hotelDetails: 'Hotel Details',
    amenities: 'Amenities',
    reviews: 'Reviews',
    availability: 'Availability',
    bookNow: 'Book Now',
    pricePerNight: 'Price/night',
    totalPrice: 'Total Price',
    
    // Booking
    bookingConfirmation: 'Booking Confirmation',
    customerInfo: 'Customer Information',
    fullName: 'Full Name',
    email: 'Email',
    phone: 'Phone Number',
    specialRequests: 'Special Requests',
    
    // Booking Status
    pending: 'Pending',
    confirmed: 'Confirmed',
    cancelled: 'Cancelled',
    completed: 'Completed',
    
    // Payment
    payment: 'Payment',
    paymentMethod: 'Payment Method',
    creditCard: 'Credit Card',
    bankTransfer: 'Bank Transfer',
    eWallet: 'E-Wallet',
    paymentSuccess: 'Payment Successful',
    paymentFailed: 'Payment Failed',
    
    // Notifications
    newBooking: 'New Booking',
    bookingSuccess: 'Booking Successful',
    paymentReminder: 'Payment Reminder',
    checkInReminder: 'Check-in Reminder',
    newPromotion: 'New Promotion',
    markAllRead: 'Mark All Read',
    viewAllNotifications: 'View All Notifications',
    noNotifications: 'No notifications',
    
    // Profile
    personalInfo: 'Personal Information',
    changePassword: 'Change Password',
    avatar: 'Avatar',
    birthDate: 'Birth Date',
    gender: 'Gender',
    male: 'Male',
    female: 'Female',
    other: 'Other',
    
    // Buttons
    save: 'Save',
    cancel: 'Cancel',
    edit: 'Edit',
    delete: 'Delete',
    update: 'Update',
    confirm: 'Confirm',
    
    // Messages
    success: 'Success',
    error: 'Error',
    warning: 'Warning',
    loading: 'Loading...',
    
    // Footer
    aboutUs: 'About Us',
    termsOfService: 'Terms of Service',
    privacyPolicy: 'Privacy Policy',
    
    // Search
    searchHotels: 'Search Hotels',
    destination: 'Destination',
    noResultsFound: 'No results found',
    
    // Language
    language: 'Language',
    vietnamese: 'Tiếng Việt',
    english: 'English',
    
    // HomePage
    heroTitle: 'Discover The World With',
    heroSubtitle: 'Book the best hotels at the best prices. Experience world-class service.',
    heroSearchPlaceholder: 'Search destinations...',
    heroSearchButton: 'Search Hotels',
    heroDestination: 'Destination',
    heroCheckin: 'Check-in',
    heroCheckout: 'Check-out',
    heroGuests: 'Guests',
    
    // Features
    featuresTitle: 'Why choose TripHotel?',
    feature1Title: 'Best Prices',
    feature1Desc: 'Guaranteed best market prices with attractive offers',
    feature2Title: '24/7 Service',
    feature2Desc: 'Dedicated customer support 24/7 anywhere, anytime',
    feature3Title: 'Easy Booking',
    feature3Desc: 'Simple interface, quick booking with just a few clicks',
    
    // Popular destinations
    popularDestinationsTitle: 'Popular Destinations',
    popularDestinationsSubtitle: 'Discover top travel destinations',
    
    // Profile Page
    updateProfile: 'Update Profile',
    uploadAvatar: 'Upload Avatar',
    changeAvatar: 'Change Avatar', 
    removeAvatar: 'Remove Avatar',
    profileUpdated: 'Profile updated successfully',
    fillRequiredInfo: 'Please fill in all required information',
    invalidBirthDate: 'Invalid birth date',
    invalidEmail: 'Invalid email format',
    invalidPhone: 'Phone number must have 10-11 digits',
    ageRestriction: 'Age must be 13 or older',
    
    // Hotel Detail
    customerReviews: 'Customer Reviews',
    reviews: 'reviews',
    allReviews: 'All Reviews',
    averageRating: 'Average Rating',
    basedOnReviews: 'based on {count} reviews',
    roomsList: 'Room List',
    filterRooms: 'Filter Rooms',
    roomType: 'Room Type',
    priceRange: 'Price Range',
    allRoomTypes: 'All Room Types',
    standardRoom: 'Standard Room',
    deluxeRoom: 'Deluxe Room',
    suiteRoom: 'Suite Room',
    available: 'Available',
    unavailable: 'Unavailable',
    selectRoom: 'Select Room',
    viewDetails: 'View Details'
  }
}

// Xuất translations để sử dụng trong hook