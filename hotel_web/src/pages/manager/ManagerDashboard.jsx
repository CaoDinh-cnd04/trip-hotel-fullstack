import React, { useState, useEffect } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { LogOut, DoorOpen, Calendar, Star, LayoutDashboard, MessageSquare, Percent, User, Building2 } from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import NotificationBell from '../../components/notifications/NotificationBell'

// Import manager pages
import Overview from './hotel/Overview'
import Rooms from './hotel/Rooms'
import Bookings from './hotel/Bookings'
import Reviews from './hotel/Reviews'
import Promotions from './hotel/Promotions'
import HotelManagement from './hotel/HotelManagement'
import ManagerProfilePage from './ManagerProfilePage'
import Messages from './hotel/Messages'

const sections = [
  { id: 'overview', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'hotel', label: 'Quản lý khách sạn', icon: Building2 },
  { id: 'rooms', label: 'Phòng', icon: DoorOpen },
  { id: 'bookings', label: 'Đặt phòng', icon: Calendar },
  { id: 'reviews', label: 'Đánh giá', icon: Star },
  { id: 'promotions', label: 'Ưu đãi', icon: Percent },
  { id: 'messages', label: 'Tin nhắn', icon: MessageSquare },
  { id: 'profile', label: 'Hồ sơ', icon: User }
]

