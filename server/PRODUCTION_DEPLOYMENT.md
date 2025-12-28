# Production Deployment Guide

## Quick Start Commands

### 1. Update Code and Install Dependencies

```bash
# Navigate to server directory
cd server

# Pull latest code from GitHub (if using git)
git pull origin master

# Install/update dependencies
npm install
```

### 2. Set Environment Variables

Ensure `.env.production` file exists in the `server/` directory with required variables:

```bash
# Required Production Environment Variables
NODE_ENV=production
PORT=5000
MONGO_URI=mongodb://your-mongodb-connection-string
JWT_SECRET=your-jwt-secret-key
GOOGLE_CLIENT_ID=your-google-oauth-web-client-id
CLIENT_ORIGIN=https://your-frontend-url.com
GCP_STORAGE_BUCKET=your-gcs-bucket-name
GCP_STORAGE_KEY_FILE=./path-to-your-service-account-key.json

# Optional
QUICKEKYC_API_KEY=your-quickekyc-api-key
GCP_PROJECT_ID=your-gcp-project-id
```

### 3. Run in Production

#### Option A: Using npm (Simple)

```bash
# Set NODE_ENV to production
export NODE_ENV=production

# Start server
npm start
# or
npm run start:prod
```

#### Option B: Using PM2 (Recommended for Production)

PM2 is a process manager that keeps your application alive forever, reloads it without downtime, and helps manage logs.

**Install PM2 globally (if not installed):**
```bash
npm install -g pm2
```

**Start with PM2:**
```bash
# Set NODE_ENV
export NODE_ENV=production

# Start with PM2
pm2 start index.js --name financenotes-backend --env production
```

**Or use ecosystem.config.js:**
```bash
pm2 start ecosystem.config.js
```

**Useful PM2 Commands:**
```bash
# View running processes
pm2 list

# View logs
pm2 logs financenotes-backend

# Stop server
pm2 stop financenotes-backend

# Restart server
pm2 restart financenotes-backend

# Delete process
pm2 delete financenotes-backend

# Save PM2 process list
pm2 save

# Setup PM2 to start on system boot
pm2 startup
```

### 4. Update and Restart Server (After Code Changes)

```bash
# Step 1: Navigate to server directory
cd server

# Step 2: Pull latest code (if using git)
git pull origin master

# Step 3: Install/update dependencies
npm install

# Step 4: Restart server

# If using npm:
# Stop current process (Ctrl+C) then:
export NODE_ENV=production
npm start

# If using PM2:
pm2 restart financenotes-backend

# Or with zero-downtime reload:
pm2 reload financenotes-backend
```

## Complete Update Script

Create a script `update-production.sh`:

```bash
#!/bin/bash

echo "🔄 Updating Finance Notes Backend..."

# Navigate to server directory
cd server

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin master

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Restart PM2 process
echo "🔄 Restarting server..."
pm2 restart financenotes-backend

# Show logs
echo "✅ Server restarted! Viewing logs..."
pm2 logs financenotes-backend --lines 50
```

Make it executable:
```bash
chmod +x update-production.sh
```

Run it:
```bash
./update-production.sh
```

## Environment Variables Checklist

### Required for Production:

- ✅ `NODE_ENV=production`
- ✅ `MONGO_URI` - MongoDB connection string
- ✅ `JWT_SECRET` - JWT secret (generate with `openssl rand -base64 32`)
- ✅ `GOOGLE_CLIENT_ID` - Google OAuth Web Client ID (client_type: 3)
- ✅ `CLIENT_ORIGIN` - CORS origin (your frontend/API URL)
- ✅ `GCP_STORAGE_BUCKET` - Google Cloud Storage bucket name
- ✅ `GCP_STORAGE_KEY_FILE` - Path to GCP service account JSON key file

### Optional:

- `PORT` - Server port (default: 5000)
- `QUICKEKYC_API_KEY` - QuickeKYC API key
- `GCP_PROJECT_ID` - Google Cloud Project ID

## Verification

After starting the server, verify it's running:

```bash
# Check if server is responding
curl http://localhost:5000/api/health

# Or if using PM2
pm2 status
```

Expected output from health check:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Troubleshooting

### Server won't start
- Check that MongoDB is accessible
- Verify all required environment variables are set in `.env.production`
- Check logs: `pm2 logs financenotes-backend`

### Port already in use
- Change PORT in `.env.production` or
- Kill process using port: `lsof -ti:5000 | xargs kill -9`

### File uploads/downloads fail
- Verify GCP Storage key file exists and is valid
- Check Google Cloud Storage bucket permissions
- Ensure service account has Storage Admin role

## Notes

- The server automatically detects production mode when `NODE_ENV=production`
- Production mode loads `.env.production` file
- Server binds to `0.0.0.0` to allow network access
- Default port is 5000 (configurable via PORT env variable)

