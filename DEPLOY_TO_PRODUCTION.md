# Deploy Forgot Password Feature to Production

## 📋 Step-by-Step Guide

### **Step 1: Clean Up and Commit Changes**

```powershell
# Navigate to project root
cd D:\FN-flutter-node.js

# Remove the accidentally staged file
git restore --staged "android/app/google-services (2).json"

# Remove the duplicate file if it exists
git rm "android/app/google-services (2).json" 2>$null

# Add all changes
git add .

# Commit changes
git commit -m "Add forgot password feature with Firebase Admin SDK

- Added Firebase Admin SDK for password reset
- Implemented forgot password endpoint
- Added profile verification check before sending payment OTP
- Added tabs to close payment screen (Sent/Received)
- Added warning dialog when closing sent payments
- Updated payment history screen
- All changes are production-ready"

# Push to GitHub
git push origin master
```

---

### **Step 2: Update DigitalOcean Server**

**SSH into your server:**
```bash
ssh root@142.93.213.231
```

**Once connected, run these commands:**

```bash
# Navigate to project directory
cd /var/www/FinanceNotes

# Pull latest code from GitHub
git pull origin master

# Navigate to server directory
cd server

# Install new dependencies (firebase-admin)
npm install --production

# Restart the backend service
pm2 restart financenotes-backend --update-env

# Check if it's running
pm2 status

# Check logs for any errors
pm2 logs financenotes-backend --lines 50
```

---

### **Step 3: Verify Everything Works**

**Check backend logs:**
```bash
pm2 logs financenotes-backend --lines 20
```

**You should see:**
```
[Firebase Admin] Initialized successfully
✅ Server running in production mode
📡 Listening on port 5000
```

**Test the endpoint:**
```bash
# Test forgot password endpoint (from your local machine or server)
curl -X POST http://142.93.213.231:5000/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

---

### **Step 4: Enable Identity Toolkit API (One-Time Setup)**

**In Google Cloud Console:**
1. Go to: https://console.cloud.google.com/
2. Select project: `financenotes-11ff0`
3. **APIs & Services** → **Library**
4. Search: **"Identity Toolkit API"**
5. Click **ENABLE**

**This is required for password reset to work!**

---

## ✅ Quick Command Summary

### **On Your Local Machine (Windows PowerShell):**
```powershell
cd D:\FN-flutter-node.js
git restore --staged "android/app/google-services (2).json"
git add .
git commit -m "Add forgot password feature with Firebase Admin SDK"
git push origin master
```

### **On DigitalOcean Server (SSH):**
```bash
cd /var/www/FinanceNotes
git pull origin master
cd server
npm install --production
pm2 restart financenotes-backend --update-env
pm2 logs financenotes-backend --lines 20
```

---

## 🔍 What Changed

### **New Files:**
- `server/src/services/firebaseAdminService.js` - Firebase Admin service
- `FORGOT_PASSWORD_SETUP.md` - Setup guide
- `PAYMENT_FLOW_CHART.md` - Flow documentation

### **Modified Files:**
- `server/src/routes/auth.js` - Added forgot password endpoint
- `server/package.json` - Added firebase-admin dependency
- `server/package-lock.json` - Updated dependencies
- `lib/screens/payment/send_payment_screen.dart` - Profile verification check
- `lib/screens/payment/close_payment_screen.dart` - Added tabs and warning
- `lib/providers/auth_provider.dart` - Updated (if any changes)

---

## ⚠️ Important Notes

1. **New Package**: `firebase-admin` needs to be installed on server
   - Run: `npm install --production` on server

2. **Identity Toolkit API**: Must be enabled in Google Cloud Console
   - This is a one-time setup

3. **Service Account**: Your existing JSON file works fine
   - No new JSON file needed

4. **Restart Required**: PM2 needs to restart to load new code
   - Run: `pm2 restart financenotes-backend`

---

## 🧪 Testing After Deployment

1. **Test Forgot Password:**
   - Register a new user (or use existing)
   - Go to login screen
   - Click "Forgot password?"
   - Enter email
   - Check email for reset link

2. **Test Payment Flow:**
   - Try sending payment (should check profile verification)
   - Try closing payment (should see tabs and warning)

---

## 🆘 If Something Goes Wrong

### **Backend won't start:**
```bash
# Check logs
pm2 logs financenotes-backend --lines 100

# Check if firebase-admin is installed
cd /var/www/FinanceNotes/server
npm list firebase-admin

# If missing, install it
npm install --production
```

### **Forgot password doesn't work:**
1. Check Identity Toolkit API is enabled
2. Check service account permissions
3. Check backend logs for errors
4. Verify user exists in Firebase Auth

### **Rollback if needed:**
```bash
# On server, revert to previous commit
cd /var/www/FinanceNotes
git log --oneline  # Find previous commit hash
git reset --hard <previous-commit-hash>
cd server
pm2 restart financenotes-backend
```

---

## ✅ Success Checklist

- [ ] Code committed and pushed to GitHub
- [ ] Code pulled on DigitalOcean server
- [ ] `npm install --production` completed
- [ ] PM2 restarted successfully
- [ ] Backend logs show no errors
- [ ] Identity Toolkit API enabled
- [ ] Tested forgot password feature
- [ ] Tested payment features

---

## 🎯 Ready to Deploy!

Follow the steps above to deploy your changes to production. The forgot password feature will work once:
1. Code is deployed ✅
2. Identity Toolkit API is enabled ⚠️ (one-time setup)
3. Service account has proper permissions ✅ (should already have)

Good luck! 🚀

