# Google Play Review Access Instructions

## What to Select in Google Play Console

**Select**: "All or some functionality in my app is restricted"

## Instructions to Provide to Google Play Reviewers

Copy and paste the following text into the "Instructions" field in Google Play Console:

---

**App Access Instructions for Google Play Reviewers:**

This app requires user authentication to access all features. Please follow these steps:

**Option 1: Create a Test Account (Recommended)**
1. Open the app
2. Tap "Register" or "Sign Up" button
3. Enter the following information:
   - **Email**: Use any valid email address (e.g., `reviewer.test@gmail.com`)
   - **Password**: Use any password with minimum 6 characters (e.g., `Test1234`)
   - **Name**: Enter any name (e.g., `Test Reviewer`)
   - **Phone**: Optional - can be left blank
4. Complete registration
5. You will be automatically logged in and have full access to all app features

**Option 2: Use Google Sign-In**
1. Open the app
2. Tap "Sign in with Google" button
3. Select any Google account
4. You will be automatically logged in and have full access to all app features

**Important Notes:**
- **Most app features work without Aadhaar verification**: After login, you can test viewing transactions, chat functionality, profile management, and search features without any Aadhaar verification.
- **Send Payment Request feature**: This feature requires Aadhaar verification (security requirement for financial transactions). To test this feature:
  1. Go to Profile section
  2. Enter a valid Aadhaar number (12 digits)
  3. OTP will be sent to the mobile number linked with that Aadhaar
  4. Enter the OTP to verify
  5. Once verified, you can test "Send Payment Request" feature
- **Note**: If you don't have access to a real Aadhaar number for testing, you can still review all other app features. The Send Payment Request feature is the only one requiring Aadhaar verification.
- No subscription or payment is required
- No location permissions are required
- No 2-step verification is needed for basic features
- You can create multiple test accounts if needed

**If you encounter any issues**, you can create a new account using any valid email address and password.

---

## Alternative: Pre-Created Test Account

If you prefer to provide a pre-created test account, you can:

1. **Create a test account manually**:
   - Register in the app with email: `googleplay.reviewer@test.com`
   - Password: `Reviewer@2025`
   - Name: `Google Play Reviewer`

2. **Then provide these credentials**:
   ```
   Email: googleplay.reviewer@test.com
   Password: Reviewer@2025
   ```

**Note**: Make sure to create this account before submitting to Google Play, and ensure the account remains active.

---

## What to Enter in Google Play Console

1. Go to **App Content** → **App Access**
2. Select: **"All or some functionality in my app is restricted"**
3. In the **"Instructions"** field, paste the instructions above (Option 1 or Pre-Created Account)
4. Click **Save**

## Testing Before Submission

Before submitting, test that:
- ✅ You can register a new account
- ✅ You can login with email/password
- ✅ You can login with Google Sign-In
- ✅ All app features are accessible after login
- ✅ No additional verification is required for basic features

