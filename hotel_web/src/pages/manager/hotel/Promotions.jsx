import { useState, useEffect } from 'react'
import { Plus, Loader2, Edit, Trash2, Percent, Calendar, Package, Power, PowerOff, Send, CheckCircle, XCircle, Clock } from 'lucide-react'
import { hotelManagerAPI } from '../../../services/api/hotelManagerAPI'
import toast from 'react-hot-toast'
import { motion } from 'framer-motion'

const Promotions = () => {
  const [promotions, setPromotions] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [showModal, setShowModal] = useState(false)
  const [editingPromotion, setEditingPromotion] = useState(null)
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    original_price: '',
    discount_type: 'percent', // 'percent' or 'amount'
    discount_value: '',
    total_rooms: '',
    start_time: '',
    end_time: '',
    submit_for_approval: false
  })

  useEffect(() => {
    fetchPromotions()
    fetchHotelId()
  }, [])

  const [hotelId, setHotelId] = useState(null)

  const fetchHotelId = async () => {
    try {
      const response = await hotelManagerAPI.getAssignedHotel()
      const hotelData = response?.data || response || {}
      const id = hotelData?.id || hotelData?.ma_khach_san
      if (id) {
        setHotelId(id)
      } else {
        toast.error('Không tìm thấy thông tin khách sạn')
      }
    } catch (err) {
      console.error('Error fetching hotel:', err)
      toast.error('Không thể tải thông tin khách sạn')
    }
  }

  const fetchPromotions = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await hotelManagerAPI.getMyPromotions()
      const promotionsData = Array.isArray(response) ? response : (response?.data || [])
      setPromotions(Array.isArray(promotionsData) ? promotionsData : [])
    } catch (err) {
      setError(err.message || 'Không thể tải danh sách ưu đãi')
      console.error('Error fetching promotions:', err)
      toast.error('Không thể tải danh sách ưu đãi')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    // Validation
    if (!formData.title || !formData.original_price || !formData.discount_value || !formData.total_rooms || !formData.start_time || !formData.end_time) {
      toast.error('Vui lòng điền đầy đủ thông tin bắt buộc')
      return
    }

    if (parseInt(formData.total_rooms) <= 0) {
      toast.error('Số lượng phòng phải lớn hơn 0')
      return
    }

    if (new Date(formData.start_time) >= new Date(formData.end_time)) {
      toast.error('Thời gian kết thúc phải sau thời gian bắt đầu')
      return
    }

    if (formData.discount_type === 'percent' && parseFloat(formData.discount_value) > 100) {
      toast.error('Phần trăm giảm giá không được vượt quá 100%')
      return
    }

    if (formData.discount_type === 'amount' && parseFloat(formData.discount_value) >= parseFloat(formData.original_price)) {
      toast.error('Số tiền giảm phải nhỏ hơn giá gốc')
      return
    }

    try {
      if (!hotelId) {
        toast.error('Không tìm thấy thông tin khách sạn. Vui lòng tải lại trang.')
        return
      }

      const promotionData = {
        hotel_id: hotelId,
        room_type_id: null, // Bảng khuyen_mai không có room_type_id
        title: formData.title,
        description: formData.description || '',
        original_price: parseFloat(formData.original_price),
        discount_type: formData.discount_type,
        discount_value: parseFloat(formData.discount_value),
        total_rooms: parseInt(formData.total_rooms),
        start_time: formData.start_time,
        end_time: formData.end_time,
        submit_for_approval: formData.submit_for_approval
      }
      
      console.log('📤 Sending promotion data:', promotionData)

      if (editingPromotion) {
        await hotelManagerAPI.updatePromotion(editingPromotion.id, promotionData)
        toast.success('Cập nhật ưu đãi thành công!')
      } else {
        await hotelManagerAPI.createPromotion(promotionData)
        toast.success(formData.submit_for_approval ? 'Đã gửi ưu đãi chờ Admin duyệt!' : 'Tạo ưu đãi thành công!')
      }

      setShowModal(false)
      resetForm()
      await fetchPromotions()
    } catch (err) {
      console.error('Error creating/updating promotion:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message || 'Vui lòng thử lại'))
    }
  }

  const resetForm = () => {
    setEditingPromotion(null)
    setFormData({
      title: '',
      description: '',
      original_price: '',
      discount_type: 'percent',
      discount_value: '',
      total_rooms: '',
      start_time: '',
      end_time: '',
      submit_for_approval: false
    })
  }

  const handleEdit = (promotion) => {
    setEditingPromotion(promotion)
    
    // Tính toán từ dữ liệu backend
    // Backend trả về: phan_tram, giam_toi_da, original_price (tính từ giam_toi_da / phan_tram * 100)
    const phanTram = parseFloat(promotion.phan_tram || promotion.discount_value || 0)
    const giamToiDa = parseFloat(promotion.giam_toi_da || 0)
    const originalPrice = promotion.original_price || (phanTram > 0 ? (giamToiDa / phanTram * 100) : 0)
    
    setFormData({
      title: promotion.title || promotion.ten || '',
      description: promotion.description || promotion.mo_ta || '',
      original_price: originalPrice.toString(),
      discount_type: 'percent', // Mặc định là percent vì bảng chỉ có phan_tram
      discount_value: phanTram.toString(),
      total_rooms: (promotion.total_rooms || 0).toString(),
      start_time: promotion.start_time || promotion.ngay_bat_dau 
        ? new Date(promotion.start_time || promotion.ngay_bat_dau).toISOString().slice(0, 16) 
        : '',
      end_time: promotion.end_time || promotion.ngay_ket_thuc 
        ? new Date(promotion.end_time || promotion.ngay_ket_thuc).toISOString().slice(0, 16) 
        : '',
      submit_for_approval: false
    })
    setShowModal(true)
  }

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc muốn xóa ưu đãi này?')) {
      try {
        await hotelManagerAPI.deletePromotion(id)
        toast.success('Xóa ưu đãi thành công!')
        await fetchPromotions()
      } catch (err) {
        toast.error('Lỗi khi xóa ưu đãi: ' + (err.message || 'Vui lòng thử lại'))
      }
    }
  }

  const handleToggle = async (promotion) => {
    try {
      const newStatus = !promotion.is_active
      await hotelManagerAPI.togglePromotion(promotion.id, newStatus)
      toast.success(newStatus ? 'Đã bật ưu đãi' : 'Đã tắt ưu đãi')
      await fetchPromotions()
    } catch (err) {
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message || 'Vui lòng thử lại'))
    }
  }

  const handleSubmitApproval = async (promotion) => {
    if (window.confirm('Gửi ưu đãi này cho Admin duyệt?')) {
      try {
        await hotelManagerAPI.submitForApproval(promotion.id)
        toast.success('Đã gửi ưu đãi chờ Admin duyệt!')
        await fetchPromotions()
      } catch (err) {
        toast.error('Lỗi: ' + (err.response?.data?.message || err.message || 'Vui lòng thử lại'))
      }
    }
  }

  const calculateDiscountedPrice = () => {
    if (!formData.original_price || !formData.discount_value) return 0
    
    const original = parseFloat(formData.original_price)
    const value = parseFloat(formData.discount_value)
    
    if (formData.discount_type === 'percent') {
      return original * (1 - value / 100)
    } else {
      return Math.max(0, original - value)
    }
  }

  const getStatusBadge = (status, isActive) => {
    const statusMap = {
      'pending': { color: 'bg-yellow-100 text-yellow-800', label: 'Chờ duyệt', icon: Clock },
      'approved': { color: 'bg-green-100 text-green-800', label: 'Đã duyệt', icon: CheckCircle },
      'rejected': { color: 'bg-red-100 text-red-800', label: 'Từ chối', icon: XCircle }
    }
    const statusInfo = statusMap[status] || { color: 'bg-gray-100 text-gray-800', label: status || 'N/A', icon: Clock }
    const Icon = statusInfo.icon
    
    return (
      <span className={`flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${statusInfo.color}`}>
        <Icon size={12} />
        {statusInfo.label}
      </span>
    )
  }

  const formatPrice = (price) => {
    return new Intl.NumberFormat('vi-VN').format(price || 0)
  }

  const formatDateTime = (dateString) => {
    if (!dateString) return 'N/A'
    try {
      const date = new Date(dateString)
      return date.toLocaleString('vi-VN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      })
    } catch {
      return dateString
    }
  }

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 className="animate-spin text-sky-500" size={32} />
        <span className="ml-3 text-slate-600">Đang tải dữ liệu...</span>
      </div>
    )
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Quản lý ưu đãi giảm giá</h1>
          <p className="text-slate-600 mt-1">Tạo và quản lý các ưu đãi giảm giá cho khách sạn</p>
        </div>
        <button
          onClick={() => {
            resetForm()
            setShowModal(true)
          }}
          className="flex items-center gap-2 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 font-medium"
        >
          <Plus size={20} />
          Tạo ưu đãi mới
        </button>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error}
        </div>
      )}

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {promotions.length === 0 ? (
          <div className="col-span-full bg-white rounded-lg shadow-sm border border-slate-200 p-12 text-center">
            <Percent className="mx-auto text-gray-400 mb-4" size={48} />
            <p className="text-slate-500 mb-4 text-lg">Chưa có ưu đãi nào</p>
            <button
              onClick={() => {
                resetForm()
                setShowModal(true)
              }}
              className="px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700"
            >
              Tạo ưu đãi đầu tiên
            </button>
          </div>
        ) : (
          promotions.map((promotion) => {
            const phanTram = parseFloat(promotion.phan_tram || promotion.discount_value || 0)
            const giamToiDa = parseFloat(promotion.giam_toi_da || 0)
            const originalPrice = promotion.original_price || (phanTram > 0 ? (giamToiDa / phanTram * 100) : 0)
            const discountedPrice = originalPrice - giamToiDa
            const isActive = promotion.is_active || promotion.trang_thai === 1
            const status = promotion.status || (isActive ? 'approved' : 'pending')
            const isExpired = new Date(promotion.end_time || promotion.ngay_ket_thuc) < new Date()
            
            return (
              <motion.div
                key={promotion.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-white rounded-lg shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="font-semibold text-slate-900 mb-2">{promotion.title || promotion.ten}</h3>
                    <p className="text-sm text-slate-600 mb-2">{promotion.description || promotion.mo_ta || 'Không có mô tả'}</p>
                    <div className="flex items-center gap-2 mb-2">
                      {getStatusBadge(status, isActive)}
                      {isExpired && (
                        <span className="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-700">
                          Đã hết hạn
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="space-y-2 mb-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-slate-600">Giá gốc:</span>
                    <span className="text-sm font-semibold text-slate-900 line-through">
                      {formatPrice(originalPrice)} VND
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-slate-600">Giá ưu đãi:</span>
                    <span className="text-lg font-bold text-sky-600">
                      {formatPrice(discountedPrice)} VND
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-slate-600">Giảm giá:</span>
                    <span className="text-sm font-bold text-red-600">
                      {formatPrice(giamToiDa)} VND ({phanTram.toFixed(1)}%)
                    </span>
                  </div>
                  <div className="flex items-center gap-2 text-sm text-slate-600">
                    <Calendar size={16} />
                    <span className="text-xs">
                      Từ: {formatDateTime(promotion.start_time || promotion.ngay_bat_dau)}<br />
                      Đến: {formatDateTime(promotion.end_time || promotion.ngay_ket_thuc)}
                    </span>
                  </div>
                </div>

                <div className="flex gap-2 flex-wrap">
                  {status === 'approved' && (
                    <button
                      onClick={() => handleToggle(promotion)}
                      className={`flex items-center gap-1 px-3 py-2 text-sm rounded-lg font-medium ${
                        isActive
                          ? 'bg-green-50 text-green-600 hover:bg-green-100'
                          : 'bg-gray-50 text-gray-600 hover:bg-gray-100'
                      }`}
                    >
                      {isActive ? <PowerOff size={16} /> : <Power size={16} />}
                      {isActive ? 'Tắt' : 'Bật'}
                    </button>
                  )}
                  {status !== 'pending' && (
                    <button
                      onClick={() => handleSubmitApproval(promotion)}
                      className="flex items-center gap-1 px-3 py-2 text-sm bg-yellow-50 text-yellow-600 rounded-lg hover:bg-yellow-100 font-medium"
                    >
                      <Send size={16} />
                      Gửi duyệt
                    </button>
                  )}
                  <button
                    onClick={() => handleEdit(promotion)}
                    className="flex items-center gap-1 px-3 py-2 text-sm bg-sky-50 text-sky-600 rounded-lg hover:bg-sky-100 font-medium"
                  >
                    <Edit size={16} />
                    Sửa
                  </button>
                  <button
                    onClick={() => handleDelete(promotion.id)}
                    className="px-3 py-2 text-sm bg-red-50 text-red-600 rounded-lg hover:bg-red-100"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </motion.div>
            )
          })
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto"
          >
            <h2 className="text-2xl font-bold text-slate-900 mb-4">
              {editingPromotion ? 'Chỉnh sửa ưu đãi' : 'Tạo ưu đãi mới'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Tiêu đề *</label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                  required
                  placeholder="Nhập tiêu đề ưu đãi"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Mô tả</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                  rows="3"
                  placeholder="Nhập mô tả ưu đãi (tùy chọn)"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Giá gốc (VND) *</label>
                <input
                  type="number"
                  value={formData.original_price}
                  onChange={(e) => setFormData({ ...formData, original_price: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                  required
                  min="0"
                  step="1000"
                  placeholder="Nhập giá gốc"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Loại giảm giá *</label>
                  <select
                    value={formData.discount_type}
                    onChange={(e) => setFormData({ ...formData, discount_type: e.target.value, discount_value: '' })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                  >
                    <option value="percent">Giảm theo %</option>
                    <option value="amount">Giảm theo số tiền</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    {formData.discount_type === 'percent' ? 'Phần trăm giảm (%) *' : 'Số tiền giảm (VND) *'}
                  </label>
                  <input
                    type="number"
                    value={formData.discount_value}
                    onChange={(e) => setFormData({ ...formData, discount_value: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                    required
                    min="0"
                    max={formData.discount_type === 'percent' ? 100 : formData.original_price}
                    step={formData.discount_type === 'percent' ? '1' : '1000'}
                    placeholder={formData.discount_type === 'percent' ? 'Nhập %' : 'Nhập số tiền'}
                  />
                </div>
              </div>

              {formData.original_price && formData.discount_value && (
                <div className="p-3 bg-sky-50 rounded-lg">
                  <p className="text-sm text-slate-700">
                    Giá sau giảm: <span className="font-bold text-sky-600">
                      {formatPrice(calculateDiscountedPrice())} VND
                    </span>
                    {formData.discount_type === 'percent' && (
                      <span className="ml-2 text-red-600">
                        (Giảm {formData.discount_value}%)
                      </span>
                    )}
                  </p>
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Số lượng phòng *</label>
                <input
                  type="number"
                  value={formData.total_rooms}
                  onChange={(e) => setFormData({ ...formData, total_rooms: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                  required
                  min="1"
                  placeholder="Nhập số lượng phòng"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Thời gian bắt đầu *</label>
                  <input
                    type="datetime-local"
                    value={formData.start_time}
                    onChange={(e) => setFormData({ ...formData, start_time: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Thời gian kết thúc *</label>
                  <input
                    type="datetime-local"
                    value={formData.end_time}
                    onChange={(e) => setFormData({ ...formData, end_time: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                    required
                  />
                </div>
              </div>

              {!editingPromotion && (
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="submit_for_approval"
                    checked={formData.submit_for_approval}
                    onChange={(e) => setFormData({ ...formData, submit_for_approval: e.target.checked })}
                    className="w-4 h-4 text-sky-600 border-slate-300 rounded focus:ring-sky-500"
                  />
                  <label htmlFor="submit_for_approval" className="text-sm text-slate-700">
                    Gửi Admin duyệt ngay sau khi tạo
                  </label>
                </div>
              )}

              <div className="flex gap-3 pt-4">
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 font-medium"
                >
                  {editingPromotion ? 'Cập nhật' : 'Tạo ưu đãi'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setShowModal(false)
                    resetForm()
                  }}
                  className="px-4 py-2 bg-slate-200 text-slate-700 rounded-lg hover:bg-slate-300 font-medium"
                >
                  Hủy
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  )
}

export default Promotions
