import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Search, Calendar, Users, Star, MapPin, TrendingUp, Award } from 'lucide-react'
import { Container, Row, Col, Card as BootstrapCard, Button as BootstrapButton, Form, InputGroup, Badge, Spinner } from 'react-bootstrap'
import { useNavigate } from 'react-router-dom'
import ImageWithFallback from '../../components/ui/ImageWithFallback'
import { useTranslation } from '../../hooks/useTranslation'
import DateRangePicker from '../../components/common/DateRangePicker'
import { hotelsAPI, locationsAPI } from '../../services/api/user'
import { getImageUrl, getLocationImageUrl, getProvinceImageUrl, getHotelImageUrl, getDefaultImageUrl } from '../../config/api'
import toast from 'react-hot-toast'

const HomePage = () => {
  const [searchData, setSearchData] = useState({
    destination: '',
    checkinDate: '',
    checkoutDate: '',
    guests: 2
  })
  const [loading, setLoading] = useState(true)
  const [featuredHotels, setFeaturedHotels] = useState([])
  const [destinations, setDestinations] = useState([])
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 })
  const [error, setError] = useState(null)

  const navigate = useNavigate()
  const { t } = useTranslation()

  // Mouse move effect
  useEffect(() => {
    const handleMouseMove = (e) => {
      setMousePosition({
        x: (e.clientX / window.innerWidth) * 100,
        y: (e.clientY / window.innerHeight) * 100
      })
    }

    window.addEventListener('mousemove', handleMouseMove)
    return () => window.removeEventListener('mousemove', handleMouseMove)
  }, [])

  useEffect(() => {
    // Set default dates
    const today = new Date()
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)
    
    setSearchData(prev => ({
      ...prev,
      checkinDate: today.toISOString().split('T')[0],
      checkoutDate: tomorrow.toISOString().split('T')[0]
    }))

    // Load featured hotels and destinations from API
    const fetchData = async () => {
      try {
        setLoading(true)
        
        // Fetch featured hotels
        const hotelsResponse = await hotelsAPI.getAll()
        if (hotelsResponse.data.success) {
          // Take first 9 hotels as featured
          const hotels = hotelsResponse.data.data.slice(0, 9)
          // Debug: Log hotel data to see image field names
          console.log('🏨 Featured Hotels:', JSON.stringify(hotels.map(h => ({
            id: h.id,
            ten: h.ten_khach_san || h.ten,
            hinh_anh: h.hinh_anh,
            image: h.image,
            gia_thap_nhat: h.gia_thap_nhat,
            danh_gia: h.danh_gia,
            so_luong_danh_gia: h.so_luong_danh_gia,
            allKeys: Object.keys(h)
          })), null, 2))
          setFeaturedHotels(hotels)
        }
        
        // Fetch destinations (provinces)
        try {
          const destinationsResponse = await locationsAPI.getProvinces(1) // Vietnam country ID = 1
          let provincesData = []
          
          // Handle different response formats
          if (destinationsResponse.data) {
            if (destinationsResponse.data.success && destinationsResponse.data.data) {
              provincesData = destinationsResponse.data.data
            } else if (Array.isArray(destinationsResponse.data)) {
              provincesData = destinationsResponse.data
            } else if (destinationsResponse.data.data && Array.isArray(destinationsResponse.data.data)) {
              provincesData = destinationsResponse.data.data
            }
          }
          
          if (provincesData.length > 0) {
            // Take first 6 provinces as popular destinations
            const destinations = provincesData.slice(0, 6)
            // Debug: Log destination data to see image field names
            console.log('📍 Destinations:', JSON.stringify(destinations.map(d => ({
              id: d.id,
              ten: d.ten_tinh || d.ten,
              hinh_anh: d.hinh_anh,
              image: d.image,
              allKeys: Object.keys(d)
            })), null, 2))
            setDestinations(destinations)
          } else {
            // Set default destinations if no data - using images from /images/provinces/
            setDestinations([
              { id: 1, ten_tinh: 'Hà Nội', hinh_anh: 'hanoi.jpg' },
              { id: 2, ten_tinh: 'Hồ Chí Minh', hinh_anh: 'hochiminh.jpg' },
              { id: 3, ten_tinh: 'Đà Nẵng', hinh_anh: 'danang.jpg' },
              { id: 4, ten_tinh: 'Nha Trang', hinh_anh: 'nhatrang.jpg' },
              { id: 5, ten_tinh: 'Phú Quốc', hinh_anh: 'phuquoc.jpg' },
              { id: 6, ten_tinh: 'Bangkok', hinh_anh: 'bangkok.jpg' }
            ])
          }
        } catch (destError) {
          console.error('Error loading destinations:', destError)
          // Set default destinations if API fails - using images from /images/provinces/
          setDestinations([
            { id: 1, ten_tinh: 'Hà Nội', hinh_anh: 'hanoi.jpg' },
            { id: 2, ten_tinh: 'Hồ Chí Minh', hinh_anh: 'hochiminh.jpg' },
            { id: 3, ten_tinh: 'Đà Nẵng', hinh_anh: 'danang.jpg' },
            { id: 4, ten_tinh: 'Nha Trang', hinh_anh: 'nhatrang.jpg' },
            { id: 5, ten_tinh: 'Phú Quốc', hinh_anh: 'phuquoc.jpg' },
            { id: 6, ten_tinh: 'Bangkok', hinh_anh: 'bangkok.jpg' }
          ])
        }
      } catch (error) {
        console.error('Error loading data:', error)
        setError('Không thể tải dữ liệu. Vui lòng thử lại sau.')
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  const handleSearch = (e) => {
    e.preventDefault()
    const searchParams = new URLSearchParams()
    
    if (searchData.destination) searchParams.append('q', searchData.destination)
    if (searchData.destination) searchParams.append('destination', searchData.destination)
    if (searchData.checkinDate) searchParams.append('checkin', searchData.checkinDate)
    if (searchData.checkoutDate) searchParams.append('checkout', searchData.checkoutDate)
    if (searchData.guests) searchParams.append('guests', searchData.guests)
    
    navigate(`/search?${searchParams.toString()}`)
  }

  const formatPrice = (price) => {
    if (price === null || price === undefined || price === '' || price === 'null' || price === 'undefined') {
      return 'Liên hệ'
    }
    const numPrice = typeof price === 'string' ? parseFloat(price.replace(/[^\d.-]/g, '')) : Number(price)
    if (isNaN(numPrice) || numPrice <= 0) {
      return 'Liên hệ'
    }
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(numPrice)
  }

  const renderStars = (rating) => {
    const numRating = rating ? (typeof rating === 'string' ? parseFloat(rating) : Number(rating)) : 0
    const validRating = isNaN(numRating) || numRating <= 0 ? 0 : Math.min(Math.max(numRating, 0), 5)
    const fullStars = Math.floor(validRating)
    
    return (
      <div className="d-flex align-items-center">
        {Array.from({ length: 5 }, (_, index) => (
          <Star
            key={index}
            size={16}
            className={index < fullStars ? 'text-warning' : 'text-muted'}
            fill={index < fullStars ? 'currentColor' : 'none'}
          />
        ))}
      </div>
    )
  }

  return (
    <div className="home-page">
      {/* Hero Section */}
      <section
        className="position-relative min-vh-100 d-flex align-items-center justify-content-center text-white overflow-hidden hero-section"
        style={{
          background: 'linear-gradient(135deg, #1e293b 0%, #7c3aed 50%, #1e293b 100%)'
        }}
      >
        {/* Wooden texture overlay */}
        <div 
          className="position-absolute top-0 start-0 w-100 h-100"
          style={{
            backgroundImage: 'url(https://images.unsplash.com/photo-1557672172-298e090bd0f1?w=1920&q=80)',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            opacity: 0.15,
            mixBlendMode: 'overlay'
          }}
        />

        {/* Dark overlay for better text readability */}
        <div 
          className="position-absolute top-0 start-0 w-100 h-100"
          style={{
            background: 'linear-gradient(135deg, rgba(30, 41, 59, 0.85) 0%, rgba(124, 58, 237, 0.7) 50%, rgba(30, 41, 59, 0.85) 100%)'
          }}
        />

        {/* Animated connection lines network */}
        <svg 
          className="position-absolute top-0 start-0 w-100 h-100" 
          style={{ opacity: 0.3, pointerEvents: 'none' }}
        >
          <defs>
            <linearGradient id="lineGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style={{ stopColor: 'rgba(255,255,255,0.8)', stopOpacity: 1 }} />
              <stop offset="100%" style={{ stopColor: 'rgba(147,51,234,0.8)', stopOpacity: 1 }} />
            </linearGradient>
          </defs>
          {/* Network lines */}
          <motion.line 
            x1="5%" y1="10%" x2="25%" y2="30%" 
            stroke="url(#lineGradient)" 
            strokeWidth="1.5"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 0.6 }}
            transition={{ duration: 2, delay: 0.5 }}
          />
          <motion.line 
            x1="25%" y1="30%" x2="15%" y2="60%" 
            stroke="url(#lineGradient)" 
            strokeWidth="1.5"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 0.6 }}
            transition={{ duration: 2, delay: 0.7 }}
          />
          <motion.line 
            x1="75%" y1="20%" x2="85%" y2="50%" 
            stroke="url(#lineGradient)" 
            strokeWidth="1.5"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 0.6 }}
            transition={{ duration: 2, delay: 0.6 }}
          />
          <motion.line 
            x1="85%" y1="50%" x2="95%" y2="80%" 
            stroke="url(#lineGradient)" 
            strokeWidth="1.5"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 0.6 }}
            transition={{ duration: 2, delay: 0.8 }}
          />
          <motion.line 
            x1="50%" y1="15%" x2="70%" y2="35%" 
            stroke="url(#lineGradient)" 
            strokeWidth="1.5"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 0.6 }}
            transition={{ duration: 2, delay: 0.9 }}
          />
          <motion.line 
            x1="30%" y1="70%" x2="50%" y2="85%" 
            stroke="url(#lineGradient)" 
            strokeWidth="1.5"
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 0.6 }}
            transition={{ duration: 2, delay: 1 }}
          />
        </svg>

        {/* Connection nodes */}
        <motion.div
          className="position-absolute"
          style={{ top: '10%', left: '5%', pointerEvents: 'none' }}
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.5, type: 'spring' }}
        >
          <div style={{
            width: '12px',
            height: '12px',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(255,255,255,0.9) 0%, rgba(147,51,234,0.6) 100%)',
            boxShadow: '0 0 20px rgba(255,255,255,0.6), 0 0 40px rgba(147,51,234,0.4)'
          }} />
        </motion.div>
        <motion.div
          className="position-absolute"
          style={{ top: '30%', left: '25%', pointerEvents: 'none' }}
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.7, type: 'spring' }}
        >
          <div style={{
            width: '10px',
            height: '10px',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(255,255,255,0.9) 0%, rgba(147,51,234,0.6) 100%)',
            boxShadow: '0 0 20px rgba(255,255,255,0.6)'
          }} />
        </motion.div>
        <motion.div
          className="position-absolute"
          style={{ top: '20%', right: '25%', pointerEvents: 'none' }}
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.6, type: 'spring' }}
        >
          <div style={{
            width: '11px',
            height: '11px',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(255,255,255,0.9) 0%, rgba(147,51,234,0.6) 100%)',
            boxShadow: '0 0 20px rgba(255,255,255,0.6)'
          }} />
        </motion.div>
        <motion.div
          className="position-absolute"
          style={{ top: '50%', right: '15%', pointerEvents: 'none' }}
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.8, type: 'spring' }}
        >
          <div style={{
            width: '9px',
            height: '9px',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(255,255,255,0.9) 0%, rgba(147,51,234,0.6) 100%)',
            boxShadow: '0 0 20px rgba(255,255,255,0.6)'
          }} />
        </motion.div>
        <motion.div
          className="position-absolute"
          style={{ bottom: '20%', right: '5%', pointerEvents: 'none' }}
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.8, type: 'spring' }}
        >
          <div style={{
            width: '10px',
            height: '10px',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(255,255,255,0.9) 0%, rgba(147,51,234,0.6) 100%)',
            boxShadow: '0 0 20px rgba(255,255,255,0.6)'
          }} />
        </motion.div>
        <motion.div
          className="position-absolute"
          style={{ bottom: '15%', left: '50%', pointerEvents: 'none' }}
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 1, type: 'spring' }}
        >
          <div style={{
            width: '11px',
            height: '11px',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(255,255,255,0.9) 0%, rgba(147,51,234,0.6) 100%)',
            boxShadow: '0 0 20px rgba(255,255,255,0.6)'
          }} />
        </motion.div>

        {/* Animated Background Gradient */}
        <motion.div
          className="position-absolute top-0 start-0 w-100 h-100"
          style={{
            background: `radial-gradient(circle at ${mousePosition.x}% ${mousePosition.y}%, rgba(147, 51, 234, 0.3) 0%, transparent 50%)`,
            pointerEvents: 'none'
          }}
          animate={{
            opacity: [0.5, 0.8, 0.5]
          }}
          transition={{
            duration: 3,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />

        {/* Parallax moving particles */}
        <motion.div
          className="position-absolute top-0 start-0 w-100 h-100 opacity-10"
          style={{
            transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
            pointerEvents: 'none'
          }}
        >
          {[...Array(15)].map((_, i) => (
            <motion.div
              key={i}
              className="position-absolute rounded-circle"
              style={{
                width: `${Math.random() * 4 + 1}px`,
                height: `${Math.random() * 4 + 1}px`,
                background: 'rgba(255, 255, 255, 0.8)',
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
                boxShadow: '0 0 8px rgba(255, 255, 255, 0.6)'
              }}
              animate={{
                y: [0, -30, 0],
                opacity: [0.3, 0.9, 0.3]
              }}
              transition={{
                duration: Math.random() * 3 + 2,
                repeat: Infinity,
                delay: Math.random() * 2
              }}
            />
          ))}
        </motion.div>        {/* Floating Elements */}
        <motion.div
          className="position-absolute"
          style={{ 
            top: '10%', 
            left: '10%',
            transform: `translate(${mousePosition.x * 0.05}px, ${mousePosition.y * 0.05}px)`
          }}
          initial={{ opacity: 0, scale: 0 }}
          animate={{
            opacity: 1,
            scale: 1,
            y: [0, -20, 0],
            rotate: [0, 5, 0]
          }}
          transition={{
            opacity: { duration: 0.8 },
            scale: { duration: 0.8 },
            y: { duration: 6, repeat: Infinity, ease: "easeInOut" },
            rotate: { duration: 6, repeat: Infinity, ease: "easeInOut" }
          }}
          whileHover={{ scale: 1.2, rotate: 15 }}
        >
          <div
            className="rounded-circle d-flex align-items-center justify-content-center floating-icon"
            style={{
              width: '80px',
              height: '80px',
              background: 'rgba(255, 255, 255, 0.1)',
              backdropFilter: 'blur(10px)',
              boxShadow: '0 8px 32px rgba(255, 215, 0, 0.3)',
              cursor: 'pointer',
              transition: 'all 0.3s ease'
            }}
          >
            <Award size={40} className="text-warning" />
          </div>
        </motion.div>

        <motion.div
          className="position-absolute"
          style={{ 
            top: '60%', 
            right: '15%',
            transform: `translate(${mousePosition.x * -0.03}px, ${mousePosition.y * -0.03}px)`
          }}
          initial={{ opacity: 0, scale: 0 }}
          animate={{
            opacity: 1,
            scale: 1,
            y: [0, 15, 0],
            x: [0, -10, 0]
          }}
          transition={{
            opacity: { duration: 0.8, delay: 0.2 },
            scale: { duration: 0.8, delay: 0.2 },
            y: { duration: 4, repeat: Infinity, ease: "easeInOut" },
            x: { duration: 4, repeat: Infinity, ease: "easeInOut" }
          }}
          whileHover={{ scale: 1.2, rotate: -15 }}
        >
          <div
            className="rounded-circle d-flex align-items-center justify-content-center floating-icon"
            style={{
              width: '60px',
              height: '60px',
              background: 'rgba(255, 255, 255, 0.1)',
              backdropFilter: 'blur(10px)',
              boxShadow: '0 8px 32px rgba(16, 185, 129, 0.3)',
              cursor: 'pointer',
              transition: 'all 0.3s ease'
            }}
          >
            <TrendingUp size={30} className="text-success" />
          </div>
        </motion.div>

        {/* Additional floating elements */}
        <motion.div
          className="position-absolute"
          style={{ 
            bottom: '20%', 
            left: '20%',
            transform: `translate(${mousePosition.x * 0.04}px, ${mousePosition.y * -0.04}px)`
          }}
          initial={{ opacity: 0, scale: 0 }}
          animate={{
            opacity: 1,
            scale: 1,
            y: [0, -15, 0],
            rotate: [0, -5, 0]
          }}
          transition={{
            opacity: { duration: 0.8, delay: 0.4 },
            scale: { duration: 0.8, delay: 0.4 },
            y: { duration: 5, repeat: Infinity, ease: "easeInOut" },
            rotate: { duration: 5, repeat: Infinity, ease: "easeInOut" }
          }}
          whileHover={{ scale: 1.2, rotate: 20 }}
        >
          <div
            className="rounded-circle d-flex align-items-center justify-content-center floating-icon"
            style={{
              width: '70px',
              height: '70px',
              background: 'rgba(255, 255, 255, 0.1)',
              backdropFilter: 'blur(10px)',
              boxShadow: '0 8px 32px rgba(147, 51, 234, 0.3)',
              cursor: 'pointer',
              transition: 'all 0.3s ease'
            }}
          >
            <MapPin size={35} className="text-info" />
          </div>
        </motion.div>

        {/* Additional floating element - top right */}
        <motion.div
          className="position-absolute d-none d-lg-block"
          style={{ 
            top: '25%', 
            right: '8%',
            transform: `translate(${mousePosition.x * -0.06}px, ${mousePosition.y * 0.04}px)`
          }}
          initial={{ opacity: 0, scale: 0 }}
          animate={{
            opacity: 1,
            scale: 1,
            y: [0, -18, 0],
            rotate: [0, 8, 0]
          }}
          transition={{
            opacity: { duration: 0.8, delay: 0.6 },
            scale: { duration: 0.8, delay: 0.6 },
            y: { duration: 4.5, repeat: Infinity, ease: "easeInOut" },
            rotate: { duration: 4.5, repeat: Infinity, ease: "easeInOut" }
          }}
          whileHover={{ scale: 1.3, rotate: -20 }}
        >
          <div
            className="rounded-circle d-flex align-items-center justify-content-center floating-icon"
            style={{
              width: '55px',
              height: '55px',
              background: 'rgba(255, 255, 255, 0.1)',
              backdropFilter: 'blur(10px)',
              boxShadow: '0 8px 32px rgba(59, 130, 246, 0.3)',
              cursor: 'pointer',
              transition: 'all 0.3s ease'
            }}
          >
            <Star size={28} className="text-primary" fill="currentColor" />
          </div>
        </motion.div>        <Container className="position-relative z-2">
          <Row className="justify-content-center">
            <Col lg={10}>
              <motion.div
                initial={{ opacity: 0, y: 50, scale: 0.9 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                transition={{ 
                  duration: 0.8,
                  type: "spring",
                  stiffness: 100
                }}
                className="text-center mb-5"
              >
                <motion.h1 
                  className="display-3 fw-bold mb-4"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.3, duration: 0.8 }}
                >
                  {t('heroTitle')}{' '}
                  <motion.span
                    initial={{ backgroundPosition: "0% 50%" }}
                    animate={{ backgroundPosition: ["0% 50%", "100% 50%", "0% 50%"] }}
                    transition={{ duration: 5, repeat: Infinity, ease: "linear" }}
                    style={{
                      background: 'linear-gradient(45deg, #f59e0b, #ef4444, #f59e0b)',
                      backgroundSize: '200% 200%',
                      WebkitBackgroundClip: 'text',
                      WebkitTextFillColor: 'transparent',
                      backgroundClip: 'text'
                    }}
                  >
                    TripHotel
                  </motion.span>
                </motion.h1>
                <motion.p 
                  className="lead fs-4 mb-0 text-white-50"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.5, duration: 0.8 }}
                >
                  {t('heroSubtitle')}
                </motion.p>
              </motion.div>              {/* Search Form */}
              <motion.div
                initial={{ opacity: 0, y: 30, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                transition={{ 
                  duration: 0.8,
                  delay: 0.6,
                  type: "spring",
                  stiffness: 100
                }}
                whileHover={{ 
                  scale: 1.01,
                  boxShadow: '0 20px 60px rgba(147, 51, 234, 0.3)'
                }}
                style={{
                  transform: `perspective(1000px) rotateX(${mousePosition.y * 0.02 - 1}deg) rotateY(${mousePosition.x * 0.02 - 1}deg)`
                }}
              >
                <BootstrapCard
                  className="shadow-lg border-0"
                  style={{
                    background: 'rgba(255, 255, 255, 0.95)',
                    backdropFilter: 'blur(20px)',
                    transition: 'all 0.3s ease'
                  }}
                >
                  <BootstrapCard.Body className="p-4">
                    <Form onSubmit={handleSearch}>
                      {/* Mobile Layout */}
                      <div className="d-lg-none">
                        <Row className="g-3">
                          <Col xs={12}>
                            <Form.Label className="text-dark fw-medium">{t('heroDestination')}</Form.Label>
                            <InputGroup size="lg">
                              <InputGroup.Text className="bg-light border-0">
                                <MapPin size={20} className="text-muted" />
                              </InputGroup.Text>
                              <Form.Control
                                type="text"
                                placeholder={t('heroSearchPlaceholder')}
                                value={searchData.destination}
                                onChange={(e) => setSearchData({...searchData, destination: e.target.value})}
                                className="border-0 bg-light"
                              />
                            </InputGroup>
                          </Col>
                          
                          <Col xs={12}>
                            <Form.Label className="text-dark fw-medium mb-2">{t('heroCheckin')} - {t('heroCheckout')}</Form.Label>
                            <motion.div
                              initial={{ opacity: 0, y: 20 }}
                              animate={{ opacity: 1, y: 0 }}
                              transition={{ duration: 0.5, delay: 0.2 }}
                            >
                              <DateRangePicker
                                checkinDate={searchData.checkinDate}
                                checkoutDate={searchData.checkoutDate}
                                onDateChange={(dates) => setSearchData({
                                  ...searchData,
                                  checkinDate: dates.checkinDate,
                                  checkoutDate: dates.checkoutDate
                                })}
                                className="w-100"
                              />
                            </motion.div>
                          </Col>
                          
                          <Col xs={6}>
                            <Form.Label className="text-dark fw-medium">{t('heroGuests')}</Form.Label>
                            <InputGroup>
                              <InputGroup.Text className="bg-light border-0">
                                <Users size={18} className="text-muted" />
                              </InputGroup.Text>
                              <Form.Select
                                value={searchData.guests}
                                onChange={(e) => setSearchData({...searchData, guests: parseInt(e.target.value)})}
                                className="border-0 bg-light"
                              >
                                {[1,2,3,4,5,6,7,8].map(num => (
                                  <option key={num} value={num}>{num} {t('guests')}</option>
                                ))}
                              </Form.Select>
                            </InputGroup>
                          </Col>
                          
                          <Col xs={6}>
                            <Form.Label className="text-dark fw-medium opacity-0">{t('search')}</Form.Label>
                            <BootstrapButton 
                              type="submit" 
                              size="lg" 
                              className="w-100 border-0 d-flex align-items-center justify-content-center"
                              style={{
                                background: 'linear-gradient(45deg, #9333ea, #3b82f6)',
                                fontSize: '16px',
                                height: '48px'
                              }}
                            >
                              <Search className="me-2" size={20} />
                              {t('heroSearchButton')}
                            </BootstrapButton>
                          </Col>
                        </Row>
                      </div>

                      {/* Desktop Layout */}
                      <div className="d-none d-lg-block">
                        <Row className="g-3">
                          <Col lg={3}>
                            <Form.Label className="text-dark fw-medium mb-2">{t('heroDestination')}</Form.Label>
                            <InputGroup size="lg">
                              <InputGroup.Text className="bg-light border-0">
                                <MapPin size={20} className="text-muted" />
                              </InputGroup.Text>
                              <Form.Control
                                type="text"
                                placeholder={t('heroSearchPlaceholder')}
                                value={searchData.destination}
                                onChange={(e) => setSearchData({...searchData, destination: e.target.value})}
                                className="border-0 bg-light"
                                style={{ fontSize: '16px' }}
                              />
                            </InputGroup>
                          </Col>
                          
                          <Col lg={4}>
                            <Form.Label className="text-dark fw-medium mb-2">{t('heroCheckin')} - {t('heroCheckout')}</Form.Label>
                            <motion.div
                              initial={{ opacity: 0, x: -20 }}
                              animate={{ opacity: 1, x: 0 }}
                              transition={{ duration: 0.5, delay: 0.3 }}
                            >
                              <DateRangePicker
                                checkinDate={searchData.checkinDate}
                                checkoutDate={searchData.checkoutDate}
                                onDateChange={(dates) => setSearchData({
                                  ...searchData,
                                  checkinDate: dates.checkinDate,
                                  checkoutDate: dates.checkoutDate
                                })}
                                className="w-100"
                              />
                            </motion.div>
                          </Col>
                          
                          <Col lg={2}>
                            <Form.Label className="text-dark fw-medium mb-2">{t('heroGuests')}</Form.Label>
                            <InputGroup size="lg">
                              <InputGroup.Text className="bg-light border-0">
                                <Users size={20} className="text-muted" />
                              </InputGroup.Text>
                              <Form.Select
                                value={searchData.guests}
                                onChange={(e) => setSearchData({...searchData, guests: parseInt(e.target.value)})}
                                className="border-0 bg-light"
                                style={{ fontSize: '16px' }}
                              >
                                {[1,2,3,4,5,6,7,8].map(num => (
                                  <option key={num} value={num}>{num} {t('guests')}</option>
                                ))}
                              </Form.Select>
                            </InputGroup>
                          </Col>
                          
                          <Col lg={3}>
                            <Form.Label className="text-dark fw-medium mb-2 opacity-0">{t('search')}</Form.Label>
                            <BootstrapButton 
                              type="submit" 
                              size="lg" 
                              className="w-100 border-0 d-flex align-items-center justify-content-center"
                              style={{
                                background: 'linear-gradient(45deg, #9333ea, #3b82f6)',
                                fontSize: '18px',
                                height: '58px',
                                borderRadius: '8px'
                              }}
                            >
                              <Search className="me-2" size={20} />
                              {t('heroSearchButton')}
                            </BootstrapButton>
                          </Col>
                        </Row>
                      </div>
                    </Form>
                  </BootstrapCard.Body>
                </BootstrapCard>
              </motion.div>
            </Col>
          </Row>
        </Container>
      </section>

      {/* Features Section */}
      <section className="py-5">
        <Container>
          <Row>
            <Col>
              <motion.div
                initial={{ opacity: 0, y: 50 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ duration: 0.8 }}
                className="text-center mb-5"
              >
                <motion.h2 
                  className="display-5 fw-bold mb-3"
                  initial={{ opacity: 0, scale: 0.9 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: 0.2, duration: 0.6 }}
                >
                  {t('featuresTitle')}
                </motion.h2>
              </motion.div>
            </Col>
          </Row>

          <Row>
            <Col lg={4} md={6} className="mb-4">
              <motion.div
                initial={{ opacity: 0, y: 50, scale: 0.9 }}
                whileInView={{ opacity: 1, y: 0, scale: 1 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ duration: 0.6, delay: 0.1 }}
                whileHover={{ y: -10, transition: { duration: 0.3 } }}
                className="text-center p-4"
              >
                <motion.div 
                  className="mb-4"
                  whileHover={{ rotate: 360, scale: 1.1 }}
                  transition={{ duration: 0.6 }}
                >
                  <div className="bg-primary rounded-circle d-inline-flex align-items-center justify-content-center" style={{ width: '80px', height: '80px', boxShadow: '0 10px 30px rgba(147, 51, 234, 0.3)' }}>
                    <TrendingUp className="text-white" size={40} />
                  </div>
                </motion.div>
                <h5 className="fw-bold mb-3">{t('feature1Title')}</h5>
                <p className="text-muted">{t('feature1Desc')}</p>
              </motion.div>
            </Col>

            <Col lg={4} md={6} className="mb-4">
              <motion.div
                initial={{ opacity: 0, y: 50, scale: 0.9 }}
                whileInView={{ opacity: 1, y: 0, scale: 1 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ duration: 0.6, delay: 0.2 }}
                whileHover={{ y: -10, transition: { duration: 0.3 } }}
                className="text-center p-4"
              >
                <motion.div 
                  className="mb-4"
                  whileHover={{ rotate: 360, scale: 1.1 }}
                  transition={{ duration: 0.6 }}
                >
                  <div className="bg-success rounded-circle d-inline-flex align-items-center justify-content-center" style={{ width: '80px', height: '80px', boxShadow: '0 10px 30px rgba(16, 185, 129, 0.3)' }}>
                    <Award className="text-white" size={40} />
                  </div>
                </motion.div>
                <h5 className="fw-bold mb-3">{t('feature2Title')}</h5>
                <p className="text-muted">{t('feature2Desc')}</p>
              </motion.div>
            </Col>

            <Col lg={4} md={6} className="mb-4">
              <motion.div
                initial={{ opacity: 0, y: 50, scale: 0.9 }}
                whileInView={{ opacity: 1, y: 0, scale: 1 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ duration: 0.6, delay: 0.3 }}
                whileHover={{ y: -10, transition: { duration: 0.3 } }}
                className="text-center p-4"
              >
                <motion.div 
                  className="mb-4"
                  whileHover={{ rotate: 360, scale: 1.1 }}
                  transition={{ duration: 0.6 }}
                >
                  <div className="bg-info rounded-circle d-inline-flex align-items-center justify-content-center" style={{ width: '80px', height: '80px', boxShadow: '0 10px 30px rgba(59, 130, 246, 0.3)' }}>
                    <Search className="text-white" size={40} />
                  </div>
                </motion.div>
                <h5 className="fw-bold mb-3">{t('feature3Title')}</h5>
                <p className="text-muted">{t('feature3Desc')}</p>
              </motion.div>
            </Col>
          </Row>
        </Container>
      </section>      {/* Popular Destinations */}
      <section className="py-5 bg-light">
        <Container>
          <Row>
            <Col>
              <motion.div
                initial={{ opacity: 0, y: 50 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8 }}
                className="text-center mb-5"
              >
                <h2 className="display-5 fw-bold mb-3">{t('popularDestinationsTitle')}</h2>
                <p className="lead text-muted">{t('popularDestinationsSubtitle')}</p>
              </motion.div>
            </Col>
          </Row>
          
          <Row>
            {loading ? (
              Array.from({ length: 6 }, (_, index) => (
                <Col lg={4} md={6} key={index} className="mb-4">
                  <BootstrapCard className="border-0 shadow-sm">
                    <div className="placeholder-glow">
                      <div className="placeholder" style={{ height: '200px', backgroundColor: '#f8f9fa' }}></div>
                    </div>
                    <BootstrapCard.Body>
                      <div className="placeholder-glow">
                        <span className="placeholder col-6"></span>
                      </div>
                    </BootstrapCard.Body>
                  </BootstrapCard>
                </Col>
              ))
            ) : (
              destinations.map((destination, index) => (
                <Col lg={4} md={6} key={destination.id} className="mb-4">
                  <motion.div
                    initial={{ opacity: 0, y: 50, scale: 0.9 }}
                    whileInView={{ opacity: 1, y: 0, scale: 1 }}
                    viewport={{ once: true, amount: 0.2 }}
                    transition={{ 
                      duration: 0.5, 
                      delay: index * 0.1,
                      type: "spring",
                      stiffness: 100
                    }}
                    whileHover={{ 
                      y: -10,
                      transition: { duration: 0.3 }
                    }}
                  >
                    <BootstrapCard
                      className="border-0 shadow-sm h-100 overflow-hidden destination-card"
                      style={{ cursor: 'pointer' }}
                      onClick={() => navigate(`/search?destination=${destination.ten_tinh || destination.ten}`)}
                    >
                      <div className="position-relative overflow-hidden" style={{ height: '200px' }}>
                        <ImageWithFallback 
                          src={(() => {
                            // Try multiple possible field names and paths
                            const imagePath = destination.hinh_anh || destination.image || destination.hinhAnh
                            let imageUrl = null
                            
                            if (imagePath) {
                              // Try province first (for destinations), then location
                              imageUrl = getProvinceImageUrl(imagePath) || getLocationImageUrl(imagePath)
                            }
                            
                            // If no image path, use default based on destination name
                            if (!imageUrl) {
                              // Try to map destination name to image file
                              const destName = (destination.ten_tinh || destination.ten || '').toLowerCase()
                              const imageMap = {
                                'hà nội': 'hanoi.jpg',
                                'hồ chí minh': 'hochiminh.jpg',
                                'đà nẵng': 'danang.jpg',
                                'nha trang': 'nhatrang.jpg',
                                'phú quốc': 'phuquoc.jpg',
                                'bangkok': 'bangkok.jpg'
                              }
                              const mappedImage = imageMap[destName]
                              if (mappedImage) {
                                imageUrl = getProvinceImageUrl(mappedImage)
                              } else {
                                imageUrl = getDefaultImageUrl()
                              }
                            }
                            
                            console.log(`📍 Destination ${destination.id} image:`, JSON.stringify({ 
                              id: destination.id,
                              name: destination.ten_tinh || destination.ten,
                              imagePath, 
                              imageUrl,
                              hinh_anh: destination.hinh_anh,
                              image: destination.image
                            }, null, 2))
                            return imageUrl
                          })()}
                          alt={destination.ten_tinh || destination.ten}
                          className="w-100 h-100"
                          style={{ objectFit: 'cover', transition: 'transform 0.3s ease' }}
                          fallbackSrc={getDefaultImageUrl()}
                        />
                        <div 
                          className="position-absolute top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center"
                          style={{
                            background: 'linear-gradient(rgba(0,0,0,0.2), rgba(0,0,0,0.5))'
                          }}
                        >
                          <h5 className="text-white fw-bold text-center">{destination.ten_tinh || destination.ten}</h5>
                        </div>
                      </div>
                    </BootstrapCard>
                  </motion.div>
                </Col>
              ))
            )}
          </Row>
        </Container>
      </section>

      {/* Featured Hotels */}
      <section className="py-5">
        <Container>
          <Row>
            <Col>
              <motion.div
                initial={{ opacity: 0, y: 50 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8 }}
                className="text-center mb-5"
              >
                <h2 className="display-5 fw-bold mb-3">Khách Sạn Nổi Bật</h2>
                <p className="lead text-muted">Những khách sạn được đánh giá cao nhất</p>
              </motion.div>
            </Col>
          </Row>
          
          {/* Row đầu tiên - 6 khách sạn nổi bật */}
          <Row>
            {loading ? (
              Array.from({ length: 6 }, (_, index) => (
                <Col xl={4} lg={6} md={6} key={index} className="mb-4">
                  <BootstrapCard className="border-0 shadow-sm">
                    <div className="placeholder-glow">
                      <div className="placeholder" style={{ height: '220px', backgroundColor: '#f8f9fa' }}></div>
                    </div>
                    <BootstrapCard.Body>
                      <div className="placeholder-glow">
                        <span className="placeholder col-8 mb-2"></span>
                        <span className="placeholder col-6"></span>
                      </div>
                    </BootstrapCard.Body>
                  </BootstrapCard>
                </Col>
              ))
            ) : (
              featuredHotels.slice(0, 6).map((hotel, index) => (
                <Col xl={4} lg={6} md={6} key={hotel.id} className="mb-4">
                  <motion.div
                    initial={{ opacity: 0, y: 60, scale: 0.9 }}
                    whileInView={{ opacity: 1, y: 0, scale: 1 }}
                    viewport={{ once: true, amount: 0.2 }}
                    transition={{ 
                      duration: 0.6, 
                      delay: index * 0.1,
                      type: "spring",
                      stiffness: 80
                    }}
                    whileHover={{ 
                      y: -12,
                      scale: 1.02,
                      transition: { duration: 0.3 }
                    }}
                  >
                    <BootstrapCard
                      className="border-0 shadow-sm h-100 hotel-card"
                      style={{ cursor: 'pointer' }}
                      onClick={() => navigate(`/hotels/${hotel.id}`)}
                    >
                      <div className="position-relative overflow-hidden" style={{ height: '220px' }}>
                        <ImageWithFallback 
                          src={(() => {
                            // Try multiple possible field names
                            const imagePath = hotel.hinh_anh || hotel.image || hotel.hinhAnh || hotel.avatar
                            const imageUrl = imagePath ? getHotelImageUrl(imagePath) : getDefaultImageUrl()
                            console.log(`🏨 Hotel ${hotel.id} image:`, JSON.stringify({ 
                              id: hotel.id,
                              name: hotel.ten_khach_san || hotel.ten,
                              imagePath, 
                              imageUrl,
                              hinh_anh: hotel.hinh_anh,
                              image: hotel.image
                            }, null, 2))
                            return imageUrl
                          })()}
                          alt={hotel.ten_khach_san || hotel.ten}
                          className="w-100 h-100"
                          style={{ objectFit: 'cover', transition: 'transform 0.3s ease' }}
                          fallbackSrc={getDefaultImageUrl()}
                        />
                        <div className="position-absolute top-0 end-0 m-3">
                          {index < 3 ? (
                            <Badge bg="danger" className="px-3 py-2">
                              <Star size={14} className="me-1" fill="white" />
                              Top {index + 1}
                            </Badge>
                          ) : (
                            <Badge bg="primary" className="px-3 py-2">
                              Nổi bật
                            </Badge>
                          )}
                        </div>
                        <div className="position-absolute bottom-0 start-0 m-3">
                          <Badge bg="success" className="px-2 py-1">
                            Giảm 15%
                          </Badge>
                        </div>
                      </div>
                      <BootstrapCard.Body className="p-3">
                        <h6 className="fw-bold mb-2 text-truncate" title={hotel.ten_khach_san}>
                          {hotel.ten_khach_san}
                        </h6>
                        
                        <div className="d-flex align-items-center mb-2">
                          <MapPin size={14} className="text-muted me-2" />
                          <small className="text-muted text-truncate">{hotel.dia_chi}</small>
                        </div>

                        <div className="d-flex align-items-center mb-2">
                          <div className="d-flex align-items-center me-3">
                            <div className="me-1">
                              {renderStars(hotel.danh_gia || hotel.rating || 0)}
                            </div>
                            <strong className="me-1 small">
                              {hotel.danh_gia || hotel.rating || '0.0'}
                            </strong>
                            <small className="text-muted">
                              ({hotel.so_luong_danh_gia || hotel.num_reviews || hotel.review_count || 0})
                            </small>
                          </div>
                        </div>

                        <div className="d-flex align-items-center justify-content-between">
                          <div className="text-start">
                            {(() => {
                              const price = hotel.gia_thap_nhat || hotel.gia_tien || hotel.price || hotel.gia_co_ban
                              const numPrice = price ? (typeof price === 'string' ? parseFloat(price) : Number(price)) : 0
                              return numPrice > 0 ? (
                                <>
                                  <small className="text-muted text-decoration-line-through">
                                    {formatPrice(numPrice * 1.15)}
                                  </small>
                                  <h6 className="text-primary fw-bold mb-0">
                                    {formatPrice(numPrice)}
                                  </h6>
                                  <small className="text-muted">/đêm</small>
                                </>
                              ) : (
                                <h6 className="text-primary fw-bold mb-0">
                                  {formatPrice(0)}
                                </h6>
                              )
                            })()}
                          </div>
                          <BootstrapButton 
                            variant="outline-primary" 
                            size="sm"
                            onClick={(e) => {
                              e.stopPropagation()
                              navigate(`/hotels/${hotel.id}`)
                            }}
                          >
                            Đặt ngay
                          </BootstrapButton>
                        </div>
                      </BootstrapCard.Body>
                    </BootstrapCard>
                  </motion.div>
                </Col>
              ))
            )}
          </Row>

          {/* Row thứ hai - 3 khách sạn còn lại với layout đặc biệt */}
          {!loading && featuredHotels.length > 6 && (
            <Row className="mt-4">
              <Col>
                <h4 className="fw-bold mb-4 text-center">Khách Sạn Cao Cấp</h4>
              </Col>
            </Row>
          )}
          
          {!loading && featuredHotels.length > 6 && (
            <Row>
              {featuredHotels.slice(6, 9).map((hotel, index) => (
                <Col lg={4} key={hotel.id} className="mb-4">
                  <motion.div
                    initial={{ opacity: 0, y: 60, scale: 0.95, rotateY: -10 }}
                    whileInView={{ opacity: 1, y: 0, scale: 1, rotateY: 0 }}
                    viewport={{ once: true, amount: 0.2 }}
                    transition={{ 
                      duration: 0.7, 
                      delay: index * 0.15,
                      type: "spring",
                      stiffness: 70
                    }}
                    whileHover={{ 
                      y: -15,
                      scale: 1.03,
                      rotateY: 2,
                      transition: { duration: 0.4 }
                    }}
                  >
                    <BootstrapCard
                      className="border-0 shadow-lg h-100 hotel-card-premium"
                      style={{ cursor: 'pointer' }}
                      onClick={() => navigate(`/hotels/${hotel.id}`)}
                    >
                      <div className="position-relative overflow-hidden" style={{ height: '280px' }}>
                        <ImageWithFallback 
                          src={hotel.hinh_anh} 
                          alt={hotel.ten_khach_san}
                          className="w-100 h-100"
                          style={{ objectFit: 'cover', transition: 'transform 0.3s ease' }}
                        />
                        <div className="position-absolute top-0 end-0 m-3">
                          <Badge bg="warning" className="px-3 py-2">
                            <Award size={14} className="me-1" />
                            Luxury
                          </Badge>
                        </div>
                        <div className="position-absolute bottom-0 start-0 end-0 p-3"
                          style={{
                            background: 'linear-gradient(transparent, rgba(0,0,0,0.7))'
                          }}
                        >
                          <h5 className="text-white fw-bold mb-1">{hotel.ten_khach_san}</h5>
                          <div className="d-flex align-items-center text-white-50">
                            <MapPin size={14} className="me-1" />
                            <small>{hotel.dia_chi}</small>
                          </div>
                        </div>
                      </div>
                      <BootstrapCard.Body className="p-4">
                        <div className="d-flex align-items-center justify-content-between mb-3">
                          <div className="d-flex align-items-center">
                            <div className="me-2">
                              {renderStars(hotel.danh_gia || hotel.rating || 0)}
                            </div>
                            <strong className="me-2">
                              {hotel.danh_gia || hotel.rating || '0.0'}
                            </strong>
                            <small className="text-muted">
                              ({hotel.so_luong_danh_gia || hotel.num_reviews || hotel.review_count || 0} đánh giá)
                            </small>
                          </div>
                        </div>

                        <div className="d-flex align-items-center justify-content-between">
                          <div>
                            <small className="text-muted">Từ</small>
                            <h5 className="text-primary fw-bold mb-0">
                              {formatPrice(hotel.gia_thap_nhat || hotel.gia_tien || hotel.price || hotel.gia_co_ban)}
                            </h5>
                            <small className="text-muted">/đêm</small>
                          </div>
                          <div className="text-end">
                            <BootstrapButton 
                              variant="primary" 
                              className="px-4"
                              onClick={(e) => {
                                e.stopPropagation()
                                navigate(`/hotels/${hotel.id}`)
                              }}
                            >
                              Xem chi tiết
                            </BootstrapButton>
                          </div>
                        </div>
                      </BootstrapCard.Body>
                    </BootstrapCard>
                  </motion.div>
                </Col>
              ))}
            </Row>
          )}
          
          <Row>
            <Col className="text-center">
              <BootstrapButton 
                variant="outline-primary" 
                size="lg"
                onClick={() => navigate('/hotels')}
              >
                Xem tất cả khách sạn
              </BootstrapButton>
            </Col>
          </Row>
        </Container>
      </section>

      {/* Stats Section */}
      <section className="py-5 bg-primary text-white position-relative overflow-hidden">
        {/* Animated background */}
        <motion.div
          className="position-absolute w-100 h-100"
          style={{ top: 0, left: 0, opacity: 0.1 }}
          animate={{
            backgroundPosition: ['0% 0%', '100% 100%']
          }}
          transition={{
            duration: 20,
            repeat: Infinity,
            repeatType: 'reverse'
          }}
        >
          <div style={{
            width: '100%',
            height: '100%',
            backgroundImage: 'radial-gradient(circle, white 1px, transparent 1px)',
            backgroundSize: '50px 50px'
          }}></div>
        </motion.div>

        <Container className="position-relative">
          <Row className="text-center">
            <Col md={3} sm={6} className="mb-4">
              <motion.div
                initial={{ opacity: 0, scale: 0.5, y: 50 }}
                whileInView={{ opacity: 1, scale: 1, y: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ 
                  duration: 0.6,
                  type: "spring",
                  stiffness: 100
                }}
                whileHover={{ scale: 1.1, transition: { duration: 0.3 } }}
              >
                <motion.h2 
                  className="display-4 fw-bold"
                  initial={{ opacity: 0 }}
                  whileInView={{ opacity: 1 }}
                  transition={{ delay: 0.2 }}
                >
                  1000+
                </motion.h2>
                <p className="mb-0">Khách sạn đối tác</p>
              </motion.div>
            </Col>
            <Col md={3} sm={6} className="mb-4">
              <motion.div
                initial={{ opacity: 0, scale: 0.5, y: 50 }}
                whileInView={{ opacity: 1, scale: 1, y: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ 
                  duration: 0.6, 
                  delay: 0.1,
                  type: "spring",
                  stiffness: 100
                }}
                whileHover={{ scale: 1.1, transition: { duration: 0.3 } }}
              >
                <motion.h2 
                  className="display-4 fw-bold"
                  initial={{ opacity: 0 }}
                  whileInView={{ opacity: 1 }}
                  transition={{ delay: 0.3 }}
                >
                  50K+
                </motion.h2>
                <p className="mb-0">Khách hàng hài lòng</p>
              </motion.div>
            </Col>
            <Col md={3} sm={6} className="mb-4">
              <motion.div
                initial={{ opacity: 0, scale: 0.5, y: 50 }}
                whileInView={{ opacity: 1, scale: 1, y: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ 
                  duration: 0.6, 
                  delay: 0.2,
                  type: "spring",
                  stiffness: 100
                }}
                whileHover={{ scale: 1.1, transition: { duration: 0.3 } }}
              >
                <motion.h2 
                  className="display-4 fw-bold"
                  initial={{ opacity: 0 }}
                  whileInView={{ opacity: 1 }}
                  transition={{ delay: 0.4 }}
                >
                  24/7
                </motion.h2>
                <p className="mb-0">Hỗ trợ khách hàng</p>
              </motion.div>
            </Col>
            <Col md={3} sm={6} className="mb-4">
              <motion.div
                initial={{ opacity: 0, scale: 0.5, y: 50 }}
                whileInView={{ opacity: 1, scale: 1, y: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ 
                  duration: 0.6, 
                  delay: 0.3,
                  type: "spring",
                  stiffness: 100
                }}
                whileHover={{ scale: 1.1, transition: { duration: 0.3 } }}
              >
                <motion.h2 
                  className="display-4 fw-bold"
                  initial={{ opacity: 0 }}
                  whileInView={{ opacity: 1 }}
                  transition={{ delay: 0.5 }}
                >
                  4.8★
                </motion.h2>
                <p className="mb-0">Đánh giá trung bình</p>
              </motion.div>
            </Col>
          </Row>
        </Container>
      </section>

      <style jsx>{`
        .destination-card img {
          transition: transform 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .destination-card:hover img {
          transform: scale(1.15) rotate(2deg);
        }
        .hotel-card img, .hotel-card-premium img {
          transition: transform 0.6s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .hotel-card:hover img {
          transform: scale(1.12) rotate(1deg);
        }
        .hotel-card-premium:hover img {
          transform: scale(1.15) rotate(-1deg);
        }
        .destination-card, .hotel-card, .hotel-card-premium {
          transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
          will-change: transform, box-shadow;
        }
        .hotel-card-premium {
          border: 2px solid transparent;
          background: linear-gradient(white, white) padding-box,
                      linear-gradient(45deg, #f59e0b, #ef4444, #9333ea) border-box;
          background-size: 200% 200%;
          animation: gradientShift 3s ease infinite;
        }
        @keyframes gradientShift {
          0%, 100% { background-position: 0% 50%; }
          50% { background-position: 100% 50%; }
        }
        .hotel-card-premium:hover {
          box-shadow: 0 20px 40px rgba(147, 51, 234, 0.3), 0 0 30px rgba(245, 158, 11, 0.2) !important;
        }
        .destination-card:hover {
          box-shadow: 0 15px 35px rgba(59, 130, 246, 0.25) !important;
        }
        .hotel-card:hover {
          box-shadow: 0 12px 30px rgba(0,0,0,0.18) !important;
        }
        .floating-icon {
          will-change: transform;
        }
        .floating-icon:hover {
          box-shadow: 0 15px 45px rgba(255, 255, 255, 0.4) !important;
        }
      `}</style>
    </div>
  )
}

export default HomePage