#!/bin/bash
# Script to update production server on DigitalOcean
# Run this on your DigitalOcean server via SSH

echo "🚀 Updating Production Server..."
echo ""

# Navigate to project directory
cd /var/www/FinanceNotes

echo "📥 Pulling latest code from GitHub..."
git pull origin master

if [ $? -ne 0 ]; then
    echo "❌ Git pull failed!"
    exit 1
fi

echo "✅ Code updated successfully"
echo ""

# Navigate to server directory
cd server

echo "📦 Installing new dependencies (firebase-admin)..."
npm install --production

if [ $? -ne 0 ]; then
    echo "❌ npm install failed!"
    exit 1
fi

echo "✅ Dependencies installed"
echo ""

echo "🔄 Restarting backend service..."
pm2 restart financenotes-backend --update-env

if [ $? -ne 0 ]; then
    echo "❌ PM2 restart failed!"
    exit 1
fi

echo "✅ Backend restarted"
echo ""

echo "📊 Checking service status..."
pm2 status

echo ""
echo "📝 Recent logs:"
pm2 logs financenotes-backend --lines 20 --nostream

echo ""
echo "✅ Update complete!"
echo ""
echo "🔍 Check logs with: pm2 logs financenotes-backend"
echo ""

