import React, { useState, useEffect } from 'react'
import { Bell, X, Trash2, Check, Calendar, CreditCard, Gift, Clock } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { useNotificationsStore } from '../../stores/notificationsStore'
import { useNavigate, useLocation } from 'react-router-dom'
import { formatDistanceToNow } from 'date-fns'
import { vi, enUS } from 'date-fns/locale'
import { useTranslation } from '../../hooks/useTranslation'
import { useAuthStore } from '../../stores/authStore'

const FixedNotificationBell = () => {
  const [isOpen, setIsOpen] = useState(false)
  const navigate = useNavigate()
  const location = useLocation()
  const { t, currentLanguage } = useTranslation()
  const { isAuthenticated } = useAuthStore()
  const { 
    notifications, 
    getUnreadCount, 
    markAsRead, 
    markAllAsRead, 
    deleteNotification,
    fetchNotifications,
    initialize
  } = useNotificationsStore()

  // Fetch notifications when component mounts and user is authenticated
  useEffect(() => {
    if (isAuthenticated()) {
      initialize()
    }
  }, [isAuthenticated, initialize])

  // Refresh notifications when dropdown opens
  useEffect(() => {
    if (isOpen && isAuthenticated()) {
      fetchNotifications(true)
    }
  }, [isOpen, isAuthenticated, fetchNotifications])

  const unreadCount = getUnreadCount()

  // Don't show on admin pages or auth pages
  const isAdminPage = location.pathname.startsWith('/admin') || location.pathname.startsWith('/admin-hotel')
  const isAuthPage = location.pathname === '/login' || location.pathname === '/register'

  // Check authentication
  const authenticated = isAuthenticated()

  // Only hide on admin pages and auth pages, but show if authenticated
  if (isAdminPage || isAuthPage) {
    return null
  }

  // Show notification bell only when authenticated
  if (!authenticated) {
    return null
  }

  const getNotificationIcon = (type) => {
    switch (type) {
      case 'booking':
        return <Calendar className="w-4 h-4 text-blue-500" />
      case 'payment':
        return <CreditCard className="w-4 h-4 text-green-500" />
      case 'promotion':
        return <Gift className="w-4 h-4 text-purple-500" />
      case 'reminder':
        return <Clock className="w-4 h-4 text-orange-500" />
      default:
        return <Bell className="w-4 h-4 text-gray-500" />
    }
  }

  const getNotificationBg = (type, isRead) => {
    if (isRead) return 'bg-gray-50'
    
    switch (type) {
      case 'booking':
        return 'bg-blue-50 border-l-4 border-blue-500'
      case 'payment':
        return 'bg-green-50 border-l-4 border-green-500'
      case 'promotion':
        return 'bg-purple-50 border-l-4 border-purple-500'
      case 'reminder':
        return 'bg-orange-50 border-l-4 border-orange-500'
      default:
        return 'bg-gray-50'
    }
  }

  const handleNotificationClick = (notification) => {
    markAsRead(notification.id)
    
    // Navigate based on notification type
    switch (notification.type) {
      case 'booking':
      case 'payment':
      case 'reminder':
        navigate('/bookings')
        break
      case 'promotion':
        navigate('/promotions')
        break
      default:
        break
    }
    
    setIsOpen(false)
  }

  const formatRelativeTime = (dateString) => {
    try {
      return formatDistanceToNow(new Date(dateString), {
        addSuffix: true,
        locale: currentLanguage === 'vi' ? vi : enUS
      })
    } catch (error) {
      return 'vừa xong'
    }
  }

  return (
    <div className="fixed top-24 right-6 z-[9999]">
      {/* Notification Bell Button */}
      <motion.button
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.95 }}
        onClick={() => setIsOpen(!isOpen)}
        className="relative w-14 h-14 bg-gradient-to-br from-purple-600 to-blue-600 text-white rounded-full shadow-2xl flex items-center justify-center hover:shadow-purple-500/50 transition-all duration-300"
        style={{
          boxShadow: '0 10px 30px rgba(147, 51, 234, 0.4)'
        }}
        aria-label="Notifications"
      >
        <Bell className="w-6 h-6" />
        {unreadCount > 0 && (
          <motion.span
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="absolute -top-1 -right-1 w-6 h-6 bg-red-500 text-white text-xs rounded-full flex items-center justify-center font-bold border-2 border-white"
          >
            {unreadCount > 9 ? '9+' : unreadCount}
          </motion.span>
        )}
      </motion.button>

      {/* Notifications Dropdown */}
      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black bg-opacity-20 z-40"
              onClick={() => setIsOpen(false)}
            />
            
            {/* Dropdown */}
            <motion.div
              initial={{ opacity: 0, y: -10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -10, scale: 0.95 }}
              className="absolute right-0 mt-4 w-96 bg-white rounded-xl shadow-2xl ring-1 ring-black ring-opacity-5 z-[10000] max-h-96 overflow-hidden"
            >
              {/* Header */}
              <div className="px-4 py-3 border-b border-gray-200 bg-gradient-to-r from-purple-50 to-blue-50 rounded-t-xl">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-gray-800">{t('notifications')}</h3>
                  <div className="flex items-center space-x-2">
                    {unreadCount > 0 && (
                      <button
                        onClick={markAllAsRead}
                        className="text-xs text-purple-600 hover:text-purple-700 flex items-center space-x-1 px-2 py-1 rounded hover:bg-purple-100 transition-colors"
                      >
                        <Check className="w-3 h-3" />
                        <span>{t('markAllRead')}</span>
                      </button>
                    )}
                    <button
                      onClick={() => setIsOpen(false)}
                      className="p-1 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-200 transition-colors"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>

              {/* Notifications List */}
              <div className="max-h-80 overflow-y-auto">
                {notifications.length === 0 ? (
                  <div className="p-6 text-center text-gray-500">
                    <Bell className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                    <p>{t('noNotifications')}</p>
                  </div>
                ) : (
                  <div className="divide-y divide-gray-100">
                    {notifications.map((notification) => (
                      <motion.div
                        key={notification.id}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        className={`p-4 cursor-pointer hover:bg-gray-50 transition-colors duration-200 relative ${getNotificationBg(notification.type, notification.isRead)}`}
                        onClick={() => handleNotificationClick(notification)}
                      >
                        <div className="flex items-start space-x-3">
                          <div className="flex-shrink-0 mt-1">
                            {getNotificationIcon(notification.type)}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between">
                              <div className="flex-1">
                                <p className={`text-sm font-medium ${notification.isRead ? 'text-gray-600' : 'text-gray-900'}`}>
                                  {notification.title}
                                </p>
                                <p className={`text-sm mt-1 ${notification.isRead ? 'text-gray-500' : 'text-gray-700'}`}>
                                  {notification.message || notification.content || ''}
                                </p>
                                <p className="text-xs text-gray-400 mt-2">
                                  {formatRelativeTime(notification.createdAt)}
                                </p>
                              </div>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation()
                                  deleteNotification(notification.id)
                                }}
                                className="flex-shrink-0 ml-2 p-1 text-gray-400 hover:text-red-500 rounded-full hover:bg-red-50 transition-colors"
                              >
                                <Trash2 className="w-3 h-3" />
                              </button>
                            </div>
                            {!notification.isRead && (
                              <div className="absolute right-2 top-4 w-2 h-2 bg-blue-500 rounded-full"></div>
                            )}
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
              </div>

              {/* Footer */}
              {notifications.length > 0 && (
                <div className="px-4 py-3 border-t border-gray-200 bg-gray-50 rounded-b-xl">
                  <button
                    onClick={() => {
                      navigate('/notifications')
                      setIsOpen(false)
                    }}
                    className="w-full text-center text-sm text-purple-600 hover:text-purple-700 font-medium transition-colors"
                  >
                    {t('viewAllNotifications')}
                  </button>
                </div>
              )}
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  )
}

export default FixedNotificationBell

