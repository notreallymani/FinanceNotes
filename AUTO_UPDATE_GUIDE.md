# Auto-Update Feature Guide

This guide explains how to use and manage the auto-update feature for your Finance Notes app.

## Overview

The auto-update feature allows you to:
- **Check for app updates** automatically when users open the app
- **Prompt users to update** with a beautiful dialog
- **Force updates** for critical security fixes or breaking changes
- **Use Google Play In-App Updates** (Android) for seamless updates

## How It Works

1. **App Startup**: When the app starts, it checks the server for the latest version
2. **Version Comparison**: Compares current app version with server version
3. **Update Prompt**: Shows update dialog if a newer version is available
4. **Update Options**:
   - **In-App Update** (Android): Updates without leaving the app
   - **App Store Redirect**: Opens Google Play Store or App Store

## Current App Version

Your current app version is defined in `pubspec.yaml`:
```yaml
version: 1.0.0+11
```
- `1.0.0` = Version name (user-facing)
- `11` = Build number (used for comparison)

## Server Configuration

The server endpoint is located at: `server/src/routes/app.js`

### Update Server Version

When you release a new version, update the server endpoint:

```javascript
// server/src/routes/app.js
const latestVersion = {
  version: '1.0.1',           // New version name
  buildNumber: 12,            // Must be higher than current (11 → 12)
  forceUpdate: false,         // Set to true to force update
  message: 'A new version is available with bug fixes...',
  releaseNotes: [
    'Bug fixes and performance improvements',
    'New features added',
  ],
};
```

### Force Update

Set `forceUpdate: true` to prevent users from using the app until they update:

```javascript
const latestVersion = {
  version: '1.0.1',
  buildNumber: 12,
  forceUpdate: true,  // Users cannot dismiss the dialog
  message: 'Critical security update required. Please update now.',
};
```

## Deployment Steps

### 1. Update App Version

In `pubspec.yaml`:
```yaml
version: 1.0.1+12  # Increment both version and build number
```

### 2. Update Server Version Endpoint

In `server/src/routes/app.js`:
```javascript
const latestVersion = {
  version: '1.0.1',
  buildNumber: 12,
  forceUpdate: false,
  message: 'New features and improvements available!',
};
```

### 3. Deploy Server Changes

```bash
# SSH into your server
ssh your-user@your-server-ip

# Navigate to project
cd /var/www/FinanceNotes

# Pull latest code
git pull origin master

# Restart server
cd server
pm2 restart financenotes-backend
```

### 4. Build and Upload New App Version

```powershell
# Build production app bundle
flutter build appbundle --flavor prod

# Upload to Google Play Console
# File: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### 5. Release on Google Play

1. Upload the new AAB to Google Play Console
2. Set rollout percentage (start with 20% for testing)
3. Monitor for issues
4. Gradually increase to 100%

## Testing Auto-Update

### Test Update Flow

1. **Set server version higher** than your current app:
   ```javascript
   buildNumber: 999  // Much higher than current
   ```

2. **Restart your app** - you should see the update dialog

3. **Test force update**:
   ```javascript
   forceUpdate: true
   ```
   - Dialog should not be dismissible
   - "Later" button should not appear

4. **Test normal update**:
   ```javascript
   forceUpdate: false
   ```
   - Dialog should be dismissible
   - "Later" button should appear

### Test In-App Update (Android)

1. Upload a new version to **Internal Testing** track in Play Console
2. Install the old version on a test device
3. Open the app - it should detect the update
4. Tap "Update Now" - should trigger in-app update

## Version Number Guidelines

### Version Name (e.g., 1.0.0)
- **Major** (1.x.x): Breaking changes, major features
- **Minor** (x.1.x): New features, backward compatible
- **Patch** (x.x.1): Bug fixes, small improvements

### Build Number (e.g., +12)
- **Must always increment** for each new release
- Used for version comparison
- Google Play requires higher build number than previous upload

## API Endpoint

### GET /api/app/version

**Response:**
```json
{
  "version": "1.0.1",
  "buildNumber": 12,
  "forceUpdate": false,
  "message": "A new version is available...",
  "releaseNotes": [
    "Bug fixes",
    "New features"
  ]
}
```

**No authentication required** - this endpoint is public.

## Features

### ✅ Automatic Update Checking
- Checks on app startup
- Non-blocking (doesn't delay app launch)
- Silent failure if server is unavailable

### ✅ Beautiful Update Dialog
- Shows current vs latest version
- Customizable message
- Force update support

### ✅ Google Play In-App Updates
- Seamless updates without leaving app (Android)
- Falls back to Play Store if in-app update unavailable

### ✅ Cross-Platform Support
- Android: In-app updates + Play Store
- iOS: App Store redirect (future: App Store Connect API)

## Troubleshooting

### Update Dialog Not Showing

1. **Check server endpoint**:
   ```bash
   curl http://your-server:5000/api/app/version
   ```

2. **Verify build number**:
   - Server `buildNumber` must be **higher** than app's build number
   - Check `pubspec.yaml` for current build number

3. **Check app logs**:
   ```dart
   debugPrint('[UpdateService] Current: ${currentBuildNumber}');
   debugPrint('[UpdateService] Latest: ${updateInfo.latestBuildNumber}');
   ```

### In-App Update Not Working

1. **Check Play Console**:
   - New version must be uploaded and available
   - Must be in same track (Production, Internal Testing, etc.)

2. **Check device**:
   - Must be signed in to Google Play
   - Must have internet connection

3. **Fallback**:
   - App automatically falls back to Play Store if in-app update fails

## Best Practices

1. **Always increment build number** when releasing
2. **Use force update sparingly** - only for critical issues
3. **Test update flow** before releasing to production
4. **Monitor rollout** - start with small percentage
5. **Update server version** before releasing app
6. **Keep release notes** informative and user-friendly

## Future Enhancements

- [ ] Store version info in database for easier management
- [ ] Admin panel to update version without code changes
- [ ] A/B testing for update prompts
- [ ] Analytics for update acceptance rates
- [ ] iOS App Store Connect API integration

## Support

For issues or questions:
1. Check server logs: `pm2 logs financenotes-backend`
2. Check app logs: Look for `[UpdateService]` and `[UpdateApi]` tags
3. Verify server endpoint is accessible from mobile devices
