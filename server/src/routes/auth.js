const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const config = require('../config');
const auth = require('../middleware/auth');
const googleAuthService = require('../services/googleAuthService');
const jwtService = require('../services/jwtService');

const router = express.Router();

/**
 * Google OAuth Authentication Endpoint
 * 
 * Flow:
 * 1. Receives Google ID token from Flutter app
 * 2. Verifies token with Google using OAuth2Client
 * 3. Extracts user info (email, name, picture) from token
 * 4. Creates or finds user in database
 * 5. Returns JWT token for authenticated session
 * 
 * IMPORTANT: The idToken must be issued for the Web Client ID
 * (not Android Client ID) for this verification to work.
 */
router.post('/google', async (req, res) => {
  const logPrefix = '[POST /api/auth/google]';
  
  try {
    const { idToken } = req.body;
    
    // Validate request
    if (!idToken) {
      console.error(`${logPrefix} ERROR: idToken missing in request`);
      return res.status(400).json({ 
        message: 'Invalid request',
        error: 'idToken is required'
      });
    }
    
    console.log(`${logPrefix} Verifying token...`);
    console.log(`${logPrefix} Expected Client ID: ${config.googleClientId}`);
    
    // Step 1: Verify token
    const payload = await googleAuthService.verifyToken(idToken);
    console.log(`${logPrefix} Token verified successfully`);
    
    // Step 2: Extract user info
    const userInfo = googleAuthService.extractUserInfo(payload);
    console.log(`${logPrefix} User info extracted:`, {
      email: userInfo.email,
      name: userInfo.name,
      googleId: userInfo.googleId.substring(0, 10) + '...'
    });
    
    // Step 3: Find or create user
    let user = await User.findOne({ email: userInfo.email });
    
    if (!user) {
      console.log(`${logPrefix} Creating new user:`, userInfo.email);
      user = await User.create({
        name: userInfo.name,
        email: userInfo.email,
        picture: userInfo.picture,
        googleId: userInfo.googleId,
        provider: 'google',
      });
    } else {
      console.log(`${logPrefix} Existing user found:`, user.id);
      // Update Google ID if missing
      if (!user.googleId) {
        user.googleId = userInfo.googleId;
        await user.save();
      }
    }
    
    // Step 4: Generate JWT token
    const token = jwtService.generateToken(user);
    
    console.log(`${logPrefix} SUCCESS: User authenticated - ${user.email} (ID: ${user.id})`);
    
    return res.json({
      success: true,
      token,
      user: user.toJSON(),
    });
    
  } catch (error) {
    console.error(`${logPrefix} ERROR:`, error.message);
    
    // Handle known errors
    if (error.message === 'ID token is required' || error.message === 'Email missing in token payload') {
      return res.status(400).json({
        message: error.message,
        error: error.message,
      });
    }
    
    if (error.message === 'Google Client ID not configured') {
      return res.status(500).json({
        message: 'Google client not configured',
        error: error.message,
      });
    }
    
    // Token verification errors
    return res.status(401).json({
      message: 'Invalid Google token',
      error: error.message || 'Token verification failed',
      hint: error.hint || 'Check server logs for details',
      ...(config.env === 'development' && { stack: error.stack }),
    });
  }
});

/**
 * Email/Password Registration Endpoint
 * 
 * Allows users to register with email and password.
 * If user exists with Google auth only, allows adding password to same account.
 */
