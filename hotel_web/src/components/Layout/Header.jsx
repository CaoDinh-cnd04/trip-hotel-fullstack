import React, { useState } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { 
  Menu, 
  X, 
  User, 
  LogOut, 
  Settings, 
  Heart, 
  Calendar,
  MapPin,
  Phone,
  Mail,
  Shield,
  Building2
} from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { Navbar, Nav, Container, Button as BootstrapButton, Dropdown } from 'react-bootstrap'
import { useAuthStore } from '../../stores/authStore'
import { useFavoritesStore } from '../../stores/favoritesStore'
import { useBookingsStore } from '../../stores/bookingsStore'
import { useNotificationsStore } from '../../stores/notificationsStore'
import Button from '../ui/Button'
import NotificationBell from '../notifications/NotificationBell'
import LanguageSelector from '../language/LanguageSelector'
import { useTranslation } from '../../hooks/useTranslation'

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  const { user, logout, isAdmin, isHotelManager } = useAuthStore()
  const isAuthenticated = useAuthStore(state => !!state.user && !!state.token)

  // Scroll effect
  React.useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])
  const { getFavoritesCount } = useFavoritesStore()
  const { getTotalBookings } = useBookingsStore()
  const { fetchNotifications, initialize } = useNotificationsStore()
  const navigate = useNavigate()
  const location = useLocation()
  const { t } = useTranslation()

  // Fetch notifications when user is authenticated
  React.useEffect(() => {
    if (isAuthenticated) {
      initialize()
      // Set up polling to fetch notifications every 30 seconds
      const interval = setInterval(() => {
        fetchNotifications()
      }, 30000)
      return () => clearInterval(interval)
    }
  }, [isAuthenticated, initialize, fetchNotifications])

  const handleLogout = () => {
    logout()
    navigate('/')
    setIsUserMenuOpen(false)
  }

  const navigation = [
    { name: t('hotels'), href: '/hotels', current: location.pathname === '/hotels' },
    { name: t('promotions'), href: '/promotions', current: location.pathname === '/promotions' },
    { name: t('booked'), href: '/bookings', current: location.pathname === '/bookings' || location.pathname.startsWith('/payment/'), badge: getTotalBookings() },
    { name: t('favorites'), href: '/favorites', current: location.pathname === '/favorites', badge: getFavoritesCount() },
    { name: t('contact'), href: '/contact', current: location.pathname === '/contact' },
  ]

  return (
    <motion.header 
      initial={{ y: -100, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.6, type: 'spring', stiffness: 100 }}
      className={`bg-white/95 backdrop-blur-lg sticky top-0 z-50 border-b transition-all duration-300 ${
        scrolled ? 'shadow-xl border-gray-200' : 'shadow-md border-gray-100'
      }`}
      style={{
        boxShadow: scrolled ? '0 10px 40px rgba(147, 51, 234, 0.1)' : '0 4px 6px rgba(0, 0, 0, 0.05)'
      }}
    >
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-20">
          {/* Logo */}
          <div className="flex items-center">
            <Link to="/" className="flex-shrink-0 flex items-center group">
              <motion.div 
                className="h-10 w-10 bg-gradient-to-br from-purple-600 to-blue-600 rounded-xl flex items-center justify-center shadow-lg"
                whileHover={{ 
                  scale: 1.1, 
                  rotate: 5,
                  boxShadow: '0 15px 30px rgba(147, 51, 234, 0.4)'
                }}
                whileTap={{ scale: 0.95 }}
                transition={{ type: 'spring', stiffness: 400, damping: 17 }}
              >
                <motion.span 
                  className="text-white font-bold text-lg"
                  animate={{ 
                    scale: [1, 1.1, 1],
                  }}
                  transition={{ 
                    duration: 2,
                    repeat: Infinity,
                    ease: 'easeInOut'
                  }}
                >
                  T
                </motion.span>
              </motion.div>
              <motion.span 
                className="ml-3 text-2xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent"
                whileHover={{ scale: 1.05 }}
                transition={{ type: 'spring', stiffness: 400 }}
              >
                TripHotel
              </motion.span>
            </Link>
          </div>



          {/* Desktop Navigation */}
          <Nav className="d-none d-md-flex align-items-center">
            {navigation.map((item, index) => (
              <motion.div
                key={item.name}
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1, duration: 0.5 }}
              >
                <Nav.Link
                  as={Link}
                  to={item.href}
                  className={`px-4 py-2 rounded-pill text-sm fw-medium transition-all mx-1 text-decoration-none position-relative ${
                    item.current
                      ? 'text-white shadow-sm'
                      : 'text-dark'
                  }`}
                  style={{
                    ...(item.current ? {
                      background: 'linear-gradient(45deg, #9333ea, #3b82f6)',
                      transform: 'translateY(-2px)'
                    } : {})
                  }}
                >
                <motion.div
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  transition={{ type: 'spring', stiffness: 400, damping: 17 }}
                >
                  <div className="d-flex align-items-center">
                    {item.name === 'Yêu thích' && <Heart size={16} className="me-1" />}
                    {item.name}
                    {item.badge > 0 && (
                      <motion.span 
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        className="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" 
                        style={{ fontSize: '10px' }}
                      >
                        {item.badge}
                        <span className="visually-hidden">khách sạn yêu thích</span>
                      </motion.span>
                    )}
                  </div>
                </motion.div>
              </Nav.Link>
              </motion.div>
            ))}
          </Nav>

          {/* Auth Buttons - Desktop */}
          <motion.div 
            className="hidden md:flex items-center space-x-4"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4, duration: 0.5 }}
          >
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <LanguageSelector />
            </motion.div>
            {isAuthenticated ? (
              <>
                {/* Notification Bell - Next to Avatar */}
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: 'spring', stiffness: 260, damping: 20 }}
                  className="flex items-center"
                >
                  <NotificationBell />
                </motion.div>
                <div className="relative">
                <motion.div
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <Button
                    variant="ghost"
                    onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
                    className="flex items-center space-x-3 px-4 py-2 rounded-full hover:bg-gray-50 transition-all duration-200"
                  >
                  <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-blue-500 rounded-full flex items-center justify-center shadow-lg overflow-hidden">
                    {user?.avatar ? (
                      <img 
                        src={user.avatar} 
                        alt="Avatar" 
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <User className="w-5 h-5 text-white" />
                    )}
                  </div>
                  <span className="text-sm font-medium text-gray-700">
                    {user?.ho_ten || 'User'}
                  </span>
                </Button>
                </motion.div>

                {/* User Dropdown */}
                <AnimatePresence>
                  {isUserMenuOpen && (
                    <motion.div
                      initial={{ opacity: 0, y: -10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5"
                    >
                      <div className="py-1">
                        <Link
                          to="/profile"
                          className="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                          onClick={() => setIsUserMenuOpen(false)}
                        >
                          <User className="w-4 h-4 mr-2" />
                          {t('profile')}
                        </Link>
                        <Link
                          to="/bookings"
                          className="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                          onClick={() => setIsUserMenuOpen(false)}
                        >
                          <Calendar className="w-4 h-4 mr-2" />
                          {t('myBookings')}
                        </Link>
                        <Link
                          to="/favorites"
                          className="flex items-center justify-between px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                          onClick={() => setIsUserMenuOpen(false)}
                        >
                          <div className="flex items-center">
                            <Heart className="w-4 h-4 mr-2" />
                            Yêu thích
                          </div>
                          {getFavoritesCount() > 0 && (
                            <span className="bg-red-500 text-white text-xs rounded-full px-2 py-1 ml-2">
                              {getFavoritesCount()}
                            </span>
                          )}
                        </Link>
                        <Link
                          to="/settings"
                          className="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                          onClick={() => setIsUserMenuOpen(false)}
                        >
                          <Settings className="w-4 h-4 mr-2" />
                          Cài đặt
                        </Link>
                        <hr className="my-1" />
                        <button
                          onClick={handleLogout}
                          className="flex items-center w-full px-4 py-2 text-sm text-red-600 hover:bg-gray-100"
                        >
                          <LogOut className="w-4 h-4 mr-2" />
                          {t('logout')}
                        </button>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
              </>
            ) : (
              <motion.div
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <Button asChild>
                  <Link to="/login">{t('login')}</Link>
                </Button>
              </motion.div>
            )}
          </motion.div>

          {/* Mobile menu button */}
          <motion.div 
            className="d-md-none"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
          >
            <motion.div
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
            >
              <BootstrapButton
                variant="outline-secondary"
                className="border-0"
                onClick={() => setIsMenuOpen(!isMenuOpen)}
              >
                <AnimatePresence mode="wait">
                  <motion.div
                    key={isMenuOpen ? 'close' : 'open'}
                    initial={{ rotate: -90, opacity: 0 }}
                    animate={{ rotate: 0, opacity: 1 }}
                    exit={{ rotate: 90, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                  >
                    {isMenuOpen ? <X size={24} /> : <Menu size={24} />}
                  </motion.div>
                </AnimatePresence>
              </BootstrapButton>
            </motion.div>
          </motion.div>
        </div>

        {/* Mobile Menu */}
        <AnimatePresence>
          {isMenuOpen && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="md:hidden"
            >
              <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3 border-t border-gray-200">
                {/* Mobile Navigation */}
                {navigation.map((item) => (
                  <Nav.Link
                    key={item.name}
                    as={Link}
                    to={item.href}
                    className={`d-block px-3 py-2 rounded text-decoration-none fw-medium position-relative ${
                      item.current
                        ? 'text-primary bg-primary bg-opacity-10'
                        : 'text-secondary'
                    }`}
                    onClick={() => setIsMenuOpen(false)}
                  >
                    <div className="d-flex align-items-center">
                      {item.name === 'Yêu thích' && <Heart size={16} className="me-2" />}
                      {item.name}
                      {item.badge > 0 && (
                        <span className="ms-2 badge bg-danger rounded-pill" style={{ fontSize: '10px' }}>
                          {item.badge}
                        </span>
                      )}
                    </div>
                  </Nav.Link>
                ))}

                {/* Mobile Auth */}
                <div className="pt-4 pb-3 border-t border-gray-200">
                  {/* Language Selector Mobile */}
                  <div className="px-3 py-2 mb-3">
                    <LanguageSelector />
                  </div>
                  
                  {isAuthenticated ? (
                    <div className="space-y-1">
                      <div className="flex items-center justify-between px-3 py-2">
                        <div className="flex items-center">
                          <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center overflow-hidden">
                            {user?.avatar ? (
                              <img 
                                src={user.avatar} 
                                alt="Avatar" 
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <User className="w-4 h-4 text-primary-600" />
                            )}
                          </div>
                          <div className="ml-3">
                            <div className="text-base font-medium text-gray-800">
                              {user?.ho_ten}
                            </div>
                            <div className="text-sm font-medium text-gray-500">
                              {user?.email}
                            </div>
                          </div>
                        </div>
                        <NotificationBell />
                      </div>
                      
                      <Link
                        to="/profile"
                        className="block px-3 py-2 text-base font-medium text-gray-500 hover:text-gray-900 hover:bg-gray-50"
                        onClick={() => setIsMenuOpen(false)}
                      >
                        {t('profile')}
                      </Link>
                      <Link
                        to="/bookings"
                        className="block px-3 py-2 text-base font-medium text-gray-500 hover:text-gray-900 hover:bg-gray-50"
                        onClick={() => setIsMenuOpen(false)}
                      >
                        {t('myBookings')}
                      </Link>
                      <button
                        onClick={handleLogout}
                        className="block w-full text-left px-3 py-2 text-base font-medium text-red-600 hover:bg-gray-50"
                      >
                        {t('logout')}
                      </button>
                    </div>
                  ) : (
                    <div className="px-3">
                      <Button className="w-full" asChild>
                        <Link to="/login" onClick={() => setIsMenuOpen(false)}>
                          {t('login')}
                        </Link>
                      </Button>
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </nav>

      {/* Click outside to close dropdowns */}
      {(isUserMenuOpen || isMenuOpen) && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-40"
          onClick={() => {
            setIsUserMenuOpen(false)
            setIsMenuOpen(false)
          }}
        />
      )}
    </motion.header>
  )
}

export default Header