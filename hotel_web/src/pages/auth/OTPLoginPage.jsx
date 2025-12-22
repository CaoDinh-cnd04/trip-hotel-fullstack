import React, { useState, useEffect, useRef } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, Mail, Clock } from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import toast from 'react-hot-toast'

const OTPLoginPage = () => {
  const location = useLocation()
  const navigate = useNavigate()
  const email = location.state?.email || ''
  
  const [otp, setOtp] = useState(['', '', '', '', '', ''])
  const [isLoading, setIsLoading] = useState(false)
  const [isResending, setIsResending] = useState(false)
  const [countdown, setCountdown] = useState(0)
  const inputRefs = useRef([])

  const { verifyOTPLogin, sendOTP } = useAuthStore()

  // Countdown timer
  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000)
      return () => clearTimeout(timer)
    }
  }, [countdown])

  // Start countdown when component mounts
  useEffect(() => {
    setCountdown(300) // 5 minutes
  }, [])

  // Redirect if no email
  useEffect(() => {
    if (!email) {
      navigate('/login')
    }
  }, [email, navigate])

  const handleOTPChange = (index, value) => {
    // Only allow numbers
    if (value && !/^\d$/.test(value)) return

    const newOtp = [...otp]
    newOtp[index] = value
    setOtp(newOtp)

    // Auto-focus next input
    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus()
    }
  }

  const handleOTPKeyDown = (index, e) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus()
    }
  }

  const handlePaste = (e) => {
    e.preventDefault()
    const pastedData = e.clipboardData.getData('text').trim()
    if (/^\d{6}$/.test(pastedData)) {
      const newOtp = pastedData.split('')
      setOtp(newOtp)
      inputRefs.current[5]?.focus()
    }
  }

  const handleVerifyOTP = async (e) => {
    e?.preventDefault()
    
    const otpString = otp.join('')
    if (otpString.length !== 6) {
      toast.error('Vui lòng nhập đầy đủ 6 số OTP')
      return
    }

    setIsLoading(true)
    try {
      const result = await verifyOTPLogin(email, otpString)
      
      if (result.success) {
        // Use user from result instead of store to ensure we have the latest data
        const user = result.user || useAuthStore.getState().user
        
        // Debug logging
        console.log('🔍 OTP Login - User from result:', user)
        console.log('🔍 OTP Login - User role:', user?.role)
        console.log('🔍 OTP Login - User chuc_vu:', user?.chuc_vu)
        
        let roleMessage = ''
        if (user?.role === 'admin') {
          roleMessage = ' (Quản trị viên)'
        } else if (user?.role === 'hotel_manager') {
          roleMessage = ' (Quản lý khách sạn)'
        }
        
        toast.success(`Chào mừng ${user?.ho_ten || user?.hoTen || 'bạn'}${roleMessage}!`)
        
        // Navigate based on role - check both role and chuc_vu for compatibility
        const userRole = user?.role || (user?.chuc_vu === 'HotelManager' ? 'hotel_manager' : user?.chuc_vu === 'Admin' ? 'admin' : 'user')
        console.log('🔍 OTP Login - Final userRole for navigation:', userRole)
        
        if (userRole === 'admin') {
          console.log('✅ Redirecting to /admin')
          navigate('/admin')
        } else if (userRole === 'hotel_manager') {
          console.log('✅ Redirecting to /manager-hotel')
          navigate('/manager-hotel')
        } else {
          console.log('✅ Redirecting to / (user)')
          navigate('/')
        }
      } else {
        toast.error(result.error || 'Mã OTP không đúng')
        // Clear OTP on error
        setOtp(['', '', '', '', '', ''])
        inputRefs.current[0]?.focus()
      }
    } catch (error) {
      toast.error('Có lỗi xảy ra khi xác thực OTP')
      console.error('OTP verify error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleResendOTP = async () => {
    if (countdown > 0) {
      toast.error(`Vui lòng đợi ${Math.floor(countdown / 60)}:${(countdown % 60).toString().padStart(2, '0')} trước khi gửi lại`)
      return
    }

    setIsResending(true)
    try {
      const result = await sendOTP(email)
      
      if (result.success) {
        toast.success('Mã OTP mới đã được gửi đến email của bạn')
        setCountdown(300) // Reset countdown
        setOtp(['', '', '', '', '', ''])
        inputRefs.current[0]?.focus()
      } else {
        toast.error(result.error || 'Gửi lại OTP thất bại')
      }
    } catch (error) {
      toast.error('Có lỗi xảy ra khi gửi lại OTP')
      console.error('Resend OTP error:', error)
    } finally {
      setIsResending(false)
    }
  }

  const formatCountdown = (seconds) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-500 via-blue-400 to-blue-600">
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Back Button */}
        <button
          onClick={() => navigate('/login')}
          className="mb-6 p-2 bg-white/20 hover:bg-white/30 rounded-full flex items-center justify-center transition-colors"
        >
          <ArrowLeft className="w-5 h-5 text-white" />
        </button>

        {/* Logo and Title */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-8"
        >
          <div className="inline-flex items-center justify-center w-20 h-20 bg-white/20 rounded-full mb-4">
            <Mail className="w-10 h-10 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">
            Nhập mã OTP
          </h1>
          <p className="text-white/90 text-base mb-2">
            Chúng tôi đã gửi mã OTP đến
          </p>
          <p className="text-white font-semibold text-lg">
            {email}
          </p>
        </motion.div>

        {/* OTP Form Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="bg-white rounded-2xl shadow-2xl p-6 mb-6"
        >
          <form onSubmit={handleVerifyOTP} className="space-y-6">
            {/* OTP Input Fields */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-4 text-center">
                Nhập 6 số mã OTP
              </label>
              <div className="flex justify-center gap-3" onPaste={handlePaste}>
                {otp.map((digit, index) => (
                  <input
                    key={index}
                    ref={(el) => (inputRefs.current[index] = el)}
                    type="text"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleOTPChange(index, e.target.value)}
                    onKeyDown={(e) => handleOTPKeyDown(index, e)}
                    className="w-12 h-14 text-center text-2xl font-bold border-2 border-gray-300 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none"
                    disabled={isLoading}
                  />
                ))}
              </div>
            </div>

            {/* Countdown Timer */}
            {countdown > 0 && (
              <div className="flex items-center justify-center gap-2 text-sm text-gray-600">
                <Clock className="w-4 h-4" />
                <span>Mã OTP còn hiệu lực trong: <strong>{formatCountdown(countdown)}</strong></span>
              </div>
            )}

            {/* Verify Button */}
            <button
              type="submit"
              disabled={isLoading || otp.join('').length !== 6}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white py-4 px-4 rounded-xl font-semibold text-base transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <div className="flex items-center justify-center">
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                  Đang xác thực...
                </div>
              ) : (
                'Xác thực OTP'
              )}
            </button>

            {/* Resend OTP */}
            <div className="text-center">
              <p className="text-sm text-gray-600 mb-2">
                Không nhận được mã OTP?
              </p>
              <button
                type="button"
                onClick={handleResendOTP}
                disabled={isResending || countdown > 0}
                className="text-blue-600 hover:text-blue-700 font-medium text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isResending ? 'Đang gửi...' : 'Gửi lại mã OTP'}
              </button>
            </div>
          </form>
        </motion.div>

        {/* Back to Login */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="text-center"
        >
          <button
            onClick={() => navigate('/login')}
            className="text-white/90 hover:text-white text-sm font-medium"
          >
            Quay lại đăng nhập
          </button>
        </motion.div>
      </div>
    </div>
  )
}

export default OTPLoginPage

