import { useState, useEffect } from 'react'
import { 
  Loader2, 
  CheckCircle, 
  XCircle, 
  Edit, 
  Trash2, 
  Eye, 
  Save, 
  X,
  Calendar,
  Filter,
  Send,
  LogIn,
  LogOut,
  Clock,
  User,
  Mail,
  Phone,
  MapPin,
  CreditCard,
  MessageSquare
} from 'lucide-react'
import { hotelManagerAPI } from '../../../services/api/hotelManagerAPI'
import toast from 'react-hot-toast'
import { motion, AnimatePresence } from 'framer-motion'

const Bookings = () => {
  const [bookings, setBookings] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [showDetailModal, setShowDetailModal] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)
  const [showNotificationModal, setShowNotificationModal] = useState(false)
  const [selectedBooking, setSelectedBooking] = useState(null)
  const [formData, setFormData] = useState({
    booking_status: '',
    check_in_date: '',
    check_out_date: '',
    guest_count: '',
    special_requests: '',
    payment_status: ''
  })
  const [notificationData, setNotificationData] = useState({
    subject: '',
    message: ''
  })
  const [saving, setSaving] = useState(false)
  const [sendingNotification, setSendingNotification] = useState(false)
  const [statusFilter, setStatusFilter] = useState('all')
  const [dateFilter, setDateFilter] = useState({
    startDate: '',
    endDate: ''
  })

  useEffect(() => {
    fetchBookings()
  }, [statusFilter, dateFilter])

  const fetchBookings = async () => {
    try {
      setLoading(true)
      setError(null)
      const params = {}
      if (statusFilter !== 'all') {
        params.status = statusFilter
      }
      if (dateFilter.startDate) {
        params.startDate = dateFilter.startDate
      }
      if (dateFilter.endDate) {
        params.endDate = dateFilter.endDate
      }
      const response = await hotelManagerAPI.getHotelBookings(params)
      const bookingsData = response?.data || []
      setBookings(Array.isArray(bookingsData) ? bookingsData : [])
    } catch (err) {
      setError(err.message || 'Không thể tải danh sách đặt phòng')
      console.error('Error fetching bookings:', err)
      toast.error('Không thể tải danh sách đặt phòng')
    } finally {
      setLoading(false)
    }
  }

  const handleViewDetail = (booking) => {
    setSelectedBooking(booking)
    setShowDetailModal(true)
  }

  const handleEdit = (booking) => {
    setSelectedBooking(booking)
    setFormData({
      booking_status: booking.booking_status || booking.trang_thai || '',
      check_in_date: booking.check_in_date || booking.ngay_nhan_phong || '',
      check_out_date: booking.check_out_date || booking.ngay_tra_phong || '',
      guest_count: booking.guest_count || '',
      special_requests: booking.special_requests || '',
      payment_status: booking.payment_status || ''
    })
    setShowEditModal(true)
  }

  const handleConfirm = async (booking) => {
    if (!window.confirm(`Xác nhận đặt phòng ${booking.booking_code || booking.id}?`)) return

    try {
      await hotelManagerAPI.updateBookingStatus(booking.id, { booking_status: 'confirmed' })
      toast.success('Đã xác nhận đặt phòng!')
      await fetchBookings()
    } catch (err) {
      console.error('Error confirming booking:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleReject = async (booking) => {
    const reason = window.prompt('Lý do từ chối đặt phòng:')
    if (!reason) return

    try {
      await hotelManagerAPI.updateBookingStatus(booking.id, { 
        booking_status: 'cancelled',
        special_requests: `Từ chối: ${reason}`
      })
      toast.success('Đã từ chối đặt phòng!')
      await fetchBookings()
    } catch (err) {
      console.error('Error rejecting booking:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleCancel = async (booking) => {
    const reason = window.prompt('Lý do hủy đặt phòng:')
    if (!reason) return

    try {
      await hotelManagerAPI.updateBookingStatus(booking.id, { 
        booking_status: 'cancelled',
        special_requests: `Hủy: ${reason}`
      })
      toast.success('Đã hủy đặt phòng!')
      await fetchBookings()
    } catch (err) {
      console.error('Error cancelling booking:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleCheckIn = async (booking) => {
    if (!window.confirm(`Xác nhận check-in cho đặt phòng ${booking.booking_code || booking.id}?`)) return

    try {
      await hotelManagerAPI.updateBookingStatus(booking.id, { 
        booking_status: 'checked_in',
        check_in_date: new Date().toISOString().split('T')[0]
      })
      toast.success('Đã check-in thành công!')
      await fetchBookings()
    } catch (err) {
      console.error('Error checking in:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleCheckOut = async (booking) => {
    if (!window.confirm(`Xác nhận check-out cho đặt phòng ${booking.booking_code || booking.id}?`)) return

    try {
      await hotelManagerAPI.updateBookingStatus(booking.id, { 
        booking_status: 'checked_out',
        check_out_date: new Date().toISOString().split('T')[0]
      })
      toast.success('Đã check-out thành công!')
      await fetchBookings()
    } catch (err) {
      console.error('Error checking out:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleSendNotification = (booking) => {
    setSelectedBooking(booking)
    setNotificationData({
      subject: `Thông báo về đặt phòng ${booking.booking_code || booking.id}`,
      message: ''
    })
    setShowNotificationModal(true)
  }

  const sendNotification = async () => {
    if (!notificationData.subject || !notificationData.message) {
      toast.error('Vui lòng điền đầy đủ thông tin')
      return
    }

    try {
      setSendingNotification(true)
      await hotelManagerAPI.sendBookingNotification(selectedBooking.id, notificationData)
      toast.success('Đã gửi thông báo cho khách hàng!')
      setShowNotificationModal(false)
      setNotificationData({ subject: '', message: '' })
    } catch (err) {
      console.error('Error sending notification:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    } finally {
      setSendingNotification(false)
    }
  }

  const handleSave = async () => {
    if (!selectedBooking) return

    try {
      setSaving(true)
      const updateData = {}
      
      if (formData.booking_status) updateData.booking_status = formData.booking_status
      if (formData.check_in_date) updateData.check_in_date = formData.check_in_date
      if (formData.check_out_date) updateData.check_out_date = formData.check_out_date
      if (formData.guest_count) updateData.guest_count = parseInt(formData.guest_count)
      if (formData.special_requests !== undefined) updateData.special_requests = formData.special_requests
      if (formData.payment_status) updateData.payment_status = formData.payment_status

      console.log('📤 Updating booking:', selectedBooking.id, updateData)
      await hotelManagerAPI.updateBookingStatus(selectedBooking.id, updateData)
      toast.success('Cập nhật đặt phòng thành công!')
      setShowEditModal(false)
      await fetchBookings()
    } catch (err) {
      console.error('Error updating booking:', err)
      const errorMsg = err.response?.data?.message || err.message || 'Có lỗi xảy ra'
      toast.error('Lỗi: ' + errorMsg)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Bạn có chắc muốn xóa đặt phòng này?')) return

    try {
      await hotelManagerAPI.deleteBooking(id)
      toast.success('Xóa đặt phòng thành công!')
      await fetchBookings()
    } catch (err) {
      console.error('Error deleting booking:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    }
  }

  const getStatusLabel = (status) => {
    const statusMap = {
      'confirmed': 'Đã xác nhận',
      'pending': 'Chờ xử lý',
      'cancelled': 'Đã hủy',
      'checked_in': 'Đã nhận phòng',
      'checked_out': 'Đã trả phòng',
      'completed': 'Hoàn thành',
      'in_progress': 'Đang diễn ra'
    }
    return statusMap[status] || status || 'Chờ xử lý'
  }

  const getStatusColor = (status) => {
    const colorMap = {
      'confirmed': 'bg-emerald-100 text-emerald-700',
      'pending': 'bg-amber-100 text-amber-700',
      'cancelled': 'bg-rose-100 text-rose-700',
      'checked_in': 'bg-blue-100 text-blue-700',
      'checked_out': 'bg-gray-100 text-gray-700',
      'completed': 'bg-green-100 text-green-700',
      'in_progress': 'bg-purple-100 text-purple-700'
    }
    return colorMap[status] || 'bg-gray-100 text-gray-700'
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A'
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('vi-VN')
    } catch {
      return dateString
    }
  }

  const formatDateTime = (dateString) => {
    if (!dateString) return 'N/A'
    try {
      const date = new Date(dateString)
      return date.toLocaleString('vi-VN')
    } catch {
      return dateString
    }
  }

  const clearDateFilter = () => {
    setDateFilter({ startDate: '', endDate: '' })
  }

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 className="animate-spin text-sky-500" size={32} />
        <span className="ml-3 text-slate-600">Đang tải dữ liệu...</span>
      </div>
    )
  }

  if (error) {
    return (
      <div className="p-8 text-center">
        <p className="text-red-600">{error}</p>
        <button
          onClick={fetchBookings}
          className="mt-4 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700"
        >
          Thử lại
        </button>
      </div>
    )
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold text-slate-900">Quản lý đặt phòng</h1>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-4 mb-6">
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex items-center gap-2">
            <Filter size={20} className="text-slate-500" />
            <span className="text-sm font-medium text-slate-700">Lọc:</span>
          </div>
          
          {/* Status Filter */}
          <div className="flex items-center gap-2">
            <label className="text-sm text-slate-600">Trạng thái:</label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent text-sm"
            >
              <option value="all">Tất cả</option>
              <option value="pending">Chờ xử lý</option>
              <option value="confirmed">Đã xác nhận</option>
              <option value="checked_in">Đã nhận phòng</option>
              <option value="checked_out">Đã trả phòng</option>
              <option value="cancelled">Đã hủy</option>
            </select>
          </div>

          {/* Date Filter */}
          <div className="flex items-center gap-2">
            <Calendar size={20} className="text-slate-500" />
            <label className="text-sm text-slate-600">Từ ngày:</label>
            <input
              type="date"
              value={dateFilter.startDate}
              onChange={(e) => setDateFilter({ ...dateFilter, startDate: e.target.value })}
              className="px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent text-sm"
            />
          </div>

          <div className="flex items-center gap-2">
            <label className="text-sm text-slate-600">Đến ngày:</label>
            <input
              type="date"
              value={dateFilter.endDate}
              onChange={(e) => setDateFilter({ ...dateFilter, endDate: e.target.value })}
              className="px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent text-sm"
            />
          </div>

          {(dateFilter.startDate || dateFilter.endDate) && (
            <button
              onClick={clearDateFilter}
              className="px-3 py-2 text-sm text-slate-600 hover:text-slate-900"
            >
              Xóa lọc ngày
            </button>
          )}
        </div>
      </div>

      {/* Bookings Table */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Mã đặt phòng</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Khách hàng</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Phòng</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Ngày nhận</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Ngày trả</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Tổng tiền</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Trạng thái</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {bookings.length === 0 ? (
                <tr>
                  <td colSpan="8" className="px-6 py-8 text-center text-slate-500">
                    Chưa có đặt phòng nào
                  </td>
                </tr>
              ) : (
                bookings.map((booking) => {
                  const status = booking.booking_status || booking.trang_thai || booking.status
                  const isPending = status === 'pending'
                  const isConfirmed = status === 'confirmed'
                  const isCheckedIn = status === 'checked_in'
                  const isCheckedOut = status === 'checked_out'
                  const isCancelled = status === 'cancelled'

                  return (
                    <tr key={booking.id} className="hover:bg-slate-50">
                      <td className="px-6 py-4 text-sm font-medium text-slate-900">
                        {booking.booking_code || booking.ma_phieu_dat || booking.id}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-900">
                        <div>
                          <div className="font-medium">{booking.user_name || booking.ten_khach_hang || 'N/A'}</div>
                          <div className="text-xs text-slate-500">{booking.user_email || booking.email_khach_hang || ''}</div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-600">
                        {booking.room_number || booking.so_phong || booking.ma_phong || 'N/A'}
                        {booking.ten_loai_phong && (
                          <div className="text-xs text-slate-500">{booking.ten_loai_phong}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-600">
                        {formatDate(booking.check_in_date || booking.ngay_nhan_phong)}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-600">
                        {formatDate(booking.check_out_date || booking.ngay_tra_phong)}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-900 font-semibold">
                        {new Intl.NumberFormat('vi-VN').format(booking.final_price || booking.tong_tien || 0)} VND
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(status)}`}>
                          {getStatusLabel(status)}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2 flex-wrap">
                          <button
                            onClick={() => handleViewDetail(booking)}
                            className="p-2 text-blue-600 hover:bg-blue-50 rounded transition"
                            title="Xem chi tiết"
                          >
                            <Eye size={16} />
                          </button>
                          
                          {isPending && (
                            <>
                              <button
                                onClick={() => handleConfirm(booking)}
                                className="p-2 text-emerald-600 hover:bg-emerald-50 rounded transition"
                                title="Xác nhận"
                              >
                                <CheckCircle size={16} />
                              </button>
                              <button
                                onClick={() => handleReject(booking)}
                                className="p-2 text-red-600 hover:bg-red-50 rounded transition"
                                title="Từ chối"
                              >
                                <XCircle size={16} />
                              </button>
                            </>
                          )}

                          {isConfirmed && !isCheckedIn && (
                            <button
                              onClick={() => handleCheckIn(booking)}
                              className="p-2 text-blue-600 hover:bg-blue-50 rounded transition"
                              title="Check-in"
                            >
                              <LogIn size={16} />
                            </button>
                          )}

                          {isCheckedIn && !isCheckedOut && (
                            <button
                              onClick={() => handleCheckOut(booking)}
                              className="p-2 text-purple-600 hover:bg-purple-50 rounded transition"
                              title="Check-out"
                            >
                              <LogOut size={16} />
                            </button>
                          )}

                          {!isCancelled && (
                            <button
                              onClick={() => handleCancel(booking)}
                              className="p-2 text-orange-600 hover:bg-orange-50 rounded transition"
                              title="Hủy phòng"
                            >
                              <XCircle size={16} />
                            </button>
                          )}

                          <button
                            onClick={() => handleSendNotification(booking)}
                            className="p-2 text-indigo-600 hover:bg-indigo-50 rounded transition"
                            title="Gửi thông báo"
                          >
                            <Send size={16} />
                          </button>

                          <button
                            onClick={() => handleEdit(booking)}
                            className="p-2 text-sky-600 hover:bg-sky-50 rounded transition"
                            title="Sửa"
                          >
                            <Edit size={16} />
                          </button>

                          {(isCancelled || isPending) && (
                            <button
                              onClick={() => handleDelete(booking.id)}
                              className="p-2 text-red-600 hover:bg-red-50 rounded transition"
                              title="Xóa"
                            >
                              <Trash2 size={16} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Detail Modal */}
      <AnimatePresence>
        {showDetailModal && selectedBooking && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
            onClick={() => setShowDetailModal(false)}
          >
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
              className="bg-white rounded-lg shadow-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">Chi tiết đặt phòng</h2>
                <button
                  onClick={() => setShowDetailModal(false)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X size={24} />
                </button>
              </div>

              <div className="p-6 space-y-6">
                {/* Booking Info */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Mã đặt phòng</label>
                    <p className="text-sm text-slate-900 font-semibold">{selectedBooking.booking_code || selectedBooking.ma_phieu_dat || selectedBooking.id}</p>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Trạng thái</label>
                    <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(selectedBooking.booking_status || selectedBooking.trang_thai)}`}>
                      {getStatusLabel(selectedBooking.booking_status || selectedBooking.trang_thai)}
                    </span>
                  </div>
                </div>

                {/* Customer Info */}
                <div className="border-t border-slate-200 pt-4">
                  <h3 className="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                    <User size={20} />
                    Thông tin khách hàng
                  </h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Tên khách hàng</label>
                      <p className="text-sm text-slate-900">{selectedBooking.user_name || selectedBooking.ten_khach_hang || 'N/A'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-1">
                        <Mail size={14} />
                        Email
                      </label>
                      <p className="text-sm text-slate-900">{selectedBooking.user_email || selectedBooking.email_khach_hang || 'N/A'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-1">
                        <Phone size={14} />
                        Số điện thoại
                      </label>
                      <p className="text-sm text-slate-900">{selectedBooking.user_phone || selectedBooking.sdt_khach_hang || 'N/A'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Số khách</label>
                      <p className="text-sm text-slate-900">{selectedBooking.guest_count || 'N/A'}</p>
                    </div>
                  </div>
                </div>

                {/* Room Info */}
                <div className="border-t border-slate-200 pt-4">
                  <h3 className="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                    <MapPin size={20} />
                    Thông tin phòng
                  </h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Số phòng</label>
                      <p className="text-sm text-slate-900">{selectedBooking.room_number || selectedBooking.so_phong || 'N/A'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Loại phòng</label>
                      <p className="text-sm text-slate-900">{selectedBooking.ten_loai_phong || 'N/A'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-1">
                        <Calendar size={14} />
                        Ngày nhận phòng
                      </label>
                      <p className="text-sm text-slate-900">{formatDate(selectedBooking.check_in_date || selectedBooking.ngay_nhan_phong)}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-1">
                        <Calendar size={14} />
                        Ngày trả phòng
                      </label>
                      <p className="text-sm text-slate-900">{formatDate(selectedBooking.check_out_date || selectedBooking.ngay_tra_phong)}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-1">
                        <Clock size={14} />
                        Số đêm
                      </label>
                      <p className="text-sm text-slate-900">{selectedBooking.nights || selectedBooking.so_dem_luu_tru || 'N/A'}</p>
                    </div>
                  </div>
                </div>

                {/* Payment Info */}
                <div className="border-t border-slate-200 pt-4">
                  <h3 className="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                    <CreditCard size={20} />
                    Thông tin thanh toán
                  </h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Tổng tiền</label>
                      <p className="text-sm text-slate-900 font-semibold text-lg">
                        {new Intl.NumberFormat('vi-VN').format(selectedBooking.final_price || selectedBooking.tong_tien || 0)} VND
                      </p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Phương thức thanh toán</label>
                      <p className="text-sm text-slate-900">{selectedBooking.payment_method || 'N/A'}</p>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Trạng thái thanh toán</label>
                      <p className="text-sm text-slate-900">{selectedBooking.payment_status || 'N/A'}</p>
                    </div>
                  </div>
                </div>

                {/* Special Requests */}
                {selectedBooking.special_requests && (
                  <div className="border-t border-slate-200 pt-4">
                    <h3 className="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                      <MessageSquare size={20} />
                      Yêu cầu đặc biệt
                    </h3>
                    <p className="text-sm text-slate-900 bg-slate-50 p-3 rounded-lg">{selectedBooking.special_requests}</p>
                  </div>
                )}

                {/* Timestamps */}
                <div className="border-t border-slate-200 pt-4">
                  <div className="grid grid-cols-2 gap-4 text-xs text-slate-500">
                    <div>
                      <span className="font-medium">Ngày tạo:</span> {formatDateTime(selectedBooking.created_at)}
                    </div>
                    {selectedBooking.updated_at && (
                      <div>
                        <span className="font-medium">Cập nhật lần cuối:</span> {formatDateTime(selectedBooking.updated_at)}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="p-6 border-t border-slate-200 flex justify-end gap-3">
                <button
                  onClick={() => {
                    setShowDetailModal(false)
                    handleSendNotification(selectedBooking)
                  }}
                  className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition flex items-center gap-2"
                >
                  <Send size={16} />
                  Gửi thông báo
                </button>
                <button
                  onClick={() => setShowDetailModal(false)}
                  className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition"
                >
                  Đóng
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Edit Modal */}
      <AnimatePresence>
        {showEditModal && selectedBooking && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
            onClick={() => setShowEditModal(false)}
          >
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
              className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">Sửa đặt phòng</h2>
                <button
                  onClick={() => setShowEditModal(false)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X size={24} />
                </button>
              </div>

              <div className="p-6 space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Trạng thái</label>
                    <select
                      value={formData.booking_status}
                      onChange={(e) => setFormData({ ...formData, booking_status: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    >
                      <option value="pending">Chờ xử lý</option>
                      <option value="confirmed">Đã xác nhận</option>
                      <option value="checked_in">Đã nhận phòng</option>
                      <option value="checked_out">Đã trả phòng</option>
                      <option value="cancelled">Đã hủy</option>
                      <option value="completed">Hoàn thành</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Trạng thái thanh toán</label>
                    <select
                      value={formData.payment_status}
                      onChange={(e) => setFormData({ ...formData, payment_status: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    >
                      <option value="">Chọn trạng thái</option>
                      <option value="pending">Chờ thanh toán</option>
                      <option value="paid">Đã thanh toán</option>
                      <option value="refunded">Đã hoàn tiền</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Ngày nhận phòng</label>
                    <input
                      type="date"
                      value={formData.check_in_date}
                      onChange={(e) => setFormData({ ...formData, check_in_date: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Ngày trả phòng</label>
                    <input
                      type="date"
                      value={formData.check_out_date}
                      onChange={(e) => setFormData({ ...formData, check_out_date: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Số khách</label>
                    <input
                      type="number"
                      value={formData.guest_count}
                      onChange={(e) => setFormData({ ...formData, guest_count: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                      min="1"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Yêu cầu đặc biệt</label>
                  <textarea
                    value={formData.special_requests}
                    onChange={(e) => setFormData({ ...formData, special_requests: e.target.value })}
                    rows={3}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    placeholder="Yêu cầu đặc biệt..."
                  />
                </div>
              </div>

              <div className="p-6 border-t border-slate-200 flex justify-end gap-3">
                <button
                  onClick={() => setShowEditModal(false)}
                  className="px-4 py-2 text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 transition"
                >
                  Hủy
                </button>
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 transition disabled:opacity-50 flex items-center gap-2"
                >
                  {saving ? <Loader2 className="animate-spin" size={16} /> : <Save size={16} />}
                  Lưu
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Notification Modal */}
      <AnimatePresence>
        {showNotificationModal && selectedBooking && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
            onClick={() => setShowNotificationModal(false)}
          >
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
              className="bg-white rounded-lg shadow-xl max-w-2xl w-full"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">Gửi thông báo cho khách hàng</h2>
                <button
                  onClick={() => setShowNotificationModal(false)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X size={24} />
                </button>
              </div>

              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Khách hàng</label>
                  <p className="text-sm text-slate-900">
                    {selectedBooking.user_name || selectedBooking.ten_khach_hang} ({selectedBooking.user_email || selectedBooking.email_khach_hang})
                  </p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Tiêu đề</label>
                  <input
                    type="text"
                    value={notificationData.subject}
                    onChange={(e) => setNotificationData({ ...notificationData, subject: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    placeholder="Tiêu đề thông báo"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Nội dung</label>
                  <textarea
                    value={notificationData.message}
                    onChange={(e) => setNotificationData({ ...notificationData, message: e.target.value })}
                    rows={6}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    placeholder="Nội dung thông báo..."
                  />
                </div>
              </div>

              <div className="p-6 border-t border-slate-200 flex justify-end gap-3">
                <button
                  onClick={() => setShowNotificationModal(false)}
                  className="px-4 py-2 text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 transition"
                >
                  Hủy
                </button>
                <button
                  onClick={sendNotification}
                  disabled={sendingNotification}
                  className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition disabled:opacity-50 flex items-center gap-2"
                >
                  {sendingNotification ? <Loader2 className="animate-spin" size={16} /> : <Send size={16} />}
                  Gửi thông báo
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default Bookings
