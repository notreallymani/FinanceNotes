/**
 * Auth Service
 * 
 * Single Responsibility: Handles authentication business logic
 * Dependency Inversion: Depends on repository abstractions
 * Open/Closed: Extendable for new auth methods
 */

const bcrypt = require('bcryptjs');
const userRepository = require('../repositories/UserRepository');
const jwtService = require('./jwtService');
const googleAuthService = require('./googleAuthService');
const firebaseAdminService = require('./firebaseAdminService');

class AuthService {
  /**
   * Authenticate with Google
   */
  async authenticateWithGoogle(idToken) {
    // Verify token
    const payload = await googleAuthService.verifyToken(idToken);
    const userInfo = googleAuthService.extractUserInfo(payload);

    // Find or create user
    let user = await userRepository.findByEmail(userInfo.email);
    
    if (!user) {
      // Create new user
      user = await userRepository.createUser({
        email: userInfo.email,
        name: userInfo.name,
        picture: userInfo.picture,
        aadhar: '',
        phone: '',
        passwordHash: null, // Google users don't have password
      });
    } else {
      // Update user info if changed
      if (user.name !== userInfo.name || user.picture !== userInfo.picture) {
        user = await userRepository.updateById(user.id, {
          $set: {
            name: userInfo.name,
            picture: userInfo.picture,
          },
        });
      }
    }

    // Generate token
    const token = jwtService.generateToken(user);

    return {
      user: user.toJSON(),
      token,
    };
  }

  /**
   * Register with email/password
   */
  async registerWithEmail(email, password, name, phone = null) {
    // Check if user exists
    const existing = await userRepository.findByEmail(email);
    if (existing) {
      throw new Error('Email already registered');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Create user
    const user = await userRepository.createUser({
      email: email.toLowerCase().trim(),
      passwordHash,
      name,
      phone,
      aadhar: '',
      picture: '',
    });

    // Create Firebase Auth user
    try {
      firebaseAdminService.initializeFirebaseAdmin();
      await firebaseAdminService.createFirebaseUser(email, password);
    } catch (error) {
      // Log but don't fail registration
      console.error('[AuthService] Failed to create Firebase user:', error.message);
    }

    // Generate token
    const token = jwtService.generateToken(user);

    return {
      user: user.toJSON(),
      token,
    };
  }

  /**
   * Login with email/password
   */
  async loginWithEmail(email, password) {
    // Find user
    const user = await userRepository.findByEmail(email);
    if (!user || !user.passwordHash) {
      throw new Error('Invalid email or password');
    }

    // Verify password
    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      throw new Error('Invalid email or password');
    }

    // Generate token
    const token = jwtService.generateToken(user);

    return {
      user: user.toJSON(),
      token,
    };
  }

  /**
   * Send password reset email
   */
  async sendPasswordReset(email) {
    const user = await userRepository.findByEmail(email);
    
    if (!user) {
      // Don't reveal if user exists (security)
      return { success: true };
    }

    if (!user.passwordHash) {
      throw new Error('This account was created with Google Sign-In');
    }

    // Send reset email via Firebase
    firebaseAdminService.initializeFirebaseAdmin();
    await firebaseAdminService.sendPasswordResetEmail(email);

    return { success: true };
  }
}

module.exports = new AuthService();

