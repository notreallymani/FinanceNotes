const admin = require('firebase-admin');
const config = require('../config');
const path = require('path');
const fs = require('fs');
const axios = require('axios');
const { GoogleAuth } = require('google-auth-library');

let firebaseAdminInitialized = false;

/**
 * Initialize Firebase Admin SDK
 * Uses the same service account key file as GCP Storage
 */
function initializeFirebaseAdmin() {
  if (firebaseAdminInitialized) {
    return admin.app();
  }

  try {
    // Use the same service account key file as GCP Storage
    const keyFilePath = path.resolve(__dirname, '../../', config.gcpStorageKeyFile);
    
    if (!fs.existsSync(keyFilePath)) {
      throw new Error(`Firebase service account key file not found: ${keyFilePath}`);
    }

    const serviceAccount = require(keyFilePath);

    // Initialize Firebase Admin if not already initialized
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id || config.gcpProjectId,
      });
      console.log('[Firebase Admin] Initialized successfully');
    }

    firebaseAdminInitialized = true;
    return admin.app();
  } catch (error) {
    console.error('[Firebase Admin] Initialization error:', error.message);
    throw error;
  }
}

/**
 * Get Firebase Admin instance
 */
function getFirebaseAdmin() {
  if (!firebaseAdminInitialized) {
    initializeFirebaseAdmin();
  }
  return admin;
}

/**
 * Send password reset email using Firebase Identity Toolkit REST API
 * 
 * PRODUCTION-READY: This uses Firebase's configured email template and automatically
 * sends the email via Firebase's email service. The email will use the template
 * configured in Firebase Console:
 * - Sender name: "Finance Notes"
 * - From: noreply@financenotes-11ff0.firebaseapp.com
 * - Subject: "Reset your password for Finance Notes"
 * - Message: Uses the template you configured
 * 
 * Note: This requires the user to exist in Firebase Auth.
 */
async function sendPasswordResetEmail(email) {
  try {
    const admin = getFirebaseAdmin();
    
    // Check if user exists in Firebase Auth first
    try {
      await admin.auth().getUserByEmail(email);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // User doesn't exist in Firebase Auth
        throw new Error('User not found in Firebase Auth');
      }
      throw error;
    }
    
    // Get service account and project details
    const serviceAccount = require(path.resolve(__dirname, '../../', config.gcpStorageKeyFile));
    const projectId = serviceAccount.project_id || config.gcpProjectId;
    
    // Get access token using service account for Identity Toolkit API
    const auth = new GoogleAuth({
      keyFile: path.resolve(__dirname, '../../', config.gcpStorageKeyFile),
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
    
    const client = await auth.getClient();
    const accessTokenResponse = await client.getAccessToken();
    
    if (!accessTokenResponse.token) {
      throw new Error('Failed to get access token for Firebase API');
    }
    
    const accessToken = accessTokenResponse.token;
    
    // Continue URL - where user will be redirected after resetting password
    // This should point to your app's password reset page
    const continueUrl = config.clientOrigin 
      ? `${config.clientOrigin}/reset-password`
      : 'https://financenotes-11ff0.firebaseapp.com/__/auth/action';
    
    // Use Firebase Identity Toolkit REST API to send password reset email
    // This will automatically use the email template configured in Firebase Console
    const identityToolkitUrl = `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:sendOobCode`;
    
    try {
      const response = await axios.post(
        identityToolkitUrl,
        {
          requestType: 'PASSWORD_RESET',
          email: email,
          continueUrl: continueUrl,
        },
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
        }
      );
      
      // Success - Firebase has sent the email using your configured template
      console.log(`[Firebase Admin] ✅ Password reset email sent successfully to: ${email}`);
      console.log(`[Firebase Admin] Email template: "Finance Notes" (configured in Firebase Console)`);
      
      return { 
        success: true, 
        email: email 
      };
      
    } catch (apiError) {
      // Handle API errors
      if (apiError.response) {
        const errorData = apiError.response.data?.error || {};
        const errorCode = errorData.message || errorData.code;
        const errorStatus = apiError.response.status;
        
        console.error(`[Firebase Admin] ❌ API Error (${errorStatus}):`, errorCode);
        
        // Handle specific Firebase errors
        if (errorCode === 'EMAIL_NOT_FOUND' || 
            errorCode === 'USER_NOT_FOUND' ||
            errorCode?.includes('USER_NOT_FOUND')) {
          throw new Error('User not found in Firebase Auth');
        }
        
        if (errorCode === 'INVALID_EMAIL' || errorCode?.includes('INVALID_EMAIL')) {
          throw new Error('Invalid email address');
        }
        
        // Permission errors
        if (errorStatus === 403 || errorCode?.includes('PERMISSION_DENIED')) {
          throw new Error('Firebase Admin does not have permission to send password reset emails. Check service account permissions.');
        }
        
        throw new Error(`Firebase API error: ${errorCode || apiError.message}`);
      }
      
      throw apiError;
    }
    
  } catch (error) {
    console.error('[Firebase Admin] ❌ Password reset error:', error.message);
    throw error;
  }
}

/**
 * Create user in Firebase Auth (if they don't exist)
 * This is needed if users are only stored in MongoDB
 */
async function createFirebaseUser(email, password) {
  try {
    const admin = getFirebaseAdmin();
    
    try {
      // Check if user already exists
      await admin.auth().getUserByEmail(email);
      // User exists, return
      return;
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // User doesn't exist, create them
        await admin.auth().createUser({
          email: email,
          password: password,
          emailVerified: false,
        });
        console.log(`[Firebase Admin] Created user in Firebase Auth: ${email}`);
      } else {
        throw error;
      }
    }
  } catch (error) {
    console.error('[Firebase Admin] Create user error:', error.message);
    throw error;
  }
}

module.exports = {
  initializeFirebaseAdmin,
  getFirebaseAdmin,
  sendPasswordResetEmail,
  createFirebaseUser,
};


