import React from 'react'
import { User } from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'

const AdminProfilePage = () => {
  const { user } = useAuthStore()

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-slate-900 mb-6">Hồ sơ quản trị viên</h1>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center gap-6 mb-6">
          <div className="w-24 h-24 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            {user?.avatar ? (
              <img
                src={user.avatar}
                alt={user.ho_ten || 'Admin'}
                className="w-full h-full rounded-full object-cover"
              />
            ) : (
              <User className="text-white" size={48} />
            )}
          </div>
          <div>
            <h2 className="text-2xl font-bold text-gray-900">{user?.ho_ten || 'Quản trị viên'}</h2>
            <p className="text-gray-600">{user?.email || 'N/A'}</p>
            <span className="inline-block mt-2 px-3 py-1 bg-emerald-100 text-emerald-700 rounded-full text-sm font-semibold">
              Quản trị viên
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Thông tin cá nhân</h3>
            <div className="space-y-3">
              <div>
                <p className="text-sm text-gray-500">Họ và tên</p>
                <p className="text-gray-900 font-medium">{user?.ho_ten || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Email</p>
                <p className="text-gray-900 font-medium">{user?.email || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Số điện thoại</p>
                <p className="text-gray-900 font-medium">{user?.sdt || 'N/A'}</p>
              </div>
            </div>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Thông tin tài khoản</h3>
            <div className="space-y-3">
              <div>
                <p className="text-sm text-gray-500">Vai trò</p>
                <p className="text-gray-900 font-medium">{user?.chuc_vu || user?.role || 'Admin'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Trạng thái</p>
                <span className="inline-block px-3 py-1 bg-green-100 text-green-700 rounded-full text-sm font-semibold">
                  Hoạt động
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default AdminProfilePage

