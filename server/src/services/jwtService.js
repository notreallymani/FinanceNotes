/**
 * JWT Service
 * 
 * Handles JWT token generation for authenticated users.
 */

const jwt = require('jsonwebtoken');
const config = require('../config');

class JwtService {
  /**
   * Generate JWT token for user
   * @param {Object} user - User object from database
   * @returns {string} JWT token
   */
  generateToken(user) {
    return jwt.sign(
      {
        id: user.id,
        email: user.email,
        aadhar: user.aadhar,
        phone: user.phone,
        role: user.role || 'user',
        aadharVerified: !!user.aadharVerified,
      },
      config.jwtSecret,
      { expiresIn: '7d' }
    );
  }
}

module.exports = new JwtService();

