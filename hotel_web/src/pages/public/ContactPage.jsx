import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { Container, Row, Col, Card, Button, Form, Alert, Spinner } from 'react-bootstrap'
import { 
  MapPin, 
  Phone, 
  Mail, 
  Clock, 
  Send, 
  MessageCircle, 
  Headphones, 
  Globe,
  Facebook,
  Instagram,
  Twitter,
  Youtube
} from 'lucide-react'

const ContactPage = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    subject: '',
    message: ''
  })
  const [showAlert, setShowAlert] = useState({ show: false, type: '', message: '' })
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsSubmitting(true)

    // Validate form
    if (!formData.name || !formData.email || !formData.message) {
      setShowAlert({
        show: true,
        type: 'danger',
        message: 'Vui lòng điền đầy đủ thông tin bắt buộc!'
      })
      setIsSubmitting(false)
      return
    }

    // Simulate API call
    try {
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      setShowAlert({
        show: true,
        type: 'success',
        message: 'Cảm ơn bạn đã liên hệ! Chúng tôi sẽ phản hồi trong vòng 24 giờ.'
      })
      
      // Reset form
      setFormData({
        name: '',
        email: '',
        phone: '',
        subject: '',
        message: ''
      })
    } catch (error) {
      setShowAlert({
        show: true,
        type: 'danger',
        message: 'Có lỗi xảy ra. Vui lòng thử lại sau!'
      })
    }

    setIsSubmitting(false)
    
    // Hide alert after 5 seconds
    setTimeout(() => {
      setShowAlert({ show: false, type: '', message: '' })
    }, 5000)
  }

  const contactInfo = [
    {
      icon: <MapPin className="text-primary" size={24} />,
      title: "Địa chỉ",
      details: [
        "Tầng 10, Tòa nhà TripHotel Center",
        "123 Nguyễn Huệ, Quận 1",
        "TP. Hồ Chí Minh, Việt Nam"
      ]
    },
    {
      icon: <Phone className="text-success" size={24} />,
      title: "Điện thoại",
      details: [
        "Hotline: 1900 6868",
        "Mobile: +84 901 234 567",
        "Fax: +84 28 3823 4567"
      ]
    },
    {
      icon: <Mail className="text-info" size={24} />,
      title: "Email",
      details: [
        "info@triphotel.vn",
        "support@triphotel.vn",
        "booking@triphotel.vn"
      ]
    },
    {
      icon: <Clock className="text-warning" size={24} />,
      title: "Giờ làm việc",
      details: [
        "Thứ 2 - Thứ 6: 8:00 - 18:00",
        "Thứ 7: 8:00 - 12:00",
        "Chủ nhật: Nghỉ"
      ]
    }
  ]

  const supportTypes = [
    {
      icon: <Headphones className="text-primary" size={32} />,
      title: "Hỗ trợ đặt phòng",
      description: "Hỗ trợ tìm kiếm và đặt phòng khách sạn phù hợp",
      contact: "booking@triphotel.vn"
    },
    {
      icon: <MessageCircle className="text-success" size={32} />,
      title: "Khiếu nại - Góp ý",
      description: "Tiếp nhận và xử lý khiếu nại, góp ý từ khách hàng",
      contact: "feedback@triphotel.vn"
    },
    {
      icon: <Globe className="text-info" size={32} />,
      title: "Hỗ trợ kỹ thuật",
      description: "Giải quyết các vấn đề kỹ thuật trên website/app",
      contact: "tech@triphotel.vn"
    }
  ]

  return (
    <div className="contact-page">
      {/* Hero Section */}
      <section className="bg-gradient-to-r from-blue-600 to-purple-600 text-white py-5">
        <Container>
          <Row className="align-items-center">
            <Col lg={8}>
              <motion.div
                initial={{ opacity: 0, y: 50 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8 }}
              >
                <h1 className="display-4 fw-bold mb-3">
                  <MessageCircle className="me-3" size={48} />
                  Liên Hệ Với Chúng Tôi
                </h1>
                <p className="lead">
                  Chúng tôi luôn sẵn sàng hỗ trợ bạn 24/7. Hãy liên hệ để được tư vấn tốt nhất!
                </p>
              </motion.div>
            </Col>
            <Col lg={4} className="text-center">
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.8, delay: 0.3 }}
              >
                <div className="bg-white bg-opacity-20 rounded-3 p-4">
                  <Headphones size={48} className="text-warning mb-3" />
                  <h5>Hỗ trợ 24/7</h5>
                  <p>Luôn sẵn sàng phục vụ</p>
                </div>
              </motion.div>
            </Col>
          </Row>
        </Container>
      </section>

      <Container className="py-5">
        {/* Alert */}
        {showAlert.show && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-4"
          >
            <Alert variant={showAlert.type} dismissible onClose={() => setShowAlert({ show: false })}>
              {showAlert.message}
            </Alert>
          </motion.div>
        )}

        <Row>
          {/* Contact Form */}
          <Col lg={8}>
            <motion.div
              initial={{ opacity: 0, x: -50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.8 }}
            >
              <Card className="shadow-lg border-0">
                <Card.Header className="bg-primary text-white">
                  <h4 className="mb-0">
                    <Send className="me-2" size={24} />
                    Gửi Tin Nhắn
                  </h4>
                </Card.Header>
                <Card.Body className="p-4">
                  <Form onSubmit={handleSubmit}>
                    <Row>
                      <Col md={6}>
                        <Form.Group className="mb-3">
                          <Form.Label>Họ và tên <span className="text-danger">*</span></Form.Label>
                          <Form.Control
                            type="text"
                            name="name"
                            value={formData.name}
                            onChange={handleInputChange}
                            placeholder="Nhập họ và tên của bạn"
                            required
                          />
                        </Form.Group>
                      </Col>
                      <Col md={6}>
                        <Form.Group className="mb-3">
                          <Form.Label>Email <span className="text-danger">*</span></Form.Label>
                          <Form.Control
                            type="email"
                            name="email"
                            value={formData.email}
                            onChange={handleInputChange}
                            placeholder="your-email@example.com"
                            required
                          />
                        </Form.Group>
                      </Col>
                    </Row>
                    
                    <Row>
                      <Col md={6}>
                        <Form.Group className="mb-3">
                          <Form.Label>Số điện thoại</Form.Label>
                          <Form.Control
                            type="tel"
                            name="phone"
                            value={formData.phone}
                            onChange={handleInputChange}
                            placeholder="+84 901 234 567"
                          />
                        </Form.Group>
                      </Col>
                      <Col md={6}>
                        <Form.Group className="mb-3">
                          <Form.Label>Chủ đề</Form.Label>
                          <Form.Select
                            name="subject"
                            value={formData.subject}
                            onChange={handleInputChange}
                          >
                            <option value="">Chọn chủ đề</option>
                            <option value="booking">Hỗ trợ đặt phòng</option>
                            <option value="complaint">Khiếu nại</option>
                            <option value="suggestion">Góp ý</option>
                            <option value="technical">Hỗ trợ kỹ thuật</option>
                            <option value="partnership">Hợp tác kinh doanh</option>
                            <option value="other">Khác</option>
                          </Form.Select>
                        </Form.Group>
                      </Col>
                    </Row>

                    <Form.Group className="mb-4">
                      <Form.Label>Tin nhắn <span className="text-danger">*</span></Form.Label>
                      <Form.Control
                        as="textarea"
                        rows={5}
                        name="message"
                        value={formData.message}
                        onChange={handleInputChange}
                        placeholder="Nhập nội dung tin nhắn của bạn..."
                        required
                      />
                    </Form.Group>

                    <div className="d-grid">
                      <Button 
                        type="submit" 
                        size="lg" 
                        disabled={isSubmitting}
                        className="bg-gradient-to-r from-blue-600 to-purple-600 border-0"
                      >
                        {isSubmitting ? (
                          <>
                            <Spinner animation="border" size="sm" className="me-2" />
                            Đang gửi...
                          </>
                        ) : (
                          <>
                            <Send className="me-2" size={20} />
                            Gửi tin nhắn
                          </>
                        )}
                      </Button>
                    </div>
                  </Form>
                </Card.Body>
              </Card>
            </motion.div>
          </Col>

          {/* Contact Info */}
          <Col lg={4}>
            <motion.div
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.8 }}
            >
              <Card className="shadow-lg border-0 mb-4">
                <Card.Header className="bg-success text-white">
                  <h5 className="mb-0">Thông Tin Liên Hệ</h5>
                </Card.Header>
                <Card.Body className="p-0">
                  {contactInfo.map((info, index) => (
                    <div key={index} className="p-3 border-bottom">
                      <div className="d-flex align-items-start">
                        <div className="me-3 mt-1">
                          {info.icon}
                        </div>
                        <div>
                          <h6 className="fw-bold mb-2">{info.title}</h6>
                          {info.details.map((detail, idx) => (
                            <p key={idx} className="text-muted mb-1 small">
                              {detail}
                            </p>
                          ))}
                        </div>
                      </div>
                    </div>
                  ))}
                </Card.Body>
              </Card>

              {/* Social Media */}
              <Card className="shadow-lg border-0">
                <Card.Header className="bg-info text-white">
                  <h5 className="mb-0">Kết Nối Với Chúng Tôi</h5>
                </Card.Header>
                <Card.Body>
                  <div className="d-flex justify-content-around">
                    <Button variant="outline-primary" className="rounded-circle p-2">
                      <Facebook size={20} />
                    </Button>
                    <Button variant="outline-danger" className="rounded-circle p-2">
                      <Instagram size={20} />
                    </Button>
                    <Button variant="outline-info" className="rounded-circle p-2">
                      <Twitter size={20} />
                    </Button>
                    <Button variant="outline-danger" className="rounded-circle p-2">
                      <Youtube size={20} />
                    </Button>
                  </div>
                  <p className="text-center text-muted mt-3 mb-0 small">
                    Theo dõi chúng tôi để cập nhật tin tức mới nhất
                  </p>
                </Card.Body>
              </Card>
            </motion.div>
          </Col>
        </Row>

        {/* Support Types */}
        <Row className="mt-5">
          <Col>
            <h3 className="text-center fw-bold mb-4">Các Loại Hỗ Trợ</h3>
            <Row>
              {supportTypes.map((support, index) => (
                <Col md={4} key={index} className="mb-4">
                  <motion.div
                    initial={{ opacity: 0, y: 50 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, delay: index * 0.2 }}
                  >
                    <Card className="text-center h-100 border-0 shadow-sm hover-shadow-lg">
                      <Card.Body className="p-4">
                        <div className="mb-3">
                          {support.icon}
                        </div>
                        <h5 className="fw-bold">{support.title}</h5>
                        <p className="text-muted">{support.description}</p>
                        <Button variant="outline-primary" size="sm">
                          <Mail className="me-1" size={16} />
                          {support.contact}
                        </Button>
                      </Card.Body>
                    </Card>
                  </motion.div>
                </Col>
              ))}
            </Row>
          </Col>
        </Row>

        {/* Map Section */}
        <Row className="mt-5">
          <Col>
            <h3 className="text-center fw-bold mb-4">Vị Trí Của Chúng Tôi</h3>
            <Card className="border-0 shadow-lg">
              <Card.Body className="p-0">
                <div style={{ height: '400px', background: '#f8f9fa' }} className="d-flex align-items-center justify-content-center">
                  <div className="text-center">
                    <MapPin size={48} className="text-muted mb-3" />
                    <h5>Google Map sẽ được tích hợp tại đây</h5>
                    <p className="text-muted">123 Nguyễn Huệ, Quận 1, TP.HCM</p>
                    <Button variant="primary">
                      Xem trên Google Maps
                    </Button>
                  </div>
                </div>
              </Card.Body>
            </Card>
          </Col>
        </Row>

        {/* FAQ Section */}
        <Row className="mt-5">
          <Col>
            <h3 className="text-center fw-bold mb-4">Câu Hỏi Thường Gặp</h3>
            <Row>
              <Col lg={6}>
                <Card className="border-0 shadow-sm mb-3">
                  <Card.Body>
                    <h6 className="fw-bold">Làm sao để đặt phòng trên TripHotel?</h6>
                    <p className="text-muted mb-0 small">
                      Bạn có thể tìm kiếm khách sạn, chọn phòng phù hợp và tiến hành đặt phòng online một cách dễ dàng.
                    </p>
                  </Card.Body>
                </Card>
                <Card className="border-0 shadow-sm mb-3">
                  <Card.Body>
                    <h6 className="fw-bold">Tôi có thể hủy đặt phòng được không?</h6>
                    <p className="text-muted mb-0 small">
                      Điều kiện hủy phòng tùy thuộc vào chính sách của từng khách sạn. Vui lòng kiểm tra thông tin chi tiết.
                    </p>
                  </Card.Body>
                </Card>
              </Col>
              <Col lg={6}>
                <Card className="border-0 shadow-sm mb-3">
                  <Card.Body>
                    <h6 className="fw-bold">Các hình thức thanh toán nào được chấp nhận?</h6>
                    <p className="text-muted mb-0 small">
                      Chúng tôi chấp nhận thanh toán qua thẻ tín dụng, chuyển khoản ngân hàng và các ví điện tử.
                    </p>
                  </Card.Body>
                </Card>
                <Card className="border-0 shadow-sm mb-3">
                  <Card.Body>
                    <h6 className="fw-bold">Làm sao để liên hệ khách sạn trực tiếp?</h6>
                    <p className="text-muted mb-0 small">
                      Thông tin liên hệ của khách sạn sẽ được gửi qua email sau khi bạn hoàn tất đặt phòng.
                    </p>
                  </Card.Body>
                </Card>
              </Col>
            </Row>
          </Col>
        </Row>
      </Container>

      <style jsx>{`
        .hover-shadow-lg {
          transition: all 0.3s ease;
        }
        .hover-shadow-lg:hover {
          transform: translateY(-5px);
          box-shadow: 0 10px 25px rgba(0,0,0,0.15) !important;
        }
        .bg-gradient-to-r {
          background: linear-gradient(to right, #3b82f6, #9333ea);
        }
        .bg-opacity-20 {
          background-color: rgba(255, 255, 255, 0.2) !important;
        }
      `}</style>
    </div>
  )
}

export default ContactPage