router.post('/email-register', async (req, res) => {
  const logPrefix = '[POST /api/auth/email-register]';
  
  try {
    const { name, email, password, phone } = req.body;
    
    // Validate required fields
    if (!name || !email || !password) {
      return res.status(400).json({ 
        message: 'Name, email and password are required' 
      });
    }

    const normalizedEmail = String(email).toLowerCase();
    const normalizedPhone = phone ? String(phone).trim() : '';

    // Check for duplicate phone number
    if (normalizedPhone) {
      const phoneUser = await User.findOne({ phone: normalizedPhone });
      if (phoneUser) {
        return res.status(400).json({ 
          message: 'This mobile number is already used by another profile' 
        });
      }
    }
    
    // Check if email already exists
    let existing = await User.findOne({ email: normalizedEmail });
    
    if (existing && existing.passwordHash) {
      return res.status(400).json({ 
        message: 'Email is already registered' 
      });
    }

    // If user exists but only has Google auth, allow adding password
    if (existing && !existing.passwordHash) {
      console.log(`${logPrefix} Adding password to existing Google account: ${normalizedEmail}`);
      existing.name = name;
      existing.phone = normalizedPhone || existing.phone;
      existing.passwordHash = await bcrypt.hash(password, 10);
      existing.provider = existing.provider || 'password';
      await existing.save();
      
      // Also create user in Firebase Auth for password reset functionality
      try {
        const firebaseAdmin = require('../services/firebaseAdminService');
        firebaseAdmin.initializeFirebaseAdmin();
        await firebaseAdmin.createFirebaseUser(normalizedEmail, password);
        console.log(`${logPrefix} User also created in Firebase Auth`);
      } catch (firebaseError) {
        // Log error but don't fail if Firebase fails
        console.error(`${logPrefix} Warning: Failed to create user in Firebase Auth:`, firebaseError.message);
      }
      
      const token = jwtService.generateToken(existing);
      return res.json({ 
        success: true, 
        token, 
        user: existing.toJSON() 
      });
    }

    // Create new user
    console.log(`${logPrefix} Creating new user: ${normalizedEmail}`);
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email: normalizedEmail,
      phone: normalizedPhone || '',
      passwordHash,
      provider: 'password',
    });

    // Also create user in Firebase Auth for password reset functionality
    try {
      const firebaseAdmin = require('../services/firebaseAdminService');
      firebaseAdmin.initializeFirebaseAdmin();
      await firebaseAdmin.createFirebaseUser(normalizedEmail, password);
      console.log(`${logPrefix} User also created in Firebase Auth`);
    } catch (firebaseError) {
      // Log error but don't fail registration if Firebase fails
      console.error(`${logPrefix} Warning: Failed to create user in Firebase Auth:`, firebaseError.message);
      console.error(`${logPrefix} User registered in database but password reset may not work`);
    }

    const token = jwtService.generateToken(user);
    
    console.log(`${logPrefix} SUCCESS: User registered - ${user.email} (ID: ${user.id})`);

    return res.json({ 
      success: true, 
      token, 
      user: user.toJSON() 
    });
  } catch (error) {
    console.error(`${logPrefix} ERROR:`, error);
    return res.status(500).json({ 
      message: 'Server error',
      error: config.env === 'development' ? error.message : undefined
    });
  }
});

/**
 * Email/Password Login Endpoint
 * 
 * Authenticates user with email and password.
 * Returns JWT token on success.
 */
router.post('/email-login', async (req, res) => {
  const logPrefix = '[POST /api/auth/email-login]';
  
  try {
    const { email, password } = req.body;
    
    // Validate required fields
    if (!email || !password) {
      return res.status(400).json({ 
        message: 'Email and password are required' 
      });
    }

    const normalizedEmail = String(email).toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    
    // Check if user exists and has password
    if (!user || !user.passwordHash) {
      console.log(`${logPrefix} Invalid credentials for: ${normalizedEmail}`);
      return res.status(400).json({ 
        message: 'Invalid email or password' 
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      console.log(`${logPrefix} Invalid password for: ${normalizedEmail}`);
      return res.status(400).json({ 
        message: 'Invalid email or password' 
      });
    }

    const token = jwtService.generateToken(user);
    
    console.log(`${logPrefix} SUCCESS: User logged in - ${user.email} (ID: ${user.id})`);

    return res.json({ 
      success: true, 
      token, 
      user: user.toJSON() 
    });
  } catch (error) {
    console.error(`${logPrefix} ERROR:`, error);
    return res.status(500).json({ 
      message: 'Server error',
      error: config.env === 'development' ? error.message : undefined
    });
  }
});

/**
 * Get Current User Profile
 * 
 * Returns the authenticated user's profile information.
 * Requires valid JWT token.
 */
router.get('/me', auth, async (req, res) => {
  const logPrefix = '[GET /api/auth/me]';
  
  try {
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({ 
        message: 'User not found' 
      });
    }
    
    return res.json({ 
      user: user.toJSON() 
    });
  } catch (error) {
    console.error(`${logPrefix} ERROR:`, error);
    return res.status(500).json({ 
      message: 'Server error',
      error: config.env === 'development' ? error.message : undefined
    });
  }
});

/**
 * Change Password Endpoint
 * 
 * Allows authenticated users to change their password.
 * Requires current password verification.
 */
router.post('/change-password', auth, async (req, res) => {
  const logPrefix = '[POST /api/auth/change-password]';
  
  try {
    const { currentPassword, newPassword } = req.body;
    
    // Validate required fields
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        message: 'Current password and new password are required' 
      });
    }
    
    const user = await User.findById(req.user.id);
    
    // Check if user exists and has password
    if (!user || !user.passwordHash) {
      return res.status(400).json({ 
        message: 'Invalid credentials' 
      });
    }
    
    // Verify current password
    const isValidPassword = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValidPassword) {
      return res.status(400).json({ 
        message: 'Invalid current password' 
      });
    }
    
    // Update password
    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();
    
    console.log(`${logPrefix} SUCCESS: Password changed for user ID: ${user.id}`);
    
    return res.json({ 
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error(`${logPrefix} ERROR:`, error);
    return res.status(500).json({ 
      message: 'Server error',
      error: config.env === 'development' ? error.message : undefined
    });
  }
});

