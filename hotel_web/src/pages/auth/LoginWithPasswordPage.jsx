import React, { useState } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, Eye, EyeOff } from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import toast from 'react-hot-toast'

const LoginWithPasswordPage = () => {
  const location = useLocation()
  const navigate = useNavigate()
  const email = location.state?.email || ''
  
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  
  const { login } = useAuthStore()

  const handleLogin = async (e) => {
    e.preventDefault()
    
    if (!password.trim()) {
      toast.error('Vui lòng nhập mật khẩu')
      return
    }

    setIsLoading(true)
    try {
      const result = await login({
        email: email,
        mat_khau: password
      })

      if (result.success) {
        toast.success('Đăng nhập thành công!')
        navigate('/')
      } else {
        toast.error(result.error || 'Đăng nhập thất bại')
      }
    } catch (error) {
      toast.error('Có lỗi xảy ra khi đăng nhập')
    } finally {
      setIsLoading(false)
    }
  }

  const handleForgotPassword = () => {
    toast.info('Tính năng quên mật khẩu đang phát triển')
  }

  // Redirect if no email
  React.useEffect(() => {
    if (!email) {
      navigate('/login')
    }
  }, [email, navigate])

  return (
    <div className="min-h-screen bg-white">
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Back Button */}
        <button
          onClick={() => navigate('/login')}
          className="mb-10 p-0 bg-transparent border-none flex items-center"
        >
          <ArrowLeft className="w-5 h-5 text-black" />
        </button>

        {/* Title */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="mb-10"
        >
          <h1 className="text-3xl font-bold text-black text-center mb-4">
            Nhập mật khẩu
          </h1>
          <p className="text-gray-600 text-center leading-relaxed mb-2">
            Nhập mật khẩu cho tài khoản:
          </p>
          <p className="text-blue-600 text-center font-medium">
            {email}
          </p>
        </motion.div>

        {/* Login Form */}
        <motion.form
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          onSubmit={handleLogin}
          className="space-y-6"
        >
          {/* Password Input */}
          <div>
            <label className="block text-base font-medium text-black mb-2">
              Mật khẩu
            </label>
            
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Nhập mật khẩu của bạn"
                className="w-full px-4 py-4 pr-12 border border-gray-300 rounded-xl focus:border-blue-600 focus:ring-2 focus:ring-blue-600 focus:outline-none bg-white"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? (
                  <EyeOff className="w-5 h-5" />
                ) : (
                  <Eye className="w-5 h-5" />
                )}
              </button>
            </div>
          </div>

          {/* Login Button */}
          <button
            type="submit"
            disabled={!password.trim() || isLoading}
            className={`w-full py-4 rounded-xl font-semibold text-base transition-colors ${
              password.trim() && !isLoading
                ? 'bg-blue-600 hover:bg-blue-700 text-white'
                : 'bg-gray-300 text-gray-500 cursor-not-allowed'
            }`}
          >
            {isLoading ? (
              <div className="flex items-center justify-center">
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                Đang đăng nhập...
              </div>
            ) : (
              'Đăng nhập'
            )}
          </button>

          {/* Forgot Password Link */}
          <div className="text-center">
            <button
              type="button"
              onClick={handleForgotPassword}
              className="text-blue-600 hover:text-blue-700 text-base font-medium"
            >
              Quên mật khẩu?
            </button>
          </div>

          {/* Register Link */}
          <div className="text-center pt-4 border-t border-gray-200">
            <p className="text-gray-600 mb-2">Chưa có tài khoản?</p>
            <Link
              to="/register"
              className="text-blue-600 hover:text-blue-700 text-base font-medium"
            >
              Đăng ký ngay
            </Link>
          </div>

          {/* Legal Text */}
          <div className="text-center text-xs text-gray-500 leading-relaxed pt-6">
            <p>
              Khi đăng nhập, tôi đồng ý với các{' '}
              <span className="text-blue-600 underline cursor-pointer">
                Điều khoản sử dụng
              </span>{' '}
              và{' '}
              <span className="text-blue-600 underline cursor-pointer">
                Chính sách bảo mật
              </span>{' '}
              của Hotel Booking.
            </p>
          </div>
        </motion.form>
      </div>
    </div>
  )
}

export default LoginWithPasswordPage