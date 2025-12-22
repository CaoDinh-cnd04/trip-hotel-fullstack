import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { authAPI } from '../services/api/user'
import axios from 'axios'
import { getFirebaseAuth } from '../config/firebase'
import { signInWithEmailAndPassword, createUserWithEmailAndPassword } from 'firebase/auth'

// Use real API for production
const API = authAPI

const useAuthStore = create(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isLoading: false,
      error: null,

      // Actions
      login: async (credentials) => {
        set({ isLoading: true, error: null })
        try {
          const response = await API.login(credentials)
          const { user, token, role } = response.data

          // Add role info to user object
          const userWithRole = {
            ...user,
            role: role?.role || 'user',
            permissions: role?.permissions || [],
            hotel_id: role?.hotel_id
          }

          set({ 
            user: userWithRole, 
            token, 
            isLoading: false, 
            error: null 
          })

          // Store token in localStorage for API requests
          localStorage.setItem('auth_token', token)
          
          // Authenticate with Firebase for Firestore access
          // Try custom token first, then fallback to email/password
          try {
            if (response.data.firebase_custom_token) {
              // Use custom token from backend (preferred)
              const { authenticateWithFirebaseCustomToken } = await import('../utils/firebaseAuth')
              await authenticateWithFirebaseCustomToken(response.data.firebase_custom_token)
              console.log('✅ Authenticated with Firebase using custom token')
            } else {
              // Fallback to email/password authentication
              await authenticateWithFirebaseForFirestore(userWithRole.email, credentials.mat_khau)
            }
          } catch (error) {
            console.warn('⚠️ Firebase authentication failed (non-critical):', error.message)
            // Continue even if Firebase auth fails - app can use offline placeholder
          }
          
          // Initialize notifications after login
          try {
            const { useNotificationsStore } = await import('./notificationsStore')
            const notificationsStore = useNotificationsStore.getState()
            if (notificationsStore.initialize) {
              await notificationsStore.initialize()
            }
          } catch (error) {
            console.error('Error initializing notifications:', error)
          }
          
          return { success: true, user: userWithRole }
        } catch (error) {
          const errorMessage = error.response?.data?.message || error.message || 'Đăng nhập thất bại'
          set({ 
            error: errorMessage, 
            isLoading: false 
          })
          return { success: false, error: errorMessage }
        }
      },

      register: async (userData) => {
        set({ isLoading: true, error: null })
        try {
          const response = await API.register(userData)
          const { user, token, role, firebase_custom_token } = response.data

          // Add role info to user object
          const userWithRole = {
            ...user,
            role: role?.role || 'user',
            permissions: role?.permissions || [],
            hotel_id: role?.hotel_id
          }

          set({ 
            user: userWithRole, 
            token, 
            isLoading: false, 
            error: null 
          })

          localStorage.setItem('auth_token', token)
          
          // Authenticate with Firebase if custom token is provided
          if (firebase_custom_token) {
            try {
              const { authenticateWithFirebaseCustomToken } = await import('../utils/firebaseAuth')
              await authenticateWithFirebaseCustomToken(firebase_custom_token)
              console.log('✅ Firebase authenticated after registration')
            } catch (firebaseError) {
              console.warn('⚠️ Firebase authentication failed (non-critical):', firebaseError.message)
              // Continue without Firebase auth - user can still use the app
            }
          } else {
            // Try to authenticate with email/password as fallback
            try {
              const { authenticateWithFirebaseEmail } = await import('../utils/firebaseAuth')
              await authenticateWithFirebaseEmail(userData.email, userData.mat_khau)
              console.log('✅ Firebase authenticated with email/password after registration')
            } catch (firebaseError) {
              console.warn('⚠️ Firebase email authentication failed (non-critical):', firebaseError.message)
            }
          }
          
          // Initialize notifications after register
          try {
            const { useNotificationsStore } = await import('./notificationsStore')
            const notificationsStore = useNotificationsStore.getState()
            if (notificationsStore.initialize) {
              await notificationsStore.initialize()
            }
          } catch (error) {
            console.error('Error initializing notifications:', error)
          }
          
          return { success: true, user: userWithRole }
        } catch (error) {
          const errorMessage = error.response?.data?.message || error.message || 'Đăng ký thất bại'
          set({ 
            error: errorMessage, 
            isLoading: false 
          })
          return { success: false, error: errorMessage }
        }
      },

      logout: async () => {
        try {
          await authAPI.logout()
        } catch (error) {
          console.error('Logout error:', error)
        } finally {
          set({ 
            user: null, 
            token: null, 
            error: null 
          })
          localStorage.removeItem('auth_token')
        }
      },

      clearError: () => set({ error: null }),

      // OTP Login
      sendOTP: async (email) => {
        set({ isLoading: true, error: null })
        try {
          const response = await API.sendOTP(email)
          if (response.data.success) {
            return { success: true, message: response.data.message || 'Mã OTP đã được gửi' }
          } else {
            const errorMessage = response.data.message || 'Gửi OTP thất bại'
            set({ error: errorMessage, isLoading: false })
            return { success: false, error: errorMessage }
          }
        } catch (error) {
          const errorMessage = error.response?.data?.message || error.message || 'Gửi OTP thất bại'
          set({ error: errorMessage, isLoading: false })
          return { success: false, error: errorMessage }
        } finally {
          set({ isLoading: false })
        }
      },

      verifyOTPLogin: async (email, otp) => {
        set({ isLoading: true, error: null })
        try {
          const response = await API.verifyOTP(email, otp)
          
          if (response.data.success) {
            const { user, token, role } = response.data

            // Debug logging
            console.log('🔍 verifyOTPLogin - Response data:', {
              user,
              role,
              roleType: typeof role,
              roleRole: role?.role
            })

            const userWithRole = {
              ...user,
              role: role?.role || 'user',
              permissions: role?.permissions || [],
              hotel_id: role?.hotel_id
            }

            console.log('🔍 verifyOTPLogin - User with role:', userWithRole)
            console.log('🔍 verifyOTPLogin - Final role:', userWithRole.role)

            set({ 
              user: userWithRole, 
              token, 
              isLoading: false, 
              error: null 
            })

            localStorage.setItem('auth_token', token)
            
            // Authenticate with Firebase for Firestore access using custom token
            try {
              if (response.data.firebase_custom_token) {
                const { authenticateWithFirebaseCustomToken } = await import('../utils/firebaseAuth')
                await authenticateWithFirebaseCustomToken(response.data.firebase_custom_token)
                console.log('✅ Authenticated with Firebase using custom token for OTP user')
              } else {
                // Fallback: try to create Firebase account or use existing
                await authenticateFirebaseForOTPUser(userWithRole.email, userWithRole.id)
              }
            } catch (error) {
              console.warn('⚠️ Firebase authentication for OTP user failed (non-critical):', error.message)
              // Continue even if Firebase auth fails
            }
            
            // Initialize notifications after login
            try {
              const { useNotificationsStore } = await import('./notificationsStore')
              const notificationsStore = useNotificationsStore.getState()
              if (notificationsStore.initialize) {
                await notificationsStore.initialize()
              }
            } catch (error) {
              console.error('Error initializing notifications:', error)
            }
            
            return { success: true, user: userWithRole }
          } else {
            const errorMessage = response.data.message || 'Xác thực OTP thất bại'
            set({ error: errorMessage, isLoading: false })
            return { success: false, error: errorMessage }
          }
        } catch (error) {
          const errorMessage = error.response?.data?.message || error.message || 'Xác thực OTP thất bại'
          set({ error: errorMessage, isLoading: false })
          return { success: false, error: errorMessage }
        }
      },

      // Firebase Google Login (using Firebase Authentication)
      firebaseGoogleLogin: async (firebaseUserData) => {
        set({ isLoading: true, error: null })
        try {
          // Send Firebase user data to backend
          const response = await API.firebaseSocialLogin(firebaseUserData)

          if (response.data.success) {
            const { user, token, role } = response.data

            const userWithRole = {
              ...user,
              role: role?.role || 'user',
              permissions: role?.permissions || [],
              hotel_id: role?.hotel_id
            }

            set({ 
              user: userWithRole, 
              token, 
              isLoading: false, 
              error: null 
            })

            localStorage.setItem('auth_token', token)
            
            // Initialize notifications after login
            try {
              const { useNotificationsStore } = await import('./notificationsStore')
              const notificationsStore = useNotificationsStore.getState()
              if (notificationsStore.initialize) {
                await notificationsStore.initialize()
              }
            } catch (error) {
              console.error('Error initializing notifications:', error)
            }
            
            return { success: true, user: userWithRole }
          } else {
            const errorMessage = response.data.message || 'Đăng nhập Google thất bại'
            set({ error: errorMessage, isLoading: false })
            return { success: false, error: errorMessage }
          }
        } catch (error) {
          const errorMessage = error.response?.data?.message || error.message || 'Đăng nhập Google thất bại'
          set({ error: errorMessage, isLoading: false })
          return { success: false, error: errorMessage }
        }
      },

      // Facebook Login
      facebookLogin: async (accessToken) => {
        set({ isLoading: true, error: null })
        try {
          const response = await API.facebookLogin(accessToken)
          
          if (response.data.success) {
            const { user, token, role } = response.data

            const userWithRole = {
              ...user,
              role: role?.role || 'user',
              permissions: role?.permissions || [],
              hotel_id: role?.hotel_id
            }

            set({ 
              user: userWithRole, 
              token, 
              isLoading: false, 
              error: null 
            })

            localStorage.setItem('auth_token', token)
            
            // Initialize notifications after login
            try {
              const { useNotificationsStore } = await import('./notificationsStore')
              const notificationsStore = useNotificationsStore.getState()
              if (notificationsStore.initialize) {
                await notificationsStore.initialize()
              }
            } catch (error) {
              console.error('Error initializing notifications:', error)
            }
            
            return { success: true, user: userWithRole }
          } else {
            const errorMessage = response.data.message || 'Đăng nhập Facebook thất bại'
            set({ error: errorMessage, isLoading: false })
            return { success: false, error: errorMessage }
          }
        } catch (error) {
          const errorMessage = error.response?.data?.message || error.message || 'Đăng nhập Facebook thất bại'
          set({ error: errorMessage, isLoading: false })
          return { success: false, error: errorMessage }
        }
      },

      // Utility methods
      isAuthenticated: () => {
        const state = get()
        return !!state.user && !!state.token
      },

      isAdmin: () => {
        const state = get()
        return state.user?.role === 'admin' || state.user?.chuc_vu === 'Admin'
      },

      isHotelManager: () => {
        const state = get()
        return state.user?.role === 'hotel_manager' || state.user?.chuc_vu === 'HotelManager'
      },

      isUser: () => {
        const state = get()
        return state.user?.chuc_vu === 'User'
      },

      hasRole: (role) => {
        const state = get()
        return state.user?.chuc_vu === role
      },

      // Update user profile
      updateUser: (userData) => {
        set(state => ({
          user: { ...state.user, ...userData }
        }))
      },

      // Initialize from localStorage
      initializeAuth: () => {
        const token = localStorage.getItem('auth_token')
        if (token) {
          set({ token })
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ 
        user: state.user, 
        token: state.token 
      }),
    }
  )
)

