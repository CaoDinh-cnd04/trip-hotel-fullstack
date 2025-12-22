import React from 'react'
import { Container, Row, Col, Card, Button, Badge } from 'react-bootstrap'
import { Heart, MapPin, Star, Trash2, ShoppingCart } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useFavoritesStore } from '../../stores/favoritesStore'

const FavoritesPage = () => {
  const navigate = useNavigate()
  const { favorites, removeFromFavorites, clearFavorites } = useFavoritesStore()

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
            size={14}
            className={index < Math.floor(rating) ? 'text-warning' : 'text-muted'}
            fill={index < Math.floor(rating) ? 'currentColor' : 'none'}
          />
        ))}
      </div>
    )
  }

  if (favorites.length === 0) {
    return (
      <div className="favorites-page bg-light min-vh-100">
        <Container className="py-5">
          <Row className="justify-content-center">
            <Col md={6} className="text-center">
              <Heart size={64} className="text-muted mb-3" />
              <h3 className="fw-bold mb-3">Danh sách yêu thích trống</h3>
              <p className="text-muted mb-4">
                Bạn chưa có khách sạn nào trong danh sách yêu thích. 
                Hãy khám phá và thêm những khách sạn ưa thích của bạn!
              </p>
              <Button 
                variant="primary" 
                size="lg"
                onClick={() => navigate('/hotels')}
              >
                Khám phá khách sạn
              </Button>
            </Col>
          </Row>
        </Container>
      </div>
    )
  }

  return (
    <div className="favorites-page bg-light min-vh-100">
      <Container className="py-4">
        {/* Header */}
        <div className="d-flex justify-content-between align-items-center mb-4">
          <div>
            <h2 className="fw-bold mb-2">
              <Heart className="text-danger me-2" size={28} />
              Danh sách yêu thích
            </h2>
            <p className="text-muted mb-0">
              Bạn có {favorites.length} khách sạn trong danh sách yêu thích
            </p>
          </div>
          
          {favorites.length > 0 && (
            <Button 
              variant="outline-danger"
              onClick={clearFavorites}
            >
              <Trash2 size={16} className="me-2" />
              Xóa tất cả
            </Button>
          )}
        </div>

        {/* Favorites Grid */}
        <Row>
          {favorites.map((hotel) => (
            <Col xl={4} lg={6} md={6} key={hotel.id} className="mb-4">
              <Card 
                className="border-0 shadow-sm h-100 hotel-card"
                style={{ cursor: 'pointer' }}
                onClick={() => navigate(`/hotels/${hotel.id}`)}
              >
                <div className="position-relative overflow-hidden" style={{ height: '200px' }}>
                  <img 
                    src={hotel.hinh_anh} 
                    alt={hotel.ten}
                    className="w-100 h-100"
                    style={{ objectFit: 'cover', transition: 'transform 0.3s ease' }}
                  />
                  <div className="position-absolute top-0 start-0 m-3">
                    <Badge bg="primary" className="px-3 py-2">
                      {hotel.so_sao} sao
                    </Badge>
                  </div>
                  <div className="position-absolute top-0 end-0 m-3">
                    <Button
                      variant="danger"
                      size="sm"
                      className="p-2 rounded-circle"
                      onClick={(e) => {
                        e.stopPropagation()
                        removeFromFavorites(hotel.id)
                      }}
                      style={{ 
                        width: '36px', 
                        height: '36px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                      }}
                    >
                      <Heart size={16} fill="currentColor" />
                    </Button>
                  </div>
                </div>
                
                <Card.Body className="p-3">
                  <h6 className="fw-bold mb-2 text-truncate" title={hotel.ten}>
                    {hotel.ten}
                  </h6>
                  
                  <div className="d-flex align-items-center mb-2">
                    <MapPin size={14} className="text-muted me-2" />
                    <small className="text-muted text-truncate">{hotel.dia_chi}</small>
                  </div>

                  <div className="d-flex align-items-center mb-3">
                    <div className="me-2">
                      {renderStars(hotel.rating)}
                    </div>
                    <strong className="me-2 small">{hotel.rating}</strong>
                    <small className="text-muted">({hotel.reviews_count} đánh giá)</small>
                  </div>

                  <div className="d-flex align-items-center justify-content-between">
                    <div>
                      <h6 className="text-primary fw-bold mb-0">
                        {formatPrice(hotel.gia_thap_nhat)}
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
                      <ShoppingCart size={14} className="me-1" />
                      Đặt ngay
                    </Button>
                  </div>

                  <div className="mt-2">
                    <small className="text-muted">
                      Đã thêm: {new Date(hotel.addedAt).toLocaleDateString('vi-VN')}
                    </small>
                  </div>
                </Card.Body>
              </Card>
            </Col>
          ))}
        </Row>
      </Container>

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

export default FavoritesPage