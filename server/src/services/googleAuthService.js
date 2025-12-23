/**
 * Google Authentication Service
 * 
 * Handles Google OAuth token verification and user data extraction.
 * This service abstracts the Google authentication logic from the route handlers.
 */

const { OAuth2Client } = require('google-auth-library');
const config = require('../config');

class GoogleAuthService {
  constructor() {
    // Log the Client ID being used for debugging
    console.log(`[GoogleAuthService] Initializing with Client ID: ${config.googleClientId}`);
    this._clientId = config.googleClientId;
    this.client = new OAuth2Client(this._clientId);
  }

  /**
   * Get the current Client ID (for debugging)
   */
  getClientId() {
    return this._clientId || config.googleClientId;
  }

  /**
   * Verify Google ID token
   * @param {string} idToken - Google ID token from client
   * @returns {Promise<Object>} Verified token payload
   * @throws {Error} If token verification fails
   */
  async verifyToken(idToken) {
    if (!idToken) {
      throw new Error('ID token is required');
    }

    if (!config.googleClientId) {
      throw new Error('Google Client ID not configured');
    }

    // Use current config value (in case it changed)
    const currentClientId = config.googleClientId;
    
    // Log the Client ID being used for verification
    console.log(`[GoogleAuthService] Verifying token with Client ID: ${currentClientId}`);
    console.log(`[GoogleAuthService] Service Client ID: ${this._clientId}`);

    // Recreate client if Client ID changed (shouldn't happen, but just in case)
    if (this._clientId !== currentClientId) {
      console.log(`[GoogleAuthService] WARNING: Client ID changed! Recreating OAuth2Client`);
      this._clientId = currentClientId;
      this.client = new OAuth2Client(currentClientId);
    }

    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: currentClientId,
      });

      const payload = ticket.getPayload();
      
      if (!payload) {
        throw new Error('Token payload is empty');
      }

      return payload;
    } catch (error) {
      // Enhance error message with helpful hints
      if (error.message?.includes('audience')) {
        error.hint = 'Token audience mismatch. Ensure Flutter app uses the same Web Client ID as the server.';
      } else if (error.message?.includes('expired')) {
        error.hint = 'Token has expired. Please sign in again.';
      } else if (error.message?.includes('malformed')) {
        error.hint = 'Token format is invalid.';
      }
      
      throw error;
    }
  }

  /**
   * Extract user information from verified token payload
   * @param {Object} payload - Verified token payload
   * @returns {Object} User information
   */
  extractUserInfo(payload) {
    const email = String(payload.email || '').toLowerCase();
    const name = payload.name || payload.given_name || 'Google User';
    const picture = payload.picture || '';
    const googleId = payload.sub || '';

    if (!email) {
      throw new Error('Email missing in token payload');
    }

    return {
      email,
      name,
      picture,
      googleId,
    };
  }
}

module.exports = new GoogleAuthService();

