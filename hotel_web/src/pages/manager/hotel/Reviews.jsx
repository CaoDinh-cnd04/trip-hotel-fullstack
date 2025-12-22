import { useState, useEffect } from 'react'
import { Loader2, MessageSquare, Star, Flag, Reply, TrendingUp, Filter } from 'lucide-react'
import { hotelManagerAPI } from '../../../services/api/hotelManagerAPI'
import toast from 'react-hot-toast'
import { motion } from 'framer-motion'

const Reviews = () => {
  const [reviews, setReviews] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedReview, setSelectedReview] = useState(null)
  const [responseText, setResponseText] = useState('')
  const [showReportModal, setShowReportModal] = useState(false)
  const [reportReason, setReportReason] = useState('')
  const [reportDescription, setReportDescription] = useState('')
  const [reportingReviewId, setReportingReviewId] = useState(null)
  const [statistics, setStatistics] = useState({ averageRating: 0, totalReviews: 0 })
  const [filterStatus, setFilterStatus] = useState('all') // all, approved, pending, rejected

  useEffect(() => {
    fetchReviews()
  }, [filterStatus])

  const fetchReviews = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await hotelManagerAPI.getHotelReviews()
      const data = response?.data || response || []
      
      // Log để debug
      console.log('📊 Reviews data:', data)
      if (data.length > 0) {
        console.log('📊 First review sample:', data[0])
        console.log('📊 Rating field:', data[0].diem_danh_gia, 'Type:', typeof data[0].diem_danh_gia)
      }
      
      // Filter reviews by status
      let filteredData = data
      if (filterStatus !== 'all') {
        filteredData = data.filter(review => {
          if (filterStatus === 'approved') return review.trang_thai === 'Đã duyệt'
          if (filterStatus === 'pending') return review.trang_thai === 'Chờ duyệt'
          if (filterStatus === 'rejected') return review.trang_thai === 'Từ chối'
          return true
        })
      }
      
      setReviews(filteredData)
      
      // Set statistics
      if (response?.statistics) {
        setStatistics(response.statistics)
      } else if (data.length > 0 && data[0].diem_trung_binh) {
        // Calculate from first review if statistics not provided
        const approvedReviews = data.filter(r => r.trang_thai === 'Đã duyệt')
        const avg = approvedReviews.length > 0
          ? (approvedReviews.reduce((sum, r) => sum + (parseFloat(r.diem_danh_gia) || 0), 0) / approvedReviews.length).toFixed(1)
          : '0.0'
        setStatistics({
          averageRating: avg,
          totalReviews: approvedReviews.length
        })
      }
    } catch (err) {
      setError(err.message || 'Không thể tải danh sách đánh giá')
      console.error('Error fetching reviews:', err)
      toast.error('Không thể tải danh sách đánh giá')
    } finally {
      setLoading(false)
    }
  }

  const handleRespond = async (reviewId) => {
    if (!responseText.trim()) {
      toast.error('Vui lòng nhập phản hồi')
      return
    }

    try {
      await hotelManagerAPI.respondToReview(reviewId, responseText)
      toast.success('Phản hồi thành công!')
      setSelectedReview(null)
      setResponseText('')
      await fetchReviews()
    } catch (err) {
      toast.error('Lỗi khi phản hồi: ' + (err.response?.data?.message || err.message || 'Vui lòng thử lại'))
    }
  }

  const handleReport = async () => {
    if (!reportReason.trim()) {
      toast.error('Vui lòng chọn lý do báo cáo')
      return
    }

    try {
      await hotelManagerAPI.reportReview(reportingReviewId, {
        reason: reportReason,
        description: reportDescription
      })
      toast.success('Đã gửi báo cáo thành công! Admin sẽ xem xét đánh giá này.')
      setShowReportModal(false)
      setReportReason('')
      setReportDescription('')
      setReportingReviewId(null)
      await fetchReviews()
    } catch (err) {
      toast.error('Lỗi khi báo cáo: ' + (err.response?.data?.message || err.message || 'Vui lòng thử lại'))
    }
  }

  const openReportModal = (reviewId) => {
    setReportingReviewId(reviewId)
    setShowReportModal(true)
  }

  const renderStars = (rating) => {
    // Handle multiple possible field names
    const ratingValue = rating || rating === 0 ? rating : null
    const numRating = ratingValue !== null && ratingValue !== undefined 
      ? parseFloat(ratingValue) 
      : 0
    
    // Ensure rating is between 0 and 5
    const clampedRating = Math.max(0, Math.min(5, numRating))
    
    return Array.from({ length: 5 }, (_, i) => (
      <Star
        key={i}
        size={18}
        className={i < clampedRating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}
      />
    ))
  }

  const getStatusBadge = (status) => {
    const statusMap = {
      'Đã duyệt': { color: 'bg-green-100 text-green-800', label: 'Đã duyệt' },
      'Chờ duyệt': { color: 'bg-yellow-100 text-yellow-800', label: 'Chờ duyệt' },
      'Từ chối': { color: 'bg-red-100 text-red-800', label: 'Từ chối' }
    }
    const statusInfo = statusMap[status] || { color: 'bg-gray-100 text-gray-800', label: status || 'N/A' }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-medium ${statusInfo.color}`}>
        {statusInfo.label}
      </span>
    )
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A'
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('vi-VN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
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

  if (error) {
    return (
      <div className="p-8 text-center">
        <p className="text-red-600">{error}</p>
        <button
          onClick={fetchReviews}
          className="mt-4 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700"
        >
          Thử lại
        </button>
      </div>
    )
  }

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-slate-900 mb-2">Quản lý đánh giá & phản hồi</h1>
        <p className="text-slate-600">Xem và quản lý đánh giá từ khách hàng</p>
      </div>

      {/* Statistics Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-r from-sky-500 to-blue-600 rounded-lg shadow-lg p-6 mb-6 text-white"
      >
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp size={24} />
              <h2 className="text-xl font-semibold">Điểm trung bình</h2>
            </div>
            <div className="flex items-baseline gap-3">
              <span className="text-4xl font-bold">{statistics.averageRating || '0.0'}</span>
              <div className="flex items-center gap-1">
                {renderStars(statistics.averageRating)}
              </div>
            </div>
            <p className="text-sm text-sky-100 mt-2">
              Dựa trên {statistics.totalReviews || 0} đánh giá đã được duyệt
            </p>
          </div>
        </div>
      </motion.div>

      {/* Filter */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-4 mb-6">
        <div className="flex items-center gap-4">
          <Filter size={20} className="text-slate-600" />
          <span className="text-sm font-medium text-slate-700">Lọc theo trạng thái:</span>
          <div className="flex gap-2">
            {['all', 'approved', 'pending', 'rejected'].map((status) => (
              <button
                key={status}
                onClick={() => setFilterStatus(status)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  filterStatus === status
                    ? 'bg-sky-600 text-white'
                    : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                }`}
              >
                {status === 'all' && 'Tất cả'}
                {status === 'approved' && 'Đã duyệt'}
                {status === 'pending' && 'Chờ duyệt'}
                {status === 'rejected' && 'Từ chối'}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Reviews List */}
      <div className="space-y-4">
        {reviews.length === 0 ? (
          <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-12 text-center">
            <MessageSquare className="mx-auto text-gray-400 mb-4" size={48} />
            <p className="text-slate-500 text-lg">Chưa có đánh giá nào</p>
            <p className="text-slate-400 text-sm mt-2">
              {filterStatus !== 'all' ? 'Không có đánh giá nào với trạng thái này' : ''}
            </p>
          </div>
        ) : (
          reviews.map((review) => (
            <motion.div
              key={review.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <div className="w-10 h-10 rounded-full bg-sky-100 flex items-center justify-center">
                      <span className="text-sky-600 font-semibold">
                        {(review.ten_khach_hang || 'K').charAt(0).toUpperCase()}
                      </span>
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-slate-900">
                          {review.ten_khach_hang || 'Khách hàng'}
                        </h3>
                        {getStatusBadge(review.trang_thai)}
                      </div>
                      <div className="flex items-center gap-2">
                        <div className="flex items-center gap-1">
                          {renderStars(review.diem_danh_gia || review.so_sao_tong || review.rating || 0)}
                        </div>
                        <span className="text-sm text-slate-500">
                          {formatDate(review.ngay_danh_gia)}
                        </span>
                        {review.so_phong && review.so_phong !== 'N/A' && (
                          <span className="text-xs text-slate-400">
                            • Phòng {review.so_phong}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                  
                  <p className="text-slate-700 mb-3 ml-13">
                    {review.noi_dung || review.binh_luan || 'Không có nội dung'}
                  </p>

                  {review.phan_hoi_khach_san ? (
                    <div className="mt-3 p-4 bg-sky-50 rounded-lg border-l-4 border-sky-500">
                      <div className="flex items-center gap-2 mb-1">
                        <Reply size={16} className="text-sky-600" />
                        <p className="text-sm font-semibold text-sky-700">Phản hồi của khách sạn:</p>
                      </div>
                      <p className="text-sm text-slate-700">{review.phan_hoi_khach_san}</p>
                      {review.ngay_phan_hoi && (
                        <p className="text-xs text-slate-400 mt-1">
                          {formatDate(review.ngay_phan_hoi)}
                        </p>
                      )}
                    </div>
                  ) : (
                    <div className="flex gap-2 mt-3">
                      <button
                        onClick={() => setSelectedReview(review.id)}
                        className="flex items-center gap-2 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 text-sm font-medium transition-colors"
                      >
                        <Reply size={16} />
                        Trả lời đánh giá
                      </button>
                      <button
                        onClick={() => openReportModal(review.id)}
                        className="flex items-center gap-2 px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 text-sm font-medium transition-colors"
                      >
                        <Flag size={16} />
                        Báo cáo vi phạm
                      </button>
                    </div>
                  )}
                </div>
              </div>

              {/* Response Form */}
              {selectedReview === review.id && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  className="mt-4 p-4 bg-slate-50 rounded-lg border border-slate-200"
                >
                  <textarea
                    value={responseText}
                    onChange={(e) => setResponseText(e.target.value)}
                    placeholder="Nhập phản hồi của bạn..."
                    className="w-full p-3 border border-slate-300 rounded-lg mb-3 focus:outline-none focus:ring-2 focus:ring-sky-500"
                    rows="3"
                  />
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleRespond(review.id)}
                      className="px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 font-medium"
                    >
                      Gửi phản hồi
                    </button>
                    <button
                      onClick={() => {
                        setSelectedReview(null)
                        setResponseText('')
                      }}
                      className="px-4 py-2 bg-slate-200 text-slate-700 rounded-lg hover:bg-slate-300 font-medium"
                    >
                      Hủy
                    </button>
                  </div>
                </motion.div>
              )}
            </motion.div>
          ))
        )}
      </div>

      {/* Report Modal */}
      {showReportModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full mx-4"
          >
            <h3 className="text-xl font-bold text-slate-900 mb-4">Báo cáo đánh giá vi phạm</h3>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-slate-700 mb-2">
                Lý do báo cáo <span className="text-red-500">*</span>
              </label>
              <select
                value={reportReason}
                onChange={(e) => setReportReason(e.target.value)}
                className="w-full p-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
              >
                <option value="">Chọn lý do...</option>
                <option value="Nội dung không phù hợp">Nội dung không phù hợp</option>
                <option value="Ngôn từ không lịch sự">Ngôn từ không lịch sự</option>
                <option value="Đánh giá giả mạo">Đánh giá giả mạo</option>
                <option value="Spam">Spam</option>
                <option value="Khác">Khác</option>
              </select>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-slate-700 mb-2">
                Mô tả chi tiết (tùy chọn)
              </label>
              <textarea
                value={reportDescription}
                onChange={(e) => setReportDescription(e.target.value)}
                placeholder="Mô tả chi tiết về vi phạm..."
                className="w-full p-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                rows="3"
              />
            </div>

            <div className="flex gap-2">
              <button
                onClick={handleReport}
                className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium"
              >
                Gửi báo cáo
              </button>
              <button
                onClick={() => {
                  setShowReportModal(false)
                  setReportReason('')
                  setReportDescription('')
                  setReportingReviewId(null)
                }}
                className="flex-1 px-4 py-2 bg-slate-200 text-slate-700 rounded-lg hover:bg-slate-300 font-medium"
              >
                Hủy
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  )
}

export default Reviews
