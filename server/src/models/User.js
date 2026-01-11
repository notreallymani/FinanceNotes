const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, default: '' },
    phone: { type: String, default: '' },
    aadhar: { type: String, default: '' },
    passwordHash: { type: String, default: '' },
    googleId: { type: String, default: '' },
    picture: { type: String, default: '' },
    provider: { type: String, default: '' },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    aadharVerified: { type: Boolean, default: false },
    fcmToken: { type: String, default: '' }, // Firebase Cloud Messaging token for push notifications
    aadharDetails: { type: mongoose.Schema.Types.Mixed, default: null }, // Store full Aadhaar verification JSON details
  },
  { timestamps: true }
);

UserSchema.set('toJSON', {
  virtuals: true,
  transform: (_, doc) => {
    doc.id = doc._id.toString();
    delete doc._id;
    delete doc.__v;
    delete doc.passwordHash;
    return doc;
  },
});

module.exports = mongoose.model('User', UserSchema);
