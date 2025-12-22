import React from 'react'
import { useAuthStore } from '../../stores/authStore'

const ManagerProfilePage = () => {
  const { user } = useAuthStore()

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-slate-900 mb-6">Hồ sơ quản lý</h1>
      
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-6">
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Họ tên</label>
            <p className="text-slate-900">{user?.ho_ten || user?.name || 'N/A'}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
            <p className="text-slate-900">{user?.email || 'N/A'}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Số điện thoại</label>
            <p className="text-slate-900">{user?.so_dien_thoai || user?.phone || 'N/A'}</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ManagerProfilePage

