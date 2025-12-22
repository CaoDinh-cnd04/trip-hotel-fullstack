import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Container, Row, Col, Card, Badge, Button, Form, InputGroup, Spinner } from 'react-bootstrap'
import { Search, Calendar, MapPin, Percent, Tag, Clock, Users } from 'lucide-react'
import { publicAPI } from '../../services/api/user'
import toast from 'react-hot-toast'

const PromotionsPage = () => {
  const [promotions, setPromotions] = useState([])
  const [searchTerm, setSearchTerm] = useState('')
  const [filterType, setFilterType] = useState('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [filteredPromotions, setFilteredPromotions] = useState([])

  // Load promotions from API
  useEffect(() => {
    const fetchPromotions = async () => {
      try {
        setLoading(true)
        const response = await publicAPI.getPromotions()
        
        if (response.data.success) {
          setPromotions(response.data.data || [])
        } else {
          throw new Error(response.data.message || 'Lỗi khi tải danh sách khuyến mãi')
        }
      } catch (error) {
        console.error('Error loading promotions:', error)
        setError(error.message)
        toast.error('Không thể tải danh sách khuyến mãi')
      } finally {
        setLoading(false)
      }
    }

    fetchPromotions()
  }, [])

  // Filter promotions
  useEffect(() => {
    let filtered = [...promotions]
    
    if (searchTerm) {
      filtered = filtered.filter(promo => 
        promo.ten?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        promo.mo_ta?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }
    
    if (filterType !== 'all') {
      filtered = filtered.filter(promo => {
        if (filterType === 'percentage') {
          // Chỉ có loại percentage trong dữ liệu
          return promo.phan_tram > 0
        } else if (filterType === 'fixed') {
          // Hiện tại chưa có loại fixed
          return false
        }
        return true
      })
    }
    
    setFilteredPromotions(filtered)
  }, [promotions, searchTerm, filterType])
  // Format discount helper
  const formatDiscount = (phan_tram) => {
    return `${phan_tram}%`
  }

  // Format date helper
  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('vi-VN')
  }

  // Check if promotion is valid
  const isValidPromotion = (ngay_ket_thuc) => {
    return new Date(ngay_ket_thuc) >= new Date()
  }

  // Get badge color based on discount
  const getDiscountBadgeColor = (phan_tram) => {
    if (phan_tram >= 30) {
      return 'danger'
    } else if (phan_tram >= 20) {
      return 'warning'
    } else if (phan_tram >= 10) {
      return 'info'
    } else {
      return 'success'
    }
  }

  if (loading) {
    return (
      <Container className="py-5">
        <div className="text-center">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="mt-3">Đang tải khuyến mãi...</p>
        </div>
      </Container>
    )
  }

  return (
    <div className="promotions-page">
      {/* Hero Section */}
      <section className="bg-gradient-to-r from-purple-600 to-blue-600 text-white py-5">
        <Container>
          <Row className="align-items-center">
            <Col lg={8}>
              <motion.div
                initial={{ opacity: 0, y: 50 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8 }}
              >
                <h1 className="display-4 fw-bold mb-3">
                  <Percent className="me-3" size={48} />
                  Khuyến Mãi Đặc Biệt
                </h1>
                <p className="lead">
                  Khám phá những ưu đãi tuyệt vời và tiết kiệm chi phí cho chuyến du lịch của bạn
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
                  <h3 className="text-warning fw-bold">Tiết kiệm đến</h3>
                  <h2 className="display-3 fw-bold">50%</h2>
                  <p>cho kỳ nghỉ của bạn</p>
                </div>
              </motion.div>
            </Col>
          </Row>
        </Container>
      </section>

      {/* Search and Filter Section */}
      <Container className="py-4">
        <Row className="mb-4">
          <Col md={8}>
            <InputGroup className="mb-3">
              <InputGroup.Text>
                <Search size={20} />
              </InputGroup.Text>
              <Form.Control
                type="text"
                placeholder="Tìm kiếm khuyến mãi..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </InputGroup>
          </Col>
          <Col md={4}>
            <Form.Select 
              value={filterType} 
              onChange={(e) => setFilterType(e.target.value)}
            >
              <option value="all">Tất cả khuyến mãi</option>
              <option value="percentage">Giảm theo %</option>
              <option value="fixed">Giảm số tiền cố định</option>
            </Form.Select>
          </Col>
        </Row>

        {/* Loading State */}
        {loading && (
          <div className="text-center py-5">
            <Spinner animation="border" variant="primary" size="lg" />
            <p className="mt-3 text-muted">Đang tải danh sách khuyến mãi...</p>
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="text-center py-5">
            <div className="text-danger mb-3">
              <h4>Có lỗi xảy ra</h4>
              <p>{error}</p>
            </div>
            <Button 
              variant="primary" 
              onClick={() => window.location.reload()}
            >
              Thử lại
            </Button>
          </div>
        )}

        {/* Stats */}
        {!loading && !error && (
          <Row className="mb-5">
            <Col md={4}>
              <Card className="border-0 shadow-sm h-100">
                <Card.Body className="text-center">
                  <Tag className="text-primary mb-3" size={48} />
                  <h4>{promotions.length}</h4>
                  <p className="text-muted">Tổng khuyến mãi</p>
                </Card.Body>
              </Card>
            </Col>
            <Col md={4}>
              <Card className="border-0 shadow-sm h-100">
                <Card.Body className="text-center">
                  <Clock className="text-success mb-3" size={48} />
                  <h4>{promotions.filter(p => isValidPromotion(p.ngay_ket_thuc)).length}</h4>
                  <p className="text-muted">Đang có hiệu lực</p>
                </Card.Body>
              </Card>
            </Col>
            <Col md={4}>
              <Card className="border-0 shadow-sm h-100">
                <Card.Body className="text-center">
                  <Users className="text-info mb-3" size={48} />
                  <h4>1000+</h4>
                  <p className="text-muted">Khách hàng đã sử dụng</p>
                </Card.Body>
              </Card>
            </Col>
          </Row>
        )}

        {/* Promotions Grid */}
        {!loading && !error && (
          <Row className="g-4">
            {filteredPromotions.length === 0 ? (
              <Col className="text-center py-5">
                <h4 className="text-muted">Không tìm thấy khuyến mãi nào</h4>
                <p className="text-muted">Hãy thử thay đổi bộ lọc tìm kiếm</p>
              </Col>
            ) : (
              filteredPromotions.map((promotion, index) => (
                <Col lg={6} xl={4} key={promotion.id} className="d-flex">
                  <motion.div
                    initial={{ opacity: 0, y: 50 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, delay: index * 0.1 }}
                    className="w-100"
                  >
                    <Card className="h-100 border-0 shadow-sm hover-shadow-lg transition-all d-flex flex-column">
                      <div className="position-relative overflow-hidden" style={{ height: '220px' }}>
                        <Card.Img
                          variant="top"
                          src={promotion.image ? `${import.meta.env.VITE_IMAGES_BASE_URL || 'http://localhost:5000/images'}/hotels/${promotion.image}` : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'}
                          style={{ height: '100%', objectFit: 'cover' }}
                          onError={(e) => {
                            e.target.src = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'
                          }}
                        />
                        <div className="position-absolute top-0 start-0 m-3">
                          <Badge 
                            bg={getDiscountBadgeColor(promotion.phan_tram)}
                            className="fs-6 px-3 py-2"
                          >
                            Giảm {formatDiscount(promotion.phan_tram)}
                          </Badge>
                        </div>
                        {!isValidPromotion(promotion.ngay_ket_thuc) && (
                          <div className="position-absolute top-0 end-0 m-3">
                            <Badge bg="secondary">Hết hạn</Badge>
                          </div>
                        )}
                      </div>

                      <Card.Body className="p-4 flex-grow-1 d-flex flex-column">
                        <Card.Title className="fw-bold text-dark mb-3" style={{ minHeight: '60px' }}>
                          {promotion.ten}
                        </Card.Title>
                        <Card.Text className="text-muted mb-3" style={{ minHeight: '72px', fontSize: '0.95rem' }}>
                          {promotion.mo_ta}
                        </Card.Text>

                        {/* Promotion Info */}
                        <div className="mb-3">
                          <div className="d-flex justify-content-between align-items-center mb-2">
                            <small className="text-muted">Mã khuyến mãi:</small>
                            <Badge bg="info" className="px-2 py-1">
                              {promotion.ma_khuyen_mai}
                            </Badge>
                          </div>
                          <div className="d-flex justify-content-between align-items-center mb-2">
                            <small className="text-muted">Hạn sử dụng:</small>
                            <small className="text-dark fw-semibold">
                              {formatDate(promotion.ngay_ket_thuc)}
                            </small>
                          </div>
                        </div>

                        <div className="mt-auto">
                          <div className="d-grid gap-2">
                            <Button
                              variant="primary"
                              className="fw-semibold"
                              disabled={!isValidPromotion(promotion.ngay_ket_thuc)}
                              onClick={() => {
                                if (promotion.ma_khuyen_mai) {
                                  navigator.clipboard.writeText(promotion.ma_khuyen_mai)
                                  toast.success('Đã sao chép mã khuyến mãi!')
                                }
                              }}
                              style={{ height: '44px' }}
                            >
                              {isValidPromotion(promotion.ngay_ket_thuc) ? 'Sao chép mã' : 'Đã hết hạn'}
                            </Button>
                            <Button 
                              variant="outline-primary" 
                              className="fw-semibold"
                              onClick={() => {
                                if (promotion.id_khach_san) {
                                  window.open(`/hotels/${promotion.id_khach_san}`, '_blank')
                                }
                              }}
                              style={{ height: '44px' }}
                            >
                              Xem khách sạn
                            </Button>
                          </div>
                        </div>
                      </Card.Body>
                    </Card>
                  </motion.div>
                </Col>
              ))
            )}
          </Row>
        )}
      </Container>

      {/* CTA Section */}
      <section className="bg-light py-5">
        <Container>
          <Row className="text-center">
            <Col>
              <h3 className="fw-bold mb-3">Đừng bỏ lỡ những ưu đãi tuyệt vời!</h3>
              <p className="text-muted mb-4">
                Đăng ký nhận thông tin về các chương trình khuyến mãi mới nhất
              </p>
              <div className="row justify-content-center">
                <div className="col-md-6">
                  <InputGroup className="mb-3">
                    <Form.Control
                      type="email"
                      placeholder="Nhập email của bạn"
                    />
                    <Button variant="primary">
                      Đăng ký ngay
                    </Button>
                  </InputGroup>
                </div>
              </div>
            </Col>
          </Row>
        </Container>
      </section>

      <style jsx>{`
        .hover-shadow-lg {
          transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .hover-shadow-lg:hover {
          transform: translateY(-8px);
          box-shadow: 0 15px 35px rgba(147, 51, 234, 0.25) !important;
        }
        .hover-shadow-lg img {
          transition: transform 0.5s ease;
        }
        .hover-shadow-lg:hover img {
          transform: scale(1.08);
        }
        .transition-all {
          transition: all 0.3s ease;
        }
        .bg-gradient-to-r {
          background: linear-gradient(to right, #9333ea, #3b82f6);
        }
        .bg-opacity-20 {
          background-color: rgba(255, 255, 255, 0.2) !important;
        }
        code {
          font-family: 'Courier New', monospace;
          font-weight: 600;
        }
        .card {
          overflow: hidden;
        }
      `}</style>
    </div>
  )
}

export default PromotionsPage