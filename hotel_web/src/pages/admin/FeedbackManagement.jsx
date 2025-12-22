import React, { useState, useEffect } from 'react'
import { Loader2, MessageSquare, CheckCircle, XCircle, Reply } from 'lucide-react'
import { feedbackAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'

const FeedbackManagement = () => {
  const [feedbacks, setFeedbacks] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedFeedback, setSelectedFeedback] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [responseText, setResponseText] = useState('')
  const [filter, setFilter] = useState('all') // all, pending, in_progress, resolved, closed

  useEffect(() => {
    fetchFeedbacks()
  }, [filter])

  const fetchFeedbacks = async () => {
    try {
      setLoading(true)
      const params = filter !== 'all' ? { status: filter } : {}
      const response = await feedbackAPI.getAll(params)
      
      // Handle different response formats
      let feedbacksList = []
      if (response) {
        // If response.data exists and is an array
        if (Array.isArray(response.data)) {
          feedbacksList = response.data
        } 
        // If response is already an array (from axios interceptor)
        else if (Array.isArray(response)) {
          feedbacksList = response
        }
        // If response.data.data exists (nested format)
        else if (response.data?.data && Array.isArray(response.data.data)) {
          feedbacksList = response.data.data
        }
      }
      
      console.log('📋 Fetched feedbacks:', feedbacksList.length)
      setFeedbacks(feedbacksList)
    } catch (err) {
      console.error('Error fetching feedbacks:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể tải danh sách phản hồi'
      toast.error(errorMessage)
      setFeedbacks([])
    } finally {
      setLoading(false)
    }
  }

  const handleUpdateStatus = async (id, status) => {
    try {
      await feedbackAPI.updateStatus(id, status)
      toast.success('Cập nhật trạng thái thành công!')
      fetchFeedbacks()
    } catch (err) {
      toast.error('Lỗi khi cập nhật: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleRespond = async (id) => {
    if (!responseText.trim()) {
      toast.error('Vui lòng nhập phản hồi')
      return
    }
    try {
      await feedbackAPI.respond(id, responseText)
      toast.success('Gửi phản hồi thành công!')
      setIsModalOpen(false)
      setResponseText('')
      fetchFeedbacks()
    } catch (err) {
      toast.error('Lỗi khi gửi phản hồi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleViewDetails = (feedback) => {
    setSelectedFeedback(feedback)
    setResponseText(feedback.phanHoiAdmin || feedback.phan_hoi_admin || '')
    setIsModalOpen(true)
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'pending':
        return 'bg-yellow-100 text-yellow-700'
      case 'in_progress':
        return 'bg-blue-100 text-blue-700'
      case 'resolved':
        return 'bg-green-100 text-green-700'
      case 'closed':
        return 'bg-gray-100 text-gray-700'
      default:
        return 'bg-gray-100 text-gray-700'
    }
  }

  const getStatusLabel = (status) => {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý'
      case 'in_progress':
        return 'Đang xử lý'
      case 'resolved':
        return 'Đã giải quyết'
      case 'closed':
        return 'Đã đóng'
      default:
        return status
    }
  }

  const getTypeLabel = (type) => {
    switch (type) {
      case 'complaint':
        return 'Khiếu nại'
      case 'suggestion':
        return 'Góp ý'
      case 'compliment':
        return 'Khen ngợi'
      case 'question':
        return 'Câu hỏi'
      default:
        return type
    }
  }

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 className="animate-spin text-emerald-500" size={32} />
        <span className="ml-3 text-slate-600">Đang tải phản hồi...</span>
      </div>
    )
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-slate-900 mb-6">Quản lý phản hồi</h1>

      <div className="mb-6 flex gap-4">
        <Button
          variant={filter === 'all' ? 'primary' : 'secondary'}
          onClick={() => setFilter('all')}
        >
          Tất cả
        </Button>
        <Button
          variant={filter === 'pending' ? 'primary' : 'secondary'}
          onClick={() => setFilter('pending')}
        >
          Chờ xử lý
        </Button>
        <Button
          variant={filter === 'in_progress' ? 'primary' : 'secondary'}
          onClick={() => setFilter('in_progress')}
        >
          Đang xử lý
        </Button>
        <Button
          variant={filter === 'resolved' ? 'primary' : 'secondary'}
          onClick={() => setFilter('resolved')}
        >
          Đã giải quyết
        </Button>
        <Button
          variant={filter === 'closed' ? 'primary' : 'secondary'}
          onClick={() => setFilter('closed')}
        >
          Đã đóng
        </Button>
      </div>

      {feedbacks.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow-sm border border-gray-200">
          <p className="text-gray-500">Không có phản hồi nào.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {feedbacks.map((feedback) => (
            <div
              key={feedback.id || feedback.ma_phan_hoi}
              className="bg-white rounded-lg shadow-sm border border-gray-200 p-6"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="text-lg font-semibold text-gray-900">
                      {feedback.hoTen || feedback.ten_nguoi_gui || feedback.user_name || 'Người dùng'}
                    </h3>
                    <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(feedback.trangThai || feedback.trang_thai || feedback.status)}`}>
                      {getStatusLabel(feedback.trangThai || feedback.trang_thai || feedback.status)}
                    </span>
                    <span className="px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-700">
                      {getTypeLabel(feedback.loaiPhanHoi || feedback.loai_phan_hoi || feedback.loai || feedback.type)}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mb-2">
                    <strong>Email:</strong> {feedback.email || feedback.emailNguoiDung || 'N/A'}
                  </p>
                  {feedback.tieuDe && (
                    <p className="text-sm font-semibold text-gray-800 mb-1">
                      <strong>Tiêu đề:</strong> {feedback.tieuDe}
                    </p>
                  )}
                  <p className="text-sm text-gray-700 mb-2">
                    {feedback.noiDung || feedback.noi_dung || feedback.content || 'N/A'}
                  </p>
                  {(feedback.phanHoiAdmin || feedback.phan_hoi_admin) && (
                    <div className="mt-3 p-3 bg-gray-50 rounded-lg">
                      <p className="text-sm font-semibold text-gray-700 mb-1">Phản hồi của admin:</p>
                      <p className="text-sm text-gray-600">{feedback.phanHoiAdmin || feedback.phan_hoi_admin}</p>
                    </div>
                  )}
                </div>
              </div>
              <div className="flex gap-2">
                <Button
                  variant="secondary"
                  size="sm"
                  onClick={() => handleViewDetails(feedback)}
                  className="flex items-center gap-1"
                >
                  <MessageSquare size={16} /> Chi tiết
                </Button>
                {(feedback.trangThai || feedback.trang_thai || feedback.status) !== 'resolved' && 
                 (feedback.trangThai || feedback.trang_thai || feedback.status) !== 'closed' && (
                  <>
                    <Button
                      variant="info"
                      size="sm"
                      onClick={() => handleUpdateStatus(feedback.id || feedback.ma_phan_hoi, 'in_progress')}
                      className="flex items-center gap-1"
                    >
                      <CheckCircle size={16} /> Đang xử lý
                    </Button>
                    <Button
                      variant="success"
                      size="sm"
                      onClick={() => handleUpdateStatus(feedback.id || feedback.ma_phan_hoi, 'resolved')}
                      className="flex items-center gap-1"
                    >
                      <CheckCircle size={16} /> Giải quyết
                    </Button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal for details and response */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false)
          setResponseText('')
          setSelectedFeedback(null)
        }}
        title="Chi tiết phản hồi"
      >
        {selectedFeedback && (
          <div className="space-y-4">
            <div>
              <h3 className="font-semibold text-gray-900 mb-2">Thông tin người gửi</h3>
              <p className="text-sm text-gray-600"><strong>Tên:</strong> {selectedFeedback.hoTen || selectedFeedback.ten_nguoi_gui || selectedFeedback.user_name}</p>
              <p className="text-sm text-gray-600"><strong>Email:</strong> {selectedFeedback.email || selectedFeedback.emailNguoiDung}</p>
              <p className="text-sm text-gray-600"><strong>Loại:</strong> {getTypeLabel(selectedFeedback.loaiPhanHoi || selectedFeedback.loai_phan_hoi || selectedFeedback.loai || selectedFeedback.type)}</p>
              <p className="text-sm text-gray-600"><strong>Trạng thái:</strong> {getStatusLabel(selectedFeedback.trangThai || selectedFeedback.trang_thai || selectedFeedback.status)}</p>
            </div>
            <div>
              <h3 className="font-semibold text-gray-900 mb-2">Nội dung phản hồi</h3>
              {selectedFeedback.tieuDe && (
                <p className="text-sm font-semibold text-gray-800 mb-1"><strong>Tiêu đề:</strong> {selectedFeedback.tieuDe}</p>
              )}
              <p className="text-sm text-gray-700">{selectedFeedback.noiDung || selectedFeedback.noi_dung || selectedFeedback.content}</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Phản hồi của admin</label>
              <textarea
                className="w-full p-3 border border-gray-300 rounded-md focus:ring-emerald-500 focus:border-emerald-500"
                rows="4"
                value={responseText}
                onChange={(e) => setResponseText(e.target.value)}
                placeholder="Nhập phản hồi của bạn..."
              />
            </div>
            <div className="flex gap-2">
              <Button
                variant="primary"
                onClick={() => handleRespond(selectedFeedback.id || selectedFeedback.ma_phan_hoi)}
                className="flex items-center gap-1"
              >
                <Reply size={16} /> Gửi phản hồi
              </Button>
              <Button
                variant="secondary"
                onClick={() => setIsModalOpen(false)}
              >
                Đóng
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}

export default FeedbackManagement

