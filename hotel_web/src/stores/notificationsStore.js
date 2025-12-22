import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { notificationAPI } from '../services/api/user'

const useNotificationsStore = create(
  persist(
    (set, get) => ({
      notifications: [],
      loading: false,
      error: null,
      lastFetchTime: null,

      // Fetch notifications from API
      fetchNotifications: async (forceRefresh = false) => {
        const state = get()
        // Don't fetch if recently fetched (within 30 seconds) unless forced
        if (!forceRefresh && state.lastFetchTime) {
          const timeSinceLastFetch = Date.now() - state.lastFetchTime
          if (timeSinceLastFetch < 30000) {
            return
          }
        }

        try {
          set({ loading: true, error: null })
          const response = await notificationAPI.getAll()
          
          // Handle different response formats
          let notificationsData = []
          if (response.data) {
            if (Array.isArray(response.data)) {
              notificationsData = response.data
            } else if (response.data.data && Array.isArray(response.data.data)) {
              notificationsData = response.data.data
            }
          } else if (Array.isArray(response)) {
            notificationsData = response
          }

          // Map backend format to frontend format
          const mappedNotifications = notificationsData.map(notif => ({
            id: notif.id || notif.ma_thong_bao,
            title: notif.title || notif.tieu_de || 'Thông báo',
            message: notif.content || notif.noi_dung || '',
            type: mapNotificationType(notif.type || notif.loai_thong_bao),
            isRead: notif.is_read || notif.da_doc || false,
            createdAt: notif.created_at || notif.ngay_tao || new Date().toISOString(),
            imageUrl: notif.image_url || notif.url_hinh_anh,
            actionUrl: notif.action_url || notif.url_hanh_dong,
            actionText: notif.action_text || notif.van_ban_nut,
            relatedId: notif.hotel_id || notif.khach_san_id
          }))

          set({ 
            notifications: mappedNotifications,
            loading: false,
            lastFetchTime: Date.now()
          })
        } catch (error) {
          console.error('Error fetching notifications:', error)
          set({ 
            loading: false, 
            error: error.message || 'Không thể tải thông báo'
          })
        }
      },

      // Fetch unread count
      fetchUnreadCount: async () => {
        try {
          const response = await notificationAPI.getUnreadCount()
          const count = response.data?.count || response.data?.unreadCount || 0
          return count
        } catch (error) {
          console.error('Error fetching unread count:', error)
          return 0
        }
      },

      // Actions
      addNotification: (notification) => {
        const newNotification = {
          id: Date.now(),
          isRead: false,
          createdAt: new Date().toISOString(),
          ...notification
        }
        set((state) => ({
          notifications: [newNotification, ...state.notifications]
        }))
      },

      markAsRead: async (id) => {
        // Update local state immediately
        set((state) => ({
          notifications: state.notifications.map(notification =>
            notification.id === id 
              ? { ...notification, isRead: true }
              : notification
          )
        }))

        // Sync with backend
        try {
          await notificationAPI.markAsRead(id)
        } catch (error) {
          console.error('Error marking notification as read:', error)
          // Revert on error
          set((state) => ({
            notifications: state.notifications.map(notification =>
              notification.id === id 
                ? { ...notification, isRead: false }
                : notification
            )
          }))
        }
      },

      markAllAsRead: async () => {
        const unreadNotifications = get().notifications.filter(n => !n.isRead)
        
        // Update local state
        set((state) => ({
          notifications: state.notifications.map(notification => ({
            ...notification,
            isRead: true
          }))
        }))

        // Sync with backend
        try {
          await Promise.all(
            unreadNotifications.map(notif => notificationAPI.markAsRead(notif.id))
          )
        } catch (error) {
          console.error('Error marking all as read:', error)
        }
      },

      deleteNotification: (id) => {
        set((state) => ({
          notifications: state.notifications.filter(notification => notification.id !== id)
        }))
      },

      clearAllNotifications: () => {
        set({ notifications: [] })
      },

      getUnreadCount: () => {
        return get().notifications.filter(notification => !notification.isRead).length
      },

      getNotificationsByType: (type) => {
        return get().notifications.filter(notification => notification.type === type)
      },

      // Initialize - fetch notifications on mount
      initialize: async () => {
        await get().fetchNotifications(true)
      }
    }),
    {
      name: 'notifications-storage',
      partialize: (state) => ({ 
        notifications: state.notifications,
        lastFetchTime: state.lastFetchTime
      })
    }
  )
)

// Map backend notification types to frontend types
function mapNotificationType(backendType) {
  const typeMap = {
    'Ưu đãi': 'promotion',
    'promotion': 'promotion',
    'Phòng mới': 'booking',
    'new_room': 'booking',
    'Chương trình app': 'promotion',
    'app_program': 'promotion',
    'Đặt phòng thành công': 'booking',
    'booking_success': 'booking',
    'booking': 'booking',
    'payment': 'payment',
    'reminder': 'reminder'
  }
  return typeMap[backendType] || 'promotion'
}

export { useNotificationsStore }
