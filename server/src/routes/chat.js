const express = require('express');
const Chat = require('../models/Chat');
const Transaction = require('../models/Transaction');
const auth = require('../middleware/auth');

const router = express.Router();

/**
 * List conversations for current user
 * Returns last message and basic transaction info per transaction
 */
router.get('/list', auth, async (req, res) => {
  try {
    const userAadhar = req.user.aadhar || '';

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
      .select('amount status senderAadhar receiverAadhar createdAt')
      .lean();
    const txnMap = txns.reduce((acc, t) => {
      acc[t._id.toString()] = t;
      return acc;
    }, {});

    const result = conversations.map((c) => {
      const tx = txnMap[c._id.toString()] || {};
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
    const userAadhar = req.user.aadhar || '';

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

    // Mark messages as read if they were sent to current user
    const unreadMessages = messages.filter(
      (msg) => msg.receiverAadhar === userAadhar && !msg.read
    );

    if (unreadMessages.length > 0) {
      await Chat.updateMany(
        { 
          _id: { $in: unreadMessages.map(m => m._id) },
          receiverAadhar: userAadhar 
        },
        { 
          read: true, 
          readAt: new Date() 
        }
      );
    }

    return res.json({ messages });
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
    const userAadhar = req.user.aadhar || '';

    if (!transactionId || !message || !message.trim()) {
      return res.status(400).json({ message: 'Transaction ID and message are required' });
    }

    // Validate user Aadhaar (must be non-empty string)
    if (!userAadhar || typeof userAadhar !== 'string' || userAadhar.trim() === '') {
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

    // Create message
    const chatMessage = await Chat.create({
      transactionId,
      senderAadhar: userAadhar.trim(),
      receiverAadhar,
      message: message.trim(),
    });

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
    const userAadhar = req.user.aadhar || '';

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

