# Update App in Google Play Console - Closed Testing

## Quick Steps

### 1. Increment Version Number

Your current version is: `1.0.0+7`

You need to increment the build number (the number after `+`) for each new release.

**Update `pubspec.yaml`:**
```yaml
version: 1.0.0+8  # Increment build number: 7 → 8
```

Or if you want to update the version name too:
```yaml
version: 1.0.1+8  # Increment version: 1.0.0 → 1.0.1, build: 7 → 8
```

### 2. Build Release App Bundle (AAB)

Run this command to build the production app bundle:

```powershell
# Navigate to project root
cd D:\FN-flutter-node.js

# Build production app bundle
flutter build appbundle --flavor prod
```

**Output location:**
```
build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### 3. Upload to Google Play Console - Closed Testing

1. **Go to Google Play Console:**
   - Visit: https://play.google.com/console
   - Select your app: **Finance Notes**

2. **Navigate to Closed Testing:**
   - Go to: **Testing** → **Closed testing**
   - Select your testing track (or create a new one)

3. **Create New Release:**
   - Click **"Create new release"** or **"Manage track"** → **"Create new release"**
   - Or if you already have a release, click **"Create new release"**

4. **Upload AAB:**
   - Click **"Upload"** or drag & drop
   - Select: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`
   - Wait for upload to complete

5. **Add Release Notes:**
   - In the **"Release name"** field: `1.0.0 (8)` or `1.0.1 (8)`
   - In the **"Release notes"** field, add what's new:
     ```
     What's new in this version:
     - Added push notifications for chat messages
     - Enhanced Aadhaar verification with duplicate detection
     - Real-time validation for Aadhaar input
     - Bug fixes and performance improvements
     ```

6. **Review and Publish:**
   - Review the release details
   - Click **"Save"** or **"Review release"**
   - Click **"Start rollout to Closed testing"**
   - Confirm the release

### 4. Testing Groups

After uploading:
- The app will be available to your testers within a few minutes
- Testers need to join your testing group (if not already)
- They'll receive an email notification if enabled

## Complete Command Sequence

```powershell
# 1. Navigate to project
cd D:\FN-flutter-node.js

# 2. Clean previous builds (optional, recommended)
flutter clean

# 3. Get dependencies (ensure everything is up to date)
flutter pub get

# 4. Build production app bundle
flutter build appbundle --flavor prod

# 5. Locate the AAB file
# File: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

## Version Number Guidelines

- **Version name** (before `+`): `1.0.0`, `1.0.1`, `1.1.0`, etc.
  - Increment for major changes or features
  - Format: `major.minor.patch`

- **Build number** (after `+`): `8`, `9`, `10`, etc.
  - **Must always increment** for each new upload to Play Console
  - Even if version name stays the same
  - Play Console requires higher build number than previous upload

## Quick Version Update Script

You can manually update `pubspec.yaml`:

```yaml
# Current:
version: 1.0.0+7

# Update to:
version: 1.0.0+8  # Or 1.0.1+8 for version bump
```

## Verification Steps

After building:

1. **Check AAB file exists:**
   ```powershell
   Test-Path "build/app/outputs/bundle/prodRelease/app-prod-release.aab"
   ```
   Should return: `True`

2. **Check file size:**
   - AAB should be reasonable size (usually 20-50 MB for Flutter apps)
   - If too large, consider enabling ProGuard/R8

3. **Test the build locally (optional):**
   ```powershell
   flutter build apk --flavor prod
   # Install and test: build/app/outputs/flutter-apk/app-prod-release.apk
   ```

## Important Notes

- ✅ **Build number must be unique and higher** than previous upload
- ✅ **AAB format is required** (not APK) for Play Console
- ✅ **Signed with your release keystore** (automatic with key.properties)
- ✅ **Closed testing** allows testing before production release
- ✅ **Multiple tracks** can be used (internal, alpha, beta, etc.)

## Troubleshooting

### Issue: "Version code must be higher"
**Solution:** Increment the build number in `pubspec.yaml`

### Issue: "AAB file not found"
**Solution:** 
1. Check the build completed successfully
2. Verify path: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`
3. Run `flutter clean` and rebuild

### Issue: "Upload failed"
**Solution:**
1. Check file size (should be reasonable)
2. Verify internet connection
3. Try uploading again
4. Check Play Console for specific error messages

## Next Steps After Upload

1. **Monitor rollout:**
   - Check Play Console for processing status
   - Usually completes within 1-2 hours

2. **Notify testers:**
   - Share testing link with your testers
   - They can download from Play Store testing page

3. **Monitor feedback:**
   - Check for crash reports
   - Monitor user feedback
   - Fix issues before production release