/**
 * Forgot Password Endpoint
 * 
 * Sends a password reset email using Firebase Auth.
 * This requires Firebase Admin SDK to be configured.
 */
router.post('/forgot-password', async (req, res) => {
  const logPrefix = '[POST /api/auth/forgot-password]';
  
  try {
    const { email } = req.body;
    
    // Validate required fields
    if (!email) {
      return res.status(400).json({ 
        message: 'Email is required' 
      });
    }

    const normalizedEmail = String(email).toLowerCase().trim();
    
    // Check if user exists in database
    const user = await User.findOne({ email: normalizedEmail });
    
    if (!user) {
      // Don't reveal if email exists or not (security best practice)
      console.log(`${logPrefix} Password reset requested for non-existent email: ${normalizedEmail}`);
      return res.json({ 
        success: true,
        message: 'If an account exists with this email, a password reset link has been sent.'
      });
    }

    // Check if user has password (not Google-only account)
    if (!user.passwordHash) {
      console.log(`${logPrefix} Password reset requested for Google-only account: ${normalizedEmail}`);
      return res.status(400).json({ 
        message: 'This account was created with Google Sign-In. Please use Google Sign-In to access your account.'
      });
    }

    // Use Firebase Admin SDK to send password reset email
    try {
      const firebaseAdmin = require('../services/firebaseAdminService');
      
      // Initialize Firebase Admin
      firebaseAdmin.initializeFirebaseAdmin();
      
      // Check if user exists in Firebase Auth, if not, create them
      try {
        await firebaseAdmin.sendPasswordResetEmail(normalizedEmail);
      } catch (firebaseError) {
        // If user doesn't exist in Firebase Auth, create them
        if (firebaseError.message.includes('not found in Firebase Auth')) {
          console.log(`${logPrefix} User not in Firebase Auth, creating user...`);
          // Note: We can't create user without password, so we'll use a temporary approach
          // In production, you should create users in Firebase Auth when they register
          throw new Error('User not found in Firebase Auth. Please ensure the user was created in Firebase Auth during registration.');
        }
        throw firebaseError;
      }

      console.log(`${logPrefix} Password reset email sent to: ${normalizedEmail}`);
      
      return res.json({ 
        success: true,
        message: 'If an account exists with this email, a password reset link has been sent.'
      });
      
    } catch (firebaseError) {
      console.error(`${logPrefix} Firebase error:`, firebaseError.message);
      
      // Handle Firebase-specific errors
      if (firebaseError.code === 'auth/user-not-found' || firebaseError.message.includes('not found')) {
        // Don't reveal if user exists (security best practice)
        return res.json({ 
          success: true,
          message: 'If an account exists with this email, a password reset link has been sent.'
        });
      }
      
      if (firebaseError.code === 'auth/invalid-email') {
        return res.status(400).json({ 
          message: 'Invalid email address'
        });
      }
      
      // If Firebase Admin is not configured properly
      if (firebaseError.message.includes('service account') || firebaseError.message.includes('not found')) {
        return res.status(500).json({ 
          message: 'Password reset service is not configured. Please contact support.',
          error: config.env === 'development' ? firebaseError.message : undefined
        });
      }
      
      throw firebaseError;
    }
    
  } catch (error) {
    console.error(`${logPrefix} ERROR:`, error);
    return res.status(500).json({ 
      message: 'Server error',
      error: config.env === 'development' ? error.message : undefined
    });
  }
});

/**
 * Logout Endpoint
 * 
 * Invalidates the current JWT token by adding it to the blacklist.
 */
router.post('/logout', async (req, res) => {
  const logPrefix = '[POST /api/auth/logout]';
  
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    
    if (token) {
      auth.blacklistAdd(token);
      console.log(`${logPrefix} Token blacklisted`);
    }
    
    return res.json({ 
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error(`${logPrefix} ERROR:`, error);
    // Still return success even if blacklisting fails
    return res.json({ 
      success: true,
      message: 'Logged out successfully'
    });
  }
});

module.exports = router;
