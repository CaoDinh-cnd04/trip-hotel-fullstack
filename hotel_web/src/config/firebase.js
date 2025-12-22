import { initializeApp, getApps } from 'firebase/app'
import { getAuth, connectAuthEmulator } from 'firebase/auth'
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore'
import { getStorage, connectStorageEmulator } from 'firebase/storage'
import { getAnalytics, isSupported } from 'firebase/analytics'

/**
 * Firebase Configuration
 * 
 * Cấu hình Firebase cho web app (trip-hotel project)
 * Sử dụng environment variables hoặc fallback values từ Firebase Console
 */
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'AIzaSyDg2UZEDkOmwTk-cVQD65x1qs8CgQxr-_g',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'trip-hotel.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'trip-hotel',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || 'trip-hotel.firebasestorage.app',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '871253844733',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '1:871253844733:web:f149b203944dfe72559494',
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID || 'G-PJWD3HBXDR'
}

// Initialize Firebase App (only if not already initialized)
let app = null
let auth = null
let db = null
let storage = null
let analytics = null

try {
  // Check if Firebase is already initialized
  const existingApps = getApps()
  if (existingApps.length === 0) {
    // Initialize Firebase App
    app = initializeApp(firebaseConfig)
    console.log('🔥 Firebase App initialized successfully')
    
    // Initialize Firebase Auth
    auth = getAuth(app)
    
    // Connect to Auth Emulator in development (if configured)
    if (import.meta.env.VITE_FIREBASE_AUTH_EMULATOR_HOST) {
      const [host, port] = import.meta.env.VITE_FIREBASE_AUTH_EMULATOR_HOST.split(':')
      connectAuthEmulator(auth, `http://${host}:${port}`, { disableWarnings: true })
      console.log('🔧 Connected to Firebase Auth Emulator')
    }
    
    // Initialize Firestore
    db = getFirestore(app)
    
    // Connect to Firestore Emulator in development (if configured)
    if (import.meta.env.VITE_FIREBASE_FIRESTORE_EMULATOR_HOST) {
      const [host, port] = import.meta.env.VITE_FIREBASE_FIRESTORE_EMULATOR_HOST.split(':')
      connectFirestoreEmulator(db, host, parseInt(port))
      console.log('🔧 Connected to Firestore Emulator')
    }
    
    // Initialize Firebase Storage
    storage = getStorage(app)
    
    // Connect to Storage Emulator in development (if configured)
    if (import.meta.env.VITE_FIREBASE_STORAGE_EMULATOR_HOST) {
      const [host, port] = import.meta.env.VITE_FIREBASE_STORAGE_EMULATOR_HOST.split(':')
      connectStorageEmulator(storage, host, parseInt(port))
      console.log('🔧 Connected to Storage Emulator')
    }
    
    // Initialize Analytics (only if supported and measurementId is provided)
    if (firebaseConfig.measurementId) {
      isSupported().then((supported) => {
        if (supported) {
          analytics = getAnalytics(app)
          console.log('📊 Firebase Analytics initialized')
        } else {
          console.log('⚠️ Firebase Analytics not supported in this environment')
        }
      }).catch((error) => {
        console.warn('⚠️ Firebase Analytics initialization failed:', error)
      })
    }
    
  } else {
    // Use existing app instance
    app = existingApps[0]
    auth = getAuth(app)
    db = getFirestore(app)
    storage = getStorage(app)
    
    // Initialize Analytics if not already done
    if (firebaseConfig.measurementId && !analytics) {
      isSupported().then((supported) => {
        if (supported) {
          analytics = getAnalytics(app)
          console.log('📊 Firebase Analytics initialized')
        }
      }).catch((error) => {
        console.warn('⚠️ Firebase Analytics initialization failed:', error)
      })
    }
    
    console.log('🔥 Using existing Firebase App instance')
  }
} catch (error) {
  console.error('❌ Firebase initialization failed:', error)
  console.warn('⚠️ Firebase services will not be available')
  // Set to null so components can check if Firebase is available
  app = null
  auth = null
  db = null
  storage = null
  analytics = null
}

/**
 * Check if Firebase is initialized and available
 * @returns {boolean} True if Firebase is initialized
 */
export const isFirebaseInitialized = () => {
  return app !== null && auth !== null
}

/**
 * Get Firebase App instance
 * @returns {FirebaseApp | null} Firebase app instance or null if not initialized
 */
export const getFirebaseApp = () => app

/**
 * Get Firebase Auth instance
 * @returns {Auth | null} Firebase Auth instance or null if not initialized
 */
export const getFirebaseAuth = () => auth

/**
 * Get Firestore instance
 * @returns {Firestore | null} Firestore instance or null if not initialized
 */
export const getFirebaseFirestore = () => db

/**
 * Get Firebase Storage instance
 * @returns {Storage | null} Firebase Storage instance or null if not initialized
 */
export const getFirebaseStorage = () => storage

/**
 * Get Firebase Analytics instance
 * @returns {Analytics | null} Analytics instance or null if not initialized
 */
export const getFirebaseAnalytics = () => analytics

// Export default instances for backward compatibility
export { auth, db as firestore, storage, analytics }
export default app