/**
 * Helper function to authenticate OTP user with Firebase
 * Since OTP users don't have password, we create Firebase account with email
 * and use a temporary password that matches the backend password hash pattern
 */
const authenticateFirebaseForOTPUser = async (email, userId) => {
  const auth = getFirebaseAuth()
  if (!auth) {
    console.warn('⚠️ Firebase Auth not initialized')
    return null
  }

  try {
    // Check if Firebase user already exists
    const firebaseUser = getCurrentFirebaseUser()
    if (firebaseUser && firebaseUser.email === email) {
      console.log('✅ Already authenticated with Firebase:', firebaseUser.uid)
      return firebaseUser
    }

    // For OTP users, we need to create Firebase account
    // Since we don't have password, we'll use a pattern: email + userId hash
    // This is a temporary solution - ideally backend should provide custom token
    const tempPassword = `otp_${userId}_${Date.now()}_temp`
    
    try {
      // Try to create Firebase account
      const userCredential = await createUserWithEmailAndPassword(auth, email, tempPassword)
      console.log('✅ Created Firebase account for OTP user:', userCredential.user.uid)
      
      // Save Firebase UID to user_mapping in Firestore
      try {
        const { getFirebaseFirestore } = await import('../config/firebase')
        const { doc, setDoc, serverTimestamp } = await import('firebase/firestore')
        const db = getFirebaseFirestore()
        if (db) {
          await setDoc(doc(db, 'user_mapping', userId.toString()), {
            firebase_uid: userCredential.user.uid,
            email: email.toLowerCase(),
            auth_method: 'otp',
            updated_at: serverTimestamp()
          }, { merge: true })
          console.log('✅ Saved Firebase UID mapping for OTP user')
        }
      } catch (mappingError) {
        console.warn('⚠️ Failed to save Firebase UID mapping:', mappingError)
      }
      
      return userCredential.user
    } catch (createError) {
      // If user already exists, try to sign in with email
      if (createError.code === 'auth/email-already-in-use') {
        console.log('ℹ️ Firebase user already exists, trying to sign in...')
        // Note: We can't sign in without password, so we'll need backend to provide custom token
        // For now, return null and let the app use offline placeholder
        console.warn('⚠️ Firebase user exists but no password available. Backend should provide custom token.')
        return null
      }
      throw createError
    }
  } catch (error) {
    console.warn('⚠️ Firebase authentication for OTP user failed:', error.message)
    throw error
  }
}

