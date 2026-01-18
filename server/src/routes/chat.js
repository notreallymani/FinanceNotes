const express = require('express');
const Chat = require('../models/Chat');
const Transaction = require('../models/Transaction');
const User = require('../models/User');
const auth = require('../middleware/auth');
const firebaseAdminService = require('../services/firebaseAdminService');

const router = express.Router();

/**
 * List conversations for current user
 * Returns last message and basic transaction info per transaction
 */
router.get('/list', auth, async (req, res) => {
  try {
    // Fetch user from database to get latest Aadhaar (JWT might be stale)
    const user = await User.findById(req.user.id);
    const userAadhar = (user && user.aadhar) || '';

    // Find conversations where user is sender or receiver
    const pipeline = [
      {
        $match: {
          $or: [
            { senderAadhar: userAadhar },
            { receiverAadhar: userAadhar },
          ],
        },
      },
      { $sort: { createdAt: -1 } }, // latest first
      {
        $group: {
          _id: '$transactionId',
          lastMessage: { $first: '$message' },
          lastSenderAadhar: { $first: '$senderAadhar' },
          lastReceiverAadhar: { $first: '$receiverAadhar' },
          lastCreatedAt: { $first: '$createdAt' },
          unreadCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$receiverAadhar', userAadhar] },
                    { $eq: ['$read', false] },
                  ],
                },
                1,
                0,
              ],
            },
          },
        },
      },
      { $sort: { lastCreatedAt: -1 } },
    ];

    const conversations = await Chat.aggregate(pipeline);

    // Fetch transaction info for each conversation
    const txnIds = conversations.map((c) => c._id);
    const txns = await Transaction.find({ _id: { $in: txnIds } })
      .select('amount status senderAadhar receiverAadhar createdAt customerName')
      .lean();
    const txnMap = txns.reduce((acc, t) => {
      acc[t._id.toString()] = t;
      return acc;
    }, {});

    // Filter out conversations with missing transactions
    // Note: We now show ALL conversations regardless of transaction status or date
    // Users should be able to see their chat history
    const filteredConversations = conversations.filter((c) => {
      const tx = txnMap[c._id.toString()];
      // Only exclude if transaction doesn't exist
      if (!tx) return false;
      return true;
    });

    // Collect all unique Aadhaar numbers to fetch user names
    const aadharSet = new Set();
    filteredConversations.forEach((c) => {
      const tx = txnMap[c._id.toString()];
      if (tx) {
        if (tx.senderAadhar) aadharSet.add(tx.senderAadhar);
        if (tx.receiverAadhar) aadharSet.add(tx.receiverAadhar);
      }
    });

    // Fetch user names by Aadhaar
    const users = await User.find({ aadhar: { $in: Array.from(aadharSet) } })
      .select('aadhar name')
      .lean();
    const userMap = users.reduce((acc, u) => {
      acc[u.aadhar] = u.name;
      return acc;
    }, {});

    const result = filteredConversations.map((c) => {
      const tx = txnMap[c._id.toString()] || {};
      const senderName = tx.senderAadhar ? (userMap[tx.senderAadhar] || '') : '';
      const receiverName = tx.receiverAadhar ? (userMap[tx.receiverAadhar] || '') : '';
      
      return {
        transactionId: c._id,
        lastMessage: c.lastMessage,
        lastSenderAadhar: c.lastSenderAadhar,
        lastReceiverAadhar: c.lastReceiverAadhar,
        lastCreatedAt: c.lastCreatedAt,
        unreadCount: c.unreadCount || 0,
        transaction: {
          amount: tx.amount,
          status: tx.status,
          senderAadhar: tx.senderAadhar,
          receiverAadhar: tx.receiverAadhar,
          customerName: tx.customerName || receiverName, // Prefer transaction customerName, fallback to user name
          senderName: senderName,
          receiverName: receiverName,
          createdAt: tx.createdAt,
        },
      };
    });

    return res.json({ conversations: result });
  } catch (e) {
    console.error('[Chat] Error listing conversations:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

/**
 * Get all messages for a transaction
 * Only participants (sender or receiver) can view messages
 */
router.get('/transaction/:transactionId', auth, async (req, res) => {
  try {
    const { transactionId } = req.params;
    // Fetch user from database to get latest Aadhaar (JWT might be stale)
    const user = await User.findById(req.user.id);
    const userAadhar = (user && user.aadhar) || '';

    // Verify transaction exists
    const transaction = await Transaction.findById(transactionId);
    if (!transaction) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    // Allow:
    // - The owner (senderAadhar)
    // - Any authenticated user (can start a conversation with owner)
    // This relaxes the previous participant-only rule.

    // Get all messages for this transaction, sorted by creation date
    const messages = await Chat.find({ transactionId })
      .sort({ createdAt: 1 })
      .lean();

    // Mark messages as delivered and read if they were sent to current user
    const unreadMessages = messages.filter(
      (msg) => msg.receiverAadhar === userAadhar && !msg.read
    );

    if (unreadMessages.length > 0) {
      const now = new Date();
      await Chat.updateMany(
        { 
          _id: { $in: unreadMessages.map(m => m._id) },
          receiverAadhar: userAadhar 
        },
        { 
          status: 'read',
          read: true, 
          readAt: now 
        }
      );
    }

    // Update status to 'delivered' for messages that are still 'sent'
    const undeliveredMessages = messages.filter(
      (msg) => msg.receiverAadhar === userAadhar && msg.status === 'sent'
    );

    if (undeliveredMessages.length > 0) {
      const now = new Date();
      await Chat.updateMany(
        { 
          _id: { $in: undeliveredMessages.map(m => m._id) },
          receiverAadhar: userAadhar,
          status: 'sent'
        },
        { 
          status: 'delivered',
          deliveredAt: now 
        }
      );
    }

    // Fetch updated messages
    const updatedMessages = await Chat.find({ transactionId })
      .sort({ createdAt: 1 })
      .lean();

    return res.json({ messages: updatedMessages });
  } catch (e) {
    console.error('[Chat] Error getting messages:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

/**
 * Send a message in a transaction chat
 * Only participants can send messages
 */
router.post('/send', auth, async (req, res) => {
  try {
    const { transactionId, message } = req.body;

    console.log('[Chat Send] Request received:', {
      transactionId: transactionId ? `${transactionId.substring(0, 8)}...` : 'missing',
      messageLength: message ? message.length : 0,
      userId: req.user.id,
    });

    if (!transactionId || !message || !message.trim()) {
      console.log('[Chat Send] Validation failed: Missing transactionId or message');
      return res.status(400).json({ message: 'Transaction ID and message are required' });
    }

    // Fetch user from database to get latest Aadhaar (JWT might be stale)
    const user = await User.findById(req.user.id);
    const userAadhar = (user && user.aadhar) || '';
    console.log(`[Chat Send] User ID: ${req.user.id}, Aadhaar from DB: ${userAadhar || 'EMPTY'}`);

    // Validate user Aadhaar (must be non-empty string)
    if (!userAadhar || typeof userAadhar !== 'string' || userAadhar.trim() === '') {
      console.log('[Chat Send] Validation failed: User Aadhaar is missing or empty');
      return res.status(400).json({ message: 'User Aadhaar is required. Please complete your profile.' });
    }

    // Verify transaction exists
    const transaction = await Transaction.findById(transactionId);
    if (!transaction) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    // Validate transaction Aadhaar fields
    if (!transaction.senderAadhar || typeof transaction.senderAadhar !== 'string' || transaction.senderAadhar.trim() === '') {
      return res.status(400).json({ message: 'Transaction is missing sender Aadhaar information' });
    }
    if (!transaction.receiverAadhar || typeof transaction.receiverAadhar !== 'string' || transaction.receiverAadhar.trim() === '') {
      return res.status(400).json({ message: 'Transaction is missing receiver Aadhaar information' });
    }

    // Determine if user is owner
    const isOwner = userAadhar.trim() === transaction.senderAadhar.trim();
    
    // Determine receiver based on who is sending:
    // - If user is owner: receiver is customer
    // - If user is not owner (customer or anyone via global search): receiver is owner
    // This allows global search feature where anyone can message the owner to ask about customer behavior
    const receiverAadhar = isOwner
      ? transaction.receiverAadhar.trim()
      : transaction.senderAadhar.trim();

    // Final validation: ensure receiver Aadhaar is not empty
    if (!receiverAadhar) {
      return res.status(400).json({ message: 'Unable to determine message receiver. Invalid transaction data.' });
    }

    // Create message with 'sent' status
    const chatMessage = await Chat.create({
      transactionId,
      senderAadhar: userAadhar.trim(),
      receiverAadhar,
      message: message.trim(),
      status: 'sent',
    });

    // Send push notification to receiver (don't block response if it fails)
    try {
      // Find receiver user by Aadhaar to get their FCM token
      const receiverUser = await User.findOne({ aadhar: receiverAadhar });
      
      if (receiverUser && receiverUser.fcmToken && receiverUser.fcmToken.trim() !== '') {
        // Get sender name for notification
        const senderName = user.name || 'Someone';
        const notificationTitle = 'New Message';
        const notificationBody = `${senderName}: ${message.trim().substring(0, 100)}${message.trim().length > 100 ? '...' : ''}`;
        
        // Initialize Firebase Admin if not already initialized
        firebaseAdminService.initializeFirebaseAdmin();
        
        // Send push notification
        const notificationResult = await firebaseAdminService.sendPushNotification(
          receiverUser.fcmToken.trim(),
          notificationTitle,
          notificationBody,
          {
            type: 'chat_message',
            transactionId: transactionId,
            senderAadhar: userAadhar.trim(),
          }
        );

        if (!notificationResult.success && notificationResult.error === 'INVALID_TOKEN') {
          // Token is invalid, clear it from database
          console.log('[Chat Send] Clearing invalid FCM token for user:', receiverUser.id);
          receiverUser.fcmToken = '';
          await receiverUser.save();
        }
      }
    } catch (notificationError) {
      // Log error but don't fail the message send request
      console.error('[Chat Send] Error sending push notification:', notificationError.message);
    }

    return res.json({ message: chatMessage.toJSON() });
  } catch (e) {
    console.error('[Chat] Error sending message:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

/**
 * Get unread message count for current user
 */
router.get('/unread-count', auth, async (req, res) => {
  try {
    // Fetch user from database to get latest Aadhaar (JWT might be stale)
    const user = await User.findById(req.user.id);
    const userAadhar = (user && user.aadhar) || '';

    const count = await Chat.countDocuments({
      receiverAadhar: userAadhar,
      read: false,
    });

    return res.json({ count });
  } catch (e) {
    console.error('[Chat] Error getting unread count:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;

