import React, { useState, useEffect } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { Container, Row, Col, Card, Button, Form, Alert, Spinner, Badge } from 'react-bootstrap'
import { motion } from 'framer-motion'
import { 
  ArrowLeft, 
  Calendar, 
  Users, 
  MapPin, 
  Star,
  CheckCircle,
  CreditCard,
  Shield,
  Clock,
  Building2,
  Wifi,
  Car,
  Coffee,
  Dumbbell
} from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import { hotelsAPI, bookingsAPI } from '../../services/api/user'
import { discountService } from '../../services/discount/discountService'
import DateRangePicker from '../../components/common/DateRangePicker'
import DiscountCodeInput from '../../components/common/DiscountCodeInput'
import HotelMap from '../../components/common/HotelMap'
import toast from 'react-hot-toast'

const BookingPage = () => {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const { user } = useAuthStore()
  const isAuthenticated = () => useAuthStore.getState().isAuthenticated()
  
  const hotelId = searchParams.get('hotelId')
  const roomId = searchParams.get('roomId')
  
  // State management
  const [hotel, setHotel] = useState(null)
  const [room, setRoom] = useState(null)
  const [availableRooms, setAvailableRooms] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  
  // Booking states
  const [checkInDate, setCheckInDate] = useState('')
  const [checkOutDate, setCheckOutDate] = useState('')
  const [adults, setAdults] = useState(2)
  const [children, setChildren] = useState(0)
  const [rooms, setRooms] = useState(1)
  const [selectedRoom, setSelectedRoom] = useState(null)
  const [discountData, setDiscountData] = useState(null)
  const [notes, setNotes] = useState('')
  
  // Calculation states
  const [nights, setNights] = useState(1)
  const [subtotal, setSubtotal] = useState(0)
  const [discountAmount, setDiscountAmount] = useState(0)
  const [totalPrice, setTotalPrice] = useState(0)
  const [processing, setProcessing] = useState(false)

  // Load hotel and room data
  useEffect(() => {
    const loadData = async () => {
      if (!hotelId) {
        setError('Không tìm thấy thông tin khách sạn')
        setLoading(false)
        return
      }

      try {
        setLoading(true)
        setError(null)

        // Load hotel details
        const hotelResponse = await hotelsAPI.getById(hotelId)
        if (hotelResponse.data.success) {
          const hotelData = hotelResponse.data.data
          setHotel(hotelData)
          
          // Set default dates
          const tomorrow = new Date()
          tomorrow.setDate(tomorrow.getDate() + 1)
          const dayAfter = new Date()
          dayAfter.setDate(dayAfter.getDate() + 2)
          
          setCheckInDate(tomorrow.toISOString().split('T')[0])
          setCheckOutDate(dayAfter.toISOString().split('T')[0])
        } else {
          throw new Error(hotelResponse.data.message || 'Không tìm thấy khách sạn')
        }

        // Load rooms
        try {
          const roomsResponse = await fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000/api'}/v2/phong/khachsan/${hotelId}`)
          if (roomsResponse.ok) {
            const roomsData = await roomsResponse.json()
            if (roomsData.success) {
              setAvailableRooms(roomsData.data || [])
              
              // Set selected room if roomId provided
              if (roomId) {
                const foundRoom = roomsData.data?.find(r => r.id === parseInt(roomId))
                if (foundRoom) {
                  setSelectedRoom(foundRoom)
                  setRoom(foundRoom)
                }
              }
            }
          }
        } catch (err) {
          console.warn('Could not load rooms:', err)
        }

      } catch (err) {
        console.error('Error loading hotel:', err)
        setError(err.message || 'Có lỗi xảy ra khi tải thông tin khách sạn')
      } finally {
        setLoading(false)
      }
    }

    loadData()
  }, [hotelId, roomId])

  // Calculate prices when dates or room changes
  useEffect(() => {
    if (!selectedRoom || !checkInDate || !checkOutDate) return

    const checkIn = new Date(checkInDate)
    const checkOut = new Date(checkOutDate)
    const nightsCount = Math.max(1, Math.ceil((checkOut - checkIn) / (1000 * 60 * 60 * 24)))
    
    setNights(nightsCount)
    
    const basePrice = selectedRoom.gia || selectedRoom.gia_phong || 0
    const calculatedSubtotal = basePrice * nightsCount * rooms
    setSubtotal(calculatedSubtotal)

    // Apply discount if available
    if (discountData && discountData.discountAmount) {
      setDiscountAmount(discountData.discountAmount)
      setTotalPrice(Math.max(0, calculatedSubtotal - discountData.discountAmount))
    } else {
      setDiscountAmount(0)
      setTotalPrice(calculatedSubtotal)
    }
  }, [selectedRoom, checkInDate, checkOutDate, rooms, discountData])

  // Handle discount code
  const handleDiscountApply = async (code) => {
    if (!isAuthenticated()) {
      toast.error('Vui lòng đăng nhập để sử dụng mã giảm giá')
      return
    }

    try {
      const token = localStorage.getItem('auth_token')
      const result = await discountService.validateDiscountCode(code, subtotal, token)
      
      if (result.success && result.data) {
        setDiscountData({
          code,
          discountAmount: result.data.discountAmount || 0,
          ...result.data
        })
        toast.success(`Áp dụng mã giảm giá thành công!`)
      } else {
        toast.error(result.message || 'Mã giảm giá không hợp lệ')
      }
    } catch (error) {
      console.error('Error applying discount:', error)
      toast.error('Có lỗi xảy ra khi áp dụng mã giảm giá')
    }
  }

  // Handle booking submission
  const handleBookingSubmit = async () => {
    if (!isAuthenticated()) {
      toast.error('Vui lòng đăng nhập để đặt phòng')
      navigate('/login', { state: { returnTo: `/booking?hotelId=${hotelId}&roomId=${roomId}` } })
      return
    }

    if (!selectedRoom) {
      toast.error('Vui lòng chọn loại phòng')
      return
    }

    if (!checkInDate || !checkOutDate) {
      toast.error('Vui lòng chọn ngày nhận và trả phòng')
      return
    }

    const checkIn = new Date(checkInDate)
    const checkOut = new Date(checkOutDate)
    
    if (checkOut <= checkIn) {
      toast.error('Ngày trả phòng phải sau ngày nhận phòng')
      return
    }

    try {
      setProcessing(true)

      const bookingData = {
        ma_khach_san: hotel.id,
        ma_phong: selectedRoom.id,
        ngay_nhan_phong: checkInDate,
        ngay_tra_phong: checkOutDate,
        so_luong_phong: rooms,
        so_luong_khach: adults + children,
        tong_tien: totalPrice,
        ghi_chu: notes || null,
        ma_giam_gia: discountData?.code || null
      }

      const response = await bookingsAPI.create(bookingData)
      
      if (response.data.success) {
        const bookingId = response.data.data?.id || response.data.data?.ma_phieu_dat_phong
        
        toast.success('Đặt phòng thành công!')
        
        // Navigate to payment page
        navigate(`/payment/${bookingId}`, {
          state: {
            booking: response.data.data,
            hotel,
            room: selectedRoom
          }
        })
      } else {
        throw new Error(response.data.message || 'Có lỗi xảy ra khi đặt phòng')
      }

    } catch (error) {
      console.error('Booking error:', error)
      toast.error(error.response?.data?.message || error.message || 'Có lỗi xảy ra khi đặt phòng')
    } finally {
      setProcessing(false)
    }
  }

  const formatPrice = (price) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(price)
  }

  if (loading) {
    return (
      <Container className="py-5">
        <div className="text-center">
          <Spinner animation="border" variant="primary" />
          <p className="mt-3">Đang tải thông tin đặt phòng...</p>
        </div>
      </Container>
    )
  }

  if (error || !hotel) {
    return (
      <Container className="py-5">
        <Alert variant="danger">
          <Alert.Heading>Lỗi</Alert.Heading>
          <p>{error || 'Không tìm thấy thông tin khách sạn'}</p>
          <Button variant="primary" onClick={() => navigate('/hotels')}>
            Quay lại danh sách khách sạn
          </Button>
        </Alert>
      </Container>
    )
  }

  return (
    <div className="booking-page">
      <Container className="py-4">
        {/* Header */}
        <div className="d-flex align-items-center mb-4">
          <Button 
            variant="light" 
            className="me-3"
            onClick={() => navigate(`/hotels/${hotelId}`)}
          >
            <ArrowLeft size={20} />
          </Button>
          <div>
            <h2 className="mb-0">Đặt phòng</h2>
            <p className="text-muted mb-0">{hotel.ten_khach_san}</p>
          </div>
        </div>

        <Row>
          <Col lg={8}>
            {/* Hotel Info Card */}
            <Card className="mb-4">
              <Card.Body>
                <Row>
                  <Col md={4}>
                    <img 
                      src={hotel.hinh_anh || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'} 
                      alt={hotel.ten_khach_san}
                      className="w-100 rounded"
                      style={{ height: '200px', objectFit: 'cover' }}
                    />
                  </Col>
                  <Col md={8}>
                    <div className="d-flex align-items-center mb-2">
                      {Array.from({ length: hotel.so_sao || 5 }).map((_, i) => (
                        <Star key={i} size={16} className="text-warning fill-warning me-1" />
                      ))}
                      <Badge bg="primary" className="ms-2">{hotel.so_sao} sao</Badge>
                    </div>
                    <h5 className="mb-2">{hotel.ten_khach_san}</h5>
                    <div className="d-flex align-items-center text-muted mb-2">
                      <MapPin size={16} className="me-2" />
                      <span>{hotel.dia_chi}</span>
                    </div>
                    <div className="d-flex align-items-center">
                      {renderStars(hotel.danh_gia || 4.5)}
                      <span className="ms-2 fw-bold">{hotel.danh_gia || 4.5}</span>
                      <span className="ms-2 text-muted">({hotel.so_luong_danh_gia || 0} đánh giá)</span>
                    </div>
                  </Col>
                </Row>
              </Card.Body>
            </Card>

            {/* Booking Form */}
            <Card className="mb-4">
              <Card.Header>
                <h5 className="mb-0">Thông tin đặt phòng</h5>
              </Card.Header>
              <Card.Body>
                {/* Date Selection */}
                <Row className="mb-4">
                  <Col md={6}>
                    <Form.Group>
                      <Form.Label>Ngày nhận phòng</Form.Label>
                      <DateRangePicker
                        checkinDate={checkInDate}
                        checkoutDate={checkOutDate}
                        onDateChange={(checkin, checkout) => {
                          setCheckInDate(checkin)
                          setCheckOutDate(checkout)
                        }}
                      />
                    </Form.Group>
                  </Col>
                </Row>

                {/* Guests and Rooms */}
                <Row className="mb-4">
                  <Col md={4}>
                    <Form.Group>
                      <Form.Label>Số phòng</Form.Label>
                      <Form.Select
                        value={rooms}
                        onChange={(e) => setRooms(parseInt(e.target.value))}
                      >
                        {[1, 2, 3, 4, 5].map(num => (
                          <option key={num} value={num}>{num} phòng</option>
                        ))}
                      </Form.Select>
                    </Form.Group>
                  </Col>
                  <Col md={4}>
                    <Form.Group>
                      <Form.Label>Người lớn</Form.Label>
                      <Form.Select
                        value={adults}
                        onChange={(e) => setAdults(parseInt(e.target.value))}
                      >
                        {[1, 2, 3, 4, 5, 6].map(num => (
                          <option key={num} value={num}>{num} người</option>
                        ))}
                      </Form.Select>
                    </Form.Group>
                  </Col>
                  <Col md={4}>
                    <Form.Group>
                      <Form.Label>Trẻ em</Form.Label>
                      <Form.Select
                        value={children}
                        onChange={(e) => setChildren(parseInt(e.target.value))}
                      >
                        {[0, 1, 2, 3, 4].map(num => (
                          <option key={num} value={num}>{num} trẻ</option>
                        ))}
                      </Form.Select>
                    </Form.Group>
                  </Col>
                </Row>

                {/* Room Selection */}
                <div className="mb-4">
                  <Form.Label className="fw-bold">Chọn loại phòng</Form.Label>
                  {availableRooms.length > 0 ? (
                    <Row>
                      {availableRooms.map((r) => (
                        <Col md={6} key={r.id} className="mb-3">
                          <Card 
                            className={`h-100 cursor-pointer ${selectedRoom?.id === r.id ? 'border-primary border-2' : ''}`}
                            onClick={() => setSelectedRoom(r)}
                            style={{ cursor: 'pointer' }}
                          >
                            <Card.Body>
                              <div className="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                  <h6 className="mb-1">{r.ten_loai_phong}</h6>
                                  <small className="text-muted">{r.mo_ta}</small>
                                </div>
                                {selectedRoom?.id === r.id && (
                                  <CheckCircle className="text-primary" size={20} />
                                )}
                              </div>
                              <div className="mt-3">
                                <div className="h5 text-primary mb-0">
                                  {formatPrice(r.gia || r.gia_phong || 0)}
                                  <small className="text-muted">/đêm</small>
                                </div>
                              </div>
                            </Card.Body>
                          </Card>
                        </Col>
                      ))}
                    </Row>
                  ) : (
                    <Alert variant="info">
                      Không có thông tin phòng. Vui lòng liên hệ khách sạn để đặt phòng.
                    </Alert>
                  )}
                </div>

                {/* Discount Code */}
                <div className="mb-4">
                  <Form.Label className="fw-bold">Mã giảm giá (nếu có)</Form.Label>
                  <DiscountCodeInput
                    onApply={handleDiscountApply}
                    orderAmount={subtotal}
                  />
                </div>

                {/* Notes */}
                <Form.Group className="mb-4">
                  <Form.Label>Ghi chú đặc biệt (tùy chọn)</Form.Label>
                  <Form.Control
                    as="textarea"
                    rows={3}
                    placeholder="Ví dụ: Phòng tầng cao, giường đôi, không hút thuốc..."
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                  />
                </Form.Group>
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

          {/* Booking Summary Sidebar */}
          <Col lg={4}>
            <Card className="sticky-top" style={{ top: '20px' }}>
              <Card.Header>
                <h5 className="mb-0">Tóm tắt đặt phòng</h5>
              </Card.Header>
              <Card.Body>
                {selectedRoom && (
                  <>
                    <div className="mb-3">
                      <h6>{selectedRoom.ten_loai_phong}</h6>
                      <small className="text-muted">{hotel.ten_khach_san}</small>
                    </div>

                    <hr />

                    <div className="d-flex justify-content-between mb-2">
                      <span>Ngày nhận phòng:</span>
                      <strong>{checkInDate ? new Date(checkInDate).toLocaleDateString('vi-VN') : '-'}</strong>
                    </div>
                    <div className="d-flex justify-content-between mb-2">
                      <span>Ngày trả phòng:</span>
                      <strong>{checkOutDate ? new Date(checkOutDate).toLocaleDateString('vi-VN') : '-'}</strong>
                    </div>
                    <div className="d-flex justify-content-between mb-2">
                      <span>Số đêm:</span>
                      <strong>{nights} đêm</strong>
                    </div>
                    <div className="d-flex justify-content-between mb-2">
                      <span>Số phòng:</span>
                      <strong>{rooms} phòng</strong>
                    </div>
                    <div className="d-flex justify-content-between mb-2">
                      <span>Số khách:</span>
                      <strong>{adults + children} người</strong>
                    </div>

                    <hr />

                    <div className="d-flex justify-content-between mb-2">
                      <span>Tạm tính:</span>
                      <span>{formatPrice(subtotal)}</span>
                    </div>
                    {discountAmount > 0 && (
                      <div className="d-flex justify-content-between mb-2 text-success">
                        <span>Giảm giá:</span>
                        <span>-{formatPrice(discountAmount)}</span>
                      </div>
                    )}
                    <hr />
                    <div className="d-flex justify-content-between mb-4">
                      <h5 className="mb-0">Tổng cộng:</h5>
                      <h5 className="mb-0 text-primary">{formatPrice(totalPrice)}</h5>
                    </div>

                    <div className="d-flex align-items-center mb-3 text-muted">
                      <Shield size={16} className="me-2" />
                      <small>Đặt phòng an toàn và bảo mật</small>
                    </div>
                    <div className="d-flex align-items-center mb-3 text-muted">
                      <CheckCircle size={16} className="me-2" />
                      <small>Xác nhận ngay lập tức</small>
                    </div>
                    <div className="d-flex align-items-center mb-4 text-muted">
                      <Clock size={16} className="me-2" />
                      <small>Miễn phí hủy trong 24h</small>
                    </div>

                    <Button
                      variant="primary"
                      size="lg"
                      className="w-100"
                      onClick={handleBookingSubmit}
                      disabled={processing || !selectedRoom || !checkInDate || !checkOutDate}
                    >
                      {processing ? (
                        <>
                          <Spinner size="sm" className="me-2" />
                          Đang xử lý...
                        </>
                      ) : (
                        <>
                          <CreditCard size={20} className="me-2" />
                          Xác nhận đặt phòng
                        </>
                      )}
                    </Button>
                  </>
                )}

                {!selectedRoom && (
                  <Alert variant="warning">
                    Vui lòng chọn loại phòng để tiếp tục
                  </Alert>
                )}
              </Card.Body>
            </Card>
          </Col>
        </Row>
      </Container>
    </div>
  )

  function renderStars(rating) {
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
}

export default BookingPage

