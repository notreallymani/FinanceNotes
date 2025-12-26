/**
 * Auth Routes (Refactored with SOLID Principles)
 * 
 * Single Responsibility: Only handles HTTP routing
 * Dependency Inversion: Depends on service abstractions
 * Open/Closed: Extendable without modification
 */

const express = require('express');
const authService = require('../services/AuthService');
const auth = require('../middleware/auth');
const { validate, validateEmail, validatePassword } = require('../middleware/validation');
const { asyncHandler, ValidationError } = require('../middleware/errorHandler');
const userRepository = require('../repositories/UserRepository');

const router = express.Router();

/**
 * Google OAuth Authentication
 */
router.post('/google', asyncHandler(async (req, res) => {
  const { idToken } = req.body;
  
  if (!idToken) {
    throw new ValidationError('idToken is required', 'idToken');
  }

  const result = await authService.authenticateWithGoogle(idToken);
  
  res.json({
    success: true,
    ...result,
  });
}));

/**
 * Email/Password Registration
 */
router.post('/email-register', 
  validate({
    email: validateEmail,
    password: validatePassword,
    name: (name) => {
      if (!name || name.trim().length < 2) {
        throw new ValidationError('Name must be at least 2 characters', 'name');
      }
      return name.trim();
    },
  }),
  asyncHandler(async (req, res) => {
    const { email, password, name, phone } = req.body;
    
    const result = await authService.registerWithEmail(email, password, name, phone);
    
    res.status(201).json({
      success: true,
      ...result,
    });
  })
);

/**
 * Email/Password Login
 */
router.post('/email-login',
  validate({
    email: validateEmail,
    password: validatePassword,
  }),
  asyncHandler(async (req, res) => {
    const { email, password } = req.body;
    
    const result = await authService.loginWithEmail(email, password);
    
    res.json({
      success: true,
      ...result,
    });
  })
);

/**
 * Forgot Password
 */
router.post('/forgot-password',
  validate({
    email: validateEmail,
  }),
  asyncHandler(async (req, res) => {
    const { email } = req.body;
    
    await authService.sendPasswordReset(email);
    
    // Don't reveal if user exists (security best practice)
    res.json({
      success: true,
      message: 'If an account exists with this email, a password reset link has been sent.',
    });
  })
);

/**
 * Get Current User
 */
router.get('/me', auth, asyncHandler(async (req, res) => {
  const user = await userRepository.findById(req.user.id);
  
  if (!user) {
    throw new NotFoundError('User');
  }
  
  res.json({
    user: user.toJSON(),
  });
}));

/**
 * Logout (token blacklisting handled in middleware)
 */
router.post('/logout', auth, asyncHandler(async (req, res) => {
  // Token blacklisting is handled in auth middleware
  res.json({
    success: true,
    message: 'Logged out successfully',
  });
}));

module.exports = router;

