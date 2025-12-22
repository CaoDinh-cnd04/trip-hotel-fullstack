import React, { useState } from 'react'
import { useQuery } from 'react-query'
import { motion } from 'framer-motion'
import { Star, Calendar, Hotel, MessageSquare, CheckCircle, Clock, XCircle } from 'lucide-react'
import { reviewAPI } from '../../services/api/user'
import toast from 'react-hot-toast'

const MyReviewsPage = () => {
  const [activeTab, setActiveTab] = useState(0) // 0: Chưa đánh giá, 1: Đã đánh giá, 2: Tất cả

  const { data: reviews, isLoading, refetch } = useQuery(
    'my-reviews',
    async () => {
      try {
        const response = await reviewAPI.getMyReviews()
        return response.data || []
      } catch (error) {
        console.error('Error fetching reviews:', error)
        return []
      }
    }
  )

  const tabs = [
    { id: 0, label: 'Chưa đánh giá', icon: Clock },
    { id: 1, label: 'Đã đánh giá', icon: CheckCircle },
    { id: 2, label: 'Tất cả', icon: MessageSquare }
  ]

  const filteredReviews = reviews?.filter(review => {
    if (activeTab === 0) return !review.isReviewed
    if (activeTab === 1) return review.isReviewed
    return true
  }) || []

  const renderStars = (rating) => {
    return Array.from({ length: 5 }).map((_, index) => (
      <Star
        key={index}
        size={16}
        className={index < rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}
      />
    ))
  }

  const formatDate = (dateString) => {
    if (!dateString) return ''
    const date = new Date(dateString)
    return date.toLocaleDateString('vi-VN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Đang tải nhận xét...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-br from-blue-600 via-blue-500 to-blue-700 text-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-8">
          <h1 className="text-3xl font-bold mb-2">Nhận xét của tôi</h1>
          <p className="text-blue-100">Xem và quản lý các nhận xét của bạn</p>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 pb-8">
        {/* Tabs */}
        <div className="bg-white rounded-xl shadow-sm mb-6 overflow-hidden">
          <div className="flex border-b border-gray-200">
            {tabs.map((tab) => {
              const Icon = tab.icon
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex-1 flex items-center justify-center gap-2 py-4 px-6 font-medium transition-colors ${
                    activeTab === tab.id
                      ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`}
                >
                  <Icon size={18} />
                  <span>{tab.label}</span>
                </button>
              )
            })}
          </div>
        </div>

        {/* Reviews List */}
        {filteredReviews.length === 0 ? (
          <div className="bg-white rounded-xl shadow-sm p-12 text-center">
            <MessageSquare size={64} className="mx-auto text-gray-300 mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 mb-2">
              {activeTab === 0 ? 'Chưa có đặt phòng nào cần đánh giá' : 'Chưa có nhận xét nào'}
            </h3>
            <p className="text-gray-500">
              {activeTab === 0
                ? 'Sau khi hoàn thành đặt phòng, bạn có thể đánh giá trải nghiệm của mình'
                : 'Các nhận xét của bạn sẽ hiển thị ở đây'}
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredReviews.map((review) => (
              <motion.div
                key={review.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                        <Hotel size={24} className="text-blue-600" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-gray-900">
                          {review.hotel_name || review.ten_khach_san || 'Khách sạn'}
                        </h3>
                        <p className="text-sm text-gray-500">
                          {formatDate(review.ngay_checkout || review.checkout_date)}
                        </p>
                      </div>
                    </div>
                  </div>
                  {review.isReviewed ? (
                    <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-medium flex items-center gap-1">
                      <CheckCircle size={14} />
                      Đã đánh giá
                    </span>
                  ) : (
                    <span className="px-3 py-1 bg-amber-100 text-amber-700 rounded-full text-xs font-medium flex items-center gap-1">
                      <Clock size={14} />
                      Chưa đánh giá
                    </span>
                  )}
                </div>

                {review.isReviewed && review.rating ? (
                  <div className="space-y-3">
                    <div className="flex items-center gap-2">
                      {renderStars(review.rating || review.so_sao_tong || review.diem_danh_gia || 0)}
                      <span className="text-sm font-medium text-gray-700">
                        {review.rating || review.so_sao_tong || review.diem_danh_gia || 0}/5
                      </span>
                    </div>
                    {review.noi_dung && (
                      <p className="text-gray-700 leading-relaxed">{review.noi_dung}</p>
                    )}
                    {review.nguoi_quan_ly_tra_loi && (
                      <div className="bg-blue-50 rounded-lg p-4 mt-3">
                        <p className="text-sm font-medium text-blue-900 mb-1">Phản hồi từ khách sạn:</p>
                        <p className="text-sm text-blue-700">{review.nguoi_quan_ly_tra_loi}</p>
                      </div>
                    )}
                    <p className="text-xs text-gray-400">
                      Đánh giá vào {formatDate(review.ngay_danh_gia || review.created_at)}
                    </p>
                  </div>
                ) : (
                  <div className="bg-gray-50 rounded-lg p-4">
                    <p className="text-sm text-gray-600 mb-3">
                      Bạn chưa đánh giá đặt phòng này. Hãy chia sẻ trải nghiệm của bạn!
                    </p>
                    <button
                      onClick={() => {
                        // TODO: Navigate to review form
                        toast.info('Tính năng đánh giá đang phát triển')
                      }}
                      className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium"
                    >
                      Viết đánh giá
                    </button>
                  </div>
                )}
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default MyReviewsPage

