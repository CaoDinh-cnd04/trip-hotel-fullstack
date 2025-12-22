import React, { useState, useEffect } from 'react'
import { Container, Row, Col, Card, Button, Form, InputGroup, Badge, Spinner } from 'react-bootstrap'
import { Search, Star, MapPin, Heart } from 'lucide-react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useFavoritesStore } from '../../stores/favoritesStore'
import { hotelsAPI, locationsAPI } from '../../services/api/user'
import toast from 'react-hot-toast'

const HotelsPage = () => {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const { toggleFavorite, isFavorite } = useFavoritesStore()
  
  const [filters, setFilters] = useState({
    search: searchParams.get('q') || '',
    stars: searchParams.get('stars') || '',
    sortBy: 'rating'
  })
  
  const [hotels, setHotels] = useState([])
  const [loading, setLoading] = useState(true)
  const [locations, setLocations] = useState([])
  const [error, setError] = useState(null)

  // Load hotels from API
  useEffect(() => {
    const fetchHotels = async () => {
      try {
        setLoading(true)
        const response = await hotelsAPI.getAll({
          page: 1,
          limit: 50,
          search: filters.search,
          stars: filters.stars,
          sort_by: filters.sortBy
        })
        
        if (response.data.success) {
          setHotels(response.data.data || [])
        } else {
          throw new Error(response.data.message || 'Lỗi khi tải danh sách khách sạn')
        }
      } catch (error) {
        console.error('Error loading hotels:', error)
        setError(error.message)
        toast.error('Không thể tải danh sách khách sạn')
      } finally {
        setLoading(false)
      }
    }

    fetchHotels()
  }, [filters])

  // Load locations for search suggestions
  useEffect(() => {
    const fetchLocations = async () => {
      try {
        const response = await locationsAPI.searchLocations('')
        if (response.data.success) {
          setLocations(response.data.data || [])
        }
      } catch (error) {
        console.error('Error loading locations:', error)
      }
    }

    fetchLocations()
  }, [])

  // Handle search
  const handleSearch = (e) => {
    e.preventDefault()
    setFilters(prev => ({ ...prev }))
  }

  // Handle hotel click
  const handleHotelClick = (hotelId) => {
    navigate(`/hotels/${hotelId}`)
  }

  const formatPrice = (price) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(price)
  }

  const renderStars = (rating) => {
    return (
      <div className="d-flex align-items-center">
        {Array.from({ length: 5 }, (_, index) => (
          <Star
            key={index}
            size={16}
            className={index < Math.floor(rating) ? 'text-warning' : 'text-muted'}
            fill={index < Math.floor(rating) ? 'currentColor' : 'none'}
          />
        ))}
      </div>
    )
  }

  return (
    <div className="hotels-page bg-light min-vh-100">
      {/* Header */}
      <div className="bg-primary text-white py-4">
        <Container>
          <Row>
            <Col>
              <h2 className="fw-bold mb-3">Khám phá khách sạn</h2>
              <p className="mb-4">Tìm thấy {hotels.length} khách sạn phù hợp</p>
              
              {/* Search and Filters */}
              <Row className="g-3">
                <Col lg={6}>
                  <InputGroup size="lg">
                    <InputGroup.Text className="bg-white border-0">
                      <Search size={20} className="text-muted" />
                    </InputGroup.Text>
                    <Form.Control
                      type="text"
                      placeholder="Tìm kiếm khách sạn..."
                      value={filters.search}
                      onChange={(e) => setFilters({...filters, search: e.target.value})}
                      className="border-0"
                    />
                  </InputGroup>
                </Col>
                <Col lg={3} md={6}>
                  <Form.Select 
                    size="lg"
                    value={filters.stars}
                    onChange={(e) => setFilters({...filters, stars: e.target.value})}
                    className="bg-white border-0"
                  >
                    <option value="">Tất cả hạng sao</option>
                    <option value="5">5 sao</option>
                    <option value="4">4 sao</option>
                    <option value="3">3 sao</option>
                  </Form.Select>
                </Col>
                <Col lg={3} md={6}>
                  <Form.Select 
                    size="lg"
                    value={filters.sortBy}
                    onChange={(e) => setFilters({...filters, sortBy: e.target.value})}
                    className="bg-white border-0"
                  >
                    <option value="rating">Đánh giá cao nhất</option>
                    <option value="price-low">Giá thấp đến cao</option>
                    <option value="price-high">Giá cao đến thấp</option>
                  </Form.Select>
                </Col>
              </Row>
            </Col>
          </Row>
        </Container>
      </div>

      {/* Loading State */}
      {loading && (
        <Container className="py-5 text-center">
          <Spinner animation="border" variant="primary" size="lg" />
          <p className="mt-3 text-muted">Đang tải danh sách khách sạn...</p>
        </Container>
      )}

      {/* Error State */}
      {error && (
        <Container className="py-5 text-center">
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
        </Container>
      )}

      {/* Hotels Grid */}
      {!loading && !error && (
        <Container className="py-4">
          <Row>
            {hotels.length === 0 ? (
              <Col className="text-center py-5">
                <h4 className="text-muted">Không tìm thấy khách sạn nào</h4>
                <p className="text-muted">Hãy thử thay đổi bộ lọc tìm kiếm</p>
              </Col>
            ) : (
              hotels.map((hotel) => (
            <Col xl={4} lg={6} md={6} key={hotel.id} className="mb-4">
              <Card 
                className="border-0 shadow-sm h-100 hotel-card"
                style={{ cursor: 'pointer' }}
                onClick={() => navigate(`/hotels/${hotel.id}`)}
              >
                <div className="position-relative overflow-hidden" style={{ height: '200px' }}>
                  <img 
                    src={hotel.hinh_anh || (hotel.image ? `${import.meta.env.VITE_IMAGES_BASE_URL || 'http://localhost:5000/images'}/hotels/${hotel.image}` : null) || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'} 
                    alt={hotel.ten_khach_san || hotel.ten}
                    className="w-100 h-100"
                    style={{ objectFit: 'cover', transition: 'transform 0.3s ease' }}
                    onError={(e) => {
                      e.target.src = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'
                    }}
                  />
                  <div className="position-absolute top-0 start-0 m-3">
                    <Badge bg="primary" className="px-3 py-2">
                      {hotel.so_sao || hotel.hang_sao || 4} sao
                    </Badge>
                  </div>
                  <div className="position-absolute top-0 end-0 m-3 d-flex flex-column gap-2">
                    <Badge bg="success" className="px-2 py-1">
                      Giảm 10%
                    </Badge>
                    <Button
                      variant={isFavorite(hotel.id) ? "danger" : "light"}
                      size="sm"
                      className="p-2 rounded-circle"
                      onClick={(e) => {
                        e.stopPropagation()
                        toggleFavorite(hotel)
                      }}
                      style={{ 
                        width: '36px', 
                        height: '36px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                      }}
                    >
                      <Heart 
                        size={16} 
                        fill={isFavorite(hotel.id) ? "currentColor" : "none"}
                      />
                    </Button>
                  </div>
                </div>
                
                <Card.Body className="p-3">
                  <h6 className="fw-bold mb-2 text-truncate" title={hotel.ten_khach_san || hotel.ten}>
                    {hotel.ten_khach_san || hotel.ten}
                  </h6>
                  
                  <div className="d-flex align-items-center mb-2">
                    <MapPin size={14} className="text-muted me-2" />
                    <small className="text-muted text-truncate">{hotel.dia_chi || hotel.address}</small>
                  </div>

                  <div className="d-flex align-items-center mb-3">
                    <div className="me-2">
                      {renderStars(hotel.danh_gia || hotel.rating || 4.5)}
                    </div>
                    <strong className="me-2 small">{hotel.danh_gia || hotel.rating || 4.5}</strong>
                    <small className="text-muted">({hotel.so_luong_danh_gia || hotel.review_count || 0} đánh giá)</small>
                  </div>

                  <div className="d-flex align-items-center justify-content-between">
                    <div>
                      <small className="text-muted text-decoration-line-through">
                        {formatPrice((hotel.gia_thap_nhat || hotel.min_price || 1000000) * 1.1)}
                      </small>
                      <h6 className="text-primary fw-bold mb-0">
                        {formatPrice(hotel.gia_thap_nhat || hotel.min_price || 1000000)}
                      </h6>
                      <small className="text-muted">/đêm</small>
                    </div>
                    <Button 
                      variant="outline-primary" 
                      size="sm"
                      onClick={(e) => {
                        e.stopPropagation()
                        navigate(`/hotels/${hotel.id}`)
                      }}
                    >
                      Đặt ngay
                    </Button>
                  </div>
                </Card.Body>
              </Card>
            </Col>
              ))
            )}
          </Row>
        </Container>
      )}

      <style jsx>{`
        .hotel-card:hover img {
          transform: scale(1.1);
        }
        .hotel-card {
          transition: all 0.3s ease;
        }
        .hotel-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 10px 25px rgba(0,0,0,0.15) !important;
        }
      `}</style>
    </div>
  )
}

export default HotelsPage