const ManagerDashboard = () => {
  const navigate = useNavigate()
  const location = useLocation()
  const { logout, user } = useAuthStore()
  
  // Get active section from URL or default to 'overview'
  const getActiveSection = () => {
    const pathParts = location.pathname.split('/').filter(Boolean)
    const managerIndex = pathParts.indexOf('manager-hotel')
    if (managerIndex !== -1 && pathParts[managerIndex + 1]) {
      const section = pathParts[managerIndex + 1]
      if (section === 'profile' || sections.find(s => s.id === section)) {
        return section
      }
    }
    // Default to overview if no section specified
    if (location.pathname === '/manager-hotel') {
      return 'overview'
    }
    return 'overview'
  }
  
  const [activeSection, setActiveSection] = useState(getActiveSection())

  // Update active section when URL changes
  useEffect(() => {
    setActiveSection(getActiveSection())
  }, [location.pathname])

  const handleSectionChange = (sectionId) => {
    setActiveSection(sectionId)
    if (sectionId === 'overview') {
      navigate('/manager-hotel')
    } else if (sectionId === 'profile') {
      navigate('/manager-hotel/profile')
    } else {
      navigate(`/manager-hotel/${sectionId}`)
    }
  }

  const handleAvatarClick = () => {
    setActiveSection('profile')
    navigate('/manager-hotel/profile')
  }

  const handleLogout = async () => {
    if (window.confirm('Bạn có chắc chắn muốn đăng xuất?')) {
      await logout()
      navigate('/manager/login')
    }
  }

  const renderContent = () => {
    try {
      switch (activeSection) {
        case 'overview':
          return <Overview />
        case 'hotel':
          return <HotelManagement />
        case 'rooms':
          return <Rooms />
        case 'bookings':
          return <Bookings />
        case 'reviews':
          return <Reviews />
        case 'promotions':
          return <Promotions />
        case 'messages':
          return <Messages />
        case 'profile':
          return <ManagerProfilePage />
        default:
          return (
            <div className="p-12 text-center text-slate-500">
              Chức năng <strong>{sections.find((s) => s.id === activeSection)?.label}</strong> sẽ cập nhật sau.
            </div>
          )
      }
    } catch (error) {
      console.error('Error rendering content:', error)
      return (
        <div className="p-12 text-center">
          <h2 className="text-2xl font-bold text-red-600 mb-4">Lỗi khi tải nội dung</h2>
          <p className="text-slate-600">{error?.message || 'Unknown error'}</p>
          <pre className="mt-4 text-xs text-left bg-slate-100 p-4 rounded overflow-auto">
            {error?.stack}
          </pre>
        </div>
      )
    }
  }

  // Animation variants
  const sidebarVariants = {
    hidden: { x: -100, opacity: 0 },
    visible: {
      x: 0,
      opacity: 1,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15
      }
    }
  }

  const menuItemVariants = {
    hidden: { x: -20, opacity: 0 },
    visible: (i) => ({
      x: 0,
      opacity: 1,
      transition: {
        delay: i * 0.05,
        type: "spring",
        stiffness: 100
      }
    })
  }

  const contentVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.3,
        ease: "easeOut"
      }
    },
    exit: {
      opacity: 0,
      y: -20,
      transition: {
        duration: 0.2
      }
    }
  }

  return (
    <div className="min-h-screen bg-slate-200 flex">
      <motion.aside
        className="w-64 bg-slate-900 text-white flex flex-col"
        variants={sidebarVariants}
        initial="hidden"
        animate="visible"
      >
        <motion.div
          className="px-6 py-6 border-b border-white/10"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          <h1 className="text-2xl font-bold tracking-wide">TripHotel</h1>
          {user && (
            <motion.p
              className="text-sm text-slate-400 mt-1"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.3 }}
            >
              {user.ho_ten || user.email}
            </motion.p>
          )}
          <motion.p
            className="text-xs text-slate-500 mt-1"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.4 }}
          >
            Quản lý khách sạn
          </motion.p>
        </motion.div>
        <nav className="flex-1 px-3 py-5 space-y-2">
          {sections.map(({ id, label, icon: Icon }, index) => (
            <motion.button
              key={id}
              onClick={() => handleSectionChange(id)}
              className={`w-full text-left px-4 py-3 rounded-lg font-semibold transition-all duration-200 relative overflow-hidden group ${
                activeSection === id 
                  ? 'bg-emerald-600 text-white shadow-lg shadow-emerald-500/50' 
                  : 'text-slate-200 hover:bg-slate-800/70 hover:text-white'
              }`}
              variants={menuItemVariants}
              custom={index}
              whileHover={{ x: 5, scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              {activeSection === id && (
                <>
                  <motion.span 
                    className="absolute left-0 top-0 h-full w-1 bg-white rounded-r-full"
                    initial={{ x: -10, opacity: 0 }}
                    animate={{ x: 0, opacity: 1 }}
                    exit={{ x: -10, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                  />
                  <motion.span 
                    className="absolute right-2 top-1/2 -translate-y-1/2 h-2 w-2 bg-white rounded-full"
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    exit={{ scale: 0 }}
                    transition={{ duration: 0.2, delay: 0.1 }}
                  />
                </>
              )}
              <span className="relative z-10 flex items-center gap-3">
                {Icon && (
                  <motion.span
                    key={id + '-icon'}
                    initial={{ rotate: 0, scale: 1 }}
                    animate={activeSection === id ? { rotate: [0, -10, 10, -10, 0], scale: 1.1 } : { rotate: 0, scale: 1 }}
                    transition={{ duration: 0.5, type: "spring", stiffness: 200 }}
                  >
                    <Icon size={20} />
                  </motion.span>
                )}
                {label}
              </span>
              <motion.span
                className="absolute inset-0 bg-gradient-to-r from-emerald-700 to-emerald-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                initial={{ opacity: 0 }}
                whileHover={{ opacity: 1 }}
                style={{ zIndex: 0 }}
              />
            </motion.button>
          ))}
        </nav>
        <motion.div
          className="p-4 border-t border-white/10"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
        >
          <motion.button
            onClick={handleLogout}
            className="w-full inline-flex items-center justify-center gap-2 bg-red-600 hover:bg-red-700 text-white font-semibold py-2.5 rounded-lg transition-colors"
            whileHover={{ scale: 1.02, boxShadow: "0 4px 12px rgba(220, 38, 38, 0.4)" }}
            whileTap={{ scale: 0.98 }}
          >
            <LogOut size={18} />
            Đăng xuất
          </motion.button>
        </motion.div>
      </motion.aside>

      <main className="flex-1 p-8 relative">
        {/* Notification Bell and Avatar - Top Right */}
        <div className="absolute top-8 right-8 z-50 flex items-center gap-3">
          {/* Notification Bell */}
          <motion.div
            initial={{ opacity: 0, scale: 0 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
          >
            {typeof NotificationBell !== 'undefined' ? <NotificationBell /> : null}
          </motion.div>
          
          {/* Avatar Button */}
          <motion.button
            onClick={handleAvatarClick}
            className="w-12 h-12 rounded-full overflow-hidden border-2 border-slate-300 hover:border-emerald-500 transition-all shadow-lg hover:shadow-xl cursor-pointer"
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.95 }}
            initial={{ opacity: 0, scale: 0 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.3, type: "spring", stiffness: 200 }}
            type="button"
          >
            {user?.avatar ? (
              <img
                src={user.avatar}
                alt={user.ho_ten || 'Manager'}
                className="w-full h-full object-cover pointer-events-none"
              />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center pointer-events-none">
                <Building2 className="text-white" size={24} />
              </div>
            )}
          </motion.button>
        </div>

        <motion.div
          className="bg-white rounded-3xl shadow-[0_20px_40px_rgba(15,23,42,0.08)] border border-slate-100"
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.3 }}
        >
          <AnimatePresence mode="wait">
            <motion.div
              key={activeSection}
              variants={contentVariants}
              initial="hidden"
              animate="visible"
              exit="exit"
            >
              {renderContent()}
            </motion.div>
          </AnimatePresence>
        </motion.div>
      </main>
    </div>
  )
}

export default ManagerDashboard

