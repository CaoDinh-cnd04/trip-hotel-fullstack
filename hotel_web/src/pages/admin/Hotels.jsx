import React, { useState, useEffect } from 'react'
import { Loader2, Search, Edit, Trash2, Plus, Eye, Star, MapPin, Phone, Mail, Lock, Unlock, Calendar, User, Building2 } from 'lucide-react'
import { hotelAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'
import { getHotelImageUrl } from '../../config/api'

const Hotels = () => {
  const [hotels, setHotels] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [showModal, setShowModal] = useState(false)
  const [showDetailModal, setShowDetailModal] = useState(false)
  const [selectedHotel, setSelectedHotel] = useState(null)
  const [editingHotel, setEditingHotel] = useState(null)
  const [formData, setFormData] = useState({
    ten: '',
    mo_ta: '',
    hinh_anh: '',
    so_sao: 3,
    dia_chi: '',
    vi_tri_id: '',
    so_dien_thoai: '',
    email: '',
    ti_le_coc: 0
  })

  useEffect(() => {
    fetchHotels()
  }, [statusFilter])

  const fetchHotels = async () => {
    try {
      setLoading(true)
      const params = { limit: 100 }
      if (statusFilter !== 'all') {
        params.trang_thai = statusFilter
      }
      const response = await hotelAPI.getAll(params)
      
      // Handle different response formats
      let hotelsList = []
      if (response?.data) {
        if (Array.isArray(response.data)) {
          hotelsList = response.data
        } else if (Array.isArray(response.data.data)) {
          hotelsList = response.data.data
        } else if (response.data.data && Array.isArray(response.data.data)) {
          hotelsList = response.data.data
        }
      }
      
      setHotels(hotelsList)
    } catch (err) {
      console.error('Error fetching hotels:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể tải danh sách khách sạn'
      toast.error(errorMessage)
      setHotels([])
    } finally {
      setLoading(false)
    }
  }

  const handleViewDetail = async (hotel) => {
    try {
      const response = await hotelAPI.getById(hotel.id || hotel.ma_khach_san)
      setSelectedHotel(response.data?.data || response.data || hotel)
      setShowDetailModal(true)
    } catch (err) {
      console.error('Error fetching hotel details:', err)
      setSelectedHotel(hotel)
      setShowDetailModal(true)
    }
  }

  const handleCreate = () => {
    setEditingHotel(null)
    setFormData({
      ten: '',
      mo_ta: '',
      hinh_anh: '',
      so_sao: 3,
      dia_chi: '',
      vi_tri_id: '',
      so_dien_thoai: '',
      email: '',
      ti_le_coc: 0
    })
    setShowModal(true)
  }

  const handleEdit = (hotel) => {
    setEditingHotel(hotel)
    setFormData({
      ten: hotel.ten || '',
      mo_ta: hotel.mo_ta || '',
      hinh_anh: hotel.hinh_anh || '',
      so_sao: hotel.so_sao || 3,
      dia_chi: hotel.dia_chi || '',
      vi_tri_id: hotel.vi_tri_id || '',
      so_dien_thoai: hotel.so_dien_thoai || hotel.sdt_lien_he || '',
      email: hotel.email || hotel.email_lien_he || '',
      ti_le_coc: hotel.ti_le_coc || 0
    })
    setShowModal(true)
  }

  const handleToggleStatus = async (hotel) => {
    const isActive = hotel.trang_thai === 'Hoạt động'
    const action = isActive ? 'lock' : 'unlock'
    const confirmMessage = isActive 
      ? 'Bạn có chắc chắn muốn khóa khách sạn này?' 
      : 'Bạn có chắc chắn muốn mở khóa khách sạn này?'
    
    if (window.confirm(confirmMessage)) {
      try {
        await hotelAPI.toggleStatus(hotel.id || hotel.ma_khach_san, action)
        toast.success(isActive ? 'Đã khóa khách sạn' : 'Đã mở khóa khách sạn')
        fetchHotels()
      } catch (err) {
        console.error('Toggle status error:', err)
        toast.error('Lỗi: ' + (err.response?.data?.message || err.message || 'Không thể thay đổi trạng thái'))
      }
    }
  }

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa khách sạn này?')) {
      try {
        await hotelAPI.delete(id)
        toast.success('Xóa khách sạn thành công!')
        fetchHotels()
      } catch (err) {
        console.error('Delete hotel error:', err)
        toast.error('Lỗi khi xóa: ' + (err.response?.data?.message || err.message || 'Không thể xóa khách sạn'))
      }
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    try {
      if (editingHotel) {
        // Update
        await hotelAPI.update(editingHotel.id || editingHotel.ma_khach_san, formData)
        toast.success('Cập nhật khách sạn thành công!')
      } else {
        // Create
        await hotelAPI.create(formData)
        toast.success('Tạo khách sạn thành công!')
      }
      setShowModal(false)
      fetchHotels()
    } catch (err) {
      console.error('Save hotel error:', err)
      const errorMessage = err.response?.data?.message || err.response?.data?.errors?.[0]?.msg || err.message || 'Không thể lưu khách sạn'
      toast.error(errorMessage)
    }
  }

  const getImageUrl = (imagePath) => {
    return getHotelImageUrl(imagePath)
  }

  const getStatusBadge = (status) => {
    const statusMap = {
      'Hoạt động': { label: 'Active', color: 'bg-green-100 text-green-800' },
      'Tạm dừng': { label: 'Pending', color: 'bg-yellow-100 text-yellow-800' },
      'Bị chặn': { label: 'Banned', color: 'bg-red-100 text-red-800' },
      'Ngừng hoạt động': { label: 'Rejected', color: 'bg-gray-100 text-gray-800' }
    }
    const statusInfo = statusMap[status] || { label: status, color: 'bg-gray-100 text-gray-800' }
    return (
      <span className={`px-2 py-1 rounded-full text-xs font-semibold ${statusInfo.color}`}>
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
        month: '2-digit',
        day: '2-digit'
      })
    } catch {
      return dateString
    }
  }

  const filteredHotels = hotels.filter(hotel => {
    const search = searchTerm.toLowerCase()
    return (
      hotel.ten?.toLowerCase().includes(search) ||
      hotel.dia_chi?.toLowerCase().includes(search) ||
      hotel.mo_ta?.toLowerCase().includes(search) ||
      hotel.ten_nguoi_quan_ly?.toLowerCase().includes(search) ||
      hotel.ten_chu_khach_san?.toLowerCase().includes(search)
    )
  })

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 className="animate-spin text-emerald-500" size={32} />
        <span className="ml-3 text-slate-600">Đang tải khách sạn...</span>
      </div>
    )
  }

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-slate-900">Quản lý khách sạn</h1>
        <Button
          variant="primary"
          onClick={handleCreate}
          className="flex items-center gap-2"
        >
          <Plus size={20} /> Thêm khách sạn
        </Button>
      </div>

      <div className="mb-6 flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
          <Input
            type="text"
            placeholder="Tìm kiếm theo tên, địa chỉ, chủ khách sạn..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500"
        >
          <option value="all">Tất cả trạng thái</option>
          <option value="Hoạt động">Hoạt động</option>
          <option value="Tạm dừng">Tạm dừng</option>
          <option value="Bị chặn">Bị chặn</option>
          <option value="Ngừng hoạt động">Ngừng hoạt động</option>
        </select>
      </div>

      {filteredHotels.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow-sm border border-gray-200">
          <p className="text-gray-500">Không tìm thấy khách sạn nào.</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Khách sạn</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Chủ khách sạn</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trạng thái</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Số phòng</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Điểm đánh giá</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ngày tạo</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Hành động</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredHotels.map((hotel) => (
                  <tr key={hotel.id || hotel.ma_khach_san} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="flex-shrink-0 h-16 w-16">
                          <img
                            className="h-16 w-16 rounded-lg object-cover"
                            src={getImageUrl(hotel.hinh_anh)}
                            alt={hotel.ten}
                            onError={(e) => {
                              e.target.src = '/images/hotels/default.jpg'
                            }}
                          />
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">{hotel.ten || 'N/A'}</div>
                          <div className="text-sm text-gray-500 flex items-center gap-1 mt-1">
                            <MapPin size={14} />
                            <span className="line-clamp-1">{hotel.dia_chi || 'N/A'}</span>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {hotel.ten_chu_khach_san || hotel.ten_nguoi_quan_ly || 'N/A'}
                      </div>
                      <div className="text-sm text-gray-500">
                        {hotel.email_chu_khach_san || hotel.email_nguoi_quan_ly || ''}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(hotel.trang_thai)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {hotel.tong_so_phong_thuc_te || hotel.tong_so_phong || 0}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-1">
                        <Star size={16} className="fill-yellow-400 text-yellow-400" />
                        <span className="text-sm font-medium">
                          {hotel.diem_danh_gia_trung_binh ? parseFloat(hotel.diem_danh_gia_trung_binh).toFixed(1) : '0.0'}
                        </span>
                        <span className="text-xs text-gray-500">
                          ({hotel.so_luot_danh_gia || 0})
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(hotel.created_at)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex items-center justify-end gap-2">
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleViewDetail(hotel)}
                          className="flex items-center gap-1"
                          title="Xem chi tiết"
                        >
                          <Eye size={16} />
                        </Button>
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleEdit(hotel)}
                          className="flex items-center gap-1"
                          title="Sửa thông tin"
                        >
                          <Edit size={16} />
                        </Button>
                        <Button
                          variant={hotel.trang_thai === 'Hoạt động' ? 'danger' : 'primary'}
                          size="sm"
                          onClick={() => handleToggleStatus(hotel)}
                          className="flex items-center gap-1"
                          title={hotel.trang_thai === 'Hoạt động' ? 'Khóa khách sạn' : 'Mở khóa khách sạn'}
                        >
                          {hotel.trang_thai === 'Hoạt động' ? <Lock size={16} /> : <Unlock size={16} />}
                        </Button>
                        <Button
                          variant="danger"
                          size="sm"
                          onClick={() => handleDelete(hotel.id || hotel.ma_khach_san)}
                          className="flex items-center gap-1"
                          title="Xóa khách sạn (Soft delete)"
                        >
                          <Trash2 size={16} />
                          <span className="sr-only">Xóa</span>
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {showDetailModal && selectedHotel && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-start mb-4">
                <h2 className="text-2xl font-bold text-slate-900">Chi tiết khách sạn</h2>
                <button
                  onClick={() => setShowDetailModal(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <img
                    src={getImageUrl(selectedHotel.hinh_anh)}
                    alt={selectedHotel.ten}
                    className="w-full h-64 object-cover rounded-lg"
                    onError={(e) => {
                      e.target.src = '/images/hotels/default.jpg'
                    }}
                  />
                </div>
                <div className="space-y-4">
                  <div>
                    <h3 className="text-xl font-semibold text-gray-900">{selectedHotel.ten}</h3>
                    <div className="mt-2 flex items-center gap-2">
                      {getStatusBadge(selectedHotel.trang_thai)}
                      <div className="flex items-center gap-1">
                        <Star size={16} className="fill-yellow-400 text-yellow-400" />
                        <span className="text-sm font-medium">{selectedHotel.so_sao || 0} sao</span>
                      </div>
                    </div>
                  </div>
                  
                  <div className="space-y-2 text-sm">
                    <div className="flex items-start gap-2">
                      <MapPin size={16} className="mt-0.5 flex-shrink-0 text-gray-400" />
                      <span className="text-gray-700">{selectedHotel.dia_chi || 'N/A'}</span>
                    </div>
                    {selectedHotel.so_dien_thoai || selectedHotel.sdt_lien_he ? (
                      <div className="flex items-center gap-2">
                        <Phone size={16} className="flex-shrink-0 text-gray-400" />
                        <span className="text-gray-700">{selectedHotel.so_dien_thoai || selectedHotel.sdt_lien_he}</span>
                      </div>
                    ) : null}
                    {selectedHotel.email || selectedHotel.email_lien_he ? (
                      <div className="flex items-center gap-2">
                        <Mail size={16} className="flex-shrink-0 text-gray-400" />
                        <span className="text-gray-700">{selectedHotel.email || selectedHotel.email_lien_he}</span>
                      </div>
                    ) : null}
                  </div>
                </div>
              </div>

              <div className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-gray-50 p-4 rounded-lg">
                  <div className="text-sm text-gray-500">Chủ khách sạn</div>
                  <div className="text-lg font-semibold text-gray-900 mt-1">
                    {selectedHotel.ten_chu_khach_san || selectedHotel.ten_nguoi_quan_ly || 'N/A'}
                  </div>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <div className="text-sm text-gray-500">Số phòng</div>
                  <div className="text-lg font-semibold text-gray-900 mt-1">
                    {selectedHotel.tong_so_phong_thuc_te || selectedHotel.tong_so_phong || 0}
                  </div>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <div className="text-sm text-gray-500">Điểm đánh giá</div>
                  <div className="text-lg font-semibold text-gray-900 mt-1 flex items-center gap-1">
                    <Star size={16} className="fill-yellow-400 text-yellow-400" />
                    {selectedHotel.diem_danh_gia_trung_binh ? parseFloat(selectedHotel.diem_danh_gia_trung_binh).toFixed(1) : '0.0'}
                    <span className="text-sm font-normal text-gray-500">
                      ({selectedHotel.so_luot_danh_gia || 0})
                    </span>
                  </div>
                </div>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <div className="text-sm text-gray-500">Ngày tạo</div>
                  <div className="text-lg font-semibold text-gray-900 mt-1">
                    {formatDate(selectedHotel.created_at)}
                  </div>
                </div>
              </div>

              {selectedHotel.mo_ta && (
                <div className="mt-6">
                  <h4 className="text-sm font-medium text-gray-700 mb-2">Mô tả</h4>
                  <p className="text-gray-600">{selectedHotel.mo_ta}</p>
                </div>
              )}

              <div className="mt-6 flex justify-end gap-3">
                <Button
                  variant="secondary"
                  onClick={() => {
                    setShowDetailModal(false)
                    handleEdit(selectedHotel)
                  }}
                >
                  Sửa thông tin
                </Button>
                <Button
                  variant="primary"
                  onClick={() => setShowDetailModal(false)}
                >
                  Đóng
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Create/Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <h2 className="text-2xl font-bold text-slate-900 mb-4">
                {editingHotel ? 'Chỉnh sửa khách sạn' : 'Thêm khách sạn mới'}
              </h2>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Tên khách sạn <span className="text-red-500">*</span>
                  </label>
                  <Input
                    type="text"
                    value={formData.ten}
                    onChange={(e) => setFormData({ ...formData, ten: e.target.value })}
                    required
                    placeholder="Nhập tên khách sạn"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Mô tả <span className="text-red-500">*</span>
                  </label>
                  <textarea
                    value={formData.mo_ta}
                    onChange={(e) => setFormData({ ...formData, mo_ta: e.target.value })}
                    required
                    rows={4}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    placeholder="Nhập mô tả khách sạn"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Số sao <span className="text-red-500">*</span>
                    </label>
                    <Input
                      type="number"
                      min="1"
                      max="5"
                      value={formData.so_sao}
                      onChange={(e) => setFormData({ ...formData, so_sao: parseInt(e.target.value) || 3 })}
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Tỷ lệ cọc (%)
                    </label>
                    <Input
                      type="number"
                      min="0"
                      max="100"
                      value={formData.ti_le_coc}
                      onChange={(e) => setFormData({ ...formData, ti_le_coc: parseFloat(e.target.value) || 0 })}
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Địa chỉ <span className="text-red-500">*</span>
                  </label>
                  <Input
                    type="text"
                    value={formData.dia_chi}
                    onChange={(e) => setFormData({ ...formData, dia_chi: e.target.value })}
                    required
                    placeholder="Nhập địa chỉ khách sạn"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Số điện thoại
                    </label>
                    <Input
                      type="tel"
                      value={formData.so_dien_thoai}
                      onChange={(e) => setFormData({ ...formData, so_dien_thoai: e.target.value })}
                      placeholder="Nhập số điện thoại"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Email
                    </label>
                    <Input
                      type="email"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      placeholder="Nhập email"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Vị trí ID <span className="text-red-500">*</span>
                  </label>
                  <Input
                    type="number"
                    value={formData.vi_tri_id}
                    onChange={(e) => setFormData({ ...formData, vi_tri_id: e.target.value })}
                    required
                    placeholder="Nhập ID vị trí"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Hình ảnh (tên file hoặc URL)
                  </label>
                  <Input
                    type="text"
                    value={formData.hinh_anh}
                    onChange={(e) => setFormData({ ...formData, hinh_anh: e.target.value })}
                    placeholder="VD: hotel.jpg hoặc /images/hotels/hotel.jpg"
                  />
                </div>

                <div className="flex justify-end gap-3 pt-4">
                  <Button
                    type="button"
                    variant="secondary"
                    onClick={() => setShowModal(false)}
                  >
                    Hủy
                  </Button>
                  <Button
                    type="submit"
                    variant="primary"
                  >
                    {editingHotel ? 'Cập nhật' : 'Tạo mới'}
                  </Button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default Hotels
