import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  Bell, 
  Calendar, 
  CreditCard, 
  Gift, 
  Clock, 
  Trash2, 
  Check,
  CheckCircle,
  Filter,
  Search,
  RefreshCw
} from 'lucide-react'
import { useNotificationsStore } from '../../stores/notificationsStore'
import { useNavigate } from 'react-router-dom'
import { formatDistanceToNow, format } from 'date-fns'
import { vi, enUS } from 'date-fns/locale'
import { useTranslation } from '../../hooks/useTranslation'
import { useAuthStore } from '../../stores/authStore'

const NotificationsPage = () => {
  const [selectedType, setSelectedType] = useState('all')
  const [searchTerm, setSearchTerm] = useState('')
  const navigate = useNavigate()
  const { t, currentLanguage } = useTranslation()
  const { isAuthenticated } = useAuthStore()
  
  const { 
    notifications, 
    getUnreadCount, 
    markAsRead, 
    markAllAsRead, 
    deleteNotification,
    clearAllNotifications,
    fetchNotifications,
    initialize,
    loading
  } = useNotificationsStore()

  // Fetch notifications when page loads
  useEffect(() => {
    if (isAuthenticated()) {
      initialize()
    }
  }, [isAuthenticated, initialize])

  const notificationTypes = [
    { key: 'all', label: 'Tất cả', icon: Bell },
    { key: 'booking', label: 'Đặt phòng', icon: Calendar },
    { key: 'payment', label: 'Thanh toán', icon: CreditCard },
    { key: 'promotion', label: 'Khuyến mãi', icon: Gift },
    { key: 'reminder', label: 'Nhắc nhở', icon: Clock },
  ]

  const getNotificationIcon = (type) => {
    switch (type) {
      case 'booking':
        return <Calendar className="w-5 h-5 text-blue-500" />
      case 'payment':
        return <CreditCard className="w-5 h-5 text-green-500" />
      case 'promotion':
        return <Gift className="w-5 h-5 text-purple-500" />
      case 'reminder':
        return <Clock className="w-5 h-5 text-orange-500" />
      default:
        return <Bell className="w-5 h-5 text-gray-500" />
    }
  }

  const getNotificationBg = (type, isRead) => {
    if (isRead) return 'bg-white border border-gray-200'
    
    switch (type) {
      case 'booking':
        return 'bg-blue-50 border border-blue-200'
      case 'payment':
        return 'bg-green-50 border border-green-200'
      case 'promotion':
        return 'bg-purple-50 border border-purple-200'
      case 'reminder':
        return 'bg-orange-50 border border-orange-200'
      default:
        return 'bg-gray-50 border border-gray-200'
    }
  }

  const filteredNotifications = notifications.filter(notification => {
    const matchesType = selectedType === 'all' || notification.type === selectedType
    const matchesSearch = notification.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         notification.message.toLowerCase().includes(searchTerm.toLowerCase())
    return matchesType && matchesSearch
  })

  const handleNotificationClick = (notification) => {
    markAsRead(notification.id)
    
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
  }

  const formatFullTime = (dateString) => {
    try {
      const dateFormat = currentLanguage === 'vi' ? 'dd/MM/yyyy HH:mm' : 'MM/dd/yyyy HH:mm'
      return format(new Date(dateString), dateFormat, { 
        locale: currentLanguage === 'vi' ? vi : enUS 
      })
    } catch (error) {
      return dateString
    }
  }

  const formatRelativeTime = (dateString) => {
    try {
      return formatDistanceToNow(new Date(dateString), {
        addSuffix: true,
        locale: currentLanguage === 'vi' ? vi : enUS
      })
    } catch (error) {
      return currentLanguage === 'vi' ? 'vừa xong' : 'just now'
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 mb-2">{t('notifications')}</h1>
              <p className="text-gray-600">
                Bạn có {getUnreadCount()} thông báo chưa đọc
              </p>
            </div>
            <div className="flex items-center space-x-3">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => fetchNotifications(true)}
                disabled={loading}
                className="flex items-center space-x-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                <span>Làm mới</span>
              </motion.button>
              {getUnreadCount() > 0 && (
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={markAllAsRead}
                  className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  <CheckCircle className="w-4 h-4" />
                  <span>Đánh dấu tất cả</span>
                </motion.button>
              )}
              {notifications.length > 0 && (
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => {
                    if (window.confirm('Bạn có chắc chắn muốn xóa tất cả thông báo?')) {
                      clearAllNotifications()
                    }
                  }}
                  className="flex items-center space-x-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                  <span>Xóa tất cả</span>
                </motion.button>
              )}
            </div>
          </div>

          {/* Filters & Search */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            {/* Type Filters */}
            <div className="flex flex-wrap gap-2 mb-4">
              {notificationTypes.map((type) => {
                const IconComponent = type.icon
                const isActive = selectedType === type.key
                return (
                  <motion.button
                    key={type.key}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => setSelectedType(type.key)}
                    className={`flex items-center space-x-2 px-4 py-2 rounded-full border transition-all ${
                      isActive
                        ? 'bg-purple-600 text-white border-purple-600'
                        : 'bg-white text-gray-600 border-gray-300 hover:border-purple-300 hover:text-purple-600'
                    }`}
                  >
                    <IconComponent className="w-4 h-4" />
                    <span className="text-sm font-medium">{type.label}</span>
                  </motion.button>
                )
              })}
            </div>

            {/* Search */}
            <div className="relative">
              <Search className="w-5 h-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              <input
                type="text"
                placeholder="Tìm kiếm thông báo..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none"
              />
            </div>
          </div>
        </div>

        {/* Notifications List */}
        <div className="space-y-4">
          {filteredNotifications.length === 0 ? (
            <div className="text-center py-12">
              <Bell className="w-16 h-16 mx-auto text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {searchTerm || selectedType !== 'all' 
                  ? 'Không tìm thấy thông báo nào' 
                  : 'Không có thông báo nào'
                }
              </h3>
              <p className="text-gray-500">
                {searchTerm || selectedType !== 'all'
                  ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                  : 'Các thông báo mới sẽ hiển thị ở đây'
                }
              </p>
            </div>
          ) : (
            filteredNotifications.map((notification, index) => (
              <motion.div
                key={notification.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.05 }}
                className={`${getNotificationBg(notification.type, notification.isRead)} rounded-lg p-6 cursor-pointer hover:shadow-md transition-all duration-200 relative`}
                onClick={() => handleNotificationClick(notification)}
              >
                <div className="flex items-start space-x-4">
                  <div className="flex-shrink-0 mt-1">
                    {getNotificationIcon(notification.type)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between">
                      <div className="flex-1 pr-4">
                        <div className="flex items-center space-x-2 mb-2">
                          <h3 className={`text-lg font-semibold ${notification.isRead ? 'text-gray-700' : 'text-gray-900'}`}>
                            {notification.title}
                          </h3>
                          {!notification.isRead && (
                            <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                          )}
                        </div>
                        <p className={`text-sm mb-3 ${notification.isRead ? 'text-gray-500' : 'text-gray-700'}`}>
                          {notification.message || notification.content || ''}
                        </p>
                        <div className="flex items-center space-x-4 text-xs text-gray-400">
                          <span>{formatRelativeTime(notification.createdAt)}</span>
                          <span>•</span>
                          <span>{formatFullTime(notification.createdAt)}</span>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        {!notification.isRead && (
                          <button
                            onClick={(e) => {
                              e.stopPropagation()
                              markAsRead(notification.id)
                            }}
                            className="p-2 text-blue-600 hover:bg-blue-100 rounded-full transition-colors"
                            title="Đánh dấu đã đọc"
                          >
                            <Check className="w-4 h-4" />
                          </button>
                        )}
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            deleteNotification(notification.id)
                          }}
                          className="p-2 text-red-600 hover:bg-red-100 rounded-full transition-colors"
                          title="Xóa thông báo"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))
          )}
        </div>
      </div>
    </div>
  )
}

export default NotificationsPage