/**
 * Firebase Admin SDK Service
 * 
 * Initialize Firebase Admin SDK for backend operations
 * Used to create custom tokens for user authentication
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let firebaseAdmin = null;

/**
 * Initialize Firebase Admin SDK
 * Uses service account from environment variables or service account file
 */
const initializeFirebaseAdmin = () => {
  if (firebaseAdmin) {
    return firebaseAdmin;
  }

  try {
    // Check if Firebase Admin is already initialized
    if (admin.apps.length > 0) {
      firebaseAdmin = admin.app();
      console.log('✅ Firebase Admin already initialized');
      return firebaseAdmin;
    }

    // Initialize Firebase Admin
    // Option 1: Use service account from environment variable (JSON string)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        firebaseAdmin = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
        console.log('✅ Firebase Admin initialized from environment variable');
        return firebaseAdmin;
      } catch (error) {
        console.warn('⚠️ Failed to parse FIREBASE_SERVICE_ACCOUNT:', error.message);
      }
    }

    // Option 2: Use service account file path from environment variable
    if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
      try {
        const serviceAccountPath = path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
        if (fs.existsSync(serviceAccountPath)) {
          firebaseAdmin = admin.initializeApp({
            credential: admin.credential.cert(serviceAccountPath)
          });
          console.log('✅ Firebase Admin initialized from service account file:', serviceAccountPath);
          return firebaseAdmin;
        } else {
          console.warn('⚠️ Service account file not found:', serviceAccountPath);
        }
      } catch (error) {
        console.warn('⚠️ Failed to initialize from service account file:', error.message);
      }
    }

    // Option 2b: Auto-detect service account file in config folder
    try {
      const configDir = path.join(__dirname, '..', 'config');
      const jsonFiles = fs.readdirSync(configDir).filter(file => 
        file.endsWith('.json') && file.includes('firebase-adminsdk')
      );
      
      if (jsonFiles.length > 0) {
        const serviceAccountPath = path.join(configDir, jsonFiles[0]);
        firebaseAdmin = admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath)
        });
        console.log('✅ Firebase Admin initialized from auto-detected file:', serviceAccountPath);
        return firebaseAdmin;
      }
    } catch (error) {
      // Ignore auto-detect errors
    }

    // Option 3: Use default credentials (for Firebase Cloud Functions, GCP, etc.)
    try {
      firebaseAdmin = admin.initializeApp();
      console.log('✅ Firebase Admin initialized with default credentials');
      return firebaseAdmin;
    } catch (error) {
      console.warn('⚠️ Failed to initialize with default credentials:', error.message);
    }

    // If all methods fail, log warning but don't throw error
    // App can still work without Firebase Admin (custom tokens won't work)
    console.warn('⚠️ Firebase Admin SDK not initialized. Custom tokens will not be available.');
    console.warn('💡 To enable custom tokens, set FIREBASE_SERVICE_ACCOUNT or FIREBASE_SERVICE_ACCOUNT_PATH in .env');
    
    return null;
  } catch (error) {
    console.error('❌ Error initializing Firebase Admin:', error);
    return null;
  }
};

/**
 * Create Firebase custom token for a user
 * @param {string|number} userId - Backend user ID
 * @param {string} email - User email
 * @param {object} additionalClaims - Additional claims (role, etc.)
 * @returns {Promise<string>} Custom token
 */
const createCustomToken = async (userId, email, additionalClaims = {}) => {
  try {
    const admin = initializeFirebaseAdmin();
    if (!admin) {
      throw new Error('Firebase Admin not initialized');
    }

    // Create custom token with user ID as UID
    const uid = userId.toString();
    const claims = {
      email: email,
      ...additionalClaims
    };

    const customToken = await admin.auth().createCustomToken(uid, claims);
    console.log(`✅ Created Firebase custom token for user ${uid} (${email})`);
    return customToken;
  } catch (error) {
    console.error('❌ Error creating Firebase custom token:', error);
    throw error;
  }
};

/**
 * Get Firebase Admin instance
 * @returns {admin.app.App|null} Firebase Admin app instance
 */
const getFirebaseAdmin = () => {
  return firebaseAdmin || initializeFirebaseAdmin();
};

module.exports = {
  initializeFirebaseAdmin,
  createCustomToken,
  getFirebaseAdmin
};

