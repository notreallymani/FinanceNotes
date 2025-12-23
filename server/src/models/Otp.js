const mongoose = require('mongoose');

const OtpSchema = new mongoose.Schema(
  {
    phone: { type: String },
    aadhar: { type: String },
    code: { type: String },
    requestId: { type: String },
    provider: { type: String, default: 'local' },
    type: { type: String, default: 'phone' },
    expiresAt: { type: Date, required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Otp', OtpSchema);
