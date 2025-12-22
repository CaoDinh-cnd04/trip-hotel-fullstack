import React, { useState, useEffect } from 'react'
import { Loader2, Search, Edit, UserCheck, UserX, Eye, Lock, Unlock, Key, Shield, Star, Calendar, BookOpen, Activity } from 'lucide-react'
import { userAPI, reviewAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'

const Users = () => {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [roleFilter, setRoleFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [showDetailModal, setShowDetailModal] = useState(false)
  const [showResetPasswordModal, setShowResetPasswordModal] = useState(false)
  const [showRoleModal, setShowRoleModal] = useState(false)
  const [selectedUser, setSelectedUser] = useState(null)
  const [userDetail, setUserDetail] = useState(null)
  const [loadingDetail, setLoadingDetail] = useState(false)
  const [newPassword, setNewPassword] = useState('')
  const [selectedRole, setSelectedRole] = useState('User')

  useEffect(() => {
    fetchUsers()
  }, [roleFilter, statusFilter])

  const fetchUsers = async () => {
    try {
      setLoading(true)
      const params = { limit: 100 }
      if (roleFilter !== 'all') {
        params.vai_tro = roleFilter
      }
      if (statusFilter !== 'all') {
        params.trang_thai = statusFilter === 'active' ? 1 : 0
      }
      
      const response = await userAPI.getAll(params)
      
      let usersList = []
      if (response?.data) {
        if (Array.isArray(response.data)) {
          usersList = response.data
        } else if (Array.isArray(response.data.data)) {
          usersList = response.data.data
        } else if (response.data.data && Array.isArray(response.data.data)) {
          usersList = response.data.data
        }
      }
      
      setUsers(usersList)
    } catch (err) {
      console.error('Error fetching users:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể tải danh sách người dùng'
      toast.error(errorMessage)
      setUsers([])
    } finally {
      setLoading(false)
    }
  }

  const handleViewDetail = async (user) => {
    try {
      setLoadingDetail(true)
      setSelectedUser(user)
      const response = await userAPI.getById(user.id || user.ma_nguoi_dung, {
        include_bookings: 'true',
        include_reviews: 'true'
      })
      
      setUserDetail(response?.data || response || user)
      setShowDetailModal(true)
    } catch (err) {
      console.error('Error fetching user detail:', err)
      setUserDetail(user)
      setShowDetailModal(true)
    } finally {
      setLoadingDetail(false)
    }
  }

  const handleApprove = async (id) => {
    try {
      await userAPI.approve(id)
      toast.success('Phê duyệt người dùng thành công!')
      fetchUsers()
    } catch (err) {
      console.error('Approve user error:', err)
      toast.error('Lỗi khi phê duyệt: ' + (err.response?.data?.message || err.message || 'Không thể phê duyệt người dùng'))
    }
  }

  const handleBlock = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn chặn người dùng này?')) {
      try {
        await userAPI.block(id)
        toast.success('Chặn người dùng thành công!')
        fetchUsers()
      } catch (err) {
        console.error('Block user error:', err)
        toast.error('Lỗi khi chặn: ' + (err.response?.data?.message || err.message || 'Không thể chặn người dùng'))
      }
    }
  }

  // Removed handleDelete - chỉ sử dụng chặn/bỏ chặn thay vì xóa

  const handleResetPassword = async () => {
    if (!newPassword || newPassword.length < 6) {
      toast.error('Mật khẩu mới phải có ít nhất 6 ký tự')
      return
    }

    try {
      await userAPI.resetPassword(selectedUser.id || selectedUser.ma_nguoi_dung, newPassword)
      toast.success('Đặt lại mật khẩu thành công!')
      setShowResetPasswordModal(false)
      setNewPassword('')
      setSelectedUser(null)
    } catch (err) {
      console.error('Reset password error:', err)
      toast.error('Lỗi khi đặt lại mật khẩu: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleUpdateRole = async () => {
    try {
      await userAPI.updateRole(selectedUser.id || selectedUser.ma_nguoi_dung, selectedRole)
      toast.success(`Cập nhật vai trò thành ${selectedRole} thành công!`)
      setShowRoleModal(false)
      setSelectedUser(null)
      fetchUsers()
    } catch (err) {
      console.error('Update role error:', err)
      toast.error('Lỗi khi cập nhật vai trò: ' + (err.response?.data?.message || err.message))
    }
  }

  const handleReviewStatusChange = async (reviewId, newStatus) => {
    try {
      await reviewAPI.updateStatus(reviewId, newStatus)
      toast.success(`Cập nhật trạng thái đánh giá thành công!`)
      // Reload user detail
      if (selectedUser) {
        handleViewDetail(selectedUser)
      }
    } catch (err) {
      console.error('Update review status error:', err)
      toast.error('Lỗi khi cập nhật trạng thái: ' + (err.response?.data?.message || err.message))
    }
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A'
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('vi-VN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      })
    } catch {
      return dateString
    }
  }

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(amount || 0)
  }

  const getStatusBadge = (status) => {
    const isActive = status === 1 || status === true || status === 'active' || status === '1'
    return (
      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
        isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
      }`}>
        {isActive ? 'Hoạt động' : 'Bị chặn'}
      </span>
    )
  }

  const getRoleBadge = (role) => {
    const roleMap = {
      'Admin': { label: 'Admin', color: 'bg-purple-100 text-purple-700' },
      'HotelManager': { label: 'Quản lý KS', color: 'bg-orange-100 text-orange-700' },
      'User': { label: 'Người dùng', color: 'bg-blue-100 text-blue-700' }
    }
    const roleInfo = roleMap[role] || { label: role, color: 'bg-gray-100 text-gray-700' }
    return (
      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${roleInfo.color}`}>
        {roleInfo.label}
      </span>
    )
  }

  const getReviewStatusBadge = (status) => {
    const statusMap = {
      'Đã duyệt': { color: 'bg-green-100 text-green-700' },
      'Chờ duyệt': { color: 'bg-yellow-100 text-yellow-700' },
      'Từ chối': { color: 'bg-red-100 text-red-700' }
    }
    const statusInfo = statusMap[status] || { color: 'bg-gray-100 text-gray-700' }
    return (
      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${statusInfo.color}`}>
        {status}
      </span>
    )
  }

  const filteredUsers = users.filter(user => {
    // Filter out soft-deleted users (trang_thai = 0) unless statusFilter is 'blocked'
    const isDeleted = user.trang_thai === 0 || user.trang_thai === false || user.trang_thai === '0'
    if (isDeleted && statusFilter !== 'blocked' && statusFilter !== 'all') {
      return false
    }
    
    // Apply search filter
    const search = searchTerm.toLowerCase()
    return (
      user.ho_ten?.toLowerCase().includes(search) ||
      user.email?.toLowerCase().includes(search) ||
      user.sdt?.toLowerCase().includes(search)
    )
  })

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 className="animate-spin text-emerald-500" size={32} />
        <span className="ml-3 text-slate-600">Đang tải người dùng...</span>
      </div>
    )
  }

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-slate-900">Quản lý người dùng</h1>
      </div>

      {/* Filters */}
      <div className="mb-6 flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
          <Input
            type="text"
            placeholder="Tìm kiếm theo tên, email, số điện thoại..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500"
        >
          <option value="all">Tất cả vai trò</option>
          <option value="User">User</option>
          <option value="HotelManager">Hotel Manager</option>
          <option value="Admin">Admin</option>
        </select>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500"
        >
          <option value="all">Tất cả trạng thái</option>
          <option value="active">Hoạt động</option>
          <option value="blocked">Bị chặn</option>
        </select>
      </div>

      {/* Users Table */}
      {filteredUsers.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow-sm border border-gray-200">
          <p className="text-gray-500">Không tìm thấy người dùng nào.</p>
        </div>
      ) : (
        <div className="overflow-x-auto bg-white rounded-lg shadow-sm border border-gray-200">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tên</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Số điện thoại</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Vai trò</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Trạng thái</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Hành động</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredUsers.map((user) => {
                const userId = user.id || user.ma_nguoi_dung
                const isActive = user.trang_thai === 1 || user.trang_thai === true || user.trang_thai === 'active' || user.trang_thai === '1'
                
                return (
                  <tr key={userId} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {user.ho_ten || 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{user.email || 'N/A'}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{user.sdt || 'N/A'}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getRoleBadge(user.chuc_vu || user.role || 'User')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(user.trang_thai)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex items-center justify-end gap-2">
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleViewDetail(user)}
                          title="Xem chi tiết"
                        >
                          <Eye size={16} />
                        </Button>
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => {
                            setSelectedUser(user)
                            setSelectedRole(user.chuc_vu || user.role || 'User')
                            setShowRoleModal(true)
                          }}
                          title="Phân quyền"
                        >
                          <Shield size={16} />
                        </Button>
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => {
                            setSelectedUser(user)
                            setShowResetPasswordModal(true)
                          }}
                          title="Reset password"
                        >
                          <Key size={16} />
                        </Button>
                        {!isActive ? (
                          <Button
                            variant="success"
                            size="sm"
                            onClick={() => handleApprove(userId)}
                            title="Bỏ chặn người dùng"
                          >
                            <Unlock size={16} />
                          </Button>
                        ) : (
                          <Button
                            variant="danger"
                            size="sm"
                            onClick={() => handleBlock(userId)}
                            title="Chặn người dùng"
                          >
                            <Lock size={16} />
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Detail Modal */}
      {showDetailModal && userDetail && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-start mb-4">
                <h2 className="text-2xl font-bold text-slate-900">Chi tiết người dùng</h2>
                <button
                  onClick={() => {
                    setShowDetailModal(false)
                    setUserDetail(null)
                    setSelectedUser(null)
                  }}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>

              {loadingDetail ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="animate-spin text-emerald-500" size={32} />
                </div>
              ) : (
                <>
                  {/* User Info */}
                  <div className="grid grid-cols-2 gap-6 mb-6">
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 mb-1">Họ tên</h3>
                      <p className="text-lg font-semibold">{userDetail.ho_ten || 'N/A'}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 mb-1">Email</h3>
                      <p className="text-lg">{userDetail.email || 'N/A'}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 mb-1">Số điện thoại</h3>
                      <p className="text-lg">{userDetail.sdt || 'N/A'}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 mb-1">Vai trò</h3>
                      {getRoleBadge(userDetail.chuc_vu || userDetail.role || 'User')}
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 mb-1">Trạng thái</h3>
                      {getStatusBadge(userDetail.trang_thai)}
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 mb-1">Ngày đăng ký</h3>
                      <p className="text-lg">{formatDate(userDetail.created_at || userDetail.ngay_dang_ky)}</p>
                    </div>
                  </div>

                  {/* Bookings */}
                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-3 flex items-center gap-2">
                      <BookOpen size={20} /> Đặt phòng ({userDetail.bookings?.length || 0})
                    </h3>
                    {userDetail.bookings && userDetail.bookings.length > 0 ? (
                      <div className="space-y-2 max-h-48 overflow-y-auto">
                        {userDetail.bookings.map((booking) => (
                          <div key={booking.id} className="bg-gray-50 p-3 rounded-lg">
                            <div className="flex justify-between items-start">
                              <div>
                                <p className="font-medium">{booking.ten_khach_san || 'N/A'}</p>
                                <p className="text-sm text-gray-600">
                                  {formatDate(booking.ngay_checkin)} - {formatDate(booking.ngay_checkout)}
                                </p>
                                <p className="text-sm text-gray-600">Phòng: {booking.ma_phong || booking.loai_phong || 'N/A'}</p>
                              </div>
                              <div className="text-right">
                                <p className="font-semibold">{formatCurrency(booking.tong_tien)}</p>
                                <span className={`text-xs px-2 py-1 rounded ${
                                  booking.trang_thai === 'Đã checkout' ? 'bg-green-100 text-green-700' :
                                  booking.trang_thai === 'Đã xác nhận' ? 'bg-blue-100 text-blue-700' :
                                  'bg-yellow-100 text-yellow-700'
                                }`}>
                                  {booking.trang_thai || 'N/A'}
                                </span>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-gray-500 text-sm">Chưa có đặt phòng nào</p>
                    )}
                  </div>

                  {/* Reviews */}
                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-3 flex items-center gap-2">
                      <Star size={20} /> Đánh giá ({userDetail.reviews?.length || 0})
                    </h3>
                    {userDetail.reviews && userDetail.reviews.length > 0 ? (
                      <div className="space-y-2 max-h-64 overflow-y-auto">
                        {userDetail.reviews.map((review) => (
                          <div key={review.id} className="bg-gray-50 p-3 rounded-lg">
                            <div className="flex justify-between items-start mb-2">
                              <div className="flex-1">
                                <div className="flex items-center gap-2 mb-1">
                                  <p className="font-medium">{review.ten_khach_san || 'N/A'}</p>
                                  <div className="flex items-center gap-1">
                                    {[...Array(5)].map((_, i) => (
                                      <Star
                                        key={i}
                                        size={14}
                                        className={i < (review.rating || 0) ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'}
                                      />
                                    ))}
                                  </div>
                                </div>
                                <p className="text-sm text-gray-700 mb-1">{review.content || review.binh_luan || 'N/A'}</p>
                                <p className="text-xs text-gray-500">{formatDate(review.review_date || review.ngay)}</p>
                              </div>
                              <div className="flex flex-col gap-2">
                                {getReviewStatusBadge(review.trang_thai || 'Chờ duyệt')}
                                {review.trang_thai !== 'Đã duyệt' && (
                                  <Button
                                    variant="success"
                                    size="sm"
                                    onClick={() => handleReviewStatusChange(review.id, 'Đã duyệt')}
                                  >
                                    Duyệt
                                  </Button>
                                )}
                                {review.trang_thai !== 'Từ chối' && (
                                  <Button
                                    variant="danger"
                                    size="sm"
                                    onClick={() => handleReviewStatusChange(review.id, 'Từ chối')}
                                  >
                                    Từ chối
                                  </Button>
                                )}
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-gray-500 text-sm">Chưa có đánh giá nào</p>
                    )}
                  </div>

                  {/* Activity Logs (Placeholder) */}
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-3 flex items-center gap-2">
                      <Activity size={20} /> Nhật ký hoạt động
                    </h3>
                    <p className="text-gray-500 text-sm">Chức năng này sẽ được cập nhật sau</p>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Reset Password Modal */}
      {showResetPasswordModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <h2 className="text-xl font-bold text-slate-900 mb-4">Đặt lại mật khẩu</h2>
            <p className="text-sm text-gray-600 mb-4">
              Đặt lại mật khẩu cho: <strong>{selectedUser.email}</strong>
            </p>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Mật khẩu mới <span className="text-red-500">*</span>
              </label>
              <Input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="Nhập mật khẩu mới (tối thiểu 6 ký tự)"
                minLength={6}
              />
            </div>
            <div className="flex justify-end gap-3">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowResetPasswordModal(false)
                  setNewPassword('')
                  setSelectedUser(null)
                }}
              >
                Hủy
              </Button>
              <Button
                variant="primary"
                onClick={handleResetPassword}
                disabled={!newPassword || newPassword.length < 6}
              >
                Đặt lại
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Role Modal */}
      {showRoleModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <h2 className="text-xl font-bold text-slate-900 mb-4">Phân quyền</h2>
            <p className="text-sm text-gray-600 mb-4">
              Cập nhật vai trò cho: <strong>{selectedUser.email}</strong>
            </p>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Vai trò <span className="text-red-500">*</span>
              </label>
              <select
                value={selectedRole}
                onChange={(e) => setSelectedRole(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500"
              >
                <option value="User">User</option>
                <option value="HotelManager">Hotel Manager</option>
                <option value="Admin">Admin</option>
              </select>
            </div>
            <div className="flex justify-end gap-3">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowRoleModal(false)
                  setSelectedUser(null)
                }}
              >
                Hủy
              </Button>
              <Button
                variant="primary"
                onClick={handleUpdateRole}
              >
                Cập nhật
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default Users
