import { useState, useEffect } from 'react'
import { Plus, Loader2, Edit, Trash2, Image as ImageIcon, Wrench, X, Save } from 'lucide-react'
import { hotelManagerAPI } from '../../../services/api/hotelManagerAPI'
import toast from 'react-hot-toast'
import { motion, AnimatePresence } from 'framer-motion'

const Rooms = () => {
  const [rooms, setRooms] = useState([])
  const [roomTypes, setRoomTypes] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [showAddModal, setShowAddModal] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)
  const [showImageModal, setShowImageModal] = useState(false)
  const [selectedRoom, setSelectedRoom] = useState(null)
  const [formData, setFormData] = useState({
    ten: '',
    ma_phong: '',
    gia_tien: '',
    trang_thai: 'Trống',
    mo_ta: '',
    loai_phong_id: '',
    dien_tich: ''
  })
  const [imageFiles, setImageFiles] = useState([])
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    fetchRooms()
    fetchRoomTypes()
  }, [])

  const fetchRooms = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await hotelManagerAPI.getHotelRooms()
      const roomsData = response?.data || []
      setRooms(Array.isArray(roomsData) ? roomsData : [])
    } catch (err) {
      setError(err.message || 'Không thể tải danh sách phòng')
      console.error('Error fetching rooms:', err)
      toast.error('Không thể tải danh sách phòng')
    } finally {
      setLoading(false)
    }
  }

  const fetchRoomTypes = async () => {
    try {
      const response = await hotelManagerAPI.getRoomTypes()
      const types = response?.data || []
      setRoomTypes(Array.isArray(types) ? types : [])
    } catch (err) {
      console.error('Error fetching room types:', err)
    }
  }

  const handleAdd = () => {
    setFormData({
      ten: '',
      ma_phong: '',
      gia_tien: '',
      trang_thai: 'Trống',
      mo_ta: '',
      loai_phong_id: roomTypes[0]?.id || '',
      dien_tich: ''
    })
    setSelectedRoom(null)
    setShowAddModal(true)
  }

  const handleEdit = (room) => {
    setSelectedRoom(room)
    setFormData({
      ten: room.ten || '',
      ma_phong: room.ma_phong || '',
      gia_tien: room.gia_phong || room.gia_tien || '',
      trang_thai: room.trang_thai || 'Trống',
      mo_ta: room.mo_ta || '',
      loai_phong_id: room.loai_phong_id ? room.loai_phong_id.toString() : '',
      dien_tich: room.dien_tich ? room.dien_tich.toString() : ''
    })
    setShowEditModal(true)
  }

  const handleSave = async () => {
    // Validate
    if (!formData.ma_phong || formData.ma_phong.trim() === '') {
      toast.error('Vui lòng nhập mã phòng')
      return
    }

    if (!formData.gia_tien || formData.gia_tien === '' || parseFloat(formData.gia_tien) <= 0) {
      toast.error('Vui lòng nhập giá phòng hợp lệ')
      return
    }

    try {
      setSaving(true)
      
      if (selectedRoom) {
        // Update room - send all fields that have values
        const submitData = {}
        
        if (formData.ten !== undefined && formData.ten !== '') {
          submitData.ten = formData.ten.trim()
        }
        if (formData.ma_phong !== undefined && formData.ma_phong.trim() !== '') {
          submitData.ma_phong = formData.ma_phong.trim()
        }
        if (formData.gia_tien !== undefined && formData.gia_tien !== '') {
          submitData.gia_tien = parseFloat(formData.gia_tien)
        }
        if (formData.trang_thai !== undefined) {
          submitData.trang_thai = formData.trang_thai
        }
        if (formData.mo_ta !== undefined) {
          submitData.mo_ta = formData.mo_ta.trim() || null
        }
        if (formData.loai_phong_id !== undefined && formData.loai_phong_id !== '') {
          submitData.loai_phong_id = parseInt(formData.loai_phong_id)
        }
        if (formData.dien_tich !== undefined && formData.dien_tich !== '') {
          submitData.dien_tich = parseFloat(formData.dien_tich)
        } else if (formData.dien_tich === '') {
          submitData.dien_tich = null
        }
        
        console.log('📤 Updating room with data:', submitData)
        await hotelManagerAPI.updateRoom(selectedRoom.id, submitData)
        toast.success('Cập nhật phòng thành công!')
        setShowEditModal(false)
      } else {
        // Add room - all fields required
        const submitData = {
          ten: formData.ten || `Phòng ${formData.ma_phong.trim()}`,
          ma_phong: formData.ma_phong.trim(),
          gia_tien: parseFloat(formData.gia_tien),
          trang_thai: formData.trang_thai || 'Trống',
          mo_ta: formData.mo_ta || null,
          loai_phong_id: formData.loai_phong_id && formData.loai_phong_id !== '' ? parseInt(formData.loai_phong_id) : 1,
          dien_tich: formData.dien_tich && formData.dien_tich !== '' ? parseFloat(formData.dien_tich) : null
        }
        
        console.log('📤 Adding room with data:', submitData)
        await hotelManagerAPI.addRoom(submitData)
        toast.success('Thêm phòng thành công!')
        setShowAddModal(false)
      }
      
      await fetchRooms()
      setFormData({
        ten: '',
        ma_phong: '',
        gia_tien: '',
        trang_thai: 'Trống',
        mo_ta: '',
        loai_phong_id: '',
        dien_tich: ''
      })
    } catch (err) {
      console.error('Error saving room:', err)
      console.error('Error response:', err.response?.data)
      const errorMsg = err.response?.data?.message || err.message || 'Có lỗi xảy ra'
      toast.error('Lỗi: ' + errorMsg)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Bạn có chắc muốn xóa phòng này?')) return

    try {
      await hotelManagerAPI.deleteRoom(id)
      toast.success('Xóa phòng thành công!')
      await fetchRooms()
    } catch (err) {
      console.error('Error deleting room:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleMaintenance = async (room) => {
    const newStatus = room.trang_thai === 'Bảo trì' ? 'Trống' : 'Bảo trì'
    try {
      console.log('📤 Updating room status:', room.id, newStatus)
      await hotelManagerAPI.updateRoomStatus(room.id, { trang_thai: newStatus })
      toast.success(`Phòng đã ${newStatus === 'Bảo trì' ? 'đặt bảo trì' : 'hủy bảo trì'}`)
      await fetchRooms()
    } catch (err) {
      console.error('Error updating room status:', err)
      console.error('Error response:', err.response?.data)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleImageUpload = async (room) => {
    setSelectedRoom(room)
    setImageFiles([])
    setShowImageModal(true)
  }

  const handleImageSave = async () => {
    if (imageFiles.length === 0) {
      toast.error('Vui lòng chọn ít nhất một ảnh')
      return
    }

    try {
      setSaving(true)
      const formData = new FormData()
      imageFiles.forEach(file => {
        formData.append('images', file)
      })

      await hotelManagerAPI.uploadRoomImages(selectedRoom.id, formData)
      toast.success('Upload ảnh thành công!')
      setShowImageModal(false)
      setImageFiles([])
      await fetchRooms()
    } catch (err) {
      console.error('Error uploading images:', err)
      toast.error('Lỗi: ' + (err.response?.data?.message || err.message))
    } finally {
      setSaving(false)
    }
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'Trống':
        return 'bg-green-100 text-green-700'
      case 'Đã đặt':
        return 'bg-blue-100 text-blue-700'
      case 'Bảo trì':
        return 'bg-red-100 text-red-700'
      default:
        return 'bg-gray-100 text-gray-700'
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
          onClick={fetchRooms}
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
        <h1 className="text-3xl font-bold text-slate-900">Quản lý phòng</h1>
        <button
          onClick={handleAdd}
          className="flex items-center gap-2 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 transition"
        >
          <Plus size={20} />
          Thêm phòng
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Mã phòng</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Tên phòng</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Loại phòng</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Giá phòng</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Trạng thái</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-slate-700 uppercase">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {rooms.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-6 py-8 text-center text-slate-500">
                    Chưa có phòng nào
                  </td>
                </tr>
              ) : (
                rooms.map((room) => (
                  <tr key={room.id} className="hover:bg-slate-50">
                    <td className="px-6 py-4 text-sm font-medium text-slate-900">{room.ma_phong || room.so_phong}</td>
                    <td className="px-6 py-4 text-sm text-slate-900">{room.ten}</td>
                    <td className="px-6 py-4 text-sm text-slate-600">{room.ten_loai_phong || 'N/A'}</td>
                    <td className="px-6 py-4 text-sm text-slate-900">
                      {new Intl.NumberFormat('vi-VN').format(room.gia_phong || room.gia_tien || 0)} VND
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(room.trang_thai)}`}>
                        {room.trang_thai || 'Trống'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleEdit(room)}
                          className="p-2 text-sky-600 hover:bg-sky-50 rounded transition"
                          title="Sửa phòng"
                        >
                          <Edit size={16} />
                        </button>
                        <button
                          onClick={() => handleImageUpload(room)}
                          className="p-2 text-purple-600 hover:bg-purple-50 rounded transition"
                          title="Quản lý ảnh"
                        >
                          <ImageIcon size={16} />
                        </button>
                        <button
                          onClick={() => handleMaintenance(room)}
                          className={`p-2 rounded transition ${
                            room.trang_thai === 'Bảo trì'
                              ? 'text-green-600 hover:bg-green-50'
                              : 'text-orange-600 hover:bg-orange-50'
                          }`}
                          title={room.trang_thai === 'Bảo trì' ? 'Hủy bảo trì' : 'Đặt bảo trì'}
                        >
                          <Wrench size={16} />
                        </button>
                        <button
                          onClick={() => handleDelete(room.id)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded transition"
                          title="Xóa phòng"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add/Edit Modal */}
      <AnimatePresence>
        {(showAddModal || showEditModal) && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
            onClick={() => {
              setShowAddModal(false)
              setShowEditModal(false)
            }}
          >
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
              className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">
                  {selectedRoom ? 'Sửa phòng' : 'Thêm phòng mới'}
                </h2>
                <button
                  onClick={() => {
                    setShowAddModal(false)
                    setShowEditModal(false)
                  }}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X size={24} />
                </button>
              </div>

              <div className="p-6 space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Mã phòng <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.ma_phong}
                      onChange={(e) => setFormData({ ...formData, ma_phong: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                      placeholder="VD: P101"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Tên phòng
                    </label>
                    <input
                      type="text"
                      value={formData.ten}
                      onChange={(e) => setFormData({ ...formData, ten: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                      placeholder="Tên phòng"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Loại phòng
                    </label>
                    <select
                      value={formData.loai_phong_id}
                      onChange={(e) => setFormData({ ...formData, loai_phong_id: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    >
                      <option value="">Chọn loại phòng</option>
                      {roomTypes.map(type => (
                        <option key={type.id} value={type.id}>{type.ten}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Giá phòng (VND) <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="number"
                      value={formData.gia_tien}
                      onChange={(e) => setFormData({ ...formData, gia_tien: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                      placeholder="500000"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Trạng thái
                    </label>
                    <select
                      value={formData.trang_thai}
                      onChange={(e) => setFormData({ ...formData, trang_thai: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    >
                      <option value="Trống">Trống</option>
                      <option value="Đã đặt">Đã đặt</option>
                      <option value="Bảo trì">Bảo trì</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">
                      Diện tích (m²)
                    </label>
                    <input
                      type="number"
                      value={formData.dien_tich}
                      onChange={(e) => setFormData({ ...formData, dien_tich: e.target.value })}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                      placeholder="25"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    Mô tả
                  </label>
                  <textarea
                    value={formData.mo_ta}
                    onChange={(e) => setFormData({ ...formData, mo_ta: e.target.value })}
                    rows={3}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                    placeholder="Mô tả về phòng..."
                  />
                </div>

                {/* Hiển thị hình ảnh phòng hiện tại (chỉ khi edit) */}
                {selectedRoom && (selectedRoom.hinh_anh || selectedRoom.hinh_anh_list) && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">
                      Hình ảnh phòng hiện tại
                    </label>
                    <div className="grid grid-cols-4 gap-2">
                      {selectedRoom.hinh_anh_list && selectedRoom.hinh_anh_list.length > 0 ? (
                        selectedRoom.hinh_anh_list.map((img, idx) => (
                          <div key={idx} className="relative">
                            <img
                              src={img}
                              alt={`Room ${idx + 1}`}
                              className="w-full h-24 object-cover rounded border border-slate-200"
                              onError={(e) => {
                                e.target.style.display = 'none'
                              }}
                            />
                          </div>
                        ))
                      ) : selectedRoom.hinh_anh ? (
                        <div className="relative">
                          <img
                            src={selectedRoom.hinh_anh}
                            alt="Room"
                            className="w-full h-24 object-cover rounded border border-slate-200"
                            onError={(e) => {
                              e.target.style.display = 'none'
                            }}
                          />
                        </div>
                      ) : null}
                    </div>
                    <p className="mt-2 text-xs text-slate-500">
                      Để thay đổi ảnh, vui lòng sử dụng nút "Quản lý ảnh" trong bảng
                    </p>
                  </div>
                )}
              </div>

              <div className="p-6 border-t border-slate-200 flex justify-end gap-3">
                <button
                  onClick={() => {
                    setShowAddModal(false)
                    setShowEditModal(false)
                  }}
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

      {/* Image Upload Modal */}
      <AnimatePresence>
        {showImageModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
            onClick={() => setShowImageModal(false)}
          >
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.9 }}
              className="bg-white rounded-lg shadow-xl max-w-md w-full"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">Quản lý ảnh phòng</h2>
                <button
                  onClick={() => setShowImageModal(false)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X size={24} />
                </button>
              </div>

              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Chọn ảnh (tối đa 5 ảnh)
                  </label>
                  <input
                    type="file"
                    multiple
                    accept="image/*"
                    onChange={(e) => setImageFiles(Array.from(e.target.files).slice(0, 5))}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-transparent"
                  />
                  {imageFiles.length > 0 && (
                    <div className="mt-2 text-sm text-slate-600">
                      Đã chọn {imageFiles.length} ảnh
                    </div>
                  )}
                </div>

                {selectedRoom?.hinh_anh_list && selectedRoom.hinh_anh_list.length > 0 && (
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">
                      Ảnh hiện tại
                    </label>
                    <div className="grid grid-cols-3 gap-2">
                      {selectedRoom.hinh_anh_list.map((img, idx) => (
                        <img
                          key={idx}
                          src={img}
                          alt={`Room ${idx + 1}`}
                          className="w-full h-20 object-cover rounded"
                        />
                      ))}
                    </div>
                  </div>
                )}
              </div>

              <div className="p-6 border-t border-slate-200 flex justify-end gap-3">
                <button
                  onClick={() => setShowImageModal(false)}
                  className="px-4 py-2 text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 transition"
                >
                  Hủy
                </button>
                <button
                  onClick={handleImageSave}
                  disabled={saving || imageFiles.length === 0}
                  className="px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 transition disabled:opacity-50 flex items-center gap-2"
                >
                  {saving ? <Loader2 className="animate-spin" size={16} /> : <Save size={16} />}
                  Upload
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default Rooms
