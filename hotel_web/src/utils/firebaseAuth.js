/**
 * Firebase Authentication Helper
 * 
 * Authenticate user with Firebase after backend login
 * This is needed for Firestore access
 */

import { getFirebaseAuth } from '../config/firebase'
import { signInWithCustomToken, signInWithEmailAndPassword, createUserWithEmailAndPassword, onAuthStateChanged } from 'firebase/auth'

/**
 * Authenticate with Firebase using custom token from backend
 * @param {string} customToken - Custom token from backend
 * @returns {Promise<User>} Firebase user
 */
export const authenticateWithFirebaseCustomToken = async (customToken) => {
  const auth = getFirebaseAuth()
  if (!auth) {
    throw new Error('Firebase Auth is not initialized')
  }

  try {
    const userCredential = await signInWithCustomToken(auth, customToken)
    console.log('✅ Authenticated with Firebase:', userCredential.user.uid)
    return userCredential.user
  } catch (error) {
    console.error('❌ Firebase custom token authentication failed:', error)
    throw error
  }
}

/**
 * Authenticate with Firebase using email and password
 * This creates a Firebase Auth session for Firestore access
 * @param {string} email - User email
 * @param {string} password - User password (from backend login)
 * @returns {Promise<User>} Firebase user
 */
export const authenticateWithFirebaseEmail = async (email, password) => {
  const auth = getFirebaseAuth()
  if (!auth) {
    throw new Error('Firebase Auth is not initialized')
  }

  try {
    // Try to sign in with email/password
    const userCredential = await signInWithEmailAndPassword(auth, email, password)
    console.log('✅ Authenticated with Firebase email:', userCredential.user.uid)
    return userCredential.user
  } catch (error) {
    // If user doesn't exist in Firebase, try to create account
    if (error.code === 'auth/user-not-found' || error.code === 'auth/invalid-credential') {
      try {
        console.log('ℹ️ Firebase user not found, creating new account...')
        const userCredential = await createUserWithEmailAndPassword(auth, email, password)
        console.log('✅ Created and authenticated Firebase user:', userCredential.user.uid)
        return userCredential.user
      } catch (createError) {
        console.warn('⚠️ Failed to create Firebase user:', createError.message)
        throw createError
      }
    } else {
      console.warn('⚠️ Firebase email authentication failed:', error.message)
      throw error
    }
  }
}

/**
 * Get current Firebase Auth user
 * @returns {User | null} Current Firebase user or null
 */
export const getCurrentFirebaseUser = () => {
  const auth = getFirebaseAuth()
  if (!auth) {
    return null
  }
  return auth.currentUser
}

/**
 * Check if user is authenticated with Firebase
 * @returns {boolean} True if authenticated
 */
export const isFirebaseAuthenticated = () => {
  const auth = getFirebaseAuth()
  if (!auth) {
    return false
  }
  return auth.currentUser !== null
}

/**
 * Listen to Firebase Auth state changes
 * @param {Function} callback - Callback function (user) => void
 * @returns {Function} Unsubscribe function
 */
export const onFirebaseAuthStateChanged = (callback) => {
  const auth = getFirebaseAuth()
  if (!auth) {
    return () => {}
  }
  return onAuthStateChanged(auth, callback)
}

/**
 * Sign out from Firebase
 */
export const signOutFromFirebase = async () => {
  const auth = getFirebaseAuth()
  if (!auth) {
    return
  }
  
  try {
    await auth.signOut()
    console.log('✅ Signed out from Firebase')
  } catch (error) {
    console.error('❌ Firebase sign out failed:', error)
  }
}

