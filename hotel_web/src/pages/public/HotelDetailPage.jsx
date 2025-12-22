import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Container, Row, Col, Card, Button, Form, Badge, Carousel, Modal, Spinner } from 'react-bootstrap'
import { motion } from 'framer-motion'
import { 
  Star, 
  MapPin, 
  Wifi, 
  Car, 
  Coffee, 
  Dumbbell, 
  ArrowLeft,
  Heart,
  Share2,
  Users,
  Calendar,
  CalendarDays,
  Phone,
  Mail,
  UserCheck,
  CreditCard,
  Shield,
  Clock,
  Smartphone,
  Building2,
  CheckCircle,
  Sparkles
} from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import { useFavoritesStore } from '../../stores/favoritesStore'
import { useBookingsStore } from '../../stores/bookingsStore'
import { hotelsAPI } from '../../services/api/user'
import DiscountCodeInput from '../../components/common/DiscountCodeInput'
import DateRangePicker from '../../components/common/DateRangePicker'
import HotelMap from '../../components/common/HotelMap'
import { paymentService } from '../../services/payment/paymentService'
import toast from 'react-hot-toast'

const HotelDetailPage = () => {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuthStore()
  const isAuthenticated = () => useAuthStore.getState().isAuthenticated()
  const { favorites, toggleFavorite } = useFavoritesStore()
  const { addBooking } = useBookingsStore()

  // State management
  const [hotel, setHotel] = useState(null)
  const [rooms, setRooms] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  
  // Booking states
  const [selectedRoom, setSelectedRoom] = useState(null)
  const [checkInDate, setCheckInDate] = useState('')
  const [checkOutDate, setCheckOutDate] = useState('')
  const [guests, setGuests] = useState({ adults: 2, children: 0 })
  const [totalPrice, setTotalPrice] = useState(0)
  const [discountData, setDiscountData] = useState(null)
  
  // Modal states
  const [showBookingModal, setShowBookingModal] = useState(false)
  const [showPaymentModal, setShowPaymentModal] = useState(false)
  const [showGalleryModal, setShowGalleryModal] = useState(false)
  const [selectedImageIndex, setSelectedImageIndex] = useState(0)
  
  // Contact form states
  const [contactForm, setContactForm] = useState({
    name: '',
    email: '',
    phone: '',
    message: ''
  })
  
  // Processing states
  const [bookingProcessing, setBookingProcessing] = useState(false)
  
  // Load hotel details
  useEffect(() => {
    const fetchHotelDetails = async () => {
      if (!id) return
      
      try {
        setLoading(true)
        setError(null)
        
        // Load hotel details
        const hotelResponse = await hotelsAPI.getById(id)
        if (hotelResponse.data.success) {
          setHotel(hotelResponse.data.data)
        } else {
          throw new Error(hotelResponse.data.message || 'Không tìm thấy khách sạn')
        }
        
        // Load rooms for this hotel (if API supports it)
        try {
          // Note: Assuming there's an endpoint for rooms by hotel ID
          // If not available, we'll create sample rooms or skip this
          const roomsResponse = await fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000/api'}/v2/phong/khachsan/${id}`)
          if (roomsResponse.ok) {
            const roomsData = await roomsResponse.json()
            if (roomsData.success) {
              setRooms(roomsData.data || [])
            }
          }
        } catch (roomsError) {
          console.log('Rooms API not available, using basic room info')
          // Create basic room types if rooms API is not available
          setRooms([
            {
              id: 1,
              ten_loai_phong: 'Phòng Standard',
              gia: hotel?.gia_thap_nhat || 1500000,
              mo_ta: 'Phòng tiêu chuẩn với đầy đủ tiện nghi',
              hinh_anh: hotel?.hinh_anh,
              tien_nghi: ['Wifi miễn phí', 'Điều hòa', 'TV', 'Minibar']
            },
            {
              id: 2,
              ten_loai_phong: 'Phòng Deluxe',
              gia: (hotel?.gia_thap_nhat || 1500000) * 1.5,
              mo_ta: 'Phòng cao cấp với view đẹp',
              hinh_anh: hotel?.hinh_anh,
              tien_nghi: ['Wifi miễn phí', 'Điều hòa', 'TV', 'Minibar', 'Ban công']
            }
          ])
        }
        
      } catch (error) {
        console.error('Error loading hotel details:', error)
        setError(error.message)
        toast.error('Không thể tải thông tin khách sạn')
      } finally {
        setLoading(false)
      }
    }

    fetchHotelDetails()
  }, [id])

  // Set default dates
  useEffect(() => {
    const today = new Date()
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)
    
    setCheckInDate(today.toISOString().split('T')[0])
    setCheckOutDate(tomorrow.toISOString().split('T')[0])
  }, [])

  // Calculate total price
  useEffect(() => {
    if (selectedRoom && checkInDate && checkOutDate) {
      const checkin = new Date(checkInDate)
      const checkout = new Date(checkOutDate)
      const nights = Math.ceil((checkout - checkin) / (1000 * 60 * 60 * 24))
      
      const basePrice = selectedRoom.gia * nights
      const discountAmount = discountData?.discountAmount || 0
      setTotalPrice(Math.max(0, basePrice - discountAmount))
    }
  }, [selectedRoom, checkInDate, checkOutDate, discountData])

  // Handle room selection and booking - Navigate to booking page (like mobile app)
  const handleRoomSelect = (room) => {
    // Navigate to booking page with hotel and room info
    navigate(`/booking?hotelId=${hotel.id}&roomId=${room.id}`, {
      state: {
        hotel,
        room,
        checkInDate: checkInDate || new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        checkOutDate: checkOutDate || new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString().split('T')[0],
        guests
      }
    })
  }

  const handleBookingSubmit = async () => {
    if (!isAuthenticated) {
      toast.error('Vui lòng đăng nhập để đặt phòng')
      navigate('/login')
      return
    }

    if (!selectedRoom || !checkInDate || !checkOutDate) {
      toast.error('Vui lòng chọn đầy đủ thông tin')
      return
    }

    try {
      setBookingProcessing(true)
      
      const bookingData = {
        hotelId: hotel.id,
        hotelName: hotel.ten_khach_san,
        roomId: selectedRoom.id,
        roomType: selectedRoom.ten_loai_phong,
        checkIn: checkInDate,
        checkOut: checkOutDate,
        guests: guests,
        totalPrice: totalPrice,
        discountCode: discountData?.code || null,
        status: 'pending'
      }
      
      // Add to local booking store
      addBooking(bookingData)
      
      // Close modals
      setShowBookingModal(false)
      setShowPaymentModal(true)
      
      toast.success('Đặt phòng thành công!')
      
    } catch (error) {
      console.error('Booking error:', error)
      toast.error('Có lỗi xảy ra khi đặt phòng')
    } finally {
      setBookingProcessing(false)
    }
  }

  const handlePayment = async (paymentMethod) => {
    try {
      // Process payment
      const result = await paymentService.processPayment({
        amount: totalPrice,
        method: paymentMethod,
        bookingId: Date.now().toString()
      })
      
      if (result.success) {
        toast.success('Thanh toán thành công!')
        setShowPaymentModal(false)
        navigate('/bookings')
      }
    } catch (error) {
      toast.error('Thanh toán thất bại')
    }
  }

  // Handle contact form
  const handleContactSubmit = (e) => {
    e.preventDefault()
    toast.success('Đã gửi liên hệ thành công!')
    setContactForm({ name: '', email: '', phone: '', message: '' })
  }

  // Utility functions
  const formatPrice = (price) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(price)
  }

  const renderStars = (rating) => {
    const stars = []
    const fullStars = Math.floor(rating)
    const hasHalfStar = rating % 1 !== 0
    
    for (let i = 0; i < fullStars; i++) {
      stars.push(<Star key={i} size={16} className="fill-yellow-400 text-yellow-400" />)
    }
    
    if (hasHalfStar) {
      stars.push(<Star key="half" size={16} className="fill-yellow-400 text-yellow-400" style={{ clipPath: 'inset(0 50% 0 0)' }} />)
    }
    
    const remainingStars = 5 - Math.ceil(rating)
    for (let i = 0; i < remainingStars; i++) {
      stars.push(<Star key={`empty-${i}`} size={16} className="text-gray-300" />)
    }
    
    return stars
  }

  const handleDiscountApply = (discount) => {
    setDiscountData(discount)
    toast.success(`Áp dụng mã giảm giá thành công! Giảm ${formatPrice(discount.discountAmount)}`)
  }

  const isFavorite = hotel ? favorites.includes(hotel.id) : false
  
  if (loading) {
    return (
      <Container className="py-5">
        <div className="text-center">
          <Spinner animation="border" variant="primary" />
          <p className="mt-3">Đang tải thông tin khách sạn...</p>
        </div>
      </Container>
    )
  }

  if (error || !hotel) {
    return (
      <Container className="py-5">
        <div className="text-center">
          <h3>Không tìm thấy khách sạn</h3>
          <p className="text-muted">{error || 'Khách sạn không tồn tại hoặc đã bị xóa'}</p>
          <Button variant="primary" onClick={() => navigate('/hotels')}>
            Quay lại danh sách khách sạn
          </Button>
        </div>
      </Container>
    )
  }

  return (
    <div className="hotel-detail-page">
      {/* Header Section */}
      <Container fluid className="p-0">
        <div className="position-relative">
          <img 
            src={hotel.hinh_anh || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80'} 
            alt={hotel.ten_khach_san}
            className="w-100"
            style={{ height: '400px', objectFit: 'cover' }}
          />
          <div className="position-absolute top-0 start-0 w-100 h-100 bg-dark bg-opacity-25"></div>
          <div className="position-absolute top-50 start-50 translate-middle text-white text-center">
            <motion.h1 
              className="display-4 fw-bold mb-3"
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8 }}
            >
              {hotel.ten_khach_san}
            </motion.h1>
            <motion.p 
              className="lead mb-4"
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.2 }}
            >
              <MapPin className="me-2" size={20} />
              {hotel.dia_chi}
            </motion.p>
          </div>
          
          {/* Back button */}
          <Button
            variant="light"
            className="position-absolute top-0 start-0 m-3"
            onClick={() => navigate(-1)}
          >
            <ArrowLeft size={20} className="me-2" />
            Quay lại
          </Button>
          
          {/* Favorite button */}
          <Button
            variant={isFavorite ? "danger" : "light"}
            className="position-absolute top-0 end-0 m-3"
            onClick={() => toggleFavorite(hotel.id)}
          >
            <Heart size={20} className={isFavorite ? "fill-white" : ""} />
          </Button>
        </div>
      </Container>

      <Container className="py-5">
        <Row>
          <Col lg={8}>
            {/* Hotel Info */}
            <Card className="mb-4">
              <Card.Body>
                <Row>
                  <Col md={8}>
                    <div className="d-flex align-items-center mb-3">
                      {Array.from({ length: hotel.so_sao || 5 }).map((_, i) => (
                        <Star key={i} size={20} className="text-warning fill-warning me-1" />
                      ))}
                      <Badge bg="primary" className="ms-3">{hotel.so_sao} sao</Badge>
                    </div>
                    
                    <div className="d-flex align-items-center mb-3">
                      {renderStars(hotel.danh_gia || 4.5)}
                      <span className="ms-2 fw-bold">{hotel.danh_gia || 4.5}</span>
                      <span className="ms-2 text-muted">({hotel.so_luong_danh_gia || 0} đánh giá)</span>
                    </div>
                    
                    <p className="text-muted mb-3">
                      {hotel.mo_ta || 'Khách sạn tuyệt vời với dịch vụ chất lượng cao và vị trí thuận lợi.'}
                    </p>
                  </Col>
                  <Col md={4} className="text-end">
                    <div className="price-display">
                      <span className="text-muted">Giá từ</span>
                      <div className="h3 text-primary fw-bold">
                        {formatPrice(hotel.gia_thap_nhat)}
                      </div>
                      <small className="text-muted">/ đêm</small>
                    </div>
                  </Col>
                </Row>
              </Card.Body>
            </Card>

            {/* Room Types */}
            <Card className="mb-4">
              <Card.Header>
                <h5 className="mb-0">Loại phòng có sẵn</h5>
              </Card.Header>
              <Card.Body>
                {rooms.length > 0 ? (
                  <Row>
                    {rooms.map((room) => (
                      <Col md={6} key={room.id} className="mb-4">
                        <Card className="h-100 shadow-sm">
                          <Card.Img 
                            variant="top" 
                            src={room.hinh_anh || hotel.hinh_anh || 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'}
                            style={{ height: '200px', objectFit: 'cover' }}
                          />
                          <Card.Body className="d-flex flex-column">
                            <Card.Title>{room.ten_loai_phong}</Card.Title>
                            <Card.Text className="text-muted flex-grow-1">
                              {room.mo_ta}
                            </Card.Text>
                            <div className="mt-auto">
                              <div className="d-flex justify-content-between align-items-center mb-3">
                                <span className="h5 text-primary mb-0">
                                  {formatPrice(room.gia)}
                                </span>
                                <small className="text-muted">/ đêm</small>
                              </div>
                              <Button 
                                variant="primary" 
                                className="w-100"
                                onClick={() => handleRoomSelect(room)}
                              >
                                Chọn phòng
                              </Button>
                            </div>
                          </Card.Body>
                        </Card>
                      </Col>
                    ))}
                  </Row>
                ) : (
                  <div className="text-center py-5">
                    <p className="text-muted">Không có thông tin phòng</p>
                    <Button 
                      variant="primary"
                      onClick={() => handleRoomSelect({
                        id: 1,
                        ten_loai_phong: 'Phòng Standard',
                        gia: hotel.gia_thap_nhat,
                        mo_ta: 'Phòng tiêu chuẩn với đầy đủ tiện nghi',
                        hinh_anh: hotel.hinh_anh
                      })}
                    >
                      Đặt phòng ngay
                    </Button>
                  </div>
                )}
              </Card.Body>
            </Card>

            {/* Description */}
            <Card className="mb-4">
              <Card.Header>
                <h5 className="mb-0">Mô tả chi tiết</h5>
              </Card.Header>
              <Card.Body>
                <p>{hotel.mo_ta || 'Thông tin chi tiết về khách sạn sẽ được cập nhật sớm.'}</p>
              </Card.Body>
            </Card>

            {/* Reviews placeholder */}
            <Card className="mb-4">
              <Card.Header>
                <h5 className="mb-0">Đánh giá từ khách hàng</h5>
              </Card.Header>
              <Card.Body>
                <div className="text-center py-5 text-muted">
                  <p>Đánh giá từ khách hàng sẽ được hiển thị khi có dữ liệu từ API</p>
                </div>
              </Card.Body>
            </Card>

            {/* Hotel Map */}
            <Card className="mb-4">
              <Card.Header>
                <h5 className="mb-0">Vị trí khách sạn</h5>
              </Card.Header>
              <Card.Body>
                <HotelMap hotel={hotel} />
              </Card.Body>
            </Card>
          </Col>

          <Col lg={4}>
            {/* Contact Form */}
            <Card className="mb-4">
              <Card.Header>
                <h5 className="mb-0">Liên hệ khách sạn</h5>
              </Card.Header>
              <Card.Body>
                <Form onSubmit={handleContactSubmit}>
                  <Form.Group className="mb-3">
                    <Form.Control
                      type="text"
                      placeholder="Họ tên"
                      value={contactForm.name}
                      onChange={(e) => setContactForm({...contactForm, name: e.target.value})}
                      required
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Control
                      type="email"
                      placeholder="Email"
                      value={contactForm.email}
                      onChange={(e) => setContactForm({...contactForm, email: e.target.value})}
                      required
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Control
                      type="tel"
                      placeholder="Số điện thoại"
                      value={contactForm.phone}
                      onChange={(e) => setContactForm({...contactForm, phone: e.target.value})}
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Control
                      as="textarea"
                      rows={3}
                      placeholder="Tin nhắn"
                      value={contactForm.message}
                      onChange={(e) => setContactForm({...contactForm, message: e.target.value})}
                      required
                    />
                  </Form.Group>
                  <Button type="submit" variant="primary" className="w-100">
                    Gửi liên hệ
                  </Button>
                </Form>
              </Card.Body>
            </Card>

            {/* Quick Info */}
            <Card>
              <Card.Header>
                <h5 className="mb-0">Thông tin nhanh</h5>
              </Card.Header>
              <Card.Body>
                <div className="d-flex align-items-center mb-3">
                  <MapPin className="me-2 text-primary" size={20} />
                  <span>{hotel.dia_chi}</span>
                </div>
                <div className="d-flex align-items-center mb-3">
                  <Phone className="me-2 text-primary" size={20} />
                  <span>Liên hệ qua form bên trên</span>
                </div>
                <div className="d-flex align-items-center mb-3">
                  <CheckCircle className="me-2 text-success" size={20} />
                  <span>Xác nhận đặt phòng ngay lập tức</span>
                </div>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      </Container>

      {/* Booking Modal */}
      <Modal show={showBookingModal} onHide={() => setShowBookingModal(false)} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>Đặt phòng - {selectedRoom?.ten_loai_phong}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Ngày nhận phòng</Form.Label>
                <Form.Control
                  type="date"
                  value={checkInDate}
                  onChange={(e) => setCheckInDate(e.target.value)}
                  min={new Date().toISOString().split('T')[0]}
                />
              </Form.Group>
            </Col>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Ngày trả phòng</Form.Label>
                <Form.Control
                  type="date"
                  value={checkOutDate}
                  onChange={(e) => setCheckOutDate(e.target.value)}
                  min={checkInDate}
                />
              </Form.Group>
            </Col>
          </Row>
          
          <Row>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Người lớn</Form.Label>
                <Form.Control
                  type="number"
                  min="1"
                  value={guests.adults}
                  onChange={(e) => setGuests({...guests, adults: parseInt(e.target.value)})}
                />
              </Form.Group>
            </Col>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Trẻ em</Form.Label>
                <Form.Control
                  type="number"
                  min="0"
                  value={guests.children}
                  onChange={(e) => setGuests({...guests, children: parseInt(e.target.value)})}
                />
              </Form.Group>
            </Col>
          </Row>

          {isAuthenticated && (
            <DiscountCodeInput
              orderAmount={selectedRoom?.gia * Math.max(1, Math.ceil((new Date(checkOutDate) - new Date(checkInDate)) / (1000 * 60 * 60 * 24)))}
              onDiscountApply={handleDiscountApply}
            />
          )}

          <Card className="mt-3">
            <Card.Body>
              <h6>Chi tiết giá</h6>
              <div className="d-flex justify-content-between">
                <span>Giá phòng/đêm:</span>
                <span>{formatPrice(selectedRoom?.gia || 0)}</span>
              </div>
              <div className="d-flex justify-content-between">
                <span>Số đêm:</span>
                <span>{Math.max(1, Math.ceil((new Date(checkOutDate) - new Date(checkInDate)) / (1000 * 60 * 60 * 24)))}</span>
              </div>
              {discountData && (
                <div className="d-flex justify-content-between text-success">
                  <span>Giảm giá:</span>
                  <span>-{formatPrice(discountData.discountAmount)}</span>
                </div>
              )}
              <hr />
              <div className="d-flex justify-content-between fw-bold">
                <span>Tổng cộng:</span>
                <span className="text-primary">{formatPrice(totalPrice)}</span>
              </div>
            </Card.Body>
          </Card>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => setShowBookingModal(false)}>
            Hủy
          </Button>
          <Button 
            variant="primary" 
            onClick={handleBookingSubmit}
            disabled={bookingProcessing}
          >
            {bookingProcessing ? 'Đang xử lý...' : 'Xác nhận đặt phòng'}
          </Button>
        </Modal.Footer>
      </Modal>

      {/* Payment Modal */}
      <Modal show={showPaymentModal} onHide={() => setShowPaymentModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>Thanh toán</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <div className="text-center mb-4">
            <h5>Tổng tiền: {formatPrice(totalPrice)}</h5>
          </div>
          <div className="d-grid gap-2">
            <Button variant="primary" onClick={() => handlePayment('bank_transfer')}>
              Chuyển khoản ngân hàng
            </Button>
            <Button variant="success" onClick={() => handlePayment('momo')}>
              Thanh toán MoMo
            </Button>
            <Button variant="info" onClick={() => handlePayment('vnpay')}>
              Thanh toán VNPay
            </Button>
          </div>
        </Modal.Body>
      </Modal>
    </div>
  )
}

export default HotelDetailPage