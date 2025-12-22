import React, { useState, useEffect } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Container, Row, Col, Card, Badge, Button, Form, Alert, Spinner } from 'react-bootstrap'
import { Filter, Star, MapPin, Calendar, Users, Search } from 'lucide-react'
import { hotelsAPI } from '../../services/api/user'
import toast from 'react-hot-toast'

const SearchResultsPage = () => {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  
  const searchQuery = searchParams.get('q') || ''
  const destination = searchParams.get('destination') || ''
  const checkin = searchParams.get('checkin') || ''
  const checkout = searchParams.get('checkout') || ''
  const guests = parseInt(searchParams.get('guests')) || 2

  const [filters, setFilters] = useState({
    sortBy: 'rating',
    priceRange: '',
    stars: ''
  })
  
  const [loading, setLoading] = useState(true)
  const [searchResults, setSearchResults] = useState([])
  const [error, setError] = useState(null)

  // Load search results from API
  useEffect(() => {
    const fetchSearchResults = async () => {
      try {
        setLoading(true)
        setError(null)
        
        const params = {}
        if (searchQuery) params.search = searchQuery
        if (destination) params.location = destination
        if (filters.priceRange) params.price_range = filters.priceRange
        if (filters.stars) params.stars = filters.stars
        
        const response = await hotelsAPI.getAll(params)
        
        if (response.data.success) {
          let results = response.data.data || []
          
          // Apply sorting
          if (filters.sortBy === 'price_low') {
            results.sort((a, b) => (a.gia_thap_nhat || 0) - (b.gia_thap_nhat || 0))
          } else if (filters.sortBy === 'price_high') {
            results.sort((a, b) => (b.gia_thap_nhat || 0) - (a.gia_thap_nhat || 0))
          } else if (filters.sortBy === 'rating') {
            results.sort((a, b) => (b.danh_gia || 0) - (a.danh_gia || 0))
          }
          
          setSearchResults(results)
        } else {
          throw new Error(response.data.message || 'Lỗi khi tìm kiếm khách sạn')
        }
      } catch (error) {
        console.error('Search error:', error)
        setError(error.message)
        toast.error('Không thể tải kết quả tìm kiếm')
        setSearchResults([])
      } finally {
        setLoading(false)
      }
    }

    fetchSearchResults()
  }, [searchQuery, destination, filters])

  const handleFilterChange = (key, value) => {
    setFilters(prev => ({
      ...prev,
      [key]: value
    }))
  }

  const formatPrice = (price) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(price)
  }

  const renderStars = (rating) => {
    const stars = []
    const fullStars = Math.floor(rating)
    
    for (let i = 0; i < fullStars; i++) {
      stars.push(<Star key={i} size={16} className="fill-yellow-400 text-yellow-400" />)
    }
    
    const remainingStars = 5 - fullStars
    for (let i = 0; i < remainingStars; i++) {
      stars.push(<Star key={`empty-${i}`} size={16} className="text-gray-300" />)
    }
    
    return stars
  }

  const handleHotelClick = (hotelId) => {
    navigate(`/hotels/${hotelId}`)
  }

  if (loading) {
    return (
      <Container className="py-5">
        <div className="text-center">
          <Spinner animation="border" variant="primary" />
          <p className="mt-3">Đang tìm kiếm khách sạn...</p>
        </div>
      </Container>
    )
  }

  return (
    <div className="search-results-page">
      {/* Header */}
      <div className="bg-primary text-white py-4">
        <Container>
          <Row>
            <Col>
              <h2 className="mb-2">Kết quả tìm kiếm</h2>
              <div className="d-flex flex-wrap gap-3 text-light">
                {searchQuery && (
                  <span><Search size={16} className="me-1" />"{searchQuery}"</span>
                )}
                {destination && (
                  <span><MapPin size={16} className="me-1" />{destination}</span>
                )}
                {checkin && checkout && (
                  <span><Calendar size={16} className="me-1" />{checkin} - {checkout}</span>
                )}
                <span><Users size={16} className="me-1" />{guests} khách</span>
              </div>
            </Col>
          </Row>
        </Container>
      </div>

      <Container className="py-4">
        <Row>
          <Col lg={3}>
            {/* Filters */}
            <Card className="mb-4">
              <Card.Header>
                <h5 className="mb-0">
                  <Filter size={20} className="me-2" />
                  Bộ lọc
                </h5>
              </Card.Header>
              <Card.Body>
                {/* Sort by */}
                <Form.Group className="mb-3">
                  <Form.Label>Sắp xếp theo</Form.Label>
                  <Form.Select
                    value={filters.sortBy}
                    onChange={(e) => handleFilterChange('sortBy', e.target.value)}
                  >
                    <option value="rating">Đánh giá cao nhất</option>
                    <option value="price_low">Giá thấp đến cao</option>
                    <option value="price_high">Giá cao đến thấp</option>
                  </Form.Select>
                </Form.Group>

                {/* Price range */}
                <Form.Group className="mb-3">
                  <Form.Label>Khoảng giá</Form.Label>
                  <Form.Select
                    value={filters.priceRange}
                    onChange={(e) => handleFilterChange('priceRange', e.target.value)}
                  >
                    <option value="">Tất cả</option>
                    <option value="0-1000000">Dưới 1 triệu</option>
                    <option value="1000000-2000000">1-2 triệu</option>
                    <option value="2000000-5000000">2-5 triệu</option>
                    <option value="5000000+">Trên 5 triệu</option>
                  </Form.Select>
                </Form.Group>

                {/* Star rating */}
                <Form.Group className="mb-3">
                  <Form.Label>Hạng sao</Form.Label>
                  <Form.Select
                    value={filters.stars}
                    onChange={(e) => handleFilterChange('stars', e.target.value)}
                  >
                    <option value="">Tất cả</option>
                    <option value="5">5 sao</option>
                    <option value="4">4 sao</option>
                    <option value="3">3 sao</option>
                  </Form.Select>
                </Form.Group>

                {/* Clear filters */}
                <Button
                  variant="outline-secondary"
                  className="w-100"
                  onClick={() => setFilters({ sortBy: 'rating', priceRange: '', stars: '' })}
                >
                  Xóa bộ lọc
                </Button>
              </Card.Body>
            </Card>
          </Col>

          <Col lg={9}>
            {error && (
              <Alert variant="danger" className="mb-4">
                {error}
              </Alert>
            )}

            <div className="d-flex justify-content-between align-items-center mb-3">
              <h5>
                {searchResults.length} khách sạn được tìm thấy
                {searchQuery && ` cho "${searchQuery}"`}
                {destination && ` tại ${destination}`}
              </h5>
            </div>

            {searchResults.length === 0 ? (
              <div className="text-center py-5">
                <h4 className="text-muted">Không tìm thấy khách sạn nào</h4>
                <p className="text-muted">Hãy thử thay đổi từ khóa tìm kiếm hoặc bộ lọc</p>
                <Button variant="primary" onClick={() => navigate('/hotels')}>
                  Xem tất cả khách sạn
                </Button>
              </div>
            ) : (
              <Row>
                {searchResults.map((hotel, index) => (
                  <Col key={hotel.id} lg={12} className="mb-4">
                    <motion.div
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.5, delay: index * 0.1 }}
                    >
                      <Card className="h-100 shadow-sm hover-shadow-lg cursor-pointer"
                            onClick={() => handleHotelClick(hotel.id)}>
                        <Row className="g-0">
                          <Col md={4}>
                            <Card.Img
                              src={hotel.hinh_anh || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'}
                              alt={hotel.ten_khach_san}
                              style={{ height: '250px', objectFit: 'cover' }}
                            />
                          </Col>
                          <Col md={8}>
                            <Card.Body className="d-flex flex-column h-100">
                              <div>
                                <div className="d-flex justify-content-between align-items-start mb-2">
                                  <div>
                                    <h5 className="card-title mb-1">{hotel.ten_khach_san}</h5>
                                    <div className="d-flex align-items-center mb-2">
                                      {Array.from({ length: hotel.so_sao || 5 }).map((_, i) => (
                                        <Star key={i} size={16} className="text-warning fill-warning" />
                                      ))}
                                      <Badge bg="primary" className="ms-2">{hotel.so_sao || 5} sao</Badge>
                                    </div>
                                  </div>
                                </div>

                                <div className="d-flex align-items-center mb-2">
                                  <MapPin size={16} className="text-muted me-1" />
                                  <small className="text-muted">{hotel.dia_chi}</small>
                                </div>

                                <div className="d-flex align-items-center mb-2">
                                  {renderStars(hotel.danh_gia || 4.5)}
                                  <span className="ms-2 fw-bold">{hotel.danh_gia || 4.5}</span>
                                  <span className="ms-1 text-muted">
                                    ({hotel.so_luong_danh_gia || 0} đánh giá)
                                  </span>
                                </div>

                                <p className="card-text text-muted mb-3">
                                  {hotel.mo_ta || 'Khách sạn tuyệt vời với dịch vụ chất lượng cao.'}
                                </p>
                              </div>

                              <div className="mt-auto">
                                <div className="d-flex justify-content-between align-items-center">
                                  <div>
                                    <small className="text-muted">Giá từ</small>
                                    <div className="h5 text-primary mb-0">
                                      {formatPrice(hotel.gia_thap_nhat)}
                                    </div>
                                    <small className="text-muted">/ đêm</small>
                                  </div>
                                  <Button variant="primary">
                                    Xem chi tiết
                                  </Button>
                                </div>
                              </div>
                            </Card.Body>
                          </Col>
                        </Row>
                      </Card>
                    </motion.div>
                  </Col>
                ))}
              </Row>
            )}
          </Col>
        </Row>
      </Container>
    </div>
  )
}

export default SearchResultsPage