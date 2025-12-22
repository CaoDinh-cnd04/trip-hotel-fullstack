import React, { useState, useEffect } from 'react'
import { Loader2, CheckCircle, XCircle, Eye, FileText, MapPin, Phone, Mail, Calendar, Star, Building } from 'lucide-react'
import { hotelRegistrationAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'

const HotelRegistrationManagement = () => {
  const [registrations, setRegistrations] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedRegistration, setSelectedRegistration] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [adminNote, setAdminNote] = useState('')
  const [filter, setFilter] = useState('all') // all, pending, approved, rejected
  const [actionType, setActionType] = useState(null) // 'approve' or 'reject'

  useEffect(() => {
    fetchRegistrations()
  }, [filter])

  const fetchRegistrations = async () => {
    try {
      setLoading(true)
      const params = filter !== 'all' ? { status: filter } : {}
      const response = await hotelRegistrationAPI.getAll(params)
      
      // Handle different response formats
      let registrationsList = []
      if (response?.data) {
        if (Array.isArray(response.data)) {
          registrationsList = response.data
        } else if (response.data.data && Array.isArray(response.data.data)) {
          registrationsList = response.data.data
        }
      }
      
      setRegistrations(registrationsList)
    } catch (err) {
      console.error('Error fetching registrations:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể tải danh sách đăng ký'
      toast.error(errorMessage)
      setRegistrations([])
    } finally {
      setLoading(false)
    }
  }

  const handleApprove = async () => {
    if (!selectedRegistration) return
    
    try {
      const id = selectedRegistration.id || selectedRegistration.ma_dang_ky
      await hotelRegistrationAPI.approve(id, adminNote)
      toast.success('Phê duyệt hồ sơ thành công!')
      setIsModalOpen(false)
      setAdminNote('')
      setSelectedRegistration(null)
      setActionType(null)
      fetchRegistrations()
    } catch (err) {
      console.error('Approve error:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể phê duyệt hồ sơ'
      toast.error(errorMessage)
    }
  }

  const handleReject = async () => {
    if (!selectedRegistration) return
    
    try {
      const id = selectedRegistration.id || selectedRegistration.ma_dang_ky
      await hotelRegistrationAPI.reject(id, adminNote)
      toast.success('Từ chối hồ sơ thành công!')
      setIsModalOpen(false)
      setAdminNote('')
      setSelectedRegistration(null)
      setActionType(null)
      fetchRegistrations()
    } catch (err) {
      console.error('Reject error:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể từ chối hồ sơ'
      toast.error(errorMessage)
    }
  }

  const handleViewDetails = (registration) => {
    setSelectedRegistration(registration)
    setActionType(null)
    setIsModalOpen(true)
  }

  const handleOpenApprove = (registration) => {
    setSelectedRegistration(registration)
    setActionType('approve')
    setAdminNote('')
    setIsModalOpen(true)
  }

  const handleOpenReject = (registration) => {
    setSelectedRegistration(registration)
    setActionType('reject')
    setAdminNote('')
    setIsModalOpen(true)
  }

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'bg-yellow-100 text-yellow-700'
      case 'approved':
        return 'bg-green-100 text-green-700'
      case 'rejected':
        return 'bg-red-100 text-red-700'
      case 'completed':
        return 'bg-blue-100 text-blue-700'
      default:
        return 'bg-gray-100 text-gray-700'
    }
  }

  const getStatusLabel = (status) => {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt'
      case 'approved':
        return 'Đã duyệt'
      case 'rejected':
        return 'Đã từ chối'
      case 'completed':
        return 'Hoàn thành'
      default:
        return status || 'N/A'
    }
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A'
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('vi-VN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    } catch {
      return dateString
    }
  }

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 className="animate-spin text-emerald-500" size={32} />
        <span className="ml-3 text-slate-600">Đang tải hồ sơ...</span>
      </div>
    )
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-slate-900 mb-6">Duyệt hồ sơ khách sạn</h1>

      {/* Filter Tabs */}
      <div className="mb-6 flex gap-2 border-b border-gray-200">
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-2 font-medium text-sm transition-colors ${
            filter === 'all'
              ? 'border-b-2 border-emerald-500 text-emerald-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Tất cả
        </button>
        <button
          onClick={() => setFilter('pending')}
          className={`px-4 py-2 font-medium text-sm transition-colors ${
            filter === 'pending'
              ? 'border-b-2 border-emerald-500 text-emerald-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Chờ duyệt
        </button>
        <button
          onClick={() => setFilter('approved')}
          className={`px-4 py-2 font-medium text-sm transition-colors ${
            filter === 'approved'
              ? 'border-b-2 border-emerald-500 text-emerald-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Đã duyệt
        </button>
        <button
          onClick={() => setFilter('rejected')}
          className={`px-4 py-2 font-medium text-sm transition-colors ${
            filter === 'rejected'
              ? 'border-b-2 border-emerald-500 text-emerald-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Đã từ chối
        </button>
      </div>

      {registrations.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow-sm border border-gray-200">
          <FileText className="mx-auto text-gray-400 mb-4" size={48} />
          <p className="text-gray-500">Không có hồ sơ nào.</p>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {registrations.map((registration) => {
            const status = registration.status || registration.trang_thai
            const isPending = status?.toLowerCase() === 'pending'
            
            return (
              <div
                key={registration.id || registration.ma_dang_ky}
                className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-gray-900 mb-1">
                      {registration.hotel_name || registration.ten_khach_san || 'N/A'}
                    </h3>
                    {registration.hotel_type && (
                      <p className="text-sm text-gray-500">{registration.hotel_type}</p>
                    )}
                  </div>
                  <span className={`px-2 py-1 text-xs font-semibold rounded-full whitespace-nowrap ${getStatusColor(status)}`}>
                    {getStatusLabel(status)}
                  </span>
                </div>

                <div className="space-y-2 mb-4">
                  <div className="flex items-start gap-2 text-sm text-gray-600">
                    <Building size={16} className="mt-0.5 flex-shrink-0 text-gray-400" />
                    <span className="flex-1">
                      <strong>Người đăng ký:</strong> {registration.owner_name || registration.ten_nguoi_dang_ky || 'N/A'}
                    </span>
                  </div>
                  
                  {registration.owner_email && (
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Mail size={16} className="flex-shrink-0 text-gray-400" />
                      <span className="truncate">{registration.owner_email}</span>
                    </div>
                  )}
                  
                  {registration.owner_phone && (
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Phone size={16} className="flex-shrink-0 text-gray-400" />
                      <span>{registration.owner_phone}</span>
                    </div>
                  )}
                  
                  {registration.address && (
                    <div className="flex items-start gap-2 text-sm text-gray-600">
                      <MapPin size={16} className="mt-0.5 flex-shrink-0 text-gray-400" />
                      <span className="line-clamp-2">{registration.address}</span>
                    </div>
                  )}

                  {registration.star_rating && (
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Star size={16} className="flex-shrink-0 text-yellow-400 fill-yellow-400" />
                      <span>{registration.star_rating} sao</span>
                    </div>
                  )}

                  {registration.created_at && (
                    <div className="flex items-center gap-2 text-sm text-gray-500">
                      <Calendar size={16} className="flex-shrink-0 text-gray-400" />
                      <span>{formatDate(registration.created_at)}</span>
                    </div>
                  )}
                </div>

                <div className="flex gap-2 pt-4 border-t border-gray-100">
                  <Button
                    variant="secondary"
                    size="sm"
                    onClick={() => handleViewDetails(registration)}
                    className="flex items-center gap-1 flex-1"
                  >
                    <Eye size={16} /> Chi tiết
                  </Button>
                  {isPending && (
                    <>
                      <Button
                        variant="success"
                        size="sm"
                        onClick={() => handleOpenApprove(registration)}
                        className="flex items-center gap-1"
                      >
                        <CheckCircle size={16} /> Duyệt
                      </Button>
                      <Button
                        variant="danger"
                        size="sm"
                        onClick={() => handleOpenReject(registration)}
                        className="flex items-center gap-1"
                      >
                        <XCircle size={16} /> Từ chối
                      </Button>
                    </>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Modal for Details/Approve/Reject */}
      {isModalOpen && selectedRegistration && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-2xl font-bold text-slate-900">
                  {actionType === 'approve' ? 'Phê duyệt hồ sơ' : 
                   actionType === 'reject' ? 'Từ chối hồ sơ' : 
                   'Chi tiết hồ sơ'}
                </h2>
                <button
                  onClick={() => {
                    setIsModalOpen(false)
                    setAdminNote('')
                    setSelectedRegistration(null)
                    setActionType(null)
                  }}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <XCircle size={24} />
                </button>
              </div>

              <div className="space-y-6">
                {/* Hotel Information */}
                <div>
                  <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                    <Building size={20} /> Thông tin khách sạn
                  </h3>
                  <div className="bg-gray-50 rounded-lg p-4 space-y-2">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-sm font-medium text-gray-700">Tên khách sạn</p>
                        <p className="text-sm text-gray-900">{selectedRegistration.hotel_name || selectedRegistration.ten_khach_san || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-700">Loại hình</p>
                        <p className="text-sm text-gray-900">{selectedRegistration.hotel_type || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-700">Số sao</p>
                        <p className="text-sm text-gray-900">{selectedRegistration.star_rating || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-700">Trạng thái</p>
                        <span className={`inline-block px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(selectedRegistration.status || selectedRegistration.trang_thai)}`}>
                          {getStatusLabel(selectedRegistration.status || selectedRegistration.trang_thai)}
                        </span>
                      </div>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-700">Địa chỉ</p>
                      <p className="text-sm text-gray-900">{selectedRegistration.address || selectedRegistration.dia_chi || 'N/A'}</p>
                    </div>
                    {selectedRegistration.description && (
                      <div>
                        <p className="text-sm font-medium text-gray-700">Mô tả</p>
                        <p className="text-sm text-gray-900 whitespace-pre-wrap">{selectedRegistration.description || selectedRegistration.mo_ta || 'N/A'}</p>
                      </div>
                    )}
                  </div>
                </div>

                {/* Owner Information */}
                <div>
                  <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                    <FileText size={20} /> Thông tin người đăng ký
                  </h3>
                  <div className="bg-gray-50 rounded-lg p-4 space-y-2">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-sm font-medium text-gray-700">Tên</p>
                        <p className="text-sm text-gray-900">{selectedRegistration.owner_name || selectedRegistration.ten_nguoi_dang_ky || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-700">Email</p>
                        <p className="text-sm text-gray-900">{selectedRegistration.owner_email || selectedRegistration.email || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-700">Số điện thoại</p>
                        <p className="text-sm text-gray-900">{selectedRegistration.owner_phone || selectedRegistration.sdt || selectedRegistration.phone || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-sm font-medium text-gray-700">Ngày đăng ký</p>
                        <p className="text-sm text-gray-900">{formatDate(selectedRegistration.created_at || selectedRegistration.ngay_dang_ky)}</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Additional Information */}
                {(selectedRegistration.contact_email || selectedRegistration.contact_phone || selectedRegistration.website || selectedRegistration.tax_id || selectedRegistration.business_license) && (
                  <div>
                    <h3 className="font-semibold text-gray-900 mb-3">Thông tin bổ sung</h3>
                    <div className="bg-gray-50 rounded-lg p-4 space-y-2">
                      {selectedRegistration.contact_email && (
                        <div>
                          <p className="text-sm font-medium text-gray-700">Email liên hệ</p>
                          <p className="text-sm text-gray-900">{selectedRegistration.contact_email}</p>
                        </div>
                      )}
                      {selectedRegistration.contact_phone && (
                        <div>
                          <p className="text-sm font-medium text-gray-700">SĐT liên hệ</p>
                          <p className="text-sm text-gray-900">{selectedRegistration.contact_phone}</p>
                        </div>
                      )}
                      {selectedRegistration.website && (
                        <div>
                          <p className="text-sm font-medium text-gray-700">Website</p>
                          <p className="text-sm text-gray-900">{selectedRegistration.website}</p>
                        </div>
                      )}
                      {selectedRegistration.tax_id && (
                        <div>
                          <p className="text-sm font-medium text-gray-700">Mã số thuế</p>
                          <p className="text-sm text-gray-900">{selectedRegistration.tax_id}</p>
                        </div>
                      )}
                      {selectedRegistration.business_license && (
                        <div>
                          <p className="text-sm font-medium text-gray-700">Giấy phép kinh doanh</p>
                          <p className="text-sm text-gray-900">{selectedRegistration.business_license}</p>
                        </div>
                      )}
                    </div>
                  </div>
                )}

                {/* Admin Note Section */}
                {(actionType === 'approve' || actionType === 'reject') && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Ghi chú (tùy chọn)
                    </label>
                    <textarea
                      value={adminNote}
                      onChange={(e) => setAdminNote(e.target.value)}
                      rows={4}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500"
                      placeholder="Nhập ghi chú cho quyết định..."
                    />
                  </div>
                )}

                {/* Admin Note Display (if exists) */}
                {selectedRegistration.admin_note && !actionType && (
                  <div>
                    <p className="text-sm font-medium text-gray-700 mb-2">Ghi chú của admin</p>
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                      <p className="text-sm text-gray-900">{selectedRegistration.admin_note}</p>
                    </div>
                  </div>
                )}

                {/* Action Buttons */}
                <div className="flex justify-end gap-3 pt-4 border-t border-gray-200">
                  <Button
                    variant="secondary"
                    onClick={() => {
                      setIsModalOpen(false)
                      setAdminNote('')
                      setSelectedRegistration(null)
                      setActionType(null)
                    }}
                  >
                    Đóng
                  </Button>
                  {actionType === 'approve' && (
                    <Button
                      variant="success"
                      onClick={handleApprove}
                      className="flex items-center gap-2"
                    >
                      <CheckCircle size={16} /> Phê duyệt
                    </Button>
                  )}
                  {actionType === 'reject' && (
                    <Button
                      variant="danger"
                      onClick={handleReject}
                      className="flex items-center gap-2"
                    >
                      <XCircle size={16} /> Từ chối
                    </Button>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default HotelRegistrationManagement
