import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Percent } from 'lucide-react'
import { promotionAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'

const CreatePromotionPage = () => {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    ten_khuyen_mai: '',
    mo_ta: '',
    loai: 'percentage',
    gia_tri: '',
    gia_tri_toi_thieu: '',
    ngay_bat_dau: '',
    ngay_ket_thuc: '',
    ma_khach_san: '',
    so_luong_su_dung: '',
    trang_thai: 'active'
  })

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!formData.ten_khuyen_mai || !formData.gia_tri || !formData.ngay_bat_dau || !formData.ngay_ket_thuc) {
      toast.error('Vui lòng điền đầy đủ thông tin bắt buộc')
      return
    }

    try {
      setLoading(true)
      
      const promotionData = {
        ten_khuyen_mai: formData.ten_khuyen_mai,
        mo_ta: formData.mo_ta || '',
        loai: formData.loai,
        gia_tri: parseFloat(formData.gia_tri),
        gia_tri_toi_thieu: formData.gia_tri_toi_thieu ? parseFloat(formData.gia_tri_toi_thieu) : null,
        ngay_bat_dau: formData.ngay_bat_dau,
        ngay_ket_thuc: formData.ngay_ket_thuc,
        ma_khach_san: formData.ma_khach_san || null,
        so_luong_su_dung: formData.so_luong_su_dung ? parseInt(formData.so_luong_su_dung) : null,
        trang_thai: formData.trang_thai
      }

      await promotionAPI.create(promotionData)
      toast.success('Tạo khuyến mãi thành công!')
      navigate('/admin-hotel/overview')
    } catch (error) {
      console.error('Error creating promotion:', error)
      const message = error.response?.data?.message || error.message || 'Không thể tạo khuyến mãi'
      toast.error(message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-slate-900 mb-6">Tạo khuyến mãi</h1>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Thông tin cơ bản</h2>
          
          <div className="space-y-4">
            <Input
              label="Tên khuyến mãi *"
              name="ten_khuyen_mai"
              value={formData.ten_khuyen_mai}
              onChange={handleChange}
              placeholder="Ví dụ: Giảm 20% cho đơn hàng đầu tiên"
              required
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Mô tả</label>
              <textarea
                name="mo_ta"
                value={formData.mo_ta}
                onChange={handleChange}
                className="w-full p-3 border border-gray-300 rounded-md focus:ring-emerald-500 focus:border-emerald-500"
                rows="3"
                placeholder="Mô tả chi tiết về khuyến mãi"
              />
            </div>

            <Select
              label="Loại khuyến mãi *"
              name="loai"
              value={formData.loai}
              onChange={handleChange}
              required
            >
              <option value="percentage">Phần trăm (%)</option>
              <option value="fixed">Số tiền cố định (VND)</option>
              <option value="free_night">Đêm miễn phí</option>
            </Select>

            <Input
              label="Giá trị khuyến mãi *"
              name="gia_tri"
              type="number"
              value={formData.gia_tri}
              onChange={handleChange}
              placeholder={formData.loai === 'percentage' ? '20' : '100000'}
              required
            />

            <Input
              label="Giá trị đơn hàng tối thiểu (VND)"
              name="gia_tri_toi_thieu"
              type="number"
              value={formData.gia_tri_toi_thieu}
              onChange={handleChange}
              placeholder="1000000"
            />
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Thời gian và điều kiện</h2>
          
          <div className="space-y-4">
            <Input
              label="Ngày bắt đầu *"
              name="ngay_bat_dau"
              type="datetime-local"
              value={formData.ngay_bat_dau}
              onChange={handleChange}
              required
            />

            <Input
              label="Ngày kết thúc *"
              name="ngay_ket_thuc"
              type="datetime-local"
              value={formData.ngay_ket_thuc}
              onChange={handleChange}
              required
            />

            <Input
              label="ID khách sạn (để trống nếu áp dụng cho tất cả)"
              name="ma_khach_san"
              type="number"
              value={formData.ma_khach_san}
              onChange={handleChange}
              placeholder="123"
            />

            <Input
              label="Số lượng sử dụng tối đa (để trống nếu không giới hạn)"
              name="so_luong_su_dung"
              type="number"
              value={formData.so_luong_su_dung}
              onChange={handleChange}
              placeholder="100"
            />

            <Select
              label="Trạng thái"
              name="trang_thai"
              value={formData.trang_thai}
              onChange={handleChange}
            >
              <option value="active">Hoạt động</option>
              <option value="inactive">Không hoạt động</option>
            </Select>
          </div>
        </div>

        <div className="flex gap-4">
          <Button
            type="submit"
            variant="primary"
            disabled={loading}
            className="flex items-center gap-2"
          >
            <Percent size={20} />
            {loading ? 'Đang tạo...' : 'Tạo khuyến mãi'}
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

export default CreatePromotionPage

