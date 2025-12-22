import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { useQuery, useMutation, useQueryClient } from 'react-query'
import { 
  User, 
  Mail, 
  Phone, 
  MapPin, 
  Calendar, 
  Camera, 
  Edit3, 
  Save, 
  X,
  Lock,
  Star,
  History,
  Heart,
  CreditCard,
  MessageSquare,
  Settings,
  HelpCircle,
  Info,
  LogOut,
  Trash2,
  ChevronRight,
  Shield,
  MessageCircle,
  Bell,
  BellOff
} from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import { userAPI } from '../../services/api/user'
import Button from '../../components/ui/Button'
import { Input, Label } from '../../components/ui/Input'
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/Card'
import { Modal, ModalHeader, ModalContent, ModalFooter } from '../../components/ui/Modal'
import toast from 'react-hot-toast'

const ProfilePage = () => {
  const { user, updateUser, logout } = useAuthStore()
  const queryClient = useQueryClient()
  const navigate = useNavigate()
  
  const [isEditing, setIsEditing] = useState(false)
  const [isChangePasswordModalOpen, setIsChangePasswordModalOpen] = useState(false)
  
  const [profileData, setProfileData] = useState({
    ho_ten: user?.ho_ten || '',
    email: user?.email || '',
    so_dien_thoai: user?.so_dien_thoai || '',
    dia_chi: user?.dia_chi || '',
    ngay_sinh: user?.ngay_sinh || '',
    gioi_tinh: user?.gioi_tinh || 'Nam',
    avatar: user?.avatar || null
  })

  const [avatarPreview, setAvatarPreview] = useState(user?.avatar || null)
  const [notificationsEnabled, setNotificationsEnabled] = useState(user?.nhan_thong_bao_email !== false)

  const [passwordData, setPasswordData] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  })

  // Fetch user profile from API
  const { data: profile, isLoading } = useQuery(
    'user-profile',
    async () => {
      try {
        const response = await userAPI.getProfile()
        return response.data
      } catch (error) {
        return { data: user }
      }
    },
    {
      select: (data) => data.data?.data || user,
      onSuccess: (data) => {
        if (data) {
          setProfileData({
            ho_ten: data.ho_ten || '',
            email: data.email || '',
            so_dien_thoai: data.so_dien_thoai || '',
            dia_chi: data.dia_chi || '',
            ngay_sinh: data.ngay_sinh || '',
            gioi_tinh: data.gioi_tinh || 'Nam',
            avatar: data.avatar || null
          })
          setAvatarPreview(data.avatar || null)
          setNotificationsEnabled(data.nhan_thong_bao_email !== false && data.nhan_thong_bao_email !== 0)
        }
      }
    }
  )

  // Update profile mutation
  const updateProfileMutation = useMutation(
    async (data) => {
      try {
        const response = await userAPI.updateProfile(data)
        return response.data
      } catch (error) {
        throw error
      }
    },
    {
      onSuccess: (response) => {
        toast.success('Cập nhật thông tin thành công!')
        updateUser(response.data)
        setIsEditing(false)
        queryClient.invalidateQueries('user-profile')
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Có lỗi xảy ra khi cập nhật thông tin'
        toast.error(message)
      }
    }
  )

  // Update notification preference mutation
  const updateNotificationMutation = useMutation(
    async (enabled) => {
      try {
        const response = await userAPI.updateNotificationPreference(enabled)
        return response.data
      } catch (error) {
        throw error
      }
    },
    {
      onSuccess: (response) => {
        const newValue = response.data?.nhan_thong_bao_email ?? notificationsEnabled
        setNotificationsEnabled(newValue)
        updateUser({ ...user, nhan_thong_bao_email: newValue })
        toast.success(newValue ? 'Đã bật thông báo' : 'Đã tắt thông báo')
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Có lỗi xảy ra khi cập nhật cài đặt'
        toast.error(message)
        // Revert toggle on error
        setNotificationsEnabled(!notificationsEnabled)
      }
    }
  )

  const handleToggleNotifications = () => {
    const newValue = !notificationsEnabled
    setNotificationsEnabled(newValue)
    updateNotificationMutation.mutate(newValue)
  }

  // Change password mutation
  const changePasswordMutation = useMutation(
    async (data) => {
      try {
        const response = await userAPI.changePassword(data)
        return response.data
      } catch (error) {
        throw error
      }
    },
    {
      onSuccess: () => {
        toast.success('Đổi mật khẩu thành công!')
        setIsChangePasswordModalOpen(false)
        setPasswordData({
          currentPassword: '',
          newPassword: '',
          confirmPassword: ''
        })
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Có lỗi xảy ra khi đổi mật khẩu'
        toast.error(message)
      }
    }
  )

  // Fetch user statistics
  const { data: userStats } = useQuery(
    'user-stats',
    async () => {
      try {
        const response = await userAPI.getUserStats()
        return response.data
      } catch (error) {
        return {
          totalBookings: 0,
          favoriteHotels: 0,
          points: 0
        }
      }
    },
    {
      select: (data) => data.data || data
    }
  )

  const handleUpdateProfile = () => {
    if (!profileData.ho_ten || !profileData.email) {
      toast.error('Vui lòng điền đầy đủ thông tin')
      return
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(profileData.email)) {
      toast.error('Email không hợp lệ')
      return
    }

    updateProfileMutation.mutate(profileData)
  }

  const handleChangePassword = () => {
    if (!passwordData.currentPassword || !passwordData.newPassword) {
      toast.error('Vui lòng điền đầy đủ thông tin')
      return
    }

    if (passwordData.newPassword !== passwordData.confirmPassword) {
      toast.error('Mật khẩu xác nhận không khớp')
      return
    }

    if (passwordData.newPassword.length < 6) {
      toast.error('Mật khẩu mới phải có ít nhất 6 ký tự')
      return
    }

    changePasswordMutation.mutate({
      mat_khau_cu: passwordData.currentPassword,
      mat_khau_moi: passwordData.newPassword
    })
  }

  const handleAvatarChange = (event) => {
    const file = event.target.files[0]
    if (file) {
      const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
      if (!allowedTypes.includes(file.type)) {
        toast.error('Chỉ hỗ trợ file ảnh (JPG, PNG, GIF, WEBP)')
        return
      }

      if (file.size > 5 * 1024 * 1024) {
        toast.error('Kích thước ảnh không được vượt quá 5MB')
        return
      }

      const reader = new FileReader()
      reader.onload = (e) => {
        const imageUrl = e.target.result
        setAvatarPreview(imageUrl)
        setProfileData(prev => ({
          ...prev,
          avatar: imageUrl
        }))
      }
      reader.readAsDataURL(file)
    }
  }

  const handleCancelEdit = () => {
    setIsEditing(false)
    setAvatarPreview(profile?.avatar || null)
    setProfileData({
      ho_ten: profile?.ho_ten || '',
      email: profile?.email || '',
      so_dien_thoai: profile?.so_dien_thoai || '',
      dia_chi: profile?.dia_chi || '',
      ngay_sinh: profile?.ngay_sinh || '',
      gioi_tinh: profile?.gioi_tinh || 'Nam',
      avatar: profile?.avatar || null
    })
  }

  const handleLogout = async () => {
    if (window.confirm('Bạn có chắc chắn muốn đăng xuất?')) {
      await logout()
      navigate('/login')
    }
  }

  const buildMenuItem = ({ icon: Icon, title, trailing, onTap, titleColor, iconColor }) => (
    <div
      onClick={onTap}
      className="flex items-center px-4 py-4 cursor-pointer hover:bg-gray-50 transition-colors"
    >
      <div
        className="w-10 h-10 rounded-lg flex items-center justify-center"
        style={{ backgroundColor: (iconColor || '#6b7280') + '15' }}
      >
        <Icon size={20} color={iconColor || '#6b7280'} />
      </div>
      <div className="flex-1 ml-4">
        <p className="text-base font-medium" style={{ color: titleColor || '#111827' }}>
          {title}
        </p>
      </div>
      {trailing && <div className="mr-2">{trailing}</div>}
      {onTap && <ChevronRight size={16} color="#9ca3af" className="ml-2" />}
    </div>
  )

  const buildSectionCard = ({ title, children }) => (
    <div className="mb-4 bg-white rounded-xl shadow-sm overflow-hidden">
      {title && (
        <div className="px-4 pt-4 pb-2">
          <h3 className="text-base font-bold text-gray-900">{title}</h3>
        </div>
      )}
      <div className="divide-y divide-gray-100">
        {children}
      </div>
    </div>
  )

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Đang tải thông tin...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header với gradient background */}
      <div className="bg-gradient-to-br from-blue-600 via-blue-500 to-blue-700 text-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-8">
          <div className="flex items-center justify-between">
            <div className="flex-1">
              <h1 className="text-2xl font-bold mb-1">
                Chào mừng, {profileData.ho_ten || profile?.ho_ten || 'Người dùng'}
              </h1>
              <p className="text-blue-100 text-base">{profile?.email || user?.email}</p>
            </div>
            {/* VIP Badge */}
            <div className="bg-black/20 backdrop-blur-sm px-3 py-2 rounded-lg flex items-center gap-2">
              <Star size={16} className="text-yellow-300" />
              <span className="text-sm font-bold">VIP</span>
              <span className="text-xs bg-gray-800/50 px-2 py-1 rounded">Đồng</span>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 pb-8">
        {/* Profile Edit Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-4"
        >
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>Thông tin cá nhân</CardTitle>
              <div className="flex space-x-2">
                {isEditing ? (
                  <>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleCancelEdit}
                      disabled={updateProfileMutation.isLoading}
                    >
                      <X className="w-4 h-4 mr-1" />
                      Hủy
                    </Button>
                    <Button
                      size="sm"
                      onClick={handleUpdateProfile}
                      disabled={updateProfileMutation.isLoading}
                    >
                      <Save className="w-4 h-4 mr-1" />
                      {updateProfileMutation.isLoading ? 'Đang lưu...' : 'Lưu'}
                    </Button>
                  </>
                ) : (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setIsEditing(true)}
                  >
                    <Edit3 className="w-4 h-4 mr-1" />
                    Chỉnh sửa
                  </Button>
                )}
              </div>
            </CardHeader>

            <CardContent className="space-y-6">
              {/* Avatar Section */}
              <div className="flex items-center gap-6">
                <div className="relative">
                  <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden border-2 border-gray-200">
                    {avatarPreview ? (
                      <img 
                        src={avatarPreview} 
                        alt="Avatar" 
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <User size={48} color="#6b7280" />
                    )}
                  </div>
                  {isEditing && (
                    <label
                      htmlFor="avatar-upload"
                      className="absolute bottom-0 right-0 bg-blue-600 text-white rounded-full p-2 cursor-pointer shadow-lg hover:bg-blue-700 transition-colors"
                    >
                      <Camera size={16} />
                      <input
                        type="file"
                        id="avatar-upload"
                        accept="image/*"
                        onChange={handleAvatarChange}
                        className="hidden"
                      />
                    </label>
                  )}
                </div>
                <div className="flex-1">
                  {isEditing ? (
                    <div className="space-y-2">
                      <input
                        type="text"
                        value={profileData.ho_ten}
                        onChange={(e) => setProfileData({...profileData, ho_ten: e.target.value})}
                        className="text-lg font-semibold text-gray-900 bg-transparent border-b border-gray-300 focus:border-blue-600 outline-none w-full pb-1"
                        placeholder="Nhập họ tên"
                      />
                      <p className="text-gray-500 text-sm">{profile?.email}</p>
                    </div>
                  ) : (
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900 mb-1">
                        {profileData.ho_ten || profile?.ho_ten || 'Chưa cập nhật'}
                      </h3>
                      <p className="text-gray-500 text-sm mb-1">{profile?.email}</p>
                      <p className="text-gray-400 text-xs">
                        Thành viên từ {new Date(profile?.created_at || Date.now()).toLocaleDateString('vi-VN')}
                      </p>
                    </div>
                  )}
                </div>
              </div>

              {/* Form Fields */}
              {isEditing && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t">
                  <div>
                    <Label htmlFor="email">Email *</Label>
                    <div className="relative mt-1">
                      <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                      <Input
                        id="email"
                        type="email"
                        value={profileData.email}
                        onChange={(e) => setProfileData({...profileData, email: e.target.value})}
                        className="pl-10"
                        placeholder="Nhập email"
                      />
                    </div>
                  </div>

                  <div>
                    <Label htmlFor="so_dien_thoai">Số điện thoại</Label>
                    <div className="relative mt-1">
                      <Phone className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                      <Input
                        id="so_dien_thoai"
                        type="tel"
                        value={profileData.so_dien_thoai}
                        onChange={(e) => setProfileData({...profileData, so_dien_thoai: e.target.value})}
                        className="pl-10"
                        placeholder="Nhập số điện thoại"
                      />
                    </div>
                  </div>

                  <div>
                    <Label htmlFor="gioi_tinh">Giới tính</Label>
                    <select
                      id="gioi_tinh"
                      value={profileData.gioi_tinh}
                      onChange={(e) => setProfileData({...profileData, gioi_tinh: e.target.value})}
                      className="mt-1 w-full h-10 px-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="Nam">Nam</option>
                      <option value="Nữ">Nữ</option>
                      <option value="Khác">Khác</option>
                    </select>
                  </div>

                  <div>
                    <Label htmlFor="ngay_sinh">Ngày sinh</Label>
                    <div className="relative mt-1">
                      <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                      <Input
                        id="ngay_sinh"
                        type="date"
                        value={profileData.ngay_sinh}
                        min="1940-01-01"
                        max={new Date().toISOString().split('T')[0]}
                        onChange={(e) => setProfileData({...profileData, ngay_sinh: e.target.value})}
                        className="pl-10"
                      />
                    </div>
                  </div>

                  <div className="md:col-span-2">
                    <Label htmlFor="dia_chi">Địa chỉ</Label>
                    <div className="relative mt-1">
                      <MapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                      <Input
                        id="dia_chi"
                        type="text"
                        value={profileData.dia_chi}
                        onChange={(e) => setProfileData({...profileData, dia_chi: e.target.value})}
                        className="pl-10"
                        placeholder="Nhập địa chỉ"
                      />
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        {/* Quyền lợi thành viên */}
        {buildSectionCard({
          title: 'Quyền lợi thành viên',
          children: [
            buildMenuItem({
              icon: Star,
              title: 'TriphotelVIP',
              onTap: () => navigate('/vip')
            }),
            buildMenuItem({
              icon: CreditCard,
              title: 'PointsMAX',
              onTap: () => toast.info('Tính năng đang phát triển')
            })
          ]
        })}

        {/* Tài khoản của tôi */}
        {buildSectionCard({
          title: 'Tài khoản của tôi',
          children: [
            buildMenuItem({
              icon: User,
              title: 'Thông tin cá nhân',
              onTap: () => setIsEditing(true)
            }),
            buildMenuItem({
              icon: MessageSquare,
              title: 'Tin nhắn từ khách sạn',
              onTap: () => navigate('/messages')
            }),
            buildMenuItem({
              icon: Heart,
              title: 'Đã lưu',
              onTap: () => navigate('/favorites')
            }),
            buildMenuItem({
              icon: History,
              title: 'Lịch sử đặt phòng',
              onTap: () => navigate('/bookings')
            }),
            buildMenuItem({
              icon: CreditCard,
              title: 'Thẻ đã lưu',
              onTap: () => navigate('/saved-cards')
            }),
            buildMenuItem({
              icon: MessageCircle,
              title: 'Nhận xét của tôi',
              onTap: () => navigate('/my-reviews')
            })
          ]
        })}

        {/* Cài đặt */}
        {buildSectionCard({
          title: 'Cài đặt',
          children: [
            buildMenuItem({
              icon: notificationsEnabled ? Bell : BellOff,
              title: 'Thông báo',
              trailing: (
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={notificationsEnabled}
                    onChange={handleToggleNotifications}
                    disabled={updateNotificationMutation.isLoading}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                </label>
              ),
              onTap: null
            }),
            buildMenuItem({
              icon: Shield,
              title: 'Bảo mật tài khoản',
              onTap: () => navigate('/account-security')
            }),
            buildMenuItem({
              icon: Settings,
              title: 'Cài đặt',
              onTap: () => toast.info('Tính năng đang phát triển')
            })
          ]
        })}

        {/* Trợ giúp và thông tin */}
        {buildSectionCard({
          title: 'Trợ giúp và thông tin',
          children: [
            buildMenuItem({
              icon: Info,
              title: 'Về chúng tôi',
              onTap: () => navigate('/about')
            }),
            buildMenuItem({
              icon: HelpCircle,
              title: 'Trung tâm trợ giúp',
              onTap: () => navigate('/help')
            })
          ]
        })}

        {/* Quản lý tài khoản */}
        {buildSectionCard({
          title: 'Quản lý tài khoản',
          children: [
            buildMenuItem({
              icon: Trash2,
              title: 'Xóa tài khoản',
              titleColor: '#dc2626',
              iconColor: '#dc2626',
              onTap: () => toast.error('Tính năng đang phát triển')
            }),
            buildMenuItem({
              icon: LogOut,
              title: 'Đăng xuất',
              titleColor: '#dc2626',
              iconColor: '#dc2626',
              onTap: handleLogout
            })
          ]
        })}
      </div>

      {/* Change Password Modal */}
      <Modal 
        isOpen={isChangePasswordModalOpen} 
        onClose={() => setIsChangePasswordModalOpen(false)}
      >
        <ModalHeader>
          <h3 className="text-lg font-semibold">Đổi mật khẩu</h3>
        </ModalHeader>
        
        <ModalContent>
          <div className="space-y-4">
            <div>
              <Label htmlFor="currentPassword">Mật khẩu hiện tại</Label>
              <Input
                id="currentPassword"
                type="password"
                value={passwordData.currentPassword}
                onChange={(e) => setPasswordData({...passwordData, currentPassword: e.target.value})}
                placeholder="Nhập mật khẩu hiện tại"
              />
            </div>
            
            <div>
              <Label htmlFor="newPassword">Mật khẩu mới</Label>
              <Input
                id="newPassword"
                type="password"
                value={passwordData.newPassword}
                onChange={(e) => setPasswordData({...passwordData, newPassword: e.target.value})}
                placeholder="Nhập mật khẩu mới (ít nhất 6 ký tự)"
              />
            </div>
            
            <div>
              <Label htmlFor="confirmPassword">Xác nhận mật khẩu mới</Label>
              <Input
                id="confirmPassword"
                type="password"
                value={passwordData.confirmPassword}
                onChange={(e) => setPasswordData({...passwordData, confirmPassword: e.target.value})}
                placeholder="Nhập lại mật khẩu mới"
              />
            </div>
          </div>
        </ModalContent>
        
        <ModalFooter>
          <Button
            variant="outline"
            onClick={() => setIsChangePasswordModalOpen(false)}
            disabled={changePasswordMutation.isLoading}
          >
            Hủy
          </Button>
          <Button
            onClick={handleChangePassword}
            disabled={changePasswordMutation.isLoading}
          >
            {changePasswordMutation.isLoading ? 'Đang xử lý...' : 'Đổi mật khẩu'}
          </Button>
        </ModalFooter>
      </Modal>
    </div>
  )
}

export default ProfilePage
