import { useState, useEffect } from 'react'
import { CheckCircle, XCircle, Clock, Package, Calendar, Building2, Filter, Search, Eye, Trash2, Edit, RefreshCw, X, Power, PowerOff } from 'lucide-react'
import { promotionOfferAPI, promotionAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import { motion, AnimatePresence } from 'framer-motion'

const PromotionOffersManagement = () => {
  const [offers, setOffers] = useState([])
  const [loading, setLoading] = useState(true)
  const [filterStatus, setFilterStatus] = useState('all') // all, pending, approved, rejected
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedOffer, setSelectedOffer] = useState(null)
  const [showDetailModal, setShowDetailModal] = useState(false)

  useEffect(() => {
    fetchOffers()
  }, [filterStatus])

  const fetchOffers = async () => {
    try {
      setLoading(true)
      const params = {}
      if (filterStatus !== 'all') {
        params.status = filterStatus
      }
      const response = await promotionOfferAPI.getAll(params)
      const offersData = response?.data || response || []
      
      console.log('📋 [Frontend] Raw offers data:', offersData)
      console.log('📋 [Frontend] Raw offers count:', offersData.length)
      
      // Map dữ liệu để đảm bảo có đầy đủ thông tin
      const mappedOffers = Array.isArray(offersData) ? offersData.map(offer => {
        // Đảm bảo id là số nguyên
        let offerId = offer.id
        if (Array.isArray(offerId)) {
          offerId = offerId[0]
        } else if (typeof offerId === 'string' && offerId.includes(',')) {
          offerId = parseInt(offerId.split(',')[0])
        } else {
          offerId = parseInt(offerId)
        }
        
        // Xử lý trang_thai - có thể là BIT (true/false) hoặc số (1/0)
        const trangThai = offer.trang_thai === true || offer.trang_thai === 1 || offer.trang_thai === '1' || offer.is_active === true || offer.is_active === 1;
        
        return {
          ...offer,
          id: offerId, // Đảm bảo id là số nguyên
          status: trangThai ? 'approved' : 'pending',
          discount_type: 'percent', // Mặc định là percent
          original_price: offer.original_price || (offer.giam_toi_da && offer.phan_tram ? 
            Math.round(offer.giam_toi_da / (offer.phan_tram / 100)) : null),
          discounted_price: offer.discounted_price || (offer.giam_toi_da && offer.phan_tram ? 
            Math.round(offer.giam_toi_da / (offer.phan_tram / 100) - offer.giam_toi_da) : null),
          total_rooms: offer.so_luong_phong || offer.total_rooms || 0,
          available_rooms: offer.so_luong_phong || offer.available_rooms || 0,
          ten_loai_phong: offer.ten_loai_phong || 'Tất cả loại phòng'
        }
      }) : []
      
      // Loại bỏ duplicate dựa trên id
      const uniqueOffers = []
      const seenIds = new Set()
      
      for (const offer of mappedOffers) {
        if (!seenIds.has(offer.id)) {
          seenIds.add(offer.id)
          uniqueOffers.push(offer)
        } else {
          console.warn(`⚠️ [Frontend] Duplicate offer ID found: ${offer.id}`)
        }
      }
      
      console.log('📋 [Frontend] Mapped offers count:', mappedOffers.length)
      console.log('📋 [Frontend] Unique offers count:', uniqueOffers.length)
      console.log('📋 [Frontend] Unique offer IDs:', uniqueOffers.map(o => o.id))
      
      setOffers(uniqueOffers)
    } catch (err) {
      console.error('Error fetching promotion offers:', err)
      toast.error('Không thể tải danh sách ưu đãi: ' + (err.response?.data?.message || err.message))
      setOffers([])
    } finally {
      setLoading(false)
    }
  }

  const handleApprove = async (offerId) => {
    if (!window.confirm('Bạn có chắc chắn muốn duyệt ưu đãi này?')) {
      return
    }

    try {
      // Đảm bảo offerId là số nguyên
      const id = parseInt(offerId)
      if (isNaN(id)) {
        toast.error('ID ưu đãi không hợp lệ')
        return
      }
      
      console.log('📤 Approving offer with ID:', id)
      await promotionOfferAPI.approve(id)
      toast.success('Đã duyệt ưu đãi thành công')
      fetchOffers()
    } catch (err) {
      console.error('Error approving offer:', err)
      toast.error('Không thể duyệt ưu đãi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleReject = async (offerId) => {
    const reason = window.prompt('Vui lòng nhập lý do từ chối:')
    if (!reason) return

    try {
      // Đảm bảo offerId là số nguyên
      const id = parseInt(offerId)
      if (isNaN(id)) {
        toast.error('ID ưu đãi không hợp lệ')
        return
      }
      
      console.log('📤 Rejecting offer with ID:', id)
      await promotionOfferAPI.reject(id, reason)
      toast.success('Đã từ chối ưu đãi')
      fetchOffers()
    } catch (err) {
      console.error('Error rejecting offer:', err)
      toast.error('Không thể từ chối ưu đãi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleViewDetail = (offer) => {
    setSelectedOffer(offer)
    setShowDetailModal(true)
  }

  const handleDelete = async (offerId) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa ưu đãi này? Hành động này không thể hoàn tác và sẽ xóa vĩnh viễn khỏi database.')) {
      return
    }

    const id = parseInt(offerId)
    if (isNaN(id)) {
      toast.error('ID ưu đãi không hợp lệ')
      return
    }

    // Optimistic update - xóa khỏi UI ngay lập tức
    const previousOffers = [...offers]
    setOffers(prevOffers => prevOffers.filter(offer => offer.id !== id))
    
    try {
      console.log('🗑️ [Frontend] Deleting promotion offer with ID:', id)
      
      // Sử dụng API promotion để xóa vì promotionOfferAPI không có delete
      const response = await promotionAPI.delete(id)
      console.log('✅ [Frontend] Delete response:', response)
      
      // Kiểm tra response
      if (response?.data?.success === false) {
        // Nếu xóa thất bại, khôi phục lại state
        setOffers(previousOffers)
        throw new Error(response.data.message || 'Xóa không thành công')
      }
      
      toast.success('Đã xóa ưu đãi thành công')
      
      // Refresh danh sách từ server để đảm bảo đồng bộ
      console.log('🔄 [Frontend] Refreshing offers list from server...')
      setLoading(true)
      await fetchOffers()
      console.log('✅ [Frontend] Offers list refreshed from server')
    } catch (err) {
      // Nếu có lỗi, khôi phục lại state
      setOffers(previousOffers)
      
      console.error('❌ [Frontend] Error deleting offer:', err)
      console.error('Error details:', {
        message: err.message,
        response: err.response?.data,
        status: err.response?.status
      })
      
      const errorMessage = err.response?.data?.message || err.message || 'Không thể xóa ưu đãi'
      
      // Nếu có lỗi foreign key constraint, thông báo rõ ràng
      if (err.response?.data?.error?.number === 547 || 
          errorMessage.includes('FOREIGN KEY') || 
          errorMessage.includes('constraint')) {
        toast.error('Không thể xóa vì ưu đãi này đang được sử dụng trong hệ thống')
      } else {
        toast.error('Không thể xóa ưu đãi: ' + errorMessage)
      }
    }
  }

  const handleToggle = async (offerId, currentStatus) => {
    try {
      const id = parseInt(offerId)
      if (isNaN(id)) {
        toast.error('ID ưu đãi không hợp lệ')
        return
      }
      
      // Sử dụng API promotion để toggle
      await promotionAPI.toggle(id)
      toast.success(`Đã ${currentStatus === 'approved' ? 'tắt' : 'bật'} ưu đãi`)
      fetchOffers()
    } catch (err) {
      console.error('Error toggling offer:', err)
      toast.error('Không thể thay đổi trạng thái: ' + (err.response?.data?.message || err.message))
    }
  }

  const formatPrice = (price) => {
    if (!price && price !== 0) return 'N/A'
    return new Intl.NumberFormat('vi-VN').format(price)
  }

  const formatDateTime = (dateString) => {
    if (!dateString) return 'N/A'
    const date = new Date(dateString)
    return date.toLocaleString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A'
    const date = new Date(dateString)
    return date.toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    })
  }

  const getStatusBadge = (status) => {
    const statusConfig = {
      pending: { label: 'Chờ duyệt', color: 'bg-yellow-100 text-yellow-800', icon: Clock },
      approved: { label: 'Đã duyệt', color: 'bg-green-100 text-green-800', icon: CheckCircle },
      rejected: { label: 'Từ chối', color: 'bg-red-100 text-red-800', icon: XCircle }
    }
    const config = statusConfig[status] || statusConfig.pending
    const Icon = config.icon
    return (
      <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium ${config.color}`}>
        <Icon size={14} />
        {config.label}
      </span>
    )
  }

  const filteredOffers = offers.filter(offer => {
    const matchesStatus = filterStatus === 'all' || offer.status === filterStatus
    const matchesSearch = !searchTerm || 
      offer.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      offer.ten_khach_san?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      offer.ten_loai_phong?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      offer.ten_nguoi_quan_ly?.toLowerCase().includes(searchTerm.toLowerCase())
    return matchesStatus && matchesSearch
  })

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-sky-600"></div>
      </div>
    )
  }

  return (
    <div className="p-6">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 mb-2">Quản lý ưu đãi khách sạn</h1>
          <p className="text-slate-600">Duyệt và quản lý các ưu đãi từ hotel managers</p>
        </div>
        <button
          onClick={fetchOffers}
          className="flex items-center gap-2 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 transition-colors font-medium"
        >
          <RefreshCw size={18} />
          Làm mới
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-4 mb-6">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
              <input
                type="text"
                placeholder="Tìm kiếm theo tên ưu đãi, khách sạn, loại phòng, quản lý..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setFilterStatus('all')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filterStatus === 'all'
                  ? 'bg-sky-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              Tất cả ({offers.length})
            </button>
            <button
              onClick={() => setFilterStatus('pending')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filterStatus === 'pending'
                  ? 'bg-yellow-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              Chờ duyệt ({offers.filter(o => o.status === 'pending').length})
            </button>
            <button
              onClick={() => setFilterStatus('approved')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filterStatus === 'approved'
                  ? 'bg-green-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              Đã duyệt ({offers.filter(o => o.status === 'approved').length})
            </button>
            <button
              onClick={() => setFilterStatus('rejected')}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filterStatus === 'rejected'
                  ? 'bg-red-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              Từ chối ({offers.filter(o => o.status === 'rejected').length})
            </button>
          </div>
        </div>
      </div>

      {/* Offers List */}
      {filteredOffers.length === 0 ? (
        <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-12 text-center">
          <Package className="mx-auto text-slate-400 mb-4" size={48} />
          <p className="text-slate-600 text-lg">Không có ưu đãi nào</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredOffers.map((offer) => (
            <motion.div
              key={offer.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-lg shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <h3 className="text-lg font-semibold text-slate-900 mb-1 line-clamp-2">{offer.title || offer.ten || 'Không có tiêu đề'}</h3>
                  <div className="flex items-center gap-2 text-sm text-slate-600 mb-2">
                    <Building2 size={16} />
                    <span className="line-clamp-1">{offer.ten_khach_san || 'N/A'}</span>
                  </div>
                </div>
                {getStatusBadge(offer.status)}
              </div>

              {offer.description && (
                <p className="text-sm text-slate-600 mb-4 line-clamp-2">{offer.description || offer.mo_ta}</p>
              )}

              <div className="space-y-2 mb-4">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-600">Loại phòng:</span>
                  <span className="font-medium">{offer.ten_loai_phong || 'Tất cả'}</span>
                </div>
                {offer.original_price && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-600">Giá gốc:</span>
                    <span className="font-medium">{formatPrice(offer.original_price)} VND</span>
                  </div>
                )}
                {offer.discounted_price && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-600">Giá sau giảm:</span>
                    <span className="font-medium text-green-600">{formatPrice(offer.discounted_price)} VND</span>
                  </div>
                )}
                {offer.phan_tram && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-600">Giảm giá:</span>
                    <span className="font-medium text-red-600">
                      {offer.phan_tram}%
                      {offer.giam_toi_da && ` (Tối đa ${formatPrice(offer.giam_toi_da)} VND)`}
                    </span>
                  </div>
                )}
                {offer.total_rooms > 0 && (
                  <div className="flex items-center gap-2 text-sm text-slate-600">
                    <Package size={16} />
                    <span>{formatPrice(offer.available_rooms || offer.total_rooms)} / {formatPrice(offer.total_rooms)} phòng</span>
                  </div>
                )}
                <div className="flex items-center gap-2 text-sm text-slate-600">
                  <Calendar size={16} />
                  <span className="text-xs">
                    {formatDate(offer.start_time || offer.ngay_bat_dau)} - {formatDate(offer.end_time || offer.ngay_ket_thuc)}
                  </span>
                </div>
                {offer.ten_nguoi_quan_ly && (
                  <div className="flex items-center gap-2 text-sm text-slate-600">
                    <span>Quản lý: <strong>{offer.ten_nguoi_quan_ly}</strong></span>
                  </div>
                )}
                {offer.email_nguoi_quan_ly && (
                  <div className="flex items-center gap-2 text-sm text-slate-500">
                    <span className="text-xs">{offer.email_nguoi_quan_ly}</span>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex gap-2 mt-4 flex-wrap">
                <button
                  onClick={() => handleViewDetail(offer)}
                  className="flex-1 min-w-[80px] flex items-center justify-center gap-2 px-3 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors font-medium text-sm"
                  title="Xem chi tiết"
                >
                  <Eye size={16} />
                  Chi tiết
                </button>
                {offer.status === 'pending' && (
                  <>
                    <button
                      onClick={() => handleApprove(offer.id)}
                      className="flex-1 min-w-[80px] flex items-center justify-center gap-2 px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium text-sm"
                      title="Duyệt ưu đãi"
                    >
                      <CheckCircle size={16} />
                      Duyệt
                    </button>
                    <button
                      onClick={() => handleReject(offer.id)}
                      className="flex-1 min-w-[80px] flex items-center justify-center gap-2 px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium text-sm"
                      title="Từ chối ưu đãi"
                    >
                      <XCircle size={16} />
                      Từ chối
                    </button>
                  </>
                )}
                {offer.status === 'approved' && (
                  <button
                    onClick={() => handleToggle(offer.id, offer.status)}
                    className="flex items-center justify-center gap-2 px-3 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors font-medium text-sm"
                    title="Tắt ưu đãi"
                  >
                    <PowerOff size={16} />
                    Tắt
                  </button>
                )}
                {offer.status === 'rejected' && (
                  <button
                    onClick={() => handleApprove(offer.id)}
                    className="flex items-center justify-center gap-2 px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium text-sm"
                    title="Duyệt lại ưu đãi"
                  >
                    <CheckCircle size={16} />
                    Duyệt lại
                  </button>
                )}
                <button
                  onClick={() => handleDelete(offer.id)}
                  className="flex items-center justify-center gap-2 px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium text-sm"
                  title="Xóa ưu đãi"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {/* Detail Modal */}
      <AnimatePresence>
        {showDetailModal && selectedOffer && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
            onClick={() => setShowDetailModal(false)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-2xl font-bold text-slate-900">Chi tiết ưu đãi</h2>
                <button
                  onClick={() => setShowDetailModal(false)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X size={24} />
                </button>
              </div>
              
              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Tên ưu đãi</label>
                  <p className="text-slate-900 font-semibold">{selectedOffer.title || selectedOffer.ten || 'N/A'}</p>
                </div>
                
                {selectedOffer.description && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Mô tả</label>
                    <p className="text-slate-600 whitespace-pre-wrap">{selectedOffer.description || selectedOffer.mo_ta}</p>
                  </div>
                )}
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Khách sạn</label>
                    <p className="text-slate-900">{selectedOffer.ten_khach_san || 'N/A'}</p>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Loại phòng</label>
                    <p className="text-slate-900">{selectedOffer.ten_loai_phong || 'Tất cả'}</p>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  {selectedOffer.original_price && (
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Giá gốc</label>
                      <p className="text-slate-900 font-semibold">{formatPrice(selectedOffer.original_price)} VND</p>
                    </div>
                  )}
                  {selectedOffer.discounted_price && (
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">Giá sau giảm</label>
                      <p className="text-green-600 font-semibold">{formatPrice(selectedOffer.discounted_price)} VND</p>
                    </div>
                  )}
                </div>
                
                {selectedOffer.phan_tram && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Giảm giá</label>
                    <p className="text-red-600 font-semibold">
                      {selectedOffer.phan_tram}%
                      {selectedOffer.giam_toi_da && ` (Tối đa ${formatPrice(selectedOffer.giam_toi_da)} VND)`}
                    </p>
                  </div>
                )}
                
                {selectedOffer.total_rooms > 0 && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Số lượng phòng</label>
                    <p className="text-slate-900">
                      {formatPrice(selectedOffer.available_rooms || selectedOffer.total_rooms)} / {formatPrice(selectedOffer.total_rooms)} phòng
                    </p>
                  </div>
                )}
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Ngày bắt đầu</label>
                    <p className="text-slate-900">{formatDateTime(selectedOffer.start_time || selectedOffer.ngay_bat_dau)}</p>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Ngày kết thúc</label>
                    <p className="text-slate-900">{formatDateTime(selectedOffer.end_time || selectedOffer.ngay_ket_thuc)}</p>
                  </div>
                </div>
                
                {selectedOffer.ten_nguoi_quan_ly && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Người quản lý</label>
                    <p className="text-slate-900">{selectedOffer.ten_nguoi_quan_ly}</p>
                    {selectedOffer.email_nguoi_quan_ly && (
                      <p className="text-slate-600 text-sm">{selectedOffer.email_nguoi_quan_ly}</p>
                    )}
                  </div>
                )}
                
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Trạng thái</label>
                  {getStatusBadge(selectedOffer.status)}
                </div>
                
                {selectedOffer.created_at && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Ngày tạo</label>
                    <p className="text-slate-600 text-sm">{formatDateTime(selectedOffer.created_at)}</p>
                  </div>
                )}
              </div>
              
              <div className="p-6 border-t border-slate-200 flex gap-3 flex-wrap">
                {selectedOffer.status === 'pending' && (
                  <>
                    <button
                      onClick={() => {
                        handleApprove(selectedOffer.id)
                        setShowDetailModal(false)
                      }}
                      className="flex-1 min-w-[120px] flex items-center justify-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
                    >
                      <CheckCircle size={18} />
                      Duyệt ưu đãi
                    </button>
                    <button
                      onClick={() => {
                        handleReject(selectedOffer.id)
                        setShowDetailModal(false)
                      }}
                      className="flex-1 min-w-[120px] flex items-center justify-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
                    >
                      <XCircle size={18} />
                      Từ chối
                    </button>
                  </>
                )}
                {selectedOffer.status === 'approved' && (
                  <button
                    onClick={() => {
                      handleToggle(selectedOffer.id, selectedOffer.status)
                      setShowDetailModal(false)
                    }}
                    className="flex-1 min-w-[120px] flex items-center justify-center gap-2 px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors font-medium"
                  >
                    <PowerOff size={18} />
                    Tắt ưu đãi
                  </button>
                )}
                {selectedOffer.status === 'rejected' && (
                  <button
                    onClick={() => {
                      handleApprove(selectedOffer.id)
                      setShowDetailModal(false)
                    }}
                    className="flex-1 min-w-[120px] flex items-center justify-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
                  >
                    <CheckCircle size={18} />
                    Duyệt lại
                  </button>
                )}
                <button
                  onClick={() => {
                    handleDelete(selectedOffer.id)
                    setShowDetailModal(false)
                  }}
                  className="flex items-center justify-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
                >
                  <Trash2 size={18} />
                  Xóa
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default PromotionOffersManagement
