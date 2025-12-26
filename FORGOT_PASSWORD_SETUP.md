# Forgot Password - Production Setup Guide

## ✅ What's Implemented

1. **Backend Endpoint**: `POST /api/auth/forgot-password`
2. **Firebase Admin Service**: Uses Firebase Identity Toolkit REST API
3. **Email Template**: Uses your configured Firebase email template
4. **User Creation**: New users are automatically created in Firebase Auth

## 🔧 How It Works

### Flow:
```
1. User clicks "Forgot password?" on login screen
   ↓
2. User enters email
   ↓
3. Frontend calls: POST /api/auth/forgot-password
   ↓
4. Backend checks:
   - User exists in MongoDB?
   - User has password (not Google-only)?
   - User exists in Firebase Auth?
   ↓
5. Backend calls Firebase Identity Toolkit API
   ↓
6. Firebase sends email using your configured template:
   - Sender: "Finance Notes"
   - From: noreply@financenotes-11ff0.firebaseapp.com
   - Subject: "Reset your password for Finance Notes"
   - Message: Your configured template
   ↓
7. User receives email with reset link
   ↓
8. User clicks link → Resets password
```

## ⚙️ Required Setup

### 1. Enable Identity Toolkit API

**In Google Cloud Console:**
1. Go to: https://console.cloud.google.com/
2. Select project: `financenotes-11ff0`
3. **APIs & Services** → **Library**
4. Search: **"Identity Toolkit API"**
5. Click **ENABLE**

### 2. Service Account Permissions

Your service account needs these permissions:
- **Firebase Authentication Admin** (or **Identity Toolkit Admin**)
- **Cloud Platform** scope

**Check permissions:**
1. Google Cloud Console → **IAM & Admin** → **IAM**
2. Find your service account (from the key file)
3. Ensure it has **Firebase Authentication Admin** role

### 3. Firebase Email Template (Already Configured ✅)

Your template is configured:
- **Sender name**: Finance Notes
- **From**: noreply@financenotes-11ff0.firebaseapp.com
- **Subject**: Reset your password for %Finance Notes%
- **Message**: Your custom template

## 🧪 Testing

### Test Steps:

1. **Register a new user** (this creates user in both MongoDB and Firebase Auth)
2. **Go to login screen**
3. **Click "Forgot password?"**
4. **Enter the registered email**
5. **Check email inbox** for password reset email
6. **Click the reset link**
7. **Set new password**

### Expected Email:
```
From: Finance Notes <noreply@financenotes-11ff0.firebaseapp.com>
Subject: Reset your password for Finance Notes

Hello,

Follow this link to reset your Finance Notes password for your [EMAIL] account.

[RESET LINK]

If you didn't ask to reset your password, you can ignore this email.

Thanks,
Your Finance Notes team
```

## 🐛 Troubleshooting

### Error: "User not found in Firebase Auth"

**Cause**: User was registered before Firebase Auth integration was added.

**Solution**: 
- Register a new user (they'll be created in Firebase Auth automatically)
- OR migrate existing users (see below)

### Error: "Firebase API error: PERMISSION_DENIED"

**Cause**: Service account doesn't have proper permissions.

**Solution**:
1. Go to Google Cloud Console → IAM
2. Find your service account
3. Add role: **Firebase Authentication Admin**

### Error: "Identity Toolkit API not enabled"

**Cause**: API is not enabled in Google Cloud Console.

**Solution**:
1. Go to APIs & Services → Library
2. Enable **Identity Toolkit API**

### Email Not Received

**Check**:
1. Check spam folder
2. Verify email address is correct
3. Check backend logs for errors
4. Verify Firebase email template is configured
5. Check Firebase Console → Authentication → Templates

## 📝 Migration for Existing Users

If you have existing users registered before this feature:

**Option 1: Automatic (Recommended)**
- Users will be created in Firebase Auth when they next login
- Or when they request password reset (if user doesn't exist, create them)

**Option 2: Manual Migration Script**
```javascript
// Run this once to migrate all existing users
const User = require('./models/User');
const firebaseAdmin = require('./services/firebaseAdminService');

async function migrateUsers() {
  const users = await User.find({ passwordHash: { $exists: true } });
  
  for (const user of users) {
    try {
      await firebaseAdmin.createFirebaseUser(user.email, 'temp_password');
      // Note: You'll need to update password after migration
      console.log(`Migrated: ${user.email}`);
    } catch (error) {
      console.error(`Failed to migrate ${user.email}:`, error.message);
    }
  }
}
```

## ✅ Production Checklist

- [ ] Identity Toolkit API is enabled
- [ ] Service account has Firebase Authentication Admin role
- [ ] Firebase email template is configured
- [ ] Tested with new user registration
- [ ] Tested password reset email delivery
- [ ] Tested password reset link works
- [ ] Backend logs show successful email sending

## 🎯 Current Status

✅ **Code is production-ready**
✅ **Uses Firebase's configured email template**
✅ **Automatic user creation in Firebase Auth**
✅ **Proper error handling**
✅ **Security best practices (doesn't reveal if email exists)**

## 📧 Email Template Details

Your configured template:
- **Sender name**: Finance Notes
- **From address**: noreply@financenotes-11ff0.firebaseapp.com
- **Subject**: Reset your password for %Finance Notes%
- **Reply to**: noreply
- **Template language**: English

The email will be sent automatically when a user requests password reset.

