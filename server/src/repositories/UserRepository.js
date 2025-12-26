/**
 * User Repository
 * 
 * Single Responsibility: Handles all User data access operations
 * Dependency Inversion: Depends on User model abstraction
 */

const BaseRepository = require('./BaseRepository');
const User = require('../models/User');

class UserRepository extends BaseRepository {
  constructor() {
    super(User);
  }

  /**
   * Find user by email
   */
  async findByEmail(email) {
    return await this.findOne({ email: email.toLowerCase().trim() });
  }

  /**
   * Find user by Aadhaar
   */
  async findByAadhar(aadhar) {
    return await this.findOne({ aadhar });
  }

  /**
   * Find user by phone
   */
  async findByPhone(phone) {
    return await this.findOne({ phone });
  }

  /**
   * Check if email exists
   */
  async emailExists(email) {
    return await this.exists({ email: email.toLowerCase().trim() });
  }

  /**
   * Check if Aadhaar exists
   */
  async aadharExists(aadhar) {
    return await this.exists({ aadhar });
  }

  /**
   * Check if phone exists
   */
  async phoneExists(phone) {
    return await this.exists({ phone });
  }

  /**
   * Create user with validation
   */
  async createUser(userData) {
    // Check for duplicates
    const emailExists = await this.emailExists(userData.email);
    if (emailExists) {
      throw new Error('Email already exists');
    }

    if (userData.aadhar) {
      const aadharExists = await this.aadharExists(userData.aadhar);
      if (aadharExists) {
        throw new Error('Aadhaar already exists');
      }
    }

    if (userData.phone) {
      const phoneExists = await this.phoneExists(userData.phone);
      if (phoneExists) {
        throw new Error('Phone number already exists');
      }
    }

    return await this.create(userData);
  }

  /**
   * Update user profile
   */
  async updateProfile(userId, updateData) {
    // Check for duplicate email (if changing)
    if (updateData.email) {
      const existing = await this.findByEmail(updateData.email);
      if (existing && existing.id !== userId) {
        throw new Error('Email already in use');
      }
    }

    // Check for duplicate Aadhaar (if changing)
    if (updateData.aadhar) {
      const existing = await this.findByAadhar(updateData.aadhar);
      if (existing && existing.id !== userId) {
        throw new Error('Aadhaar already in use');
      }
    }

    // Check for duplicate phone (if changing)
    if (updateData.phone) {
      const existing = await this.findByPhone(updateData.phone);
      if (existing && existing.id !== userId) {
        throw new Error('Phone number already in use');
      }
    }

    return await this.updateById(userId, { $set: updateData });
  }
}

module.exports = new UserRepository();

