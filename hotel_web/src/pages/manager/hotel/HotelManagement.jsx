import { useState, useEffect } from 'react'
import { Loader2, Save, Upload, Building2, MapPin, Clock, FileText, CheckCircle, XCircle, AlertCircle, Plus, Trash2, Star } from 'lucide-react'
import { hotelManagerAPI } from '../../../services/api/hotelManagerAPI'
import toast from 'react-hot-toast'

const HotelManagement = () => {
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [hotel, setHotel] = useState(null)
  const [allAmenities, setAllAmenities] = useState([])
  const [selectedAmenities, setSelectedAmenities] = useState([])
  const [showAddAmenityDialog, setShowAddAmenityDialog] = useState(false)
  const [showManagePricingDialog, setShowManagePricingDialog] = useState(false)
  const [hotelAmenitiesWithPricing, setHotelAmenitiesWithPricing] = useState([])
  const [newAmenity, setNewAmenity] = useState({
    ten: '',
    mo_ta: '',
    nhom: 'Khác'
  })
  const [isCreatingAmenity, setIsCreatingAmenity] = useState(false)
  const [isUpdatingPricing, setIsUpdatingPricing] = useState(false)
  const [pricingChanges, setPricingChanges] = useState({}) // Lưu các thay đổi tạm thời
  const [isSavingPricing, setIsSavingPricing] = useState(false)
  const [formData, setFormData] = useState({
    ten: '',
    mo_ta: '',
    dia_chi: '',
    gio_nhan_phong: '',
    gio_tra_phong: '',
    chinh_sach_huy: '',
    email_lien_he: '',
    sdt_lien_he: '',
    website: ''
  })
  const [imageFile, setImageFile] = useState(null)
  const [imagePreview, setImagePreview] = useState(null)
  const [hotelImages, setHotelImages] = useState([])
  const [uploadingImage, setUploadingImage] = useState(false)

  useEffect(() => {
    fetchHotelData()
    fetchAllAmenities()
    fetchHotelAmenitiesWithPricing()
  }, [])

  const fetchHotelData = async () => {
    try {
      setLoading(true)
      console.log('📥 Fetching hotel data...')
      const response = await hotelManagerAPI.getAssignedHotel()
      console.log('📥 Hotel data response:', response)
      
      const hotelData = response?.data || response || {}
      console.log('📥 Hotel data:', hotelData)
      
      setHotel(hotelData)
      setFormData({
        ten: hotelData.ten_khach_san || hotelData.ten || '',
        mo_ta: hotelData.mo_ta || '',
        dia_chi: hotelData.dia_chi || '',
        gio_nhan_phong: hotelData.gio_nhan_phong || '',
        gio_tra_phong: hotelData.gio_tra_phong || '',
        chinh_sach_huy: hotelData.chinh_sach_huy || '',
        email_lien_he: hotelData.email_lien_he || '',
        sdt_lien_he: hotelData.sdt_lien_he || '',
        website: hotelData.website || ''
      })
      
      // Set selected amenities
      if (hotelData.tien_nghi && Array.isArray(hotelData.tien_nghi)) {
        const amenityIds = hotelData.tien_nghi.map(a => a.id).filter(id => id != null)
        console.log('📥 Selected amenities:', amenityIds)
        setSelectedAmenities(amenityIds)
      }
      
      // Set image preview (main image)
      if (hotelData.hinh_anh) {
        setImagePreview(hotelData.hinh_anh)
      }
      
      // ✅ Set hotel images gallery
      if (hotelData.danh_sach_anh && Array.isArray(hotelData.danh_sach_anh)) {
        console.log('📥 Setting hotel images gallery:', hotelData.danh_sach_anh.length, 'images')
        setHotelImages(hotelData.danh_sach_anh)
      } else {
        console.log('📥 No gallery images found, setting empty array')
        setHotelImages([])
      }
    } catch (err) {
      console.error('❌ Error fetching hotel data:', err)
      console.error('❌ Error response:', err.response)
      toast.error('Không thể tải thông tin khách sạn: ' + (err.response?.data?.message || err.message))
    } finally {
      setLoading(false)
    }
  }

  const fetchAllAmenities = async () => {
    try {
      console.log('📥 Fetching all amenities...')
      const response = await hotelManagerAPI.getAllAmenities()
      console.log('📥 Amenities response:', response)
      
      const amenities = response?.data || response || []
      console.log('📥 All amenities:', amenities)
      setAllAmenities(amenities)
    } catch (err) {
      console.error('❌ Error fetching amenities:', err)
      console.error('❌ Error response:', err.response)
      toast.error('Không thể tải danh sách tiện nghi: ' + (err.response?.data?.message || err.message))
    }
  }

  const fetchHotelAmenitiesWithPricing = async () => {
    try {
      console.log('📥 Fetching hotel amenities with pricing...')
      const response = await hotelManagerAPI.getHotelAmenitiesWithPricing()
      console.log('📥 Hotel amenities with pricing response:', response)
      
      const amenities = response?.data || response || []
      console.log('📥 Hotel amenities with pricing:', amenities)
      setHotelAmenitiesWithPricing(amenities)
    } catch (err) {
      console.error('❌ Error fetching hotel amenities with pricing:', err)
      console.error('❌ Error response:', err.response)
      // Non-critical error, don't show toast
    }
  }

  // Lưu thay đổi tạm thời (không gọi API ngay)
  const handleUpdateAmenityPricing = (amenityId, mienPhi, giaPhi, ghiChu) => {
    setPricingChanges(prev => ({
      ...prev,
      [amenityId]: {
        mienPhi,
        giaPhi: giaPhi || null,
        ghiChu: ghiChu || null,
      }
    }))
  }

  // Lưu tất cả thay đổi cùng lúc
  const handleSaveAllPricing = async () => {
    if (Object.keys(pricingChanges).length === 0) {
      toast.error('Không có thay đổi nào để lưu')
      return
    }

    try {
      setIsSavingPricing(true)
      
      // Lưu từng thay đổi
      const promises = Object.entries(pricingChanges).map(([amenityId, data]) => 
        hotelManagerAPI.updateAmenityPricing(amenityId, data)
      )
      
      await Promise.all(promises)
      
      console.log('✅ Saved all pricing changes:', pricingChanges)
      toast.success(`Đã lưu ${Object.keys(pricingChanges).length} thay đổi!`)
      
      // Clear changes và reload data
      setPricingChanges({})
      await fetchHotelAmenitiesWithPricing()
    } catch (err) {
      console.error('❌ Error saving pricing changes:', err)
      const errorMsg = err.response?.data?.message || err.message || 'Lỗi khi lưu thay đổi'
      toast.error(errorMsg)
    } finally {
      setIsSavingPricing(false)
    }
  }

  // Reset changes khi đóng dialog
  const handleClosePricingDialog = () => {
    if (Object.keys(pricingChanges).length > 0) {
      if (confirm('Bạn có thay đổi chưa lưu. Bạn có chắc chắn muốn đóng?')) {
        setPricingChanges({})
        setShowManagePricingDialog(false)
      }
    } else {
      setShowManagePricingDialog(false)
    }
  }

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleImageChange = async (e) => {
    const file = e.target.files[0]
    if (file) {
      // Validate file
      if (!file.type.startsWith('image/')) {
        toast.error('Chỉ chấp nhận file ảnh!')
        return
      }
      if (file.size > 5 * 1024 * 1024) {
        toast.error('Kích thước file không được vượt quá 5MB!')
        return
      }
      
      // Upload image immediately
      try {
        setUploadingImage(true)
        const formData = new FormData()
        formData.append('image', file)
        
        console.log('📤 Uploading hotel image:', {
          fileName: file.name,
          fileSize: file.size,
          fileType: file.type
        })
        
        const response = await hotelManagerAPI.uploadHotelImage(formData)
        console.log('✅ Hotel image uploaded response:', response)
        
        // ✅ Response interceptor trả về response.data từ axios
        // Backend trả về: { success: true, data: { id, imageUrl, ... }, message }
        // Interceptor trả về: response.data = { success: true, data: { id, ... }, message }
        // Vậy response.data.data.id là đúng
        console.log('📋 Full response structure:', {
          response,
          'response.data': response?.data,
          'response.data?.data': response?.data?.data,
          'response.success': response?.success
        })
        
        if (response?.success && response?.data) {
          toast.success('Thêm ảnh khách sạn thành công!')
          // Refresh hotel data to get updated gallery
          await fetchHotelData()
        } else if (response?.data?.id) {
          // Fallback: nếu data trực tiếp có id
          toast.success('Thêm ảnh khách sạn thành công!')
          await fetchHotelData()
        } else {
          console.warn('⚠️ Response missing expected structure:', response)
          // Vẫn refresh để xem có ảnh mới không
          await fetchHotelData()
          toast.error('Upload thành công nhưng response không đúng format')
        }
      } catch (err) {
        console.error('❌ Error uploading hotel image:', err)
        console.error('❌ Error details:', {
          message: err.message,
          response: err.response?.data,
          status: err.response?.status
        })
        const errorMsg = err.response?.data?.message || err.message || 'Lỗi khi upload ảnh'
        toast.error(errorMsg)
      } finally {
        setUploadingImage(false)
        // Reset file input
        e.target.value = ''
      }
    }
  }

  const handleDeleteImage = async (imageId) => {
    if (!confirm('Bạn có chắc chắn muốn xóa ảnh này?')) {
      return
    }
    
    try {
      await hotelManagerAPI.deleteHotelImage(imageId)
      toast.success('Xóa ảnh thành công!')
      // Refresh hotel data
      await fetchHotelData()
    } catch (err) {
      console.error('❌ Error deleting image:', err)
      const errorMsg = err.response?.data?.message || err.message || 'Lỗi khi xóa ảnh'
      toast.error(errorMsg)
    }
  }

  const handleSetMainImage = async (imageId) => {
    try {
      await hotelManagerAPI.setMainHotelImage(imageId)
      toast.success('Đặt ảnh đại diện thành công!')
      // Refresh hotel data
      await fetchHotelData()
    } catch (err) {
      console.error('❌ Error setting main image:', err)
      const errorMsg = err.response?.data?.message || err.message || 'Lỗi khi đặt ảnh đại diện'
      toast.error(errorMsg)
    }
  }

  const handleAmenityToggle = (amenityId) => {
    setSelectedAmenities(prev => {
      if (prev.includes(amenityId)) {
        return prev.filter(id => id !== amenityId)
      } else {
        return [...prev, amenityId]
      }
    })
  }

  const handleCreateAmenity = async () => {
    if (!newAmenity.ten.trim()) {
      toast.error('Vui lòng nhập tên tiện nghi')
      return
    }

    try {
      setIsCreatingAmenity(true)
      
      const response = await hotelManagerAPI.createAmenity({
        ten: newAmenity.ten.trim(),
        mo_ta: newAmenity.mo_ta.trim() || null,
        nhom: newAmenity.nhom,
        // ✅ Removed loai_tien_nghi - column doesn't exist in database
      })

      console.log('✅ Created amenity:', response)
      
      toast.success('Thêm tiện nghi thành công!')
      
      // Close dialog and reset form
      setShowAddAmenityDialog(false)
      setNewAmenity({ ten: '', mo_ta: '', nhom: 'Khác' })
      
      // Reload amenities list
      await fetchAllAmenities()
      
      // Auto-select the newly created amenity
      if (response?.data?.amenity?.id) {
        setSelectedAmenities(prev => [...prev, response.data.amenity.id])
      }
    } catch (err) {
      console.error('❌ Error creating amenity:', err)
      const errorMsg = err.response?.data?.message || err.message || 'Lỗi khi tạo tiện nghi'
      toast.error(errorMsg)
    } finally {
      setIsCreatingAmenity(false)
    }
  }

  // Get unique groups from amenities
  const getAvailableGroups = () => {
    const groups = new Set(['Khác'])
    allAmenities.forEach(amenity => {
      if (amenity.nhom) {
        groups.add(amenity.nhom)
      }
    })
    return Array.from(groups).sort()
  }

  const getStatusBadge = (status) => {
    const statusMap = {
      'Hoạt động': { color: 'bg-green-100 text-green-700', icon: CheckCircle },
      'Pending': { color: 'bg-yellow-100 text-yellow-700', icon: AlertCircle },
      'Locked': { color: 'bg-red-100 text-red-700', icon: XCircle },
      'Tạm dừng': { color: 'bg-orange-100 text-orange-700', icon: AlertCircle }
    }
    
    const statusInfo = statusMap[status] || { color: 'bg-gray-100 text-gray-700', icon: AlertCircle }
    const Icon = statusInfo.icon
    
    return (
      <span className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-semibold ${statusInfo.color}`}>
        <Icon size={16} />
        {status}
      </span>
    )
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    if (!formData.ten.trim()) {
      toast.error('Vui lòng nhập tên khách sạn')
      return
    }

    try {
      setSaving(true)
      
      // Update hotel basic info
      const updateData = { ...formData }
      
      console.log('📤 Updating hotel with data:', updateData)
      console.log('📤 Selected amenities:', selectedAmenities)
      
      // Update hotel info
      try {
        const hotelResponse = await hotelManagerAPI.updateHotel(updateData)
        console.log('✅ Hotel updated:', hotelResponse)
      } catch (hotelErr) {
        console.error('❌ Error updating hotel:', hotelErr)
        const errorMsg = hotelErr.response?.data?.message || hotelErr.message || 'Lỗi khi cập nhật thông tin khách sạn'
        toast.error(errorMsg)
        throw hotelErr
      }
      
      // Update amenities
      try {
        const amenitiesResponse = await hotelManagerAPI.updateHotelAmenities(selectedAmenities)
        console.log('✅ Amenities updated:', amenitiesResponse)
      } catch (amenitiesErr) {
        console.error('❌ Error updating amenities:', amenitiesErr)
        const errorMsg = amenitiesErr.response?.data?.message || amenitiesErr.message || 'Lỗi khi cập nhật tiện nghi'
        toast.error(errorMsg)
        throw amenitiesErr
      }
      
      toast.success('Cập nhật thông tin khách sạn thành công!')
      
      // Refresh data
      await fetchHotelData()
    } catch (err) {
      console.error('Error updating hotel:', err)
      // Error already shown in individual try-catch blocks
      if (!err.response) {
        toast.error('Lỗi kết nối đến server. Vui lòng thử lại.')
      }
    } finally {
      setSaving(false)
    }
  }

  // Group amenities by category
  const groupedAmenities = allAmenities.reduce((acc, amenity) => {
    const group = amenity.nhom || 'Khác'
    if (!acc[group]) {
      acc[group] = []
    }
    acc[group].push(amenity)
    return acc
  }, {})

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
        <h1 className="text-3xl font-bold text-slate-900">Quản lý khách sạn</h1>
        {hotel && (
          <div className="flex items-center gap-3">
            <span className="text-sm text-slate-600">Trạng thái:</span>
            {getStatusBadge(hotel.trang_thai || 'Pending')}
          </div>
        )}
      </div>

      {hotel && (
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Basic Information */}
          <div className="bg-white border border-slate-200 rounded-2xl shadow-sm p-6">
            <h2 className="text-xl font-bold text-slate-900 mb-4 flex items-center gap-2">
              <Building2 size={24} />
              Thông tin cơ bản
            </h2>
            
            <div className="grid gap-4 md:grid-cols-2">
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Tên khách sạn *
                </label>
                <input
                  type="text"
                  name="ten"
                  value={formData.ten}
                  onChange={handleInputChange}
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                  required
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Mô tả
                </label>
                <textarea
                  name="mo_ta"
                  value={formData.mo_ta}
                  onChange={handleInputChange}
                  rows="4"
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-slate-700 mb-1 flex items-center gap-2">
                  <MapPin size={16} />
                  Địa chỉ
                </label>
                <input
                  type="text"
                  name="dia_chi"
                  value={formData.dia_chi}
                  onChange={handleInputChange}
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>
            </div>
          </div>

          {/* Hotel Images Gallery */}
          <div className="bg-white border border-slate-200 rounded-2xl shadow-sm p-6">
            <h2 className="text-xl font-bold text-slate-900 mb-4">Ảnh khách sạn</h2>
            
            {/* Image Gallery */}
            {hotelImages.length > 0 && (
              <div className="mb-6">
                <h3 className="text-sm font-medium text-slate-700 mb-3">Thư viện ảnh ({hotelImages.length})</h3>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {hotelImages.map((img) => (
                    <div key={img.id} className="relative group">
                      <div className="aspect-square rounded-lg overflow-hidden border-2 border-slate-200">
                        <img
                          src={img.duong_dan_anh}
                          alt={`Hotel image ${img.id}`}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      {img.la_anh_dai_dien && (
                        <div className="absolute top-2 left-2 bg-yellow-500 text-white px-2 py-1 rounded text-xs font-semibold flex items-center gap-1">
                          <Star size={12} className="fill-current" />
                          Ảnh đại diện
                        </div>
                      )}
                      <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-50 transition-all rounded-lg flex items-center justify-center gap-2 opacity-0 group-hover:opacity-100">
                        {!img.la_anh_dai_dien && (
                          <button
                            onClick={() => handleSetMainImage(img.id)}
                            className="px-3 py-1.5 bg-yellow-500 text-white rounded text-sm hover:bg-yellow-600 flex items-center gap-1"
                            title="Đặt làm ảnh đại diện"
                          >
                            <Star size={14} />
                            Đặt đại diện
                          </button>
                        )}
                        <button
                          onClick={() => handleDeleteImage(img.id)}
                          className="px-3 py-1.5 bg-red-500 text-white rounded text-sm hover:bg-red-600 flex items-center gap-1"
                          title="Xóa ảnh"
                        >
                          <Trash2 size={14} />
                          Xóa
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
            
            {/* Add New Image */}
            <div className="border-2 border-dashed border-slate-300 rounded-lg p-6 text-center">
              <label className="cursor-pointer">
                <div className="flex flex-col items-center gap-3">
                  {uploadingImage ? (
                    <>
                      <Loader2 className="w-8 h-8 text-sky-600 animate-spin" />
                      <span className="text-sm text-slate-600">Đang upload...</span>
                    </>
                  ) : (
                    <>
                      <Upload className="w-8 h-8 text-slate-400" />
                      <div>
                        <span className="text-sky-600 hover:text-sky-700 font-medium">
                          Thêm ảnh mới
                        </span>
                        <span className="text-slate-500 text-sm ml-2">
                          hoặc kéo thả ảnh vào đây
                        </span>
                      </div>
                      <p className="text-xs text-slate-500">
                        Định dạng: JPG, PNG. Kích thước tối đa: 5MB
                      </p>
                    </>
                  )}
                </div>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleImageChange}
                  disabled={uploadingImage}
                  className="hidden"
                />
              </label>
            </div>
          </div>

          {/* Check-in/Check-out Times */}
          <div className="bg-white border border-slate-200 rounded-2xl shadow-sm p-6">
            <h2 className="text-xl font-bold text-slate-900 mb-4 flex items-center gap-2">
              <Clock size={24} />
              Giờ check-in / check-out
            </h2>
            
            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Giờ nhận phòng
                </label>
                <input
                  type="text"
                  name="gio_nhan_phong"
                  value={formData.gio_nhan_phong}
                  onChange={handleInputChange}
                  placeholder="VD: 14:00"
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Giờ trả phòng
                </label>
                <input
                  type="text"
                  name="gio_tra_phong"
                  value={formData.gio_tra_phong}
                  onChange={handleInputChange}
                  placeholder="VD: 12:00"
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>
            </div>
          </div>

          {/* Cancellation Policy */}
          <div className="bg-white border border-slate-200 rounded-2xl shadow-sm p-6">
            <h2 className="text-xl font-bold text-slate-900 mb-4 flex items-center gap-2">
              <FileText size={24} />
              Chính sách hủy phòng
            </h2>
            
            <textarea
              name="chinh_sach_huy"
              value={formData.chinh_sach_huy}
              onChange={handleInputChange}
              rows="6"
              placeholder="Nhập chính sách hủy phòng của khách sạn..."
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
            />
          </div>

          {/* Amenities */}
          <div className="bg-white border border-slate-200 rounded-2xl shadow-sm p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-slate-900">Tiện nghi</h2>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setShowManagePricingDialog(true)}
                  className="flex items-center gap-2 px-4 py-2 bg-orange-50 text-orange-700 rounded-lg hover:bg-orange-100 transition-colors text-sm font-semibold"
                >
                  <Upload size={18} />
                  Quản lý giá
                </button>
                <button
                  type="button"
                  onClick={() => setShowAddAmenityDialog(true)}
                  className="flex items-center gap-2 px-4 py-2 bg-green-50 text-green-700 rounded-lg hover:bg-green-100 transition-colors text-sm font-semibold"
                >
                  <Plus size={18} />
                  Thêm tiện nghi mới
                </button>
              </div>
            </div>
            
            <div className="space-y-6">
              {Object.entries(groupedAmenities).map(([group, amenities]) => (
                <div key={group}>
                  <h3 className="text-sm font-semibold text-slate-700 mb-3">{group}</h3>
                  <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
                    {amenities.map(amenity => (
                      <label
                        key={amenity.id}
                        className="flex items-center gap-3 p-3 border border-slate-200 rounded-lg cursor-pointer hover:bg-slate-50 transition-colors"
                      >
                        <input
                          type="checkbox"
                          checked={selectedAmenities.includes(amenity.id)}
                          onChange={() => handleAmenityToggle(amenity.id)}
                          className="w-4 h-4 text-sky-600 border-slate-300 rounded focus:ring-sky-500"
                        />
                        <span className="text-sm text-slate-700">{amenity.ten}</span>
                      </label>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Contact Information */}
          <div className="bg-white border border-slate-200 rounded-2xl shadow-sm p-6">
            <h2 className="text-xl font-bold text-slate-900 mb-4">Thông tin liên hệ</h2>
            
            <div className="grid gap-4 md:grid-cols-3">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Email
                </label>
                <input
                  type="email"
                  name="email_lien_he"
                  value={formData.email_lien_he}
                  onChange={handleInputChange}
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Số điện thoại
                </label>
                <input
                  type="tel"
                  name="sdt_lien_he"
                  value={formData.sdt_lien_he}
                  onChange={handleInputChange}
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Website
                </label>
                <input
                  type="url"
                  name="website"
                  value={formData.website}
                  onChange={handleInputChange}
                  placeholder="https://..."
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>
            </div>
          </div>

          {/* Submit Button */}
          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={() => fetchHotelData()}
              className="px-6 py-2 border border-slate-300 rounded-lg text-slate-700 hover:bg-slate-50"
            >
              Hủy
            </button>
            <button
              type="submit"
              disabled={saving}
              className="px-6 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {saving ? (
                <>
                  <Loader2 className="animate-spin" size={20} />
                  Đang lưu...
                </>
              ) : (
                <>
                  <Save size={20} />
                  Lưu thay đổi
                </>
              )}
            </button>
          </div>
        </form>
      )}

      {/* Add Amenity Dialog */}
      {showAddAmenityDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl shadow-xl p-6 w-full max-w-md mx-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-bold text-slate-900">Thêm tiện nghi mới</h3>
              <button
                onClick={() => {
                  setShowAddAmenityDialog(false)
                  setNewAmenity({ ten: '', mo_ta: '', nhom: 'Khác' })
                }}
                className="text-slate-400 hover:text-slate-600"
              >
                <XCircle size={24} />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Tên tiện nghi *
                </label>
                <input
                  type="text"
                  value={newAmenity.ten}
                  onChange={(e) => setNewAmenity({ ...newAmenity, ten: e.target.value })}
                  placeholder="VD: WiFi miễn phí, Bể bơi, Gym..."
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Mô tả (tùy chọn)
                </label>
                <textarea
                  value={newAmenity.mo_ta}
                  onChange={(e) => setNewAmenity({ ...newAmenity, mo_ta: e.target.value })}
                  placeholder="Mô tả chi tiết về tiện nghi..."
                  rows="3"
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Nhóm tiện nghi
                </label>
                <select
                  value={newAmenity.nhom}
                  onChange={(e) => setNewAmenity({ ...newAmenity, nhom: e.target.value })}
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                >
                  {getAvailableGroups().map(group => (
                    <option key={group} value={group}>{group}</option>
                  ))}
                </select>
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                type="button"
                onClick={() => {
                  setShowAddAmenityDialog(false)
                  setNewAmenity({ ten: '', mo_ta: '', nhom: 'Khác' })
                }}
                className="flex-1 px-4 py-2 border border-slate-300 rounded-lg text-slate-700 hover:bg-slate-50"
                disabled={isCreatingAmenity}
              >
                Hủy
              </button>
              <button
                type="button"
                onClick={handleCreateAmenity}
                disabled={isCreatingAmenity || !newAmenity.ten.trim()}
                className="flex-1 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {isCreatingAmenity ? (
                  <>
                    <Loader2 className="animate-spin" size={18} />
                    Đang tạo...
                  </>
                ) : (
                  <>
                    <Plus size={18} />
                    Thêm
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Manage Pricing Dialog */}
      {showManagePricingDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl shadow-xl p-6 w-full max-w-2xl mx-4 max-h-[80vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-bold text-slate-900">Quản lý giá dịch vụ</h3>
              <button
                onClick={handleClosePricingDialog}
                className="text-slate-400 hover:text-slate-600"
                disabled={isSavingPricing}
              >
                <XCircle size={24} />
              </button>
            </div>

            <p className="text-sm text-slate-600 mb-6">
              Thiết lập giá cho các dịch vụ tiện nghi. Dịch vụ miễn phí sẽ tự động được thêm khi khách đặt phòng giá cao (≥ 1,000,000 VNĐ/đêm).
            </p>

            <div className="space-y-4">
              {hotelAmenitiesWithPricing.length === 0 ? (
                <div className="text-center py-8 text-slate-500">
                  <p>Chưa có dịch vụ nào. Vui lòng thêm tiện nghi trước.</p>
                </div>
              ) : (
                hotelAmenitiesWithPricing.map((amenity) => {
                  // Merge với thay đổi tạm thời nếu có
                  const changes = pricingChanges[amenity.id]
                  const mergedAmenity = changes ? { ...amenity, ...changes } : amenity
                  
                  return (
                    <AmenityPricingItem
                      key={amenity.id}
                      amenity={mergedAmenity}
                      onUpdate={handleUpdateAmenityPricing}
                      isUpdating={isSavingPricing}
                      hasChanges={!!changes}
                    />
                  )
                })
              )}
            </div>

            <div className="flex gap-3 mt-6">
              <button
                type="button"
                onClick={handleClosePricingDialog}
                className="flex-1 px-4 py-2 border border-slate-300 rounded-lg text-slate-700 hover:bg-slate-50"
                disabled={isSavingPricing}
              >
                {Object.keys(pricingChanges).length > 0 ? 'Hủy' : 'Đóng'}
              </button>
              <button
                type="button"
                onClick={handleSaveAllPricing}
                disabled={isSavingPricing || Object.keys(pricingChanges).length === 0}
                className="flex-1 px-4 py-2 bg-sky-600 text-white rounded-lg hover:bg-sky-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {isSavingPricing ? (
                  <>
                    <Loader2 className="animate-spin" size={18} />
                    Đang lưu...
                  </>
                ) : (
                  <>
                    <Save size={18} />
                    Lưu {Object.keys(pricingChanges).length > 0 && `(${Object.keys(pricingChanges).length})`}
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

// Amenity Pricing Item Component
const AmenityPricingItem = ({ amenity, onUpdate, isUpdating, hasChanges }) => {
  const [isFree, setIsFree] = useState(amenity.mien_phi === true || amenity.mien_phi === 1)
  const [price, setPrice] = useState(amenity.gia_phi?.toString() || '')
  const [amenityImage, setAmenityImage] = useState(amenity.icon || null)
  const [uploadingImage, setUploadingImage] = useState(false)

  // ✅ Cập nhật state khi amenity prop thay đổi (khi có thay đổi tạm thời)
  useEffect(() => {
    setIsFree(amenity.mien_phi === true || amenity.mien_phi === 1)
    setPrice(amenity.gia_phi?.toString() || '')
    setAmenityImage(amenity.icon || null)
  }, [amenity.mien_phi, amenity.gia_phi, amenity.icon])

  const handleToggle = (e) => {
    const newMienPhi = !e.target.checked
    setIsFree(newMienPhi)
    // ✅ Chỉ lưu vào state tạm thời, không gọi API ngay
    onUpdate(
      amenity.id,
      newMienPhi,
      newMienPhi ? null : (parseFloat(price) || 0),
      amenity.ghi_chu
    )
  }

  const handlePriceChange = (e) => {
    setPrice(e.target.value)
  }

  const handlePriceBlur = (e) => {
    const newPrice = parseFloat(e.target.value) || 0
    // ✅ Chỉ lưu vào state tạm thời, không gọi API ngay
    if (newPrice > 0) {
      onUpdate(
        amenity.id,
        false,
        newPrice,
        amenity.ghi_chu
      )
    }
  }

  const handleAmenityImageChange = async (e) => {
    const file = e.target.files[0]
    if (file) {
      // Validate file
      if (!file.type.startsWith('image/')) {
        toast.error('Chỉ chấp nhận file ảnh!')
        return
      }
      if (file.size > 2 * 1024 * 1024) {
        toast.error('Kích thước file không được vượt quá 2MB!')
        return
      }
      
      // Show preview immediately
      const reader = new FileReader()
      reader.onloadend = () => {
        setAmenityImage(reader.result)
      }
      reader.readAsDataURL(file)
      
      // Upload image immediately
      try {
        setUploadingImage(true)
        const formData = new FormData()
        formData.append('image', file)
        
        const response = await hotelManagerAPI.uploadAmenityImage(amenity.id, formData)
        console.log('✅ Amenity image uploaded:', response)
        
        if (response?.data?.imageUrl) {
          setAmenityImage(response.data.imageUrl)
          toast.success('Upload ảnh tiện nghi thành công!')
        }
      } catch (err) {
        console.error('❌ Error uploading amenity image:', err)
        const errorMsg = err.response?.data?.message || err.message || 'Lỗi khi upload ảnh'
        toast.error(errorMsg)
        // Reset preview on error
        setAmenityImage(amenity.icon || null)
      } finally {
        setUploadingImage(false)
      }
    }
  }

  return (
    <div className="border border-slate-200 rounded-lg p-4">
      <div className="flex items-start gap-4 mb-3">
        {/* Amenity Image */}
        <div className="flex-shrink-0">
          <div className="relative">
            {amenityImage ? (
              <img
                src={amenityImage}
                alt={amenity.ten}
                className="w-16 h-16 object-cover rounded-lg border border-slate-200"
              />
            ) : (
              <div className="w-16 h-16 bg-slate-100 rounded-lg border border-slate-200 flex items-center justify-center">
                <Upload size={20} className="text-slate-400" />
              </div>
            )}
            {uploadingImage && (
              <div className="absolute inset-0 bg-slate-900 bg-opacity-50 rounded-lg flex items-center justify-center">
                <Loader2 size={16} className="text-white animate-spin" />
              </div>
            )}
          </div>
          <label className="mt-2 block">
            <input
              type="file"
              accept="image/*"
              onChange={handleAmenityImageChange}
              disabled={uploadingImage || isUpdating}
              className="hidden"
            />
            <span className="text-xs text-slate-600 hover:text-orange-600 cursor-pointer underline">
              {amenityImage ? 'Thay ảnh' : 'Thêm ảnh'}
            </span>
          </label>
        </div>
        
        <div className="flex-1">
          <h4 className="font-semibold text-slate-900">{amenity.ten}</h4>
          {amenity.mo_ta && (
            <p className="text-sm text-slate-600 mt-1">{amenity.mo_ta}</p>
          )}
        </div>
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={!isFree}
            onChange={handleToggle}
            disabled={isUpdating}
            className="w-4 h-4 text-orange-600 border-slate-300 rounded focus:ring-orange-500"
          />
          <span className={`text-sm font-semibold ${isFree ? 'text-green-600' : 'text-orange-600'}`}>
            {isFree ? 'Miễn phí' : 'Có phí'}
          </span>
        </label>
      </div>
      {!isFree && (
        <div className="mt-3">
          <label className="block text-sm font-medium text-slate-700 mb-1">
            Giá (VNĐ)
          </label>
          <input
            type="number"
            value={price}
            onChange={handlePriceChange}
            onBlur={handlePriceBlur}
            disabled={isUpdating}
            placeholder="VD: 500000"
            className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 disabled:opacity-50 ${
              hasChanges ? 'border-yellow-400 bg-yellow-50' : 'border-slate-300'
            }`}
          />
          {hasChanges && (
            <p className="text-xs text-yellow-600 mt-1">⚠️ Thay đổi chưa lưu</p>
          )}
        </div>
      )}
    </div>
  )
}

export default HotelManagement

