import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bell, Mail } from 'lucide-react'
import { notificationAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'

const CreateNotificationPage = () => {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    type: 'general',
    image_url: '',
    action_url: '',
    action_text: '',
    hotel_id: '',
    expires_at: '',
    target_audience: 'all',
    send_email: false
  })

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!formData.title || !formData.content) {
      toast.error('Vui lòng điền đầy đủ thông tin bắt buộc')
      return
    }

    try {
      setLoading(true)
      
      const notificationData = {
        title: formData.title,
        content: formData.content,
        type: formData.type,
        image_url: formData.image_url || null,
        action_url: formData.action_url || null,
        action_text: formData.action_text || null,
        hotel_id: formData.hotel_id || null,
        expires_at: formData.expires_at || null,
        target_audience: formData.target_audience,
        send_email: formData.send_email
      }

      const response = await notificationAPI.create(notificationData)
      
      let successMessage = 'Tạo thông báo thành công!'
      if (formData.send_email && response.data?.emailResults) {
        const emailResults = response.data.emailResults
        if (emailResults.success) {
          successMessage = `Tạo thông báo thành công! Đã gửi email đến ${emailResults.sent || 0} người dùng.`
        } else if (emailResults.error) {
          successMessage = 'Tạo thông báo thành công! (Có lỗi khi gửi email)'
        }
      }
      
      toast.success(successMessage)
      navigate('/admin-hotel/overview')
    } catch (error) {
      console.error('Error creating notification:', error)
      const message = error.response?.data?.message || error.message || 'Không thể tạo thông báo'
      toast.error(message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-slate-900 mb-6">Tạo thông báo</h1>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Thông tin cơ bản</h2>
          
          <div className="space-y-4">
            <Input
              label="Tiêu đề *"
              name="title"
              value={formData.title}
              onChange={handleChange}
              placeholder="Nhập tiêu đề thông báo"
              required
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Nội dung *</label>
              <textarea
                name="content"
                value={formData.content}
                onChange={handleChange}
                className="w-full p-3 border border-gray-300 rounded-md focus:ring-emerald-500 focus:border-emerald-500"
                rows="5"
                placeholder="Nhập nội dung thông báo"
                required
              />
            </div>

            <Select
              label="Loại thông báo"
              name="type"
              value={formData.type}
              onChange={handleChange}
            >
              <option value="general">Chung</option>
              <option value="booking">Đặt phòng</option>
              <option value="payment">Thanh toán</option>
              <option value="promotion">Khuyến mãi</option>
              <option value="reminder">Nhắc nhở</option>
            </Select>

            <Select
              label="Đối tượng nhận"
              name="target_audience"
              value={formData.target_audience}
              onChange={handleChange}
            >
              <option value="all">Tất cả người dùng</option>
              <option value="users">Chỉ người dùng</option>
              <option value="hotel_managers">Chỉ quản lý khách sạn</option>
            </Select>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Tùy chọn nâng cao</h2>
          
          <div className="space-y-4">
            <Input
              label="URL hình ảnh"
              name="image_url"
              value={formData.image_url}
              onChange={handleChange}
              placeholder="https://example.com/image.jpg"
            />

            <Input
              label="URL hành động"
              name="action_url"
              value={formData.action_url}
              onChange={handleChange}
              placeholder="/hotels/123"
            />

            <Input
              label="Văn bản hành động"
              name="action_text"
              value={formData.action_text}
              onChange={handleChange}
              placeholder="Xem chi tiết"
            />

            <Input
              label="ID khách sạn (nếu áp dụng cho khách sạn cụ thể)"
              name="hotel_id"
              type="number"
              value={formData.hotel_id}
              onChange={handleChange}
              placeholder="123"
            />

            <Input
              label="Ngày hết hạn"
              name="expires_at"
              type="datetime-local"
              value={formData.expires_at}
              onChange={handleChange}
            />

            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="send_email"
                name="send_email"
                checked={formData.send_email}
                onChange={handleChange}
                className="form-checkbox h-5 w-5 text-emerald-600 rounded"
              />
              <label htmlFor="send_email" className="text-sm font-medium text-gray-700 flex items-center gap-2">
                <Mail size={16} />
                Gửi email cho người dùng đã đăng nhập
              </label>
            </div>
          </div>
        </div>

        <div className="flex gap-4">
          <Button
            type="submit"
            variant="primary"
            disabled={loading}
            className="flex items-center gap-2"
          >
            <Bell size={20} />
            {loading ? 'Đang tạo...' : 'Tạo thông báo'}
          </Button>
          <Button
            type="button"
            variant="secondary"
            onClick={() => navigate('/admin-hotel/overview')}
          >
            Hủy
          </Button>
        </div>
      </form>
    </div>
  )
}

export default CreateNotificationPage

