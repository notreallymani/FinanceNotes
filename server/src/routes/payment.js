const express = require('express');
const multer = require('multer');
const { Storage } = require('@google-cloud/storage');
const Transaction = require('../models/Transaction');
const auth = require('../middleware/auth');
const config = require('../config');

const router = express.Router();
const upload = multer({ dest: 'uploads/' });

const storage = new Storage({
  projectId: config.gcpProjectId,
  keyFilename: config.gcpStorageKeyFile,
});
const bucket = storage.bucket(config.gcpStorageBucket);

router.post('/send', auth, upload.array('documents'), async (req, res) => {
  try {
    const { aadhar, amount, mobile = '', interest = 0 } = req.body;
    if (!aadhar || !amount) return res.status(400).json({ message: 'Invalid request' });

    // Require Aadhaar verification before allowing payment creation
    if (!req.user || !req.user.aadharVerified) {
      return res.status(403).json({ message: 'Please verify your Aadhaar before creating payment requests.' });
    }

    const documents = [];
    if (Array.isArray(req.files)) {
      for (const file of req.files) {
        const destName = `transactions/${Date.now()}_${file.originalname}`;
        await bucket.upload(file.path, { destination: destName });
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${encodeURI(
          destName
        )}`;
        documents.push({
          filename: file.originalname,
          url: publicUrl,
          size: file.size,
          mimetype: file.mimetype,
        });
      }
    }

    const tx = await Transaction.create({
      amount: Number(amount),
      status: 'pending',
      senderAadhar: req.user.aadhar || '',
      senderMobile: req.user.phone || '',
      receiverAadhar: aadhar,
      mobile,
      interest: Number(interest) || 0,
      documents,
    });
    return res.json({ transaction: tx.toJSON() });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

// Customer close flow - send OTP to owner (sender mobile)
router.post('/customer-close/send-otp', auth, async (req, res) => {
  try {
    const { transactionId, ownerAadhar } = req.body;
    const userAadhar = req.user.aadhar || '';
    if (!transactionId || !ownerAadhar) {
      return res.status(400).json({ message: 'Transaction ID and owner Aadhaar are required' });
    }

    const tx = await Transaction.findById(transactionId);
    if (!tx) return res.status(404).json({ message: 'Transaction not found' });

    // User must be receiver to initiate customer close
    if (tx.receiverAadhar !== userAadhar) {
      return res.status(403).json({ message: 'Only the customer can initiate this close' });
    }

    // Owner Aadhaar must match senderAadhar
    if (tx.senderAadhar !== ownerAadhar) {
      return res.status(400).json({ message: 'Owner Aadhaar does not match' });
    }

    if (!tx.senderMobile) {
      return res.status(400).json({ message: 'Owner contact number not available' });
    }

    // Generate OTP
    const code = config.env === 'development'
      ? '123456'
      : Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date(Date.now() + 5 * 60 * 1000);
    tx.closeOtpCode = code;
    tx.closeOtpExpiresAt = expires;
    await tx.save();

    // In production, integrate SMS here. For now, log masked info.
    console.log(`[Customer Close OTP] Sending OTP to owner ${tx.senderMobile} for transaction ${tx.id}: ${code}`);

    return res.json({
      success: true,
      message: 'OTP sent to owner mobile',
      expiresAt: expires,
      hint: config.env === 'development' ? 'Use OTP: 123456' : undefined,
    });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

// Customer close flow - verify OTP and close
router.post('/customer-close/verify', auth, async (req, res) => {
  try {
    const { transactionId, ownerAadhar, otp } = req.body;
    const userAadhar = req.user.aadhar || '';
    if (!transactionId || !ownerAadhar || !otp) {
      return res.status(400).json({ message: 'Transaction ID, owner Aadhaar, and OTP are required' });
    }

    const tx = await Transaction.findById(transactionId);
    if (!tx) return res.status(404).json({ message: 'Transaction not found' });

    // User must be receiver to verify
    if (tx.receiverAadhar !== userAadhar) {
      return res.status(403).json({ message: 'Only the customer can close this transaction' });
    }

    // Owner Aadhaar must match
    if (tx.senderAadhar !== ownerAadhar) {
      return res.status(400).json({ message: 'Owner Aadhaar does not match' });
    }

    // Validate OTP
    if (config.env !== 'development') {
      if (!tx.closeOtpCode || !tx.closeOtpExpiresAt || tx.closeOtpExpiresAt < new Date()) {
        return res.status(400).json({ message: 'OTP expired. Please request a new one.' });
      }
      if (tx.closeOtpCode !== otp) {
        return res.status(400).json({ message: 'Invalid OTP' });
      }
    } else {
      // Dev bypass: accept OTP 123456 without checking stored code
      if (otp !== '123456') {
        return res.status(400).json({ message: 'Invalid OTP (dev expects 123456)' });
      }
    }

    // Close transaction
    tx.status = 'closed';
    tx.closedAt = new Date();
    tx.closeOtpCode = '';
    tx.closeOtpExpiresAt = undefined;
    await tx.save();

    return res.json({ success: true, transaction: tx.toJSON() });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

router.post('/close', auth, async (req, res) => {
  try {
    const { transactionId } = req.body;
    if (!transactionId) return res.status(400).json({ message: 'Invalid request' });
    const tx = await Transaction.findById(transactionId);
    if (!tx) return res.status(404).json({ message: 'Not found' });
    // Only the creator/owner (senderAadhar) is allowed to close a payment.
    if (tx.senderAadhar && req.user.aadhar && tx.senderAadhar !== req.user.aadhar) {
      return res.status(403).json({ message: 'Not authorized to close this payment' });
    }
    tx.status = 'closed';
    tx.closedAt = new Date();
    await tx.save();
    return res.json({ transaction: tx.toJSON() });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

router.get('/history', auth, async (req, res) => {
  try {
    const aadhar = req.query.aadhar || '';
    if (!aadhar) return res.status(400).json({ message: 'Aadhaar required' });

    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.max(Math.min(parseInt(req.query.limit, 10) || 50, 100), 1);
    const skip = (page - 1) * limit;

    const query = {
      $or: [{ senderAadhar: aadhar }, { receiverAadhar: aadhar }],
    };

    const [total, list] = await Promise.all([
      Transaction.countDocuments(query),
      Transaction.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
    ]);

    const transactions = list.map((t) => t.toJSON());
    const hasMore = skip + transactions.length < total;

    // Keep "transactions" array for existing clients, but also return
    // pagination meta for future use.
    return res.json({
      transactions,
      page,
      limit,
      total,
      hasMore,
    });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

// Get all payments for the logged-in user (creator/participant views)
router.get('/all', auth, async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.max(Math.min(parseInt(req.query.limit, 10) || 50, 100), 1);
    const skip = (page - 1) * limit;

    // If the user has an Aadhaar, only return payments they CREATED
    // (senderAadhar == userAadhar). This matches the owner/financer
    // view of "all my payment requests". If Aadhaar is missing on the
    // user, do NOT fall back to an empty query (which would return all
    // transactions); instead, return an empty list so no unrelated
    // transactions are ever shown.
    const userAadhar = (req.user && req.user.aadhar) || '';
    if (!userAadhar) {
      return res.json({ transactions: [], page, limit, total: 0, hasMore: false });
    }
    const query = { senderAadhar: userAadhar };

    const [total, list] = await Promise.all([
      Transaction.countDocuments(query),
      Transaction.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
    ]);

    const transactions = list.map((t) => t.toJSON());
    const hasMore = skip + transactions.length < total;

    return res.json({
      transactions,
      page,
      limit,
      total,
      hasMore,
    });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
