import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Loader2, Hotel, Users, FileCheck, DollarSign, UserCircle, Clock, Building2, BarChart3, MessageSquare, Bell, Percent } from 'lucide-react'
import { statsAPI, userAPI, hotelAPI, bookingAPI, hotelRegistrationAPI } from '../../services/api/admin'

const Overview = () => {
  const navigate = useNavigate()
  const [stats, setStats] = useState([
    { label: 'Tổng khách sạn', value: 0, suffix: 'Khách sạn', icon: Hotel, color: 'blue' },
    { label: 'Tổng người dùng', value: 0, suffix: 'Người dùng', icon: Users, color: 'orange' },
    { label: 'Hồ sơ chờ duyệt', value: 0, suffix: 'Hồ sơ', icon: FileCheck, color: 'purple' },
    { label: 'Doanh thu tháng', value: '0', suffix: 'VND', icon: DollarSign, color: 'green' }
  ])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      setLoading(true)
      
      // Fetch stats from admin API - prioritize KPI endpoint, fallback to individual APIs
      const [statsResponse, userStatsResponse, hotelStatsResponse, bookingStatsResponse, registrationsResponse] = await Promise.all([
        statsAPI.getOverview().catch((err) => {
          console.warn('KPI API error, using fallback:', err);
          return { data: null };
        }),
        userAPI.getStats().catch((err) => {
          console.warn('User stats API error:', err);
          return { data: { activeUsers: 0, totalUsers: 0 } };
        }),
        statsAPI.getHotelStats().catch((err) => {
          console.warn('Hotel stats API error:', err);
          return { data: { activeHotels: 0, totalHotels: 0 } };
        }),
        bookingAPI.getStats().catch((err) => {
          console.warn('Booking stats API error:', err);
          return { data: { monthlyRevenue: 0, totalRevenue: 0 } };
        }),
        hotelRegistrationAPI.getAll({ status: 'pending' }).catch((err) => {
          console.warn('Registrations API error:', err);
          return { data: [] };
        })
      ])

      // Extract data from responses - handle different response formats
      const kpiData = (statsResponse?.success && statsResponse?.data) ? statsResponse.data : null;
      const userStats = (userStatsResponse?.success && userStatsResponse?.data) 
                       ? userStatsResponse.data 
                       : (userStatsResponse?.data || {});
      const hotelStats = (hotelStatsResponse?.success && hotelStatsResponse?.data) 
                        ? hotelStatsResponse.data 
                        : (hotelStatsResponse?.data || {});
      const bookingStats = (bookingStatsResponse?.success && bookingStatsResponse?.data) 
                          ? bookingStatsResponse.data 
                          : (bookingStatsResponse?.data || {});
      const registrations = (registrationsResponse?.success && registrationsResponse?.data) 
                           ? registrationsResponse.data 
                           : (Array.isArray(registrationsResponse?.data) ? registrationsResponse.data : []);

      // Get values with proper fallback chain
      const totalUsers = kpiData?.tongSoNguoiDung || 
                        kpiData?.activeUsers || 
                        userStats?.activeUsers || 
                        userStats?.totalUsers || 
                        0;
      
      const totalHotels = kpiData?.tongSoKhachSan || 
                         kpiData?.activeHotels || 
                         hotelStats?.activeHotels || 
                         hotelStats?.totalHotels || 
                         0;
      
      const pendingRegistrations = kpiData?.hoSoChoDuyet !== undefined 
                                  ? kpiData.hoSoChoDuyet 
                                  : (Array.isArray(registrations) ? registrations.length : 0);
      
      const monthlyRevenue = kpiData?.monthlyRevenue || 
                            bookingStats?.monthlyRevenue || 
                            0;

      console.log('📊 Dashboard data:', {
        kpiData,
        totalUsers,
        totalHotels,
        pendingRegistrations,
        monthlyRevenue
      });

      setStats([
        { 
          label: 'Tổng khách sạn', 
          value: totalHotels, 
          suffix: 'Khách sạn', 
          icon: Hotel, 
          color: 'blue' 
        },
        { 
          label: 'Tổng người dùng', 
          value: totalUsers, 
          suffix: 'Người dùng', 
          icon: Users, 
          color: 'orange' 
        },
        { 
          label: 'Hồ sơ chờ duyệt', 
          value: pendingRegistrations, 
          suffix: 'Hồ sơ', 
          icon: FileCheck, 
          color: 'purple' 
        },
        { 
          label: 'Doanh thu tháng', 
          value: formatPrice(monthlyRevenue), 
          suffix: 'VND', 
          icon: DollarSign, 
          color: 'green' 
        }
      ])
    } catch (err) {
      console.error('Error fetching dashboard data:', err)
      // Set default values on error
      setStats([
        { label: 'Tổng khách sạn', value: 0, suffix: 'Khách sạn', icon: Hotel, color: 'blue' },
        { label: 'Tổng người dùng', value: 0, suffix: 'Người dùng', icon: Users, color: 'orange' },
        { label: 'Hồ sơ chờ duyệt', value: 0, suffix: 'Hồ sơ', icon: FileCheck, color: 'purple' },
        { label: 'Doanh thu tháng', value: '0', suffix: 'VND', icon: DollarSign, color: 'green' }
      ])
    } finally {
      setLoading(false)
    }
  }

  const formatPrice = (price) => {
    return new Intl.NumberFormat('vi-VN').format(price)
  }

  const getColorClasses = (color) => {
    const colors = {
      blue: 'bg-blue-100 text-blue-600 border-blue-200',
      orange: 'bg-orange-100 text-orange-600 border-orange-200',
      purple: 'bg-purple-100 text-purple-600 border-purple-200',
      green: 'bg-green-100 text-green-600 border-green-200'
    }
    return colors[color] || colors.blue
  }

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 className="animate-spin text-emerald-500" size={32} />
        <span className="ml-3 text-slate-600">Đang tải dữ liệu...</span>
      </div>
    )
  }

  const quickActions = [
    {
      label: 'Quản lý người dùng',
      icon: UserCircle,
      color: 'blue',
      onClick: () => navigate('/admin-hotel/users')
    },
    {
      label: 'Duyệt hồ sơ',
      icon: Clock,
      color: 'orange',
      onClick: () => navigate('/admin-hotel/hotel-registrations')
    },
    {
      label: 'Quản lý khách sạn',
      icon: Building2,
      color: 'green',
      onClick: () => navigate('/admin/hotels')
    },
    {
      label: 'Báo cáo hệ thống',
      icon: BarChart3,
      color: 'purple',
      onClick: () => navigate('/admin/reports')
    },
    {
      label: 'Phản hồi',
      icon: MessageSquare,
      color: 'teal',
      onClick: () => navigate('/admin-hotel/feedback')
    },
    {
      label: 'Tạo thông báo',
      icon: Bell,
      color: 'red',
      onClick: () => navigate('/admin-hotel/create-notification')
    }
  ]

  const getActionColorClasses = (color) => {
    const colors = {
      blue: 'bg-blue-50 hover:bg-blue-100 border-blue-200 text-blue-700',
      orange: 'bg-orange-50 hover:bg-orange-100 border-orange-200 text-orange-700',
      green: 'bg-green-50 hover:bg-green-100 border-green-200 text-green-700',
      purple: 'bg-purple-50 hover:bg-purple-100 border-purple-200 text-purple-700',
      teal: 'bg-teal-50 hover:bg-teal-100 border-teal-200 text-teal-700',
      red: 'bg-red-50 hover:bg-red-100 border-red-200 text-red-700'
    }
    return colors[color] || colors.blue
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-slate-900 mb-6">Bảng điều khiển</h1>

      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-4 mb-8">
        {stats.map((item) => {
          const Icon = item.icon
          return (
            <div
              key={item.label}
              className={`bg-white border-2 rounded-2xl shadow-sm px-6 py-5 flex flex-col ${getColorClasses(item.color)}`}
            >
              <div className="flex items-center justify-between mb-3">
                <Icon size={24} className="opacity-80" />
              </div>
              <p className="text-sm font-semibold mb-1">{item.label}</p>
              <p className="text-3xl font-bold mb-1">{item.value}</p>
              <p className="text-xs opacity-70">{item.suffix}</p>
            </div>
          )
        })}
      </div>

      {/* Quick Actions Section */}
      <div className="mt-8">
        <h2 className="text-xl font-semibold text-slate-900 mb-4">Thao tác nhanh</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {quickActions.map((action, index) => {
            const Icon = action.icon
            return (
              <button
                key={index}
                onClick={action.onClick}
                className={`${getActionColorClasses(action.color)} border-2 rounded-xl p-4 flex flex-col items-center justify-center gap-2 transition-all hover:scale-105 hover:shadow-md cursor-pointer`}
              >
                <Icon size={28} />
                <span className="text-sm font-semibold text-center">{action.label}</span>
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}

export default Overview