/**
 * Helper function to authenticate with Firebase after backend login
 * This is needed for Firestore access
 */
const authenticateWithFirebaseForFirestore = async (email, password) => {
  const auth = getFirebaseAuth()
  if (!auth) {
    console.warn('⚠️ Firebase Auth not initialized')
    return null
  }

  try {
    // Try to sign in with email/password
    const userCredential = await signInWithEmailAndPassword(auth, email, password)
    console.log('✅ Authenticated with Firebase for Firestore:', userCredential.user.uid)
    
    // Save Firebase UID to user_mapping in Firestore
    try {
      const { getFirebaseFirestore } = await import('../config/firebase')
      const { doc, setDoc, serverTimestamp } = await import('firebase/firestore')
      const db = getFirebaseFirestore()
      if (db) {
        const { user } = useAuthStore.getState()
        if (user?.id) {
          await setDoc(doc(db, 'user_mapping', user.id.toString()), {
            firebase_uid: userCredential.user.uid,
            email: email.toLowerCase(),
            updated_at: serverTimestamp()
          }, { merge: true })
          console.log('✅ Saved Firebase UID mapping')
        }
      }
    } catch (mappingError) {
      console.warn('⚠️ Failed to save Firebase UID mapping:', mappingError)
    }
    
    return userCredential.user
  } catch (error) {
    // If user doesn't exist in Firebase, try to create account
    if (error.code === 'auth/user-not-found' || error.code === 'auth/invalid-credential') {
      try {
        console.log('ℹ️ Firebase user not found, creating new account...')
        const userCredential = await createUserWithEmailAndPassword(auth, email, password)
        console.log('✅ Created and authenticated Firebase user:', userCredential.user.uid)
        
        // Save Firebase UID to user_mapping in Firestore
        try {
          const { getFirebaseFirestore } = await import('../config/firebase')
          const { doc, setDoc, serverTimestamp } = await import('firebase/firestore')
          const db = getFirebaseFirestore()
          if (db) {
            const { user } = useAuthStore.getState()
            if (user?.id) {
              await setDoc(doc(db, 'user_mapping', user.id.toString()), {
                firebase_uid: userCredential.user.uid,
                email: email.toLowerCase(),
                updated_at: serverTimestamp()
              }, { merge: true })
              console.log('✅ Saved Firebase UID mapping for new user')
            }
          }
        } catch (mappingError) {
          console.warn('⚠️ Failed to save Firebase UID mapping:', mappingError)
        }
        
        return userCredential.user
      } catch (createError) {
        console.warn('⚠️ Failed to create Firebase user:', createError.message)
        throw createError
      }
    } else {
      console.warn('⚠️ Firebase authentication error:', error.message)
      throw error
    }
  }
}

export { useAuthStore }