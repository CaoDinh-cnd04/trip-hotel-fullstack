import { useState, useEffect } from 'react'
import { Loader2, TrendingUp, TrendingDown } from 'lucide-react'
import { hotelManagerAPI } from '../../../services/api/hotelManagerAPI'
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts'

const Overview = () => {
  const [kpiData, setKpiData] = useState({
    totalRooms: 0,
    availableRooms: 0,
    occupiedRooms: 0,
    todayBookings: 0,
    ongoingBookings: 0,
    todayRevenue: 0,
    monthlyRevenue: 0,
    occupancyRate: 0,
    revenueChart: []
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      setLoading(true)
      const response = await hotelManagerAPI.getDashboardKpi()
      
      // API interceptor returns response.data (from axios)
      const data = response?.data || response || {}
      
      console.log('📊 Dashboard KPI Response:', response)
      console.log('📊 Dashboard KPI Data:', data)
      
      setKpiData({
        totalRooms: data?.totalRooms || 0,
        availableRooms: data?.availableRooms || 0,
        occupiedRooms: data?.occupiedRooms || 0,
        todayBookings: data?.todayBookings || 0,
        ongoingBookings: data?.ongoingBookings || 0,
        todayRevenue: data?.todayRevenue || 0,
        monthlyRevenue: data?.monthlyRevenue || 0,
        occupancyRate: data?.occupancyRate || 0,
        revenueChart: data?.revenueChart || []
      })
    } catch (err) {
      console.error('Error fetching dashboard data:', err)
    } finally {
      setLoading(false)
    }
  }

  const formatPrice = (price) => {
    return new Intl.NumberFormat('vi-VN').format(price)
  }

  // Prepare data for room status pie chart
  const roomStatusData = [
    { name: 'Đang trống', value: kpiData.availableRooms, color: '#10b981' },
    { name: 'Đã đặt', value: kpiData.occupiedRooms, color: '#3b82f6' }
  ]

  // Format revenue chart data for display
  const formattedRevenueChart = kpiData.revenueChart.map(item => ({
    date: new Date(item.date).toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
    revenue: item.revenue
  }))

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
      <h1 className="text-3xl font-bold text-slate-900 mb-6">Bảng điều khiển</h1>

      {/* KPI Cards - Row 1 */}
      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-4 mb-6">
        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm px-6 py-5">
          <p className="text-sm font-semibold text-slate-600 mb-1">Tổng số phòng</p>
          <p className="text-3xl font-bold text-sky-600 mb-1">{kpiData.totalRooms}</p>
          <p className="text-xs text-slate-400">Phòng</p>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm px-6 py-5">
          <p className="text-sm font-semibold text-slate-600 mb-1">Phòng đang trống / đã đặt</p>
          <div className="flex items-center gap-4 mb-1">
            <div>
              <p className="text-2xl font-bold text-green-600">{kpiData.availableRooms}</p>
              <p className="text-xs text-slate-400">Trống</p>
            </div>
            <span className="text-slate-300">/</span>
            <div>
              <p className="text-2xl font-bold text-blue-600">{kpiData.occupiedRooms}</p>
              <p className="text-xs text-slate-400">Đã đặt</p>
            </div>
          </div>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm px-6 py-5">
          <p className="text-sm font-semibold text-slate-600 mb-1">Booking hôm nay</p>
          <p className="text-3xl font-bold text-sky-600 mb-1">{kpiData.todayBookings}</p>
          <p className="text-xs text-slate-400">Đơn</p>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm px-6 py-5">
          <p className="text-sm font-semibold text-slate-600 mb-1">Booking đang diễn ra</p>
          <p className="text-3xl font-bold text-orange-600 mb-1">{kpiData.ongoingBookings}</p>
          <p className="text-xs text-slate-400">Đơn</p>
        </div>
      </div>

      {/* KPI Cards - Row 2 */}
      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3 mb-6">
        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm px-6 py-5">
          <p className="text-sm font-semibold text-slate-600 mb-1">Doanh thu hôm nay</p>
          <p className="text-3xl font-bold text-green-600 mb-1">{formatPrice(kpiData.todayRevenue)}</p>
          <p className="text-xs text-slate-400">VND</p>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm px-6 py-5">
          <p className="text-sm font-semibold text-slate-600 mb-1">Doanh thu tháng</p>
          <p className="text-3xl font-bold text-sky-600 mb-1">{formatPrice(kpiData.monthlyRevenue)}</p>
          <p className="text-xs text-slate-400">VND</p>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm px-6 py-5">
          <p className="text-sm font-semibold text-slate-600 mb-1">Tỷ lệ lấp đầy phòng</p>
          <div className="flex items-center gap-2 mb-1">
            <p className="text-3xl font-bold text-purple-600">{kpiData.occupancyRate}%</p>
            {kpiData.occupancyRate >= 70 ? (
              <TrendingUp className="text-green-500" size={24} />
            ) : (
              <TrendingDown className="text-red-500" size={24} />
            )}
          </div>
          <p className="text-xs text-slate-400">Tỷ lệ phòng đã đặt</p>
        </div>
      </div>

      {/* Charts Row */}
      <div className="grid gap-5 md:grid-cols-2 mb-6">
        {/* Revenue Chart */}
        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm p-6">
          <h2 className="text-lg font-bold text-slate-900 mb-4">Biểu đồ doanh thu (30 ngày gần nhất)</h2>
          {formattedRevenueChart.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={formattedRevenueChart}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="date" 
                  tick={{ fontSize: 12 }}
                  angle={-45}
                  textAnchor="end"
                  height={80}
                />
                <YAxis 
                  tick={{ fontSize: 12 }}
                  tickFormatter={(value) => formatPrice(value)}
                />
                <Tooltip 
                  formatter={(value) => formatPrice(value) + ' VND'}
                  labelStyle={{ color: '#1e293b' }}
                />
                <Legend />
                <Line 
                  type="monotone" 
                  dataKey="revenue" 
                  stroke="#3b82f6" 
                  strokeWidth={2}
                  name="Doanh thu"
                  dot={{ r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-[300px] text-slate-400">
              <p>Chưa có dữ liệu doanh thu</p>
            </div>
          )}
        </div>

        {/* Room Status Pie Chart */}
        <div className="bg-white border border-slate-200 rounded-2xl shadow-sm p-6">
          <h2 className="text-lg font-bold text-slate-900 mb-4">Tỷ lệ lấp đầy phòng</h2>
          {kpiData.totalRooms > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={roomStatusData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(1)}%`}
                  outerRadius={100}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {roomStatusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-[300px] text-slate-400">
              <p>Chưa có dữ liệu phòng</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default Overview
