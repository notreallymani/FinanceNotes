const express = require('express');
const User = require('../models/User');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'Not found' });
    return res.json({ user: user.toJSON() });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

router.put('/', auth, async (req, res) => {
  try {
    const { name, phone, email, aadhar } = req.body;

    // Enforce unique phone and Aadhaar across different users
    const query = { _id: { $ne: req.user.id }, $or: [] };
    if (phone) {
      query.$or.push({ phone });
    }
    if (aadhar) {
      query.$or.push({ aadhar });
    }

    if (query.$or.length > 0) {
      const existing = await User.findOne(query);
      if (existing) {
        if (phone && existing.phone === phone) {
          return res
            .status(400)
            .json({ message: 'This mobile number is already used by another profile' });
        }
        if (aadhar && existing.aadhar === aadhar) {
          return res
            .status(400)
            .json({ message: 'This Aadhaar number is already used by another profile' });
        }
        return res.status(400).json({ message: 'Mobile or Aadhaar already in use' });
      }
    }

    const updates = {};
    if (name !== undefined) updates.name = name;
    if (phone !== undefined) updates.phone = phone;
    if (email !== undefined) updates.email = email;
    if (aadhar !== undefined) {
      updates.aadhar = aadhar;
      // Aadhaar has just been verified via OTP in the app, mark it as verified
      updates.aadharVerified = true;
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: updates },
      { new: true }
    );
    return res.json({ user: user.toJSON() });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

/**
 * Check if Aadhaar number is available (not used by another user)
 */
router.post('/check-aadhar', auth, async (req, res) => {
  try {
    const { aadhar } = req.body;

    if (!aadhar || typeof aadhar !== 'string' || aadhar.trim() === '') {
      return res.status(400).json({ message: 'Aadhaar number is required' });
    }

    const trimmedAadhar = aadhar.trim();

    // Check if Aadhaar is already used by another user
    const existingUser = await User.findOne({
      _id: { $ne: req.user.id },
      aadhar: trimmedAadhar,
    }).lean();

    if (existingUser) {
      return res.json({
        available: false,
        message: 'This Aadhaar number is already used by another profile',
      });
    }

    return res.json({
      available: true,
      message: 'Aadhaar number is available',
    });
  } catch (e) {
    console.error('[Profile] Error checking Aadhaar:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

/**
 * Update FCM token for push notifications
 */
router.post('/fcm-token', auth, async (req, res) => {
  try {
    const { fcmToken } = req.body;

    if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim() === '') {
      return res.status(400).json({ message: 'FCM token is required' });
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: { fcmToken: fcmToken.trim() } },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    return res.json({ success: true, message: 'FCM token updated' });
  } catch (e) {
    console.error('[Profile] Error updating FCM token:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
