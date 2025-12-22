import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Tag, Plus, Eye, Edit, Trash2, Power, PowerOff, RefreshCw, Search, X, Calendar, DollarSign, Users, Clock } from 'lucide-react'
import { discountAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import { motion, AnimatePresence } from 'framer-motion'

const CreateDiscountCodePage = () => {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('create') // 'create' or 'manage'
  const [loading, setLoading] = useState(false)
  const [discounts, setDiscounts] = useState([])
  const [loadingDiscounts, setLoadingDiscounts] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedDiscount, setSelectedDiscount] = useState(null)
  const [showDetailModal, setShowDetailModal] = useState(false)
  const [editingDiscount, setEditingDiscount] = useState(null)
  const [formData, setFormData] = useState({
    ma_giam_gia: '',
    ten_ma_giam_gia: '',
    mo_ta: '',
    loai_giam_gia: 'percentage',
    gia_tri_giam: '',
    gia_tri_don_hang_toi_thieu: '',
    gia_tri_giam_toi_da: '',
    ngay_bat_dau: '',
    ngay_ket_thuc: '',
    so_luong_gioi_han: '',
    gioi_han_su_dung_moi_nguoi: '',
    trang_thai: 'active'
  })

  useEffect(() => {
    if (activeTab === 'manage') {
      fetchDiscounts()
    }
  }, [activeTab])

  const fetchDiscounts = async () => {
    try {
      setLoadingDiscounts(true)
      const response = await discountAPI.getAll()
      console.log('📋 [Frontend] Discount API response:', response)
      
      const discountsData = response?.data?.data || response?.data || response || []
      console.log('📋 [Frontend] Discounts data:', discountsData)
      
      // Đảm bảo mỗi discount có id (string) để dùng cho delete/toggle
      // id trong bảng ma_giam_gia là STRING (FLASH20, NEWUSER, etc.), không phải số
      const mappedDiscounts = Array.isArray(discountsData) ? discountsData.map((discount, index) => {
        // id là string, không phải số
        let id = discount.id || discount.ma_giam_gia || `DISCOUNT_${index}`
        
        // Đảm bảo id là string
        if (typeof id !== 'string') {
          id = String(id)
        }
        
        console.log(`📋 [Frontend] Mapping discount ${index}:`, {
          original: discount,
          allKeys: Object.keys(discount),
          id: id,
          id_type: typeof id,
          ma_giam_gia: discount.ma_giam_gia
        })
        
        // Map loai từ "Phần trăm" / "Số tiền cố định" sang "percentage" / "fixed_amount"
        let loai_giam_gia = discount.loai_giam_gia || discount.loai
        if (loai_giam_gia === 'Phần trăm' || loai_giam_gia === 'phan_tram') {
          loai_giam_gia = 'percentage'
        } else if (loai_giam_gia === 'Số tiền cố định' || loai_giam_gia === 'so_tien_co_dinh') {
          loai_giam_gia = 'fixed_amount'
        }
        
        return {
          ...discount,
          id: id, // id là string
          // Đảm bảo các field cần thiết có giá trị
          ma_giam_gia: discount.ma_giam_gia || discount.id || '',
          ten_ma_giam_gia: discount.ten_ma_giam_gia || discount.ten || '',
          loai_giam_gia: loai_giam_gia || 'percentage',
          gia_tri_giam: discount.gia_tri_giam || discount.gia_tri || 0,
          giam_toi_da: discount.giam_toi_da || null,
          gia_tri_don_hang_toi_thieu: discount.gia_tri_don_hang_toi_thieu || discount.gia_tri_toi_thieu || null,
          ngay_bat_dau: discount.ngay_bat_dau || discount.ngay_bd || null,
          ngay_ket_thuc: discount.ngay_ket_thuc || discount.ngay_kt || null,
          so_luong_gioi_han: discount.so_luong_gioi_han || discount.so_luong || null,
          gioi_han_su_dung_moi_nguoi: discount.gioi_han_su_dung_moi_nguoi || null,
          trang_thai: discount.trang_thai !== undefined ? discount.trang_thai : true
        }
      }) : []
      
      console.log('✅ [Frontend] Mapped discounts:', mappedDiscounts)
      setDiscounts(mappedDiscounts)
    } catch (err) {
      console.error('❌ [Frontend] Error fetching discount codes:', err)
      toast.error('Không thể tải danh sách mã giảm giá: ' + (err.response?.data?.message || err.message))
      setDiscounts([])
    } finally {
      setLoadingDiscounts(false)
    }
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const resetForm = () => {
    setFormData({
      ma_giam_gia: '',
      ten_ma_giam_gia: '',
      mo_ta: '',
      loai_giam_gia: 'percentage',
      gia_tri_giam: '',
      gia_tri_don_hang_toi_thieu: '',
      gia_tri_giam_toi_da: '',
      ngay_bat_dau: '',
      ngay_ket_thuc: '',
      so_luong_gioi_han: '',
      gioi_han_su_dung_moi_nguoi: '',
      trang_thai: 'active'
    })
    setEditingDiscount(null)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!formData.ma_giam_gia || !formData.ten_ma_giam_gia || !formData.gia_tri_giam || !formData.ngay_bat_dau || !formData.ngay_ket_thuc) {
      toast.error('Vui lòng điền đầy đủ thông tin bắt buộc')
      return
    }

    // Validate discount code format (uppercase, alphanumeric)
    const codeRegex = /^[A-Z0-9]+$/
    if (!codeRegex.test(formData.ma_giam_gia.toUpperCase())) {
      toast.error('Mã giảm giá chỉ được chứa chữ cái in hoa và số')
      return
    }

    try {
      setLoading(true)
      
      const discountCodeData = {
        ma_giam_gia: formData.ma_giam_gia.toUpperCase(),
        ten_ma_giam_gia: formData.ten_ma_giam_gia,
        mo_ta: formData.mo_ta || '',
        loai_giam_gia: formData.loai_giam_gia,
        gia_tri_giam: parseFloat(formData.gia_tri_giam),
        gia_tri_don_hang_toi_thieu: formData.gia_tri_don_hang_toi_thieu ? parseFloat(formData.gia_tri_don_hang_toi_thieu) : null,
        gia_tri_giam_toi_da: formData.gia_tri_giam_toi_da ? parseFloat(formData.gia_tri_giam_toi_da) : null,
        ngay_bat_dau: formData.ngay_bat_dau,
        ngay_ket_thuc: formData.ngay_ket_thuc,
        so_luong_gioi_han: formData.so_luong_gioi_han ? parseInt(formData.so_luong_gioi_han) : null,
        gioi_han_su_dung_moi_nguoi: formData.gioi_han_su_dung_moi_nguoi ? parseInt(formData.gioi_han_su_dung_moi_nguoi) : null,
        trang_thai: formData.trang_thai
      }

      if (editingDiscount) {
        await discountAPI.update(editingDiscount.id, discountCodeData)
        toast.success('Cập nhật mã giảm giá thành công!')
      } else {
        await discountAPI.create(discountCodeData)
        toast.success('Tạo mã giảm giá thành công!')
      }
      
      resetForm()
      if (activeTab === 'manage') {
        fetchDiscounts()
      } else {
        setActiveTab('manage')
        fetchDiscounts()
      }
    } catch (error) {
      console.error('Error creating/updating discount code:', error)
      const message = error.response?.data?.message || error.message || 'Không thể tạo/cập nhật mã giảm giá'
      toast.error(message)
    } finally {
      setLoading(false)
    }
  }

  const handleEdit = (discount) => {
    setEditingDiscount(discount)
    setFormData({
      ma_giam_gia: discount.ma_giam_gia || '',
      ten_ma_giam_gia: discount.ten_ma_giam_gia || '',
      mo_ta: discount.mo_ta || '',
      loai_giam_gia: discount.loai_giam_gia || 'percentage',
      gia_tri_giam: discount.gia_tri_giam || '',
      gia_tri_don_hang_toi_thieu: discount.gia_tri_don_hang_toi_thieu || '',
      gia_tri_giam_toi_da: discount.gia_tri_giam_toi_da || '',
      ngay_bat_dau: discount.ngay_bat_dau ? new Date(discount.ngay_bat_dau).toISOString().slice(0, 16) : '',
      ngay_ket_thuc: discount.ngay_ket_thuc ? new Date(discount.ngay_ket_thuc).toISOString().slice(0, 16) : '',
      so_luong_gioi_han: discount.so_luong_gioi_han || '',
      gioi_han_su_dung_moi_nguoi: discount.gioi_han_su_dung_moi_nguoi || '',
      trang_thai: discount.trang_thai || 'active'
    })
    setActiveTab('create')
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa mã giảm giá này? Hành động này không thể hoàn tác và sẽ xóa vĩnh viễn khỏi database.')) {
      return
    }

    // id là string (FLASH20, NEWUSER, etc.)
    const discountId = String(id).trim()
    
    if (!discountId || discountId === '') {
      console.error('❌ [Frontend] Empty ID')
      toast.error('ID mã giảm giá không hợp lệ')
      return
    }
    
    console.log('🗑️ [Frontend] Deleting discount:', {
      originalId: id,
      discountId: discountId
    })

    // Optimistic update
    const previousDiscounts = [...discounts]
    setDiscounts(prevDiscounts => prevDiscounts.filter(d => {
      const dId = String(d.id || '').trim()
      return dId !== discountId
    }))

    try {
      console.log('🗑️ [Frontend] Calling delete API with ID:', discountId)
      const response = await discountAPI.delete(discountId)
      console.log('✅ [Frontend] Delete response:', response)
      
      if (response?.data?.success === false) {
        setDiscounts(previousDiscounts)
        throw new Error(response.data.message || 'Xóa không thành công')
      }
      
      toast.success('Đã xóa mã giảm giá thành công')
      await new Promise(resolve => setTimeout(resolve, 300))
      await fetchDiscounts()
    } catch (err) {
      setDiscounts(previousDiscounts)
      console.error('❌ [Frontend] Error deleting discount code:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể xóa mã giảm giá'
      toast.error('Không thể xóa mã giảm giá: ' + errorMessage)
    }
  }

  const handleToggle = async (id) => {
    // id là string (FLASH20, NEWUSER, etc.)
    const discountId = String(id).trim()
    
    if (!discountId || discountId === '') {
      console.error('❌ [Frontend] Empty ID')
      toast.error('ID mã giảm giá không hợp lệ')
      return
    }
    
    console.log('🔄 [Frontend] Toggling discount:', {
      originalId: id,
      discountId: discountId
    })

    try {
      console.log('🔄 [Frontend] Calling toggle API with ID:', discountId)
      const response = await discountAPI.toggle(discountId)
      console.log('✅ [Frontend] Toggle response:', response)
      
      if (response?.data?.success === false) {
        throw new Error(response.data.message || 'Cập nhật không thành công')
      }
      
      toast.success('Đã cập nhật trạng thái mã giảm giá thành công')
      await new Promise(resolve => setTimeout(resolve, 300))
      await fetchDiscounts()
    } catch (err) {
      console.error('❌ [Frontend] Error toggling discount code:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể cập nhật trạng thái'
      toast.error('Không thể cập nhật trạng thái: ' + errorMessage)
    }
  }

  const handleViewDetail = (discount) => {
    setSelectedDiscount(discount)
    setShowDetailModal(true)
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

  const filteredDiscounts = discounts.filter(discount => {
    const matchesSearch = !searchTerm || 
      discount.ma_giam_gia?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      discount.ten_ma_giam_gia?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      discount.mo_ta?.toLowerCase().includes(searchTerm.toLowerCase())
    return matchesSearch
  })

  const getStatusBadge = (status) => {
    const isActive = status === 'active' || status === 1 || status === true
    return (
      <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium ${
        isActive 
          ? 'bg-green-100 text-green-800' 
          : 'bg-gray-100 text-gray-800'
      }`}>
        {isActive ? 'Hoạt động' : 'Không hoạt động'}
      </span>
    )
  }

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-slate-900 mb-2">Quản lý mã giảm giá</h1>
        <p className="text-slate-600">Tạo và quản lý các mã giảm giá cho hệ thống</p>
      </div>

      {/* Tabs */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 mb-6">
        <div className="flex border-b border-slate-200">
          <button
            onClick={() => {
              setActiveTab('create')
              resetForm()
            }}
            className={`flex-1 px-6 py-4 font-medium transition-colors ${
              activeTab === 'create'
                ? 'text-sky-600 border-b-2 border-sky-600'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <div className="flex items-center justify-center gap-2">
              <Plus size={20} />
              {editingDiscount ? 'Chỉnh sửa mã giảm giá' : 'Tạo mã giảm giá mới'}
            </div>
          </button>
          <button
            onClick={() => {
              setActiveTab('manage')
              fetchDiscounts()
            }}
            className={`flex-1 px-6 py-4 font-medium transition-colors ${
              activeTab === 'manage'
                ? 'text-sky-600 border-b-2 border-sky-600'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <div className="flex items-center justify-center gap-2">
              <Tag size={20} />
              Quản lý mã giảm giá ({discounts.length})
            </div>
          </button>
        </div>
      </div>

      {/* Create/Edit Form */}
      {activeTab === 'create' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
        >
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-4">
              <Input
                label="Mã giảm giá *"
                name="ma_giam_gia"
                value={formData.ma_giam_gia}
                onChange={handleChange}
                placeholder="Ví dụ: SUMMER2024"
                required
                className="uppercase"
                disabled={!!editingDiscount}
              />
              <p className="text-xs text-slate-500 -mt-2">Mã sẽ được tự động chuyển thành chữ in hoa {editingDiscount && '(Không thể thay đổi)'}</p>

              <Input
                label="Tên mã giảm giá *"
                name="ten_ma_giam_gia"
                value={formData.ten_ma_giam_gia}
                onChange={handleChange}
                placeholder="Ví dụ: Ưu đãi mùa hè 2024"
                required
              />

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Mô tả</label>
                <textarea
                  name="mo_ta"
                  value={formData.mo_ta}
                  onChange={handleChange}
                  className="w-full p-3 border border-slate-300 rounded-md focus:ring-sky-500 focus:border-sky-500"
                  rows="3"
                  placeholder="Mô tả chi tiết về mã giảm giá"
                />
              </div>

              <Select
                label="Loại giảm giá *"
                name="loai_giam_gia"
                value={formData.loai_giam_gia}
                onChange={handleChange}
                required
              >
                <option value="percentage">Phần trăm (%)</option>
                <option value="fixed_amount">Số tiền cố định (VND)</option>
              </Select>

              <Input
                label="Giá trị giảm giá *"
                name="gia_tri_giam"
                type="number"
                value={formData.gia_tri_giam}
                onChange={handleChange}
                placeholder={formData.loai_giam_gia === 'percentage' ? '20' : '100000'}
                required
                min="0"
              />

              <Input
                label="Giá trị đơn hàng tối thiểu (VND)"
                name="gia_tri_don_hang_toi_thieu"
                type="number"
                value={formData.gia_tri_don_hang_toi_thieu}
                onChange={handleChange}
                placeholder="1000000"
                min="0"
              />

              {formData.loai_giam_gia === 'percentage' && (
                <Input
                  label="Giá trị giảm tối đa (VND)"
                  name="gia_tri_giam_toi_da"
                  type="number"
                  value={formData.gia_tri_giam_toi_da}
                  onChange={handleChange}
                  placeholder="500000"
                  min="0"
                />
              )}

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
                label="Số lượng sử dụng tối đa (để trống nếu không giới hạn)"
                name="so_luong_gioi_han"
                type="number"
                value={formData.so_luong_gioi_han}
                onChange={handleChange}
                placeholder="100"
                min="1"
              />

              <Input
                label="Giới hạn sử dụng mỗi người (để trống nếu không giới hạn)"
                name="gioi_han_su_dung_moi_nguoi"
                type="number"
                value={formData.gioi_han_su_dung_moi_nguoi}
                onChange={handleChange}
                placeholder="1"
                min="1"
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

            <div className="flex gap-4 pt-4">
              <Button
                type="submit"
                variant="primary"
                disabled={loading}
                className="flex items-center gap-2"
              >
                <Tag size={20} />
                {loading ? 'Đang lưu...' : editingDiscount ? 'Cập nhật mã giảm giá' : 'Tạo mã giảm giá'}
              </Button>
              {editingDiscount && (
                <Button
                  type="button"
                  variant="secondary"
                  onClick={() => {
                    resetForm()
                    setActiveTab('manage')
                  }}
                >
                  Hủy chỉnh sửa
                </Button>
              )}
            </div>
          </form>
        </motion.div>
      )}

      {/* Manage List */}
      {activeTab === 'manage' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          {/* Search */}
          <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-4 mb-6">
            <div className="flex gap-4">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
                <input
                  type="text"
                  placeholder="Tìm kiếm theo mã, tên, mô tả..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-sky-500"
                />
              </div>
              <button
                onClick={fetchDiscounts}
                className="flex items-center gap-2 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 transition-colors font-medium"
              >
                <RefreshCw size={18} />
                Làm mới
              </button>
            </div>
          </div>

          {/* Discounts List */}
          {loadingDiscounts ? (
            <div className="flex items-center justify-center h-64">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-sky-600"></div>
            </div>
          ) : filteredDiscounts.length === 0 ? (
            <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-12 text-center">
              <Tag className="mx-auto text-slate-400 mb-4" size={48} />
              <p className="text-slate-600 text-lg">Không có mã giảm giá nào</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredDiscounts.map((discount) => (
                <motion.div
                  key={discount.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="bg-white rounded-lg shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-slate-900 mb-1">
                        {discount.ma_giam_gia || discount.ma_giam || 'Chưa có mã'}
                      </h3>
                      <p className="text-sm text-slate-600">
                        {discount.ten_ma_giam_gia || discount.ten_ma || discount.ten || 'Chưa có tên'}
                      </p>
                    </div>
                    {getStatusBadge(discount.trang_thai)}
                  </div>

                  {discount.mo_ta && (
                    <p className="text-sm text-slate-600 mb-4 line-clamp-2">{discount.mo_ta}</p>
                  )}

                  <div className="space-y-2 mb-4">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-slate-600">Loại:</span>
                      <span className="font-medium text-slate-900">
                        {(discount.loai_giam_gia === 'percentage' || discount.loai_giam === 'phan_tram' || discount.loai_giam_gia === 'phan_tram') 
                          ? 'Phần trăm' 
                          : (discount.loai_giam_gia === 'fixed_amount' || discount.loai_giam === 'so_tien_co_dinh' || discount.loai_giam_gia === 'so_tien_co_dinh')
                          ? 'Số tiền cố định'
                          : discount.loai_giam_gia || discount.loai_giam || 'Chưa xác định'}
                      </span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-slate-600">Giá trị:</span>
                      <span className="font-medium text-red-600">
                        {(discount.loai_giam_gia === 'percentage' || discount.loai_giam === 'phan_tram' || discount.loai_giam_gia === 'phan_tram')
                          ? `${discount.gia_tri_giam || discount.gia_tri || 0}%`
                          : discount.gia_tri_giam || discount.gia_tri
                          ? `${formatPrice(discount.gia_tri_giam || discount.gia_tri)} VND`
                          : '0 VND'}
                      </span>
                    </div>
                    {(discount.gia_tri_don_hang_toi_thieu !== null && discount.gia_tri_don_hang_toi_thieu !== undefined && discount.gia_tri_don_hang_toi_thieu > 0) && (
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-slate-600">Đơn tối thiểu:</span>
                        <span className="font-medium text-slate-900">{formatPrice(discount.gia_tri_don_hang_toi_thieu)} VND</span>
                      </div>
                    )}
                    {discount.ngay_bat_dau && discount.ngay_ket_thuc && (
                      <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Calendar size={16} />
                        <span className="text-xs">
                          {formatDateTime(discount.ngay_bat_dau)} - {formatDateTime(discount.ngay_ket_thuc)}
                        </span>
                      </div>
                    )}
                    {(discount.so_luong_gioi_han !== null && discount.so_luong_gioi_han !== undefined && discount.so_luong_gioi_han > 0) && (
                      <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Users size={16} />
                        <span>Giới hạn: {discount.so_luong_gioi_han} lần</span>
                      </div>
                    )}
                    {(discount.gioi_han_su_dung_moi_nguoi !== null && discount.gioi_han_su_dung_moi_nguoi !== undefined && discount.gioi_han_su_dung_moi_nguoi > 0) && (
                      <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Users size={16} />
                        <span>Mỗi người: {discount.gioi_han_su_dung_moi_nguoi} lần</span>
                      </div>
                    )}
                  </div>

                  {/* Action Buttons */}
                  <div className="flex gap-2 mt-4">
                    <button
                      onClick={() => handleViewDetail(discount)}
                      className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-colors font-medium text-sm"
                    >
                      <Eye size={16} />
                      Chi tiết
                    </button>
                    <button
                      onClick={() => handleEdit(discount)}
                      className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium text-sm"
                    >
                      <Edit size={16} />
                      Sửa
                    </button>
                    <button
                      onClick={() => handleToggle(discount.id)}
                      className={`flex items-center justify-center gap-2 px-3 py-2 rounded-lg transition-colors font-medium text-sm ${
                        discount.trang_thai === 'active' || discount.trang_thai === 1
                          ? 'bg-yellow-600 text-white hover:bg-yellow-700'
                          : 'bg-green-600 text-white hover:bg-green-700'
                      }`}
                    >
                      {discount.trang_thai === 'active' || discount.trang_thai === 1 ? (
                        <>
                          <PowerOff size={16} />
                          Tắt
                        </>
                      ) : (
                        <>
                          <Power size={16} />
                          Bật
                        </>
                      )}
                    </button>
                    <button
                      onClick={() => handleDelete(discount.id)}
                      className="flex items-center justify-center gap-2 px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium text-sm"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </motion.div>
      )}

      {/* Detail Modal */}
      <AnimatePresence>
        {showDetailModal && selectedDiscount && (
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
                <h2 className="text-2xl font-bold text-slate-900">Chi tiết mã giảm giá</h2>
                <button
                  onClick={() => setShowDetailModal(false)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X size={24} />
                </button>
              </div>
              
              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Mã giảm giá</label>
                  <p className="text-slate-900 font-semibold text-lg">{selectedDiscount.ma_giam_gia}</p>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Tên mã giảm giá</label>
                  <p className="text-slate-900">{selectedDiscount.ten_ma_giam_gia || 'N/A'}</p>
                </div>
                
                {selectedDiscount.mo_ta && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Mô tả</label>
                    <p className="text-slate-600 whitespace-pre-wrap">{selectedDiscount.mo_ta}</p>
                  </div>
                )}
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Loại giảm giá</label>
                    <p className="text-slate-900">
                      {selectedDiscount.loai_giam_gia === 'percentage' ? 'Phần trăm (%)' : 'Số tiền cố định (VND)'}
                    </p>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Giá trị</label>
                    <p className="text-red-600 font-semibold">
                      {selectedDiscount.loai_giam_gia === 'percentage' 
                        ? `${selectedDiscount.gia_tri_giam}%`
                        : `${formatPrice(selectedDiscount.gia_tri_giam)} VND`}
                    </p>
                  </div>
                </div>
                
                {selectedDiscount.gia_tri_don_hang_toi_thieu && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Giá trị đơn hàng tối thiểu</label>
                    <p className="text-slate-900">{formatPrice(selectedDiscount.gia_tri_don_hang_toi_thieu)} VND</p>
                  </div>
                )}
                
                {selectedDiscount.gia_tri_giam_toi_da && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Giá trị giảm tối đa</label>
                    <p className="text-slate-900">{formatPrice(selectedDiscount.gia_tri_giam_toi_da)} VND</p>
                  </div>
                )}
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Ngày bắt đầu</label>
                    <p className="text-slate-900">{formatDateTime(selectedDiscount.ngay_bat_dau)}</p>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Ngày kết thúc</label>
                    <p className="text-slate-900">{formatDateTime(selectedDiscount.ngay_ket_thuc)}</p>
                  </div>
                </div>
                
                {selectedDiscount.so_luong_gioi_han && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Số lượng sử dụng tối đa</label>
                    <p className="text-slate-900">{formatPrice(selectedDiscount.so_luong_gioi_han)} lần</p>
                  </div>
                )}
                
                {selectedDiscount.gioi_han_su_dung_moi_nguoi && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Giới hạn sử dụng mỗi người</label>
                    <p className="text-slate-900">{formatPrice(selectedDiscount.gioi_han_su_dung_moi_nguoi)} lần</p>
                  </div>
                )}
                
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Trạng thái</label>
                  {getStatusBadge(selectedDiscount.trang_thai)}
                </div>
              </div>
              
              <div className="p-6 border-t border-slate-200 flex gap-3">
                <button
                  onClick={() => {
                    handleEdit(selectedDiscount)
                    setShowDetailModal(false)
                  }}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
                >
                  <Edit size={18} />
                  Chỉnh sửa
                </button>
                <button
                  onClick={() => {
                    handleToggle(selectedDiscount.id)
                    setShowDetailModal(false)
                  }}
                  className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-lg transition-colors font-medium ${
                    selectedDiscount.trang_thai === 'active' || selectedDiscount.trang_thai === 1
                      ? 'bg-yellow-600 text-white hover:bg-yellow-700'
                      : 'bg-green-600 text-white hover:bg-green-700'
                  }`}
                >
                  {selectedDiscount.trang_thai === 'active' || selectedDiscount.trang_thai === 1 ? (
                    <>
                      <PowerOff size={18} />
                      Tắt mã
                    </>
                  ) : (
                    <>
                      <Power size={18} />
                      Bật mã
                    </>
                  )}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default CreateDiscountCodePage
