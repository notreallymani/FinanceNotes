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
