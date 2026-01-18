# Commands to Update Code on Digital Ocean Server

## Quick Update (Recommended - Using Existing Script)

If you have SSH access to your Digital Ocean server, use the existing update script:

```bash
# 1. SSH into your Digital Ocean server
ssh your-user@your-server-ip

# 2. Navigate to project directory and run the update script
cd /var/www/FinanceNotes
bash UPDATE_PRODUCTION_SERVER.sh
```

## Manual Update (Step by Step)

If you prefer to run commands manually:

```bash
# 1. SSH into your Digital Ocean server
ssh your-user@your-server-ip

# 2. Navigate to project directory
cd /var/www/FinanceNotes

# 3. Pull latest code from GitHub
git pull origin master

# 4. Navigate to server directory
cd server

# 5. Install/update dependencies (this will install firebase-messaging and other new packages)
npm install --production

# 6. Restart the backend service using PM2
pm2 restart financenotes-backend --update-env

# 7. Check service status
pm2 status

# 8. View recent logs to verify everything is working
pm2 logs financenotes-backend --lines 50 --nostream
```

## Alternative: Zero-Downtime Reload (Recommended for Production)

For zero-downtime updates:

```bash
# 1-4. Same as above (SSH, navigate, pull, install)
cd /var/www/FinanceNotes
git pull origin master
cd server
npm install --production

# 5. Reload instead of restart (zero-downtime)
pm2 reload financenotes-backend --update-env

# 6. Check status and logs
pm2 status
pm2 logs financenotes-backend --lines 50 --nostream
```

## Verify Update

After updating, check:

```bash
# Check PM2 process status
pm2 status

# View real-time logs
pm2 logs financenotes-backend

# Check if server is responding
curl http://localhost:5000/api/health
# Or if you have a health endpoint, test it

# View last 100 lines of logs
pm2 logs financenotes-backend --lines 100 --nostream
```

## Important Notes

1. **Dependencies**: The update includes `firebase_messaging` for Flutter (client-side) - you don't need to install this on the server
2. **Backend Dependencies**: The server-side already has `firebase-admin` which is used for push notifications
3. **Environment Variables**: Make sure your `.env.production` file is properly configured (PM2 will use it automatically)
4. **Firebase Service Account**: Ensure your Firebase service account JSON file is in the correct location (`server/financenotes-11ff0-05155bafecde.json`)

## Troubleshooting

If the server fails to start:

```bash
# Check error logs
pm2 logs financenotes-backend --err --lines 100

# Check if port is already in use
netstat -tulpn | grep :5000

# Restart PM2 process
pm2 restart financenotes-backend

# If issues persist, check Node.js version
node --version
# Should be v18.x or higher
```

