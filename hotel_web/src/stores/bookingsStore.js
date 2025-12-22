import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import toast from 'react-hot-toast'
import { useNotificationsStore } from './notificationsStore'

const useBookingsStore = create(
  persist(
    (set, get) => ({
      bookings: [], // Array of bookings - will be loaded from API

      // Actions
      createBooking: (bookingData) => {
        const bookingId = 'TH' + Date.now().toString().slice(-8)
        const booking = {
          id: bookingId,
          ...bookingData,
          status: 'pending', // pending, confirmed, cancelled, completed
          paymentStatus: 'pending', // pending, paid, failed
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }

        set(state => ({
          bookings: [booking, ...state.bookings]
        }))

        // Add notification
        const notificationStore = useNotificationsStore.getState()
        notificationStore.addNotification({
          title: 'Đặt phòng thành công',
          message: `Bạn đã đặt phòng tại ${bookingData.hotelName} thành công. Mã đặt phòng: ${bookingId}`,
          type: 'booking',
          relatedId: bookingId
        })

        toast.success('Đặt phòng thành công!')
        return booking
      },

      updateBookingStatus: (bookingId, status) => {
        set(state => ({
          bookings: state.bookings.map(booking => 
            booking.id === bookingId 
              ? { ...booking, status, updatedAt: new Date().toISOString() }
              : booking
          )
        }))
        
        const statusMessages = {
          confirmed: 'Đặt phòng đã được xác nhận',
          cancelled: 'Đặt phòng đã bị hủy',
          completed: 'Đặt phòng đã hoàn thành'
        }
        
        if (statusMessages[status]) {
          toast.success(statusMessages[status])
        }
      },

      updatePaymentStatus: (bookingId, paymentStatus, transactionId = null) => {
        const booking = get().bookings.find(b => b.id === bookingId)
        
        set(state => ({
          bookings: state.bookings.map(booking => 
            booking.id === bookingId 
              ? { 
                  ...booking, 
                  paymentStatus, 
                  transactionId,
                  updatedAt: new Date().toISOString() 
                }
              : booking
          )
        }))

        // Add payment notification
        const notificationStore = useNotificationsStore.getState()
        if (paymentStatus === 'paid') {
          notificationStore.addNotification({
            title: 'Thanh toán thành công',
            message: `Thanh toán cho đặt phòng ${bookingId} tại ${booking?.hotelName} đã được xử lý thành công`,
            type: 'payment',
            relatedId: bookingId
          })
          toast.success('Thanh toán thành công')
        } else if (paymentStatus === 'failed') {
          notificationStore.addNotification({
            title: 'Thanh toán thất bại',
            message: `Có lỗi xảy ra khi thanh toán cho đặt phòng ${bookingId}. Vui lòng thử lại`,
            type: 'payment',
            relatedId: bookingId
          })
          toast.error('Thanh toán thất bại')
        }
      },

      cancelBooking: (bookingId, reason = '') => {
        set(state => ({
          bookings: state.bookings.map(booking => 
            booking.id === bookingId 
              ? { 
                  ...booking, 
                  status: 'cancelled',
                  cancelReason: reason,
                  cancelledAt: new Date().toISOString(),
                  updatedAt: new Date().toISOString() 
                }
              : booking
          )
        }))
        
        toast.success('Đặt phòng đã được hủy')
      },

      getBookingById: (bookingId) => {
        const state = get()
        return state.bookings.find(booking => booking.id === bookingId)
      },

      getBookingsByStatus: (status) => {
        const state = get()
        return state.bookings.filter(booking => booking.status === status)
      },

      getTotalBookings: () => {
        const state = get()
        return state.bookings.length
      },

      clearBookings: () => {
        set({ bookings: [] })
        toast.success('Đã xóa tất cả đặt phòng')
      },

      // Add booking (direct addition for completed bookings)
      addBooking: (bookingData) => {
        const booking = {
          ...bookingData,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }

        set(state => ({
          bookings: [booking, ...state.bookings]
        }))

        // Add notification
        const notificationStore = useNotificationsStore.getState()
        notificationStore.addNotification({
          title: 'Đặt phòng thành công',
          message: `Bạn đã đặt phòng tại ${booking.hotel?.ten || 'khách sạn'} thành công. Mã đặt phòng: ${booking.id}`,
          type: 'booking',
          relatedId: booking.id
        })

        return booking
      }
    }),
    {
      name: 'bookings-storage',
      partialize: (state) => ({ bookings: state.bookings }),
    }
  )
)

export { useBookingsStore }