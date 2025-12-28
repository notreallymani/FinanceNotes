const mongoose = require('mongoose');

const ChatSchema = new mongoose.Schema(
  {
    transactionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Transaction', required: true },
    senderAadhar: { type: String, required: true }, // Who sent the message
    receiverAadhar: { type: String, required: true }, // Who receives the message
    message: { type: String, required: true },
    status: { 
      type: String, 
      enum: ['sent', 'delivered', 'read'], 
      default: 'sent' 
    },
    read: { type: Boolean, default: false },
    readAt: { type: Date },
    deliveredAt: { type: Date },
  },
  { timestamps: true }
);

// Index for faster queries
ChatSchema.index({ transactionId: 1, createdAt: -1 });
ChatSchema.index({ senderAadhar: 1, receiverAadhar: 1 });

ChatSchema.set('toJSON', {
  virtuals: true,
  transform: (_, doc) => {
    doc.id = doc._id.toString();
    delete doc._id;
    delete doc.__v;
    return doc;
  },
});

module.exports = mongoose.model('Chat', ChatSchema);

