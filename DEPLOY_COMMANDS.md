# Quick Deploy Commands

## 🚀 Step 1: Commit and Push to GitHub

**Run these commands in PowerShell (from project root):**

```powershell
# Make sure you're in the project root
cd D:\FN-flutter-node.js

# Add all changes
git add .

# Commit with descriptive message
git commit -m "Add forgot password feature and payment improvements

- Added Firebase Admin SDK for password reset functionality
- Implemented forgot password endpoint with Firebase Identity Toolkit API
- Added profile Aadhaar verification check before sending payment OTP
- Added Sent/Received tabs to close payment screen
- Added warning dialog when closing sent payments
- Updated payment history screen
- Production-ready code"

# Push to GitHub
git push origin master
```

---

## 🖥️ Step 2: Update DigitalOcean Server

**SSH into your server:**
```bash
ssh root@142.93.213.231
```

**Once connected, run these commands one by one:**
```bash
# 1. Navigate to project
cd /var/www/FinanceNotes

# 2. Pull latest code
git pull origin master

# 3. Go to server directory
cd server

# 4. Install new package (firebase-admin)
npm install --production

# 5. Restart backend
pm2 restart financenotes-backend --update-env

# 6. Check status
pm2 status

# 7. Check logs (should see Firebase Admin initialized)
pm2 logs financenotes-backend --lines 30
```

---

## ✅ Step 3: Verify It Works

**Check logs for:**
```
[Firebase Admin] Initialized successfully
✅ Server running in production mode
📡 Listening on port 5000
```

**Test forgot password:**
- Open your app
- Go to login screen
- Click "Forgot password?"
- Enter email
- Check email inbox

---

## ⚠️ One-Time Setup: Enable Identity Toolkit API

**In Google Cloud Console:**
1. Go to: https://console.cloud.google.com/
2. Select project: `financenotes-11ff0`
3. **APIs & Services** → **Library**
4. Search: **"Identity Toolkit API"**
5. Click **ENABLE**

**This is required for password reset to work!**

---

## 🆘 Troubleshooting

### If backend won't start:
```bash
pm2 logs financenotes-backend --lines 100
# Look for errors, fix them, then:
pm2 restart financenotes-backend
```

### If firebase-admin not found:
```bash
cd /var/www/FinanceNotes/server
npm install --production
pm2 restart financenotes-backend
```

### If forgot password doesn't work:
1. Check Identity Toolkit API is enabled ✅
2. Check backend logs for errors
3. Verify user exists in Firebase Auth

---

## 📝 Summary

1. ✅ Commit and push code to GitHub
2. ✅ Pull code on DigitalOcean server
3. ✅ Install firebase-admin package
4. ✅ Restart PM2 process
5. ✅ Enable Identity Toolkit API (one-time)
6. ✅ Test forgot password feature

**That's it! Your production server will be updated.** 🎉

