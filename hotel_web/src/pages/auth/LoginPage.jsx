import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, Mail, Lock, Eye, EyeOff } from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import toast from 'react-hot-toast'
import { getFirebaseAuth } from '../../config/firebase'
import { GoogleAuthProvider, signInWithPopup, signInWithRedirect, getRedirectResult } from 'firebase/auth'

const LoginPage = () => {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  
  const { login } = useAuthStore()
  const navigate = useNavigate()

  const handleEmailLogin = async (e) => {
    e?.preventDefault()
    
    if (!email.trim() || !password.trim()) {
      toast.error('Vui lòng điền đầy đủ thông tin')
      return
    }

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      toast.error('Email không hợp lệ')
      return
    }

    setIsLoading(true)
    try {
      const result = await login({
        email: email.trim(),
        mat_khau: password
      })

      if (result.success) {
        // Get role information for welcome message
        const { user } = useAuthStore.getState()
        let roleMessage = ''
        if (user?.role === 'admin') {
          roleMessage = ' (Quản trị viên)'
        } else if (user?.role === 'hotel_manager') {
          roleMessage = ' (Quản lý khách sạn)'
        } else if (user?.role === 'user') {
          roleMessage = ' (Người dùng)'
        }

        toast.success(`Chào mừng ${user?.ho_ten || user?.hoTen || 'bạn'}${roleMessage}!`)
        
        // Navigate based on role
        if (user?.role === 'admin') {
          navigate('/admin')
        } else if (user?.role === 'hotel_manager') {
          navigate('/manager-hotel')
        } else {
          navigate('/')
        }
      } else {
        toast.error(result.error || 'Đăng nhập thất bại')
      }
    } catch (error) {
      toast.error('Có lỗi xảy ra khi đăng nhập')
      console.error('Login error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleOTPLogin = async () => {
    if (!email.trim()) {
      toast.error('Vui lòng nhập email')
      return
    }

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      toast.error('Email không hợp lệ')
      return
    }

    setIsLoading(true)
    try {
      const { sendOTP } = useAuthStore.getState()
      const result = await sendOTP(email.trim())
      
      if (result.success) {
        toast.success('Mã OTP đã được gửi đến email của bạn')
        navigate('/login-otp', { state: { email: email.trim() } })
      } else {
        toast.error(result.error || 'Gửi OTP thất bại')
      }
    } catch (error) {
      toast.error('Có lỗi xảy ra khi gửi OTP')
      console.error('OTP error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleLogin = async () => {
    setIsLoading(true)
    try {
      const auth = getFirebaseAuth()
      
      if (!auth) {
        toast.error('Firebase chưa được khởi tạo. Vui lòng kiểm tra cấu hình.', {
          duration: 4000
        })
        setIsLoading(false)
        return
      }

      // Check for redirect result first (if user was redirected back)
      try {
        const redirectResult = await getRedirectResult(auth)
        if (redirectResult) {
          await _handleFirebaseAuthSuccess(redirectResult.user)
          return
        }
      } catch (error) {
        console.log('No redirect result:', error)
      }

      // Use popup for Google sign in
      const provider = new GoogleAuthProvider()
      provider.addScope('email')
      provider.addScope('profile')
      
      // Set custom parameters
      provider.setCustomParameters({
        prompt: 'select_account'
      })

      try {
        const result = await signInWithPopup(auth, provider)
        await _handleFirebaseAuthSuccess(result.user)
      } catch (error) {
        console.error('Firebase Google login error:', error)
        
        // Handle specific errors
        if (error.code === 'auth/popup-closed-by-user') {
          toast.error('Đăng nhập Google bị hủy')
        } else if (error.code === 'auth/popup-blocked') {
          // Fallback to redirect if popup is blocked
          toast.info('Đang chuyển hướng đến Google...')
          await signInWithRedirect(auth, provider)
        } else if (error.code === 'auth/account-exists-with-different-credential') {
          toast.error('Tài khoản này đã được liên kết với phương thức đăng nhập khác')
        } else {
          toast.error(error.message || 'Đăng nhập Google thất bại. Vui lòng thử lại.')
        }
        setIsLoading(false)
      }
    } catch (error) {
      console.error('Google login error:', error)
      toast.error('Lỗi khởi tạo Google đăng nhập. Vui lòng thử lại sau.', {
        duration: 4000
      })
      setIsLoading(false)
    }
  }

  const _handleFirebaseAuthSuccess = async (firebaseUser) => {
    try {
      // Get Google provider data
      const googleProviderData = firebaseUser.providerData.find(
        provider => provider.providerId === 'google.com'
      )
      
      const { firebaseGoogleLogin } = useAuthStore.getState()
      const result = await firebaseGoogleLogin({
        firebase_uid: firebaseUser.uid,
        email: firebaseUser.email,
        ho_ten: firebaseUser.displayName || firebaseUser.email?.split('@')[0] || 'User',
        anh_dai_dien: firebaseUser.photoURL || null,
        provider: 'google.com',
        google_id: googleProviderData?.uid || firebaseUser.uid,
        access_token: null // Firebase handles token internally
      })
      
      if (result.success) {
        const { user } = useAuthStore.getState()
        let roleMessage = ''
        if (user?.role === 'admin') {
          roleMessage = ' (Quản trị viên)'
        } else if (user?.role === 'hotel_manager') {
          roleMessage = ' (Quản lý khách sạn)'
        }
        
        toast.success(`Chào mừng ${user?.ho_ten || user?.hoTen || 'bạn'}${roleMessage}!`)
        
        if (user?.role === 'admin') {
          navigate('/admin')
        } else if (user?.role === 'hotel_manager') {
          navigate('/manager-hotel')
        } else {
          navigate('/')
        }
      } else {
        toast.error(result.error || 'Đăng nhập Google thất bại')
      }
    } catch (error) {
      console.error('Firebase auth success handler error:', error)
      toast.error('Lỗi xử lý đăng nhập Google. Vui lòng thử lại.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleFacebookLogin = async () => {
    setIsLoading(true)
    try {
      // Check if running on HTTPS or localhost
      const isSecure = window.location.protocol === 'https:' || window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
      
      if (!isSecure && window.location.protocol === 'http:') {
        toast.error('Đăng nhập Facebook yêu cầu HTTPS. Vui lòng sử dụng phương thức đăng nhập khác hoặc truy cập qua HTTPS.', {
          duration: 5000
        })
        setIsLoading(false)
        return
      }

      const facebookAppId = import.meta.env.VITE_FACEBOOK_APP_ID
      
      if (!facebookAppId || facebookAppId === 'YOUR_FACEBOOK_APP_ID') {
        toast.error('Tính năng đăng nhập Facebook chưa được kích hoạt. Vui lòng sử dụng phương thức khác.', {
          duration: 4000
        })
        setIsLoading(false)
        return
      }

      // Load Facebook SDK if not loaded
      if (!window.FB) {
        await new Promise((resolve, reject) => {
          // Check if fbAsyncInit already exists
          if (window.fbAsyncInit) {
            // Wait a bit and check if FB is ready
            setTimeout(() => {
              if (window.FB) {
                resolve()
              } else {
                reject(new Error('Facebook SDK already initializing'))
              }
            }, 1000)
            return
          }

          window.fbAsyncInit = function() {
            try {
              window.FB.init({
                appId: facebookAppId,
                cookie: true,
                xfbml: true,
                version: 'v18.0'
              })
              resolve()
            } catch (error) {
              reject(error)
            }
          }

          const script = document.createElement('script')
          script.src = 'https://connect.facebook.net/en_US/sdk.js'
          script.async = true
          script.defer = true
          
          script.onload = () => {
            // Wait for FB to be ready
            let attempts = 0
            const checkFB = setInterval(() => {
              attempts++
              if (window.FB && typeof window.FB.init === 'function') {
                clearInterval(checkFB)
                // FB.init should have been called by fbAsyncInit
                if (window.FB.getAuthResponse) {
                  resolve()
                } else {
                  // Wait a bit more for full initialization
                  setTimeout(resolve, 500)
                }
              } else if (attempts > 100) {
                clearInterval(checkFB)
                reject(new Error('Facebook SDK initialization timeout'))
              }
            }, 100)
          }
          
          script.onerror = () => {
            reject(new Error('Failed to load Facebook script'))
          }
          
          document.head.appendChild(script)
          
          // Timeout after 10 seconds
          setTimeout(() => {
            if (!window.FB) {
              reject(new Error('Timeout loading Facebook script'))
            }
          }, 10000)
        })
      }

      // Ensure FB is ready
      if (!window.FB || typeof window.FB.login !== 'function') {
        throw new Error('Facebook SDK not ready')
      }

      // Perform login
      await _performFacebookLogin()
    } catch (error) {
      console.error('Facebook login error:', error)
      toast.error('Lỗi khởi tạo Facebook đăng nhập. Vui lòng thử lại sau.', {
        duration: 4000
      })
      setIsLoading(false)
    }
  }

  const _performFacebookLogin = () => {
    return new Promise((resolve, reject) => {
      try {
        // Login with Facebook - wrap callback in regular function, not async
        window.FB.login((response) => {
          // Handle response in async function
          const handleResponse = async () => {
            if (response.authResponse) {
              try {
                const { facebookLogin } = useAuthStore.getState()
                const result = await facebookLogin(response.authResponse.accessToken)
                
                if (result.success) {
                  const { user } = useAuthStore.getState()
                  let roleMessage = ''
                  if (user?.role === 'admin') {
                    roleMessage = ' (Quản trị viên)'
                  } else if (user?.role === 'hotel_manager') {
                    roleMessage = ' (Quản lý khách sạn)'
                  }
                  
                  toast.success(`Chào mừng ${user?.ho_ten || user?.hoTen || 'bạn'}${roleMessage}!`)
                  
                  if (user?.role === 'admin') {
                    navigate('/admin')
                  } else if (user?.role === 'hotel_manager') {
                    navigate('/manager-hotel')
                  } else {
                    navigate('/')
                  }
                  resolve()
                } else {
                  toast.error(result.error || 'Đăng nhập Facebook thất bại')
                  reject(new Error(result.error || 'Đăng nhập Facebook thất bại'))
                }
              } catch (error) {
                console.error('Facebook login processing error:', error)
                toast.error('Lỗi xử lý đăng nhập Facebook. Vui lòng thử lại.')
                reject(error)
              } finally {
                setIsLoading(false)
              }
            } else {
              if (response.status !== 'unknown') {
                toast.error('Đăng nhập Facebook bị hủy hoặc thất bại')
              }
              setIsLoading(false)
              reject(new Error('Facebook login cancelled or failed'))
            }
          }
          
          // Call async handler
          handleResponse().catch(reject)
        }, { scope: 'email,public_profile' })
      } catch (error) {
        console.error('Facebook login init error:', error)
        toast.error('Lỗi khởi tạo Facebook login. Vui lòng thử lại.')
        setIsLoading(false)
        reject(error)
      }
    })
  }

  const handleGuestMode = () => {
    navigate('/')
  }

  // Check if social logins are configured
  // Google uses Firebase (no need for separate Client ID)
  // Facebook still needs App ID
  const facebookAppId = import.meta.env.VITE_FACEBOOK_APP_ID
  const isGoogleEnabled = getFirebaseAuth() !== null // Firebase is configured
  const isFacebookEnabled = facebookAppId && facebookAppId !== 'YOUR_FACEBOOK_APP_ID'

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-500 via-blue-400 to-blue-600 flex items-center justify-center py-8">
      <div className="max-w-md w-full mx-auto px-6">
        {/* Back Button */}
        <button
          onClick={() => navigate('/')}
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
          <div className="inline-flex items-center justify-center w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full mb-4 shadow-lg">
            <span className="text-4xl">🏨</span>
          </div>
          <h1 className="text-3xl font-bold text-white mb-2 drop-shadow-lg">
            TripHotel
          </h1>
          <p className="text-white/90 text-base font-medium">
            Đăng nhập để tiếp tục
          </p>
        </motion.div>

        {/* Login Form Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="bg-white rounded-2xl shadow-2xl p-6 mb-6 backdrop-blur-sm"
        >
          <h2 className="text-2xl font-bold text-gray-800 text-center mb-6">
            Đăng nhập
          </h2>

          <form onSubmit={handleEmailLogin} className="space-y-4">
            {/* Email Field */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Email
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Mail className="w-5 h-5 text-gray-400" />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Nhập email của bạn"
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none bg-gray-50 transition-all hover:border-gray-400"
                  required
                  disabled={isLoading}
                />
              </div>
            </div>

            {/* Password Field */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Mật khẩu
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="w-5 h-5 text-gray-400" />
                </div>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Nhập mật khẩu"
                  className="w-full pl-10 pr-12 py-3 border border-gray-300 rounded-xl focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none bg-gray-50 transition-all hover:border-gray-400"
                  required
                  disabled={isLoading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? (
                    <EyeOff className="w-5 h-5" />
                  ) : (
                    <Eye className="w-5 h-5" />
                  )}
                </button>
              </div>
            </div>

            {/* Forgot Password */}
            <div className="text-right">
              <button
                type="button"
                onClick={() => toast.info('Tính năng quên mật khẩu đang phát triển')}
                className="text-sm text-blue-600 hover:text-blue-700 font-medium"
              >
                Quên mật khẩu?
              </button>
            </div>

            {/* Login Buttons */}
            <div className="space-y-3">
              {/* Password Login Button */}
              <button
                type="submit"
                disabled={isLoading || !email.trim() || !password.trim()}
                className="w-full bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white py-4 px-4 rounded-xl font-semibold text-base transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-md hover:shadow-lg transform hover:scale-[1.01] active:scale-[0.99]"
              >
                {isLoading ? (
                  <div className="flex items-center justify-center">
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                    Đang đăng nhập...
                  </div>
                ) : (
                  'Đăng nhập với mật khẩu'
                )}
              </button>

              {/* OTP Login Button */}
              <button
                type="button"
                onClick={handleOTPLogin}
                disabled={isLoading}
                className="w-full border-2 border-blue-600 text-blue-600 hover:bg-blue-50 active:bg-blue-100 py-4 px-4 rounded-xl font-semibold text-base transition-all disabled:opacity-50 disabled:cursor-not-allowed hover:border-blue-700"
              >
                Đăng nhập với mã OTP
              </button>
            </div>
          </form>
        </motion.div>

        {/* Social Login Buttons */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="mb-6"
        >
          {/* Separator - Only show if at least one social login is enabled */}
          {(isGoogleEnabled || isFacebookEnabled) && (
            <div className="flex items-center mb-6">
              <div className="flex-1 border-t border-white/30"></div>
              <span className="px-4 text-white/90 text-sm font-medium">Hoặc đăng nhập với</span>
              <div className="flex-1 border-t border-white/30"></div>
            </div>
          )}

          {/* Social Buttons */}
          <div className={`grid gap-4 ${isGoogleEnabled && isFacebookEnabled ? 'grid-cols-2' : 'grid-cols-1'}`}>
            {/* Google Button */}
            {isGoogleEnabled ? (
              <button
                onClick={handleGoogleLogin}
                disabled={isLoading}
                className="bg-white hover:bg-gray-50 active:bg-gray-100 text-gray-800 py-3.5 px-4 rounded-xl flex items-center justify-center transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-md hover:shadow-lg transform hover:scale-[1.02] active:scale-[0.98] border border-gray-200"
              >
                <svg className="w-6 h-6 mr-3" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                </svg>
                <span className="font-semibold text-base">Google</span>
              </button>
            ) : null}

            {/* Facebook Button */}
            {isFacebookEnabled ? (
              <button
                onClick={handleFacebookLogin}
                disabled={isLoading}
                className="bg-[#1877F2] hover:bg-[#166FE5] active:bg-[#1460CC] text-white py-3.5 px-4 rounded-xl flex items-center justify-center transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-md hover:shadow-lg transform hover:scale-[1.02] active:scale-[0.98]"
              >
                <svg className="w-6 h-6 mr-3" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                </svg>
                <span className="font-semibold text-base">Facebook</span>
              </button>
            ) : null}
          </div>
        </motion.div>

        {/* Register Link */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="text-center mb-6"
        >
          <p className="text-white/90 mb-2">
            Chưa có tài khoản?{' '}
            <Link
              to="/register"
              className="text-white font-bold underline hover:text-white/80"
            >
              Đăng ký ngay
            </Link>
          </p>
        </motion.div>

        {/* Guest Mode Button */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="text-center"
        >
          <button
            onClick={handleGuestMode}
            className="inline-flex items-center px-6 py-3 border-2 border-white/50 text-white rounded-full hover:bg-white/10 transition-colors"
          >
            <span className="mr-2">👤</span>
            <span className="font-medium">Tiếp tục với tư cách khách</span>
          </button>
        </motion.div>

        {/* Legal Text */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.5 }}
          className="text-center text-xs text-white/70 leading-relaxed mt-6"
        >
          <p>
            Khi đăng nhập, tôi đồng ý với các{' '}
            <span className="text-white underline cursor-pointer">
              Điều khoản sử dụng
            </span>{' '}
            và{' '}
            <span className="text-white underline cursor-pointer">
              Chính sách bảo mật
            </span>{' '}
            của TripHotel.
          </p>
        </motion.div>
      </div>
    </div>
  )
}

export default LoginPage