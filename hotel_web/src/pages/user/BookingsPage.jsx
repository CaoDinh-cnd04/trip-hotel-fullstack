import React, { useState, useEffect } from 'react'
import { Container, Row, Col, Card, Badge, Button, Modal, Form, Tab, Tabs, Spinner } from 'react-bootstrap'
import { motion, AnimatePresence } from 'framer-motion'
import { useBookingsStore } from '../../stores/bookingsStore'
import { useFavoritesStore } from '../../stores/favoritesStore'
import { FaCalendarAlt, FaMapMarkerAlt, FaUser, FaCreditCard, FaPhone, FaEnvelope, FaEye, FaTimes } from 'react-icons/fa'
import { Smartphone, CheckCircle } from 'lucide-react'
import { paymentService } from '../../services/payment/paymentService'
import { hotelsAPI } from '../../services/api/user'
import toast from 'react-hot-toast'
import { useNavigate } from 'react-router-dom'

const BookingsPage = () => {
  const navigate = useNavigate()
  const { bookings, cancelBooking, updateBookingStatus } = useBookingsStore()
  const { favorites } = useFavoritesStore()
  const [showModal, setShowModal] = useState(false)
  const [selectedBooking, setSelectedBooking] = useState(null)
  const [cancelReason, setCancelReason] = useState('')
  const [activeTab, setActiveTab] = useState('all')
  const [showPaymentModal, setShowPaymentModal] = useState(false)
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState('')
  const [showQRModal, setShowQRModal] = useState(false)
  const [qrCodeData, setQrCodeData] = useState(null)
  const [paymentProcessing, setPaymentProcessing] = useState(false)

  const [hotels, setHotels] = useState([])
  const [hotelsLoading, setHotelsLoading] = useState(false)

  // Load hotels from API
  useEffect(() => {
    const fetchHotels = async () => {
      try {
        setHotelsLoading(true)
        const response = await hotelsAPI.getAll()
        if (response.data.success) {
          setHotels(response.data.data || [])
        }
      } catch (error) {
        console.error('Error loading hotels:', error)
      } finally {
        setHotelsLoading(false)
      }
    }

    fetchHotels()
  }, [])

  const getHotelInfo = (hotelId) => {
    const hotel = hotels.find(h => h.id === parseInt(hotelId))
    if (hotel) {
      return {
        id: hotel.id,
        name: hotel.ten_khach_san,
        location: hotel.dia_chi,
        image: hotel.hinh_anh || 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        rating: hotel.danh_gia || 0,
        price: hotel.gia_thap_nhat || 0
      }
    }
    
    return {
      id: hotelId,
      name: 'Khách sạn không tìm thấy',
      location: 'Chưa xác định',
      image: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      rating: 0,
      price: 0
    }
  }

  const getStatusBadge = (status) => {
    const statusConfig = {
      pending: { variant: 'warning', text: 'Chờ xác nhận' },
      confirmed: { variant: 'success', text: 'Đã xác nhận' },
      cancelled: { variant: 'danger', text: 'Đã hủy' },
      completed: { variant: 'primary', text: 'Hoàn thành' }
    }
    
    const config = statusConfig[status] || { variant: 'secondary', text: 'Không xác định' }
    return <Badge bg={config.variant}>{config.text}</Badge>
  }

  const getPaymentStatusBadge = (paymentStatus) => {
    const statusConfig = {
      pending: { variant: 'warning', text: 'Chưa thanh toán' },
      paid: { variant: 'success', text: 'Đã thanh toán' },
      failed: { variant: 'danger', text: 'Thanh toán thất bại' }
    }
    
    const config = statusConfig[paymentStatus] || { variant: 'secondary', text: 'Không xác định' }
    return <Badge bg={config.variant}>{config.text}</Badge>
  }

  const filteredBookings = bookings.filter(booking => {
    if (activeTab === 'all') return true
    if (activeTab === 'pending') return booking.status === 'pending'
    if (activeTab === 'confirmed') return booking.status === 'confirmed'
    if (activeTab === 'cancelled') return booking.status === 'cancelled'
    if (activeTab === 'completed') return booking.status === 'completed'
    return true
  })

  const handleViewDetails = (booking) => {
    setSelectedBooking(booking)
    setShowModal(true)
  }

  const handleCancelBooking = (bookingId) => {
    if (cancelReason.trim()) {
      cancelBooking(bookingId, cancelReason)
      setShowModal(false)
      setCancelReason('')
      setSelectedBooking(null)
    } else {
      toast.error('Vui lòng nhập lý do hủy đặt phòng')
    }
  }

  const handlePaymentClick = (booking) => {
    setSelectedBooking(booking)
    setShowPaymentModal(true)
  }

  const handlePaymentMethodSelect = async (method) => {
    setSelectedPaymentMethod(method)
    
    if (method === 'momo' || method === 'zalopay') {
      try {
        setPaymentProcessing(true)
        
        const orderInfo = {
          orderId: `PAY_${selectedBooking.id}_${Date.now()}`,
          amount: selectedBooking.totalPrice,
          description: `Thanh toán đặt phòng ${selectedBooking.hotelName}`
        }

        let qrResult
        if (method === 'momo') {
          qrResult = await paymentService.generateMoMoQR(orderInfo.amount, orderInfo.orderId, orderInfo.description)
        } else {
          qrResult = await paymentService.generateZaloPayQR(orderInfo.amount, orderInfo.orderId, orderInfo.description)
        }

        if (qrResult.success) {
          setQrCodeData(qrResult.data)
          setShowPaymentModal(false)
          setShowQRModal(true)
        } else {
          toast.error('Không thể tạo mã QR thanh toán')
        }
      } catch (error) {
        console.error('Error generating QR code:', error)
        toast.error('Có lỗi xảy ra khi tạo mã QR')
      } finally {
        setPaymentProcessing(false)
      }
    } else if (method === 'cash') {
      // Handle cash payment
      toast.success('Bạn sẽ thanh toán tại quầy khi nhận phòng')
      setShowPaymentModal(false)
    }
  }

  const completePayment = () => {
    // Update booking payment status
    updateBookingStatus(selectedBooking.id, { paymentStatus: 'paid' })
    
    // Close modals
    setShowQRModal(false)
    setShowPaymentModal(false)
    setSelectedPaymentMethod('')
    setQrCodeData(null)
    
    toast.success('Thanh toán thành công!')
  }

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('vi-VN', { 
      style: 'currency', 
      currency: 'VND' 
    }).format(amount)
  }

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    })
  }

  const calculateNights = (checkin, checkout) => {
    const checkinDate = new Date(checkin)
    const checkoutDate = new Date(checkout)
    const diffTime = Math.abs(checkoutDate - checkinDate)
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  }

  if (bookings.length === 0) {
    return (
      <Container className="py-5">
        <h2 className="mb-4">Phòng đã đặt</h2>
        <div className="text-center py-5">
          <div className="display-4 text-muted mb-3">📋</div>
          <h4 className="text-muted mb-3">Chưa có đặt phòng nào</h4>
          <p className="text-muted mb-4">Hãy khám phá và đặt phòng khách sạn yêu thích của bạn!</p>
          <Button variant="primary" size="lg" onClick={() => navigate('/hotels')}>
            Khám phá khách sạn
          </Button>
        </div>
      </Container>
    )
  }

  return (
    <Container className="py-5">
      <Row>
        <Col>
          <div className="d-flex justify-content-between align-items-center mb-4">
            <h2>Phòng đã đặt</h2>
            <Badge bg="info" className="fs-6">
              {bookings.length} đặt phòng
            </Badge>
          </div>

          {/* Tabs */}
          <Tabs
            activeKey={activeTab}
            onSelect={(tab) => setActiveTab(tab)}
            className="mb-4"
          >
            <Tab eventKey="all" title={`Tất cả (${bookings.length})`} />
            <Tab eventKey="pending" title={`Chờ xác nhận (${bookings.filter(b => b.status === 'pending').length})`} />
            <Tab eventKey="confirmed" title={`Đã xác nhận (${bookings.filter(b => b.status === 'confirmed').length})`} />
            <Tab eventKey="completed" title={`Hoàn thành (${bookings.filter(b => b.status === 'completed').length})`} />
            <Tab eventKey="cancelled" title={`Đã hủy (${bookings.filter(b => b.status === 'cancelled').length})`} />
          </Tabs>

          {/* Bookings List */}
          <Row>
            {filteredBookings.map((booking, index) => {
              const hotel = getHotelInfo(booking.hotelId)
              const nights = calculateNights(booking.checkinDate, booking.checkoutDate)
              
              return (
                <Col lg={6} className="mb-4" key={booking.id}>
                  <motion.div
                    initial={{ opacity: 0, y: 30, scale: 0.95 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    transition={{ 
                      duration: 0.5, 
                      delay: index * 0.1,
                      type: "spring",
                      stiffness: 100
                    }}
                    whileHover={{ 
                      y: -5,
                      transition: { duration: 0.3 }
                    }}
                  >
                    <Card 
                      className="h-100 shadow-sm" 
                      style={{ 
                        borderRadius: '16px',
                        overflow: 'hidden',
                        transition: 'all 0.3s ease',
                        border: 'none',
                        boxShadow: '0 4px 15px rgba(0,0,0,0.08)'
                      }}
                    >
                    <Row className="g-0">
                      <Col md={4}>
                        <Card.Img 
                          src={hotel.image} 
                          alt={hotel.name}
                          className="h-100 object-fit-cover"
                          style={{ minHeight: '200px' }}
                        />
                      </Col>
                      <Col md={8}>
                        <Card.Body className="d-flex flex-column">
                          <div className="d-flex justify-content-between align-items-start mb-2">
                            <div>
                              <Card.Title className="h6 mb-1">{hotel.name}</Card.Title>
                              <small className="text-muted">
                                <FaMapMarkerAlt className="me-1" />
                                {hotel.location}
                              </small>
                            </div>
                            <div className="text-end">
                              {getStatusBadge(booking.status)}
                            </div>
                          </div>

                          <div className="mb-2">
                            <small className="text-muted d-block">
                              <strong>Mã đặt phòng:</strong> {booking.id}
                            </small>
                            <small className="text-muted d-block">
                              <FaCalendarAlt className="me-1" />
                              {formatDate(booking.checkinDate)} - {formatDate(booking.checkoutDate)} ({nights} đêm)
                            </small>
                            <small className="text-muted d-block">
                              <FaUser className="me-1" />
                              {booking.guests} khách - {booking.rooms} phòng
                            </small>
                          </div>

                          <div className="mb-3">
                            <div className="d-flex justify-content-between align-items-center">
                              <span className="fw-bold text-primary">
                                {formatCurrency(booking.totalPrice)}
                              </span>
                              {getPaymentStatusBadge(booking.paymentStatus)}
                            </div>
                          </div>

                          <div className="mt-auto d-flex gap-2">
                            <Button 
                              size="sm" 
                              variant="outline-primary"
                              onClick={() => handleViewDetails(booking)}
                            >
                              <FaEye className="me-1" />
                              Chi tiết
                            </Button>
                            
                            {booking.paymentStatus === 'pending' && booking.status !== 'cancelled' && (
                              <Button 
                                size="sm" 
                                variant="success"
                                onClick={() => handlePaymentClick(booking)}
                              >
                                <FaCreditCard className="me-1" />
                                Thanh toán
                              </Button>
                            )}
                            
                            {booking.status === 'pending' && (
                              <Button 
                                size="sm" 
                                variant="outline-danger"
                                onClick={() => {
                                  setSelectedBooking(booking)
                                  setShowModal(true)
                                }}
                              >
                                <FaTimes className="me-1" />
                                Hủy
                              </Button>
                            )}
                          </div>
                        </Card.Body>
                      </Col>
                    </Row>
                  </Card>
                  </motion.div>
                </Col>
              )
            })}
          </Row>

          {filteredBookings.length === 0 && (
            <div className="text-center py-5">
              <div className="display-4 text-muted mb-3">🔍</div>
              <h4 className="text-muted">Không có đặt phòng nào trong danh mục này</h4>
            </div>
          )}
        </Col>
      </Row>

      {/* Booking Details Modal */}
      <Modal show={showModal} onHide={() => setShowModal(false)} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>Chi tiết đặt phòng</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedBooking && (
            <Row>
              <Col md={6}>
                <h6>Thông tin khách sạn</h6>
                <p><strong>{getHotelInfo(selectedBooking.hotelId).name}</strong></p>
                <p className="text-muted">{getHotelInfo(selectedBooking.hotelId).location}</p>
                
                <h6 className="mt-4">Thông tin đặt phòng</h6>
                <p><strong>Mã đặt phòng:</strong> {selectedBooking.id}</p>
                <p><strong>Check-in:</strong> {formatDate(selectedBooking.checkinDate)}</p>
                <p><strong>Check-out:</strong> {formatDate(selectedBooking.checkoutDate)}</p>
                <p><strong>Số phòng:</strong> {selectedBooking.rooms}</p>
                <p><strong>Số khách:</strong> {selectedBooking.guests}</p>
                <p><strong>Trạng thái:</strong> {getStatusBadge(selectedBooking.status)}</p>
                <p><strong>Thanh toán:</strong> {getPaymentStatusBadge(selectedBooking.paymentStatus)}</p>
              </Col>
              
              <Col md={6}>
                <h6>Thông tin khách hàng</h6>
                <p><strong>Họ tên:</strong> {selectedBooking.customerName}</p>
                <p><strong>Email:</strong> {selectedBooking.email}</p>
                <p><strong>Điện thoại:</strong> {selectedBooking.phone}</p>
                
                <h6 className="mt-4">Chi phí</h6>
                <div className="d-flex justify-content-between">
                  <span>Tổng tiền:</span>
                  <strong className="text-primary">{formatCurrency(selectedBooking.totalPrice)}</strong>
                </div>
                
                {selectedBooking.status === 'cancelled' && selectedBooking.cancelReason && (
                  <div className="mt-4">
                    <h6>Lý do hủy</h6>
                    <p className="text-muted">{selectedBooking.cancelReason}</p>
                  </div>
                )}
                
                {selectedBooking.specialRequests && (
                  <div className="mt-4">
                    <h6>Yêu cầu đặc biệt</h6>
                    <p className="text-muted">{selectedBooking.specialRequests}</p>
                  </div>
                )}
              </Col>
            </Row>
          )}
          
          {/* Cancel booking form */}
          {selectedBooking && selectedBooking.status === 'pending' && (
            <div className="mt-4 border-top pt-4">
              <h6>Hủy đặt phòng</h6>
              <Form.Group>
                <Form.Label>Lý do hủy *</Form.Label>
                <Form.Control
                  as="textarea"
                  rows={3}
                  placeholder="Nhập lý do hủy đặt phòng..."
                  value={cancelReason}
                  onChange={(e) => setCancelReason(e.target.value)}
                />
              </Form.Group>
            </div>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => setShowModal(false)}>
            Đóng
          </Button>
          {selectedBooking && selectedBooking.status === 'pending' && (
            <Button 
              variant="danger" 
              onClick={() => handleCancelBooking(selectedBooking.id)}
            >
              Xác nhận hủy
            </Button>
          )}
        </Modal.Footer>
      </Modal>

      {/* Payment Method Modal */}
      <Modal show={showPaymentModal} onHide={() => setShowPaymentModal(false)} centered>
        <Modal.Header closeButton>
          <Modal.Title>Chọn phương thức thanh toán</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <motion.div 
            className="d-grid gap-3"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1, duration: 0.3 }}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Button
                variant={selectedPaymentMethod === 'momo' ? 'success' : 'outline-secondary'}
                size="lg"
                onClick={() => handlePaymentMethodSelect('momo')}
                className="d-flex align-items-center justify-content-center w-100"
                style={{ 
                  borderRadius: '12px',
                  transition: 'all 0.3s ease',
                  boxShadow: selectedPaymentMethod === 'momo' ? '0 4px 15px rgba(25, 135, 84, 0.3)' : '0 2px 10px rgba(0,0,0,0.1)'
                }}
              >
                <motion.div
                  animate={{ rotate: selectedPaymentMethod === 'momo' ? 360 : 0 }}
                  transition={{ duration: 0.5 }}
                >
                  <Smartphone className="me-2" size={20} />
                </motion.div>
                Ví MoMo
              </Button>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2, duration: 0.3 }}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Button
                variant={selectedPaymentMethod === 'zalopay' ? 'success' : 'outline-secondary'}
                size="lg"
                onClick={() => handlePaymentMethodSelect('zalopay')}
                className="d-flex align-items-center justify-content-center w-100"
                style={{ 
                  borderRadius: '12px',
                  transition: 'all 0.3s ease',
                  boxShadow: selectedPaymentMethod === 'zalopay' ? '0 4px 15px rgba(25, 135, 84, 0.3)' : '0 2px 10px rgba(0,0,0,0.1)'
                }}
              >
                <motion.div
                  animate={{ rotate: selectedPaymentMethod === 'zalopay' ? 360 : 0 }}
                  transition={{ duration: 0.5 }}
                >
                  <Smartphone className="me-2" size={20} />
                </motion.div>
                ZaloPay
              </Button>
            </motion.div>
          </motion.div>
          
          <AnimatePresence>
            {selectedPaymentMethod && (
              <motion.div 
                className="mt-4 text-center"
                initial={{ opacity: 0, y: 20, scale: 0.9 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: -20, scale: 0.9 }}
                transition={{ duration: 0.4, type: "spring", stiffness: 100 }}
              >
                <motion.div
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <Button 
                    variant="primary" 
                    size="lg"
                    onClick={() => completePayment()}
                    disabled={paymentProcessing}
                    className="w-100"
                    style={{ 
                      borderRadius: '12px',
                      background: paymentProcessing ? '#6c757d' : 'linear-gradient(135deg, #007bff, #0056b3)',
                      border: 'none',
                      boxShadow: '0 4px 15px rgba(0, 123, 255, 0.3)',
                      transition: 'all 0.3s ease'
                    }}
                  >
                    {paymentProcessing ? (
                      <motion.div
                        className="d-flex align-items-center justify-content-center"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ duration: 0.3 }}
                      >
                        <motion.div
                          animate={{ rotate: 360 }}
                          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                        >
                          <Spinner animation="border" size="sm" className="me-2" />
                        </motion.div>
                        Đang xử lý...
                      </motion.div>
                    ) : (
                      <motion.span
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ duration: 0.3 }}
                      >
                        Tiếp tục thanh toán
                      </motion.span>
                    )}
                  </Button>
                </motion.div>
              </motion.div>
            )}
          </AnimatePresence>
        </Modal.Body>
      </Modal>

      {/* QR Code Modal */}
      <Modal show={showQRModal} onHide={() => setShowQRModal(false)} centered>
        <Modal.Header closeButton>
          <Modal.Title>Quét mã QR để thanh toán</Modal.Title>
        </Modal.Header>
        <Modal.Body className="text-center">
          <AnimatePresence mode="wait">
            {qrCodeData ? (
              <motion.div
                key="qr-content"
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.8 }}
                transition={{ duration: 0.5, type: "spring", stiffness: 100 }}
              >
                <motion.div
                  initial={{ y: -20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: 0.2, duration: 0.4 }}
                  whileHover={{ scale: 1.05 }}
                  style={{
                    background: 'linear-gradient(135deg, #f8f9fa, #e9ecef)',
                    borderRadius: '16px',
                    padding: '20px',
                    margin: '0 auto 20px',
                    maxWidth: '280px',
                    boxShadow: '0 8px 25px rgba(0,0,0,0.1)'
                  }}
                >
                  <motion.img 
                    src={qrCodeData} 
                    alt="QR Code" 
                    style={{ maxWidth: '200px', width: '100%', borderRadius: '8px' }}
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ delay: 0.3, duration: 0.5, type: "spring", stiffness: 200 }}
                  />
                </motion.div>
                <motion.p 
                  className="text-muted"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4, duration: 0.3 }}
                >
                  Mở ứng dụng {selectedPaymentMethod === 'momo' ? 'MoMo' : 'ZaloPay'} và quét mã QR để thanh toán
                </motion.p>
                <motion.div 
                  className="d-flex align-items-center justify-content-center text-success mt-3"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.5, duration: 0.3 }}
                >
                  <motion.div
                    animate={{ 
                      scale: [1, 1.2, 1],
                      rotate: [0, 180, 360]
                    }}
                    transition={{ 
                      duration: 2, 
                      repeat: Infinity, 
                      ease: "easeInOut"
                    }}
                  >
                    <CheckCircle className="me-2" size={20} />
                  </motion.div>
                  <motion.span
                    animate={{ opacity: [0.7, 1, 0.7] }}
                    transition={{ duration: 1.5, repeat: Infinity }}
                  >
                    Chờ xác nhận thanh toán...
                  </motion.span>
                </motion.div>
              </motion.div>
            ) : (
              <motion.div 
                key="loading"
                className="text-center py-4"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.3 }}
              >
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                  style={{ display: 'inline-block' }}
                >
                  <Spinner animation="border" className="me-2" />
                </motion.div>
                <motion.span
                  animate={{ opacity: [0.5, 1, 0.5] }}
                  transition={{ duration: 1.2, repeat: Infinity }}
                >
                  Đang tạo mã QR...
                </motion.span>
              </motion.div>
            )}
          </AnimatePresence>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="outline-secondary" onClick={() => setShowQRModal(false)}>
            Đóng
          </Button>
        </Modal.Footer>
      </Modal>
    </Container>
  )
}

export default BookingsPage