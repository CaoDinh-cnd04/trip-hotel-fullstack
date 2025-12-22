import React, { useState, useEffect } from 'react'
import { Loader2, BarChart3, TrendingUp, DollarSign, Calendar, Users, Building2, BookOpen } from 'lucide-react'
import { reportAPI } from '../../services/api/admin'
import toast from 'react-hot-toast'
import Button from '../../components/ui/Button'

const SystemReports = () => {
  const [loading, setLoading] = useState(true)
  const [statistics, setStatistics] = useState(null)
  const [selectedPeriod, setSelectedPeriod] = useState('30days')
  const [error, setError] = useState(null)

  const periodOptions = [
    { value: '7days', label: '7 ngày qua' },
    { value: '30days', label: '30 ngày qua' },
    { value: '90days', label: '90 ngày qua' },
    { value: 'year', label: 'Năm nay' }
  ]

  useEffect(() => {
    loadStatistics()
  }, [selectedPeriod])

  const loadStatistics = async () => {
    try {
      setLoading(true)
      setError(null)

      const toDate = new Date()
      let fromDate = new Date()

      switch (selectedPeriod) {
        case '7days':
          fromDate = new Date(toDate.getTime() - 7 * 24 * 60 * 60 * 1000)
          break
        case '30days':
          fromDate = new Date(toDate.getTime() - 30 * 24 * 60 * 60 * 1000)
          break
        case '90days':
          fromDate = new Date(toDate.getTime() - 90 * 24 * 60 * 60 * 1000)
          break
        case 'year':
          fromDate = new Date(toDate.getFullYear(), 0, 1)
          break
        default:
          fromDate = new Date(toDate.getTime() - 30 * 24 * 60 * 60 * 1000)
      }

      const response = await reportAPI.getSystemStatistics({
        from_date: fromDate.toISOString(),
        to_date: toDate.toISOString()
      })

      if (response?.success && response?.data) {
        setStatistics(response.data)
      } else {
        throw new Error('Không thể tải dữ liệu thống kê')
      }
    } catch (err) {
      console.error('Error loading statistics:', err)
      const errorMessage = err.response?.data?.message || err.message || 'Không thể tải dữ liệu thống kê'
      setError(errorMessage)
      toast.error(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND'
    }).format(amount || 0)
  }

  const formatDate = (dateString) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit'
    })
  }

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 className="animate-spin text-emerald-500" size={32} />
        <span className="ml-3 text-slate-600">Đang tải dữ liệu báo cáo...</span>
      </div>
    )
  }

  if (error && !statistics) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
          <p className="text-red-600 mb-4">{error}</p>
          <Button variant="primary" onClick={loadStatistics}>
            Thử lại
          </Button>
        </div>
      </div>
    )
  }

  const summary = statistics?.summary || {}
  const bookingTrend = statistics?.booking_trend || []
  const revenueTrend = statistics?.revenue_trend || []
  const userStats = statistics?.user_stats || {}
  const hotelStats = statistics?.hotel_stats || {}

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-slate-900 flex items-center gap-2">
          <BarChart3 size={32} className="text-purple-600" />
          Báo cáo Hệ thống
        </h1>
        <div className="flex items-center gap-3">
          <select
            value={selectedPeriod}
            onChange={(e) => setSelectedPeriod(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
          >
            {periodOptions.map(option => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <Button variant="secondary" onClick={loadStatistics}>
            Làm mới
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 mb-1">Tổng đặt phòng</p>
              <p className="text-2xl font-bold text-gray-900">{summary.total_bookings || 0}</p>
            </div>
            <div className="bg-blue-100 p-3 rounded-full">
              <BookOpen className="text-blue-600" size={24} />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm">
            <span className="text-gray-600">Hoàn thành: </span>
            <span className="font-semibold text-green-600 ml-1">{summary.completed_bookings || 0}</span>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 mb-1">Tổng doanh thu</p>
              <p className="text-2xl font-bold text-gray-900">{formatCurrency(summary.total_revenue || 0)}</p>
            </div>
            <div className="bg-green-100 p-3 rounded-full">
              <DollarSign className="text-green-600" size={24} />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm">
            <span className="text-gray-600">Giá trị TB: </span>
            <span className="font-semibold text-green-600 ml-1">{formatCurrency(summary.avg_booking_value || 0)}</span>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 mb-1">Tổng người dùng</p>
              <p className="text-2xl font-bold text-gray-900">{userStats.activeUsers || 0}</p>
            </div>
            <div className="bg-purple-100 p-3 rounded-full">
              <Users className="text-purple-600" size={24} />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm">
            <span className="text-gray-600">Mới tháng này: </span>
            <span className="font-semibold text-purple-600 ml-1">{userStats.newUsersThisMonth || 0}</span>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 mb-1">Tổng khách sạn</p>
              <p className="text-2xl font-bold text-gray-900">{hotelStats.activeHotels || 0}</p>
            </div>
            <div className="bg-orange-100 p-3 rounded-full">
              <Building2 className="text-orange-600" size={24} />
            </div>
          </div>
          <div className="mt-4 flex items-center text-sm">
            <span className="text-gray-600">Mới tháng này: </span>
            <span className="font-semibold text-orange-600 ml-1">{hotelStats.newHotelsThisMonth || 0}</span>
          </div>
        </div>
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Booking Trend Chart */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <TrendingUp size={20} className="text-blue-600" />
            Xu hướng Đặt phòng
          </h3>
          {bookingTrend.length > 0 ? (
            <div className="space-y-2">
              {bookingTrend.map((item, index) => (
                <div key={index} className="flex items-center gap-3">
                  <div className="w-20 text-xs text-gray-600">{formatDate(item.date)}</div>
                  <div className="flex-1 bg-gray-200 rounded-full h-6 relative overflow-hidden">
                    <div
                      className="bg-blue-500 h-full rounded-full flex items-center justify-end pr-2"
                      style={{ width: `${Math.min((item.count / Math.max(...bookingTrend.map(b => b.count))) * 100, 100)}%` }}
                    >
                      {item.count > 0 && (
                        <span className="text-xs text-white font-semibold">{item.count}</span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              Không có dữ liệu đặt phòng trong khoảng thời gian này
            </div>
          )}
        </div>

        {/* Revenue Trend Chart */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <DollarSign size={20} className="text-green-600" />
            Xu hướng Doanh thu
          </h3>
          {revenueTrend.length > 0 ? (
            <div className="space-y-2">
              {revenueTrend.map((item, index) => {
                const maxRevenue = Math.max(...revenueTrend.map(r => r.amount))
                return (
                  <div key={index} className="flex items-center gap-3">
                    <div className="w-20 text-xs text-gray-600">{formatDate(item.date)}</div>
                    <div className="flex-1 bg-gray-200 rounded-full h-6 relative overflow-hidden">
                      <div
                        className="bg-green-500 h-full rounded-full flex items-center justify-end pr-2"
                        style={{ width: `${maxRevenue > 0 ? Math.min((item.amount / maxRevenue) * 100, 100) : 0}%` }}
                      >
                        {item.amount > 0 && (
                          <span className="text-xs text-white font-semibold">
                            {formatCurrency(item.amount).replace('₫', '').trim()}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              Không có dữ liệu doanh thu trong khoảng thời gian này
            </div>
          )}
        </div>
      </div>

      {/* Additional Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Thống kê Đặt phòng</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Đã xác nhận:</span>
              <span className="font-semibold text-blue-600">{summary.confirmed_bookings || 0}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Hoàn thành:</span>
              <span className="font-semibold text-green-600">{summary.completed_bookings || 0}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Đang chờ:</span>
              <span className="font-semibold text-yellow-600">{summary.pending_bookings || 0}</span>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Thống kê Người dùng</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Tổng người dùng:</span>
              <span className="font-semibold">{userStats.activeUsers || 0}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Admin:</span>
              <span className="font-semibold text-purple-600">{userStats.roleDistribution?.find(r => r.role === 'Admin')?.count || 0}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Quản lý khách sạn:</span>
              <span className="font-semibold text-orange-600">{userStats.roleDistribution?.find(r => r.role === 'HotelManager')?.count || 0}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-gray-600">Người dùng:</span>
              <span className="font-semibold text-blue-600">{userStats.roleDistribution?.find(r => r.role === 'User')?.count || 0}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default SystemReports

