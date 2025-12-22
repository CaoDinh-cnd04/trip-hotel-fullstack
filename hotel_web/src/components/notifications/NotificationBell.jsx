import React, { useState, useEffect } from 'react'
import { Bell, X, Trash2, Check, Calendar, CreditCard, Gift, Clock } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { useNotificationsStore } from '../../stores/notificationsStore'
import { useNavigate } from 'react-router-dom'
import { formatDistanceToNow } from 'date-fns'
import { vi, enUS } from 'date-fns/locale'
import { useTranslation } from '../../hooks/useTranslation'
import { useAuthStore } from '../../stores/authStore'

const NotificationBell = () => {
  const [isOpen, setIsOpen] = useState(false)
  const navigate = useNavigate()
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
    <div className="relative">
      {/* Notification Bell Button */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2.5 text-gray-600 hover:text-purple-600 transition-colors duration-200 rounded-full hover:bg-gray-100 flex items-center justify-center"
        aria-label="Notifications"
      >
        <Bell className="w-6 h-6" />
        {unreadCount > 0 && (
          <motion.span
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center font-medium"
          >
            {unreadCount > 9 ? '9+' : unreadCount}
          </motion.span>
        )}
      </motion.button>

      {/* Backdrop */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-10 z-40"
            onClick={() => setIsOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Notifications Dropdown */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20, scale: 0.9, x: 10 }}
            animate={{ opacity: 1, y: 0, scale: 1, x: 0 }}
            exit={{ opacity: 0, y: -20, scale: 0.9, x: 10 }}
            transition={{ 
              type: "spring", 
              stiffness: 300, 
              damping: 25,
              mass: 0.8
            }}
            className="absolute right-0 mt-2 w-96 bg-white rounded-xl shadow-2xl ring-1 ring-black ring-opacity-5 z-50 max-h-96 overflow-hidden"
          >
            {/* Header */}
            <motion.div 
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="px-4 py-3 border-b border-gray-200 bg-gradient-to-r from-purple-50 to-blue-50 rounded-t-xl"
            >
              <div className="flex items-center justify-between">
                <motion.h3 
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.15 }}
                  className="text-lg font-semibold text-gray-800"
                >
                  {t('notifications')}
                </motion.h3>
                <div className="flex items-center space-x-2">
                  {unreadCount > 0 && (
                    <motion.button
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ delay: 0.2 }}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={markAllAsRead}
                      className="text-xs text-purple-600 hover:text-purple-700 flex items-center space-x-1 px-2 py-1 rounded hover:bg-purple-100 transition-colors"
                    >
                      <Check className="w-3 h-3" />
                      <span>{t('markAllRead')}</span>
                    </motion.button>
                  )}
                  <motion.button
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.2 }}
                    whileHover={{ scale: 1.1, rotate: 90 }}
                    whileTap={{ scale: 0.9 }}
                    onClick={() => setIsOpen(false)}
                    className="p-1 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-200 transition-colors"
                  >
                    <X className="w-4 h-4" />
                  </motion.button>
                </div>
              </div>
            </motion.div>

            {/* Notifications List */}
            <div className="max-h-80 overflow-y-auto">
              {notifications.length === 0 ? (
                <motion.div 
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.2 }}
                  className="p-6 text-center text-gray-500"
                >
                  <motion.div
                    animate={{ 
                      rotate: [0, 10, -10, 10, 0],
                      scale: [1, 1.1, 1]
                    }}
                    transition={{ 
                      duration: 2,
                      repeat: Infinity,
                      repeatDelay: 3
                    }}
                  >
                    <Bell className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                  </motion.div>
                  <p>{t('noNotifications')}</p>
                </motion.div>
              ) : (
                <div className="divide-y divide-gray-100">
                  {notifications.map((notification, index) => (
                    <motion.div
                      key={notification.id}
                      initial={{ opacity: 0, x: -30, scale: 0.95 }}
                      animate={{ opacity: 1, x: 0, scale: 1 }}
                      transition={{ 
                        delay: 0.1 + (index * 0.05),
                        type: "spring",
                        stiffness: 200,
                        damping: 20
                      }}
                      whileHover={{ 
                        x: 5,
                        scale: 1.02,
                        transition: { duration: 0.2 }
                      }}
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
                                {notification.message}
                              </p>
                              <p className="text-xs text-gray-400 mt-2">
                                {formatRelativeTime(notification.createdAt)}
                              </p>
                            </div>
                            <motion.button
                              initial={{ opacity: 0, scale: 0 }}
                              animate={{ opacity: 1, scale: 1 }}
                              transition={{ delay: 0.2 + (index * 0.05) }}
                              whileHover={{ scale: 1.2, rotate: 15 }}
                              whileTap={{ scale: 0.9 }}
                              onClick={(e) => {
                                e.stopPropagation()
                                deleteNotification(notification.id)
                              }}
                              className="flex-shrink-0 ml-2 p-1 text-gray-400 hover:text-red-500 rounded-full hover:bg-red-50 transition-colors"
                            >
                              <Trash2 className="w-3 h-3" />
                            </motion.button>
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
              <motion.div 
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="px-4 py-3 border-t border-gray-200 bg-gray-50 rounded-b-xl"
              >
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => {
                    navigate('/notifications')
                    setIsOpen(false)
                  }}
                  className="w-full text-center text-sm text-purple-600 hover:text-purple-700 font-medium transition-colors"
                >
                  {t('viewAllNotifications')}
                </motion.button>
              </motion.div>
            )}
          </motion.div>
        )}
      </AnimatePresence>

    </div>
  )
}

export default NotificationBell