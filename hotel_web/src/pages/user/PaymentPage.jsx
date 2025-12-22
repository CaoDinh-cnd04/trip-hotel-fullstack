import React, { useState, useEffect } from 'react'
import { Container, Row, Col, Card, Button, Form, Alert, Spinner, Modal, Badge } from 'react-bootstrap'
import { useParams, useNavigate } from 'react-router-dom'
import { useBookingsStore } from '../../stores/bookingsStore'
import { FaCreditCard, FaPaypal, FaUniversity, FaQrcode, FaCheckCircle, FaTimesCircle } from 'react-icons/fa'
import toast from 'react-hot-toast'

const PaymentPage = () => {
  const { bookingId } = useParams()
  const navigate = useNavigate()
  const { getBookingById, updatePaymentStatus } = useBookingsStore()
  
  const [paymentMethod, setPaymentMethod] = useState('card')
  const [isProcessing, setIsProcessing] = useState(false)
  const [paymentSuccess, setPaymentSuccess] = useState(false)
  const [paymentError, setPaymentError] = useState('')
  const [showConfirmModal, setShowConfirmModal] = useState(false)
  const [cardData, setCardData] = useState({
    cardNumber: '',
    expiryDate: '',
    cvv: '',
    cardName: ''
  })

  const booking = getBookingById(bookingId)

  useEffect(() => {
    if (!booking) {
      toast.error('Không tìm thấy thông tin đặt phòng')
      navigate('/bookings')
      return
    }

    if (booking.paymentStatus === 'paid') {
      toast.info('Đặt phòng này đã được thanh toán')
      navigate('/bookings')
    }
  }, [booking, navigate])

  // Get hotel info from booking data
  const getHotelFromBooking = () => {
    if (!booking) return null
    return {
      id: booking.hotelId,
      name: booking.hotelName || 'Khách sạn',
      location: booking.hotelAddress || '',
      image: booking.hotelImage || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      rating: booking.hotelRating || 4,
      price: booking.roomPrice || booking.totalAmount
    }
  }

  const getHotelInfo = (hotelId) => {
    return getHotelFromBooking() || {
      id: hotelId,
      name: 'Khách sạn không tìm thấy',
      location: 'Chưa xác định',
      image: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      rating: 0,
      price: 0
    }
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

  const paymentMethods = [
    {
      id: 'card',
      name: 'Thẻ tín dụng/ghi nợ',
      icon: FaCreditCard,
      description: 'Visa, Mastercard, JCB'
    },
    {
      id: 'momo',
      name: 'Ví điện tử MoMo',
      icon: FaQrcode,
      description: 'Thanh toán qua ứng dụng MoMo'
    },
    {
      id: 'banking',
      name: 'Chuyển khoản ngân hàng',
      icon: FaUniversity,
      description: 'Internet Banking'
    },
    {
      id: 'paypal',
      name: 'PayPal',
      icon: FaPaypal,
      description: 'Thanh toán quốc tế'
    }
  ]

  const handleCardInputChange = (field, value) => {
    if (field === 'cardNumber') {
      // Format card number
      const formatted = value.replace(/\s/g, '').replace(/(.{4})/g, '$1 ').trim()
      if (formatted.length <= 19) {
        setCardData(prev => ({ ...prev, [field]: formatted }))
      }
    } else if (field === 'expiryDate') {
      // Format MM/YY
      const formatted = value.replace(/\D/g, '').replace(/(\d{2})(\d)/, '$1/$2')
      if (formatted.length <= 5) {
        setCardData(prev => ({ ...prev, [field]: formatted }))
      }
    } else if (field === 'cvv') {
      // Only numbers, max 4 digits
      const formatted = value.replace(/\D/g, '')
      if (formatted.length <= 4) {
        setCardData(prev => ({ ...prev, [field]: formatted }))
      }
    } else {
      setCardData(prev => ({ ...prev, [field]: value }))
    }
  }

  const validateCardData = () => {
    if (!cardData.cardNumber || cardData.cardNumber.replace(/\s/g, '').length < 13) {
      return 'Số thẻ không hợp lệ'
    }
    if (!cardData.expiryDate || cardData.expiryDate.length !== 5) {
      return 'Ngày hết hạn không hợp lệ'
    }
    if (!cardData.cvv || cardData.cvv.length < 3) {
      return 'Mã CVV không hợp lệ'
    }
    if (!cardData.cardName || cardData.cardName.trim().length < 2) {
      return 'Tên chủ thẻ không hợp lệ'
    }
    return null
  }

  const simulatePayment = () => {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        // 90% success rate for demo
        if (Math.random() > 0.1) {
          resolve({
            transactionId: 'TXN' + Date.now(),
            status: 'success'
          })
        } else {
          reject({
            error: 'Thanh toán thất bại',
            code: 'PAYMENT_DECLINED'
          })
        }
      }, 3000) // 3 second simulation
    })
  }

  const handlePayment = async () => {
    if (paymentMethod === 'card') {
      const cardError = validateCardData()
      if (cardError) {
        toast.error(cardError)
        return
      }
    }

    setShowConfirmModal(false)
    setIsProcessing(true)
    setPaymentError('')

    try {
      const result = await simulatePayment()
      
      // Update booking payment status
      updatePaymentStatus(bookingId, 'paid', result.transactionId)
      
      setPaymentSuccess(true)
      setIsProcessing(false)
      
      setTimeout(() => {
        navigate('/bookings')
      }, 3000)
      
    } catch (error) {
      setPaymentError(error.error || 'Có lỗi xảy ra trong quá trình thanh toán')
      setIsProcessing(false)
      updatePaymentStatus(bookingId, 'failed')
    }
  }

  if (!booking) {
    return (
      <Container className="py-5">
        <div className="text-center">
          <Spinner animation="border" role="status">
            <span className="visually-hidden">Loading...</span>
          </Spinner>
        </div>
      </Container>
    )
  }

  if (paymentSuccess) {
    return (
      <Container className="py-5">
        <Row className="justify-content-center">
          <Col md={8}>
            <Card className="text-center border-success">
              <Card.Body className="py-5">
                <FaCheckCircle size={64} className="text-success mb-4" />
                <h3 className="text-success mb-3">Thanh toán thành công!</h3>
                <p className="text-muted mb-4">
                  Cảm ơn bạn đã thanh toán. Chúng tôi sẽ gửi email xác nhận trong ít phút.
                </p>
                <Button variant="primary" onClick={() => navigate('/bookings')}>
                  Về trang đặt phòng
                </Button>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      </Container>
    )
  }

  const hotel = getHotelInfo(booking.hotelId)
  const nights = calculateNights(booking.checkinDate, booking.checkoutDate)

  return (
    <Container className="py-5">
      <Row>
        <Col lg={8}>
          <Card className="mb-4">
            <Card.Header>
              <h5 className="mb-0">Thanh toán đặt phòng</h5>
            </Card.Header>
            <Card.Body>
              {paymentError && (
                <Alert variant="danger" className="d-flex align-items-center">
                  <FaTimesCircle className="me-2" />
                  {paymentError}
                </Alert>
              )}

              {/* Payment Methods */}
              <h6 className="mb-3">Chọn phương thức thanh toán</h6>
              <Row>
                {paymentMethods.map(method => {
                  const IconComponent = method.icon
                  return (
                    <Col md={6} key={method.id} className="mb-3">
                      <Card 
                        className={`h-100 cursor-pointer ${paymentMethod === method.id ? 'border-primary bg-light' : ''}`}
                        onClick={() => setPaymentMethod(method.id)}
                      >
                        <Card.Body className="text-center">
                          <IconComponent size={32} className={`mb-2 ${paymentMethod === method.id ? 'text-primary' : 'text-muted'}`} />
                          <h6 className="mb-1">{method.name}</h6>
                          <small className="text-muted">{method.description}</small>
                        </Card.Body>
                      </Card>
                    </Col>
                  )
                })}
              </Row>

              {/* Card Payment Form */}
              {paymentMethod === 'card' && (
                <div className="mt-4">
                  <h6 className="mb-3">Thông tin thẻ</h6>
                  <Row>
                    <Col md={12} className="mb-3">
                      <Form.Group>
                        <Form.Label>Số thẻ *</Form.Label>
                        <Form.Control
                          type="text"
                          placeholder="1234 5678 9012 3456"
                          value={cardData.cardNumber}
                          onChange={(e) => handleCardInputChange('cardNumber', e.target.value)}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>Ngày hết hạn *</Form.Label>
                        <Form.Control
                          type="text"
                          placeholder="MM/YY"
                          value={cardData.expiryDate}
                          onChange={(e) => handleCardInputChange('expiryDate', e.target.value)}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>CVV *</Form.Label>
                        <Form.Control
                          type="text"
                          placeholder="123"
                          value={cardData.cvv}
                          onChange={(e) => handleCardInputChange('cvv', e.target.value)}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={12} className="mb-3">
                      <Form.Group>
                        <Form.Label>Tên chủ thẻ *</Form.Label>
                        <Form.Control
                          type="text"
                          placeholder="NGUYEN VAN A"
                          value={cardData.cardName}
                          onChange={(e) => handleCardInputChange('cardName', e.target.value.toUpperCase())}
                        />
                      </Form.Group>
                    </Col>
                  </Row>
                </div>
              )}

              {/* Other Payment Methods Info */}
              {paymentMethod === 'momo' && (
                <Alert variant="info" className="mt-4">
                  <FaQrcode className="me-2" />
                  Bạn sẽ được chuyển đến ứng dụng MoMo để hoàn tất thanh toán.
                </Alert>
              )}

              {paymentMethod === 'banking' && (
                <Alert variant="info" className="mt-4">
                  <FaUniversity className="me-2" />
                  Thông tin chuyển khoản sẽ được hiển thị sau khi xác nhận đặt phòng.
                </Alert>
              )}

              {paymentMethod === 'paypal' && (
                <Alert variant="info" className="mt-4">
                  <FaPaypal className="me-2" />
                  Bạn sẽ được chuyển đến PayPal để hoàn tất thanh toán.
                </Alert>
              )}

              <div className="d-grid mt-4">
                <Button 
                  variant="primary" 
                  size="lg"
                  onClick={() => setShowConfirmModal(true)}
                  disabled={isProcessing}
                >
                  {isProcessing ? (
                    <>
                      <Spinner as="span" animation="border" size="sm" role="status" className="me-2" />
                      Đang xử lý...
                    </>
                  ) : (
                    <>
                      <FaCreditCard className="me-2" />
                      Thanh toán {formatCurrency(booking.totalPrice || booking.total_amount || booking.tong_tien)}
                    </>
                  )}
                </Button>
              </div>
            </Card.Body>
          </Card>
        </Col>

        {/* Booking Summary */}
        <Col lg={4}>
          <Card className="position-sticky" style={{ top: '2rem' }}>
            <Card.Header>
              <h6 className="mb-0">Chi tiết đặt phòng</h6>
            </Card.Header>
            <Card.Body>
              <div className="d-flex mb-3">
                <img 
                  src={hotel.image} 
                  alt={hotel.name}
                  className="rounded me-3"
                  style={{ width: '60px', height: '60px', objectFit: 'cover' }}
                />
                <div>
                  <h6 className="mb-1">{hotel.name}</h6>
                  <small className="text-muted">{hotel.location}</small>
                </div>
              </div>

              <hr />

              <div className="mb-2">
                <strong>Mã đặt phòng:</strong>
                <div>{booking.id}</div>
              </div>

              <div className="mb-2">
                <strong>Check-in:</strong>
                <div>{formatDate(booking.checkinDate)}</div>
              </div>

              <div className="mb-2">
                <strong>Check-out:</strong>
                <div>{formatDate(booking.checkoutDate)}</div>
              </div>

              <div className="mb-2">
                <strong>Thời gian:</strong>
                <div>{nights} đêm</div>
              </div>

              <div className="mb-2">
                <strong>Khách:</strong>
                <div>{booking.guests} người</div>
              </div>

              <div className="mb-3">
                <strong>Phòng:</strong>
                <div>{booking.rooms} phòng</div>
              </div>

              <hr />

              <div className="d-flex justify-content-between align-items-center mb-3">
                <strong>Tổng tiền:</strong>
                <Badge bg="primary" className="fs-6">
                  {formatCurrency(booking.totalPrice || booking.total_amount || booking.tong_tien)}
                </Badge>
              </div>

              <small className="text-muted">
                * Bao gồm thuế và phí dịch vụ
              </small>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Confirm Payment Modal */}
      <Modal show={showConfirmModal} onHide={() => setShowConfirmModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>Xác nhận thanh toán</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Bạn có chắc chắn muốn thanh toán <strong>{formatCurrency(booking.totalPrice || booking.total_amount || booking.tong_tien)}</strong> cho đặt phòng này?</p>
          
          <Alert variant="warning" className="mb-0">
            <small>
              Lưu ý: Đây là môi trường demo. Không có giao dịch thực tế nào được thực hiện.
            </small>
          </Alert>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => setShowConfirmModal(false)}>
            Hủy
          </Button>
          <Button variant="primary" onClick={handlePayment}>
            Xác nhận thanh toán
          </Button>
        </Modal.Footer>
      </Modal>
    </Container>
  )
}

export default PaymentPage