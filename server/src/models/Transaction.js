const mongoose = require('mongoose');

const TransactionSchema = new mongoose.Schema(
  {
    amount: { type: Number, required: true },
    status: { type: String, default: 'pending' },
    senderAadhar: { type: String, default: '' },
    senderMobile: { type: String, default: '' }, // Owner mobile for OTP
    receiverAadhar: { type: String, default: '' },
    mobile: { type: String, default: '' },
    interest: { type: Number, default: 0 },
    customerName: { type: String, default: '' },
    documents: [
      {
        filename: { type: String },
        url: { type: String },
        size: { type: Number },
        mimetype: { type: String },
      },
    ],
    closedAt: { type: Date },
    closeOtpCode: { type: String, default: '' },
    closeOtpExpiresAt: { type: Date },
  },
  { timestamps: true }
);

TransactionSchema.set('toJSON', {
  virtuals: true,
  transform: (_, doc) => {
    doc.id = doc._id.toString();
    doc.createdAt = doc.createdAt;
    delete doc._id;
    delete doc.__v;
    return doc;
  },
});

module.exports = mongoose.model('Transaction', TransactionSchema);
