# Privacy Policy URL Setup Guide for Google Play Store

## Overview
This guide explains how to set up your Privacy Policy URL for Google Play Store submission.

## Option 1: GitHub Pages (Free & Recommended)

### Steps:
1. **Create a GitHub Repository** (if not already created):
   - Go to GitHub and create a new repository
   - Or use your existing repository

2. **Host the Privacy Policy**:
   - Copy the `PRIVACY_POLICY.md` file
   - Rename it to `privacy-policy.html` or `index.html` in a `docs` folder
   - Commit and push to your repository

3. **Enable GitHub Pages**:
   - Go to your repository Settings
   - Scroll to "Pages" section
   - Select source branch (usually `main` or `master`)
   - Select folder (usually `/docs` or `/root`)
   - Click Save

4. **Your Privacy Policy URL will be**:
   ```
   https://[your-username].github.io/[repository-name]/privacy-policy.html
   ```
   Example: `https://notreallymani.github.io/FinanceNotes/privacy-policy.html`

### Convert Markdown to HTML:
You can use online tools like:
- https://dillinger.io/
- https://www.markdowntohtml.com/
- Or GitHub's built-in markdown renderer

## Option 2: Your Own Website

If you have your own website:

1. **Upload the Privacy Policy**:
   - Convert `PRIVACY_POLICY.md` to HTML
   - Upload to your website
   - Example: `https://yourdomain.com/privacy-policy.html`

2. **Use this URL in Google Play Console**:
   ```
   https://yourdomain.com/privacy-policy.html
   ```

## Option 3: Use a Privacy Policy Generator

You can also use services like:
- https://www.freeprivacypolicy.com/
- https://www.privacypolicygenerator.info/
- https://termly.io/

These services will generate a privacy policy and provide a URL.

## What to Put in Google Play Console

In the "Privacy Policy URL" field, enter one of the following:

### If using GitHub Pages:
```
https://notreallymani.github.io/FinanceNotes/privacy-policy.html
```

### If using your own domain:
```
https://yourdomain.com/privacy-policy.html
```

### If using a generator service:
```
[The URL provided by the service]
```

## Important Notes

1. **The URL must be publicly accessible** - Google needs to verify the link
2. **Use HTTPS** - Secure connection is preferred
3. **Keep it updated** - Update the policy when you make changes to data collection
4. **Make it readable** - Ensure proper formatting and clear language

## Quick Setup (GitHub Pages)

1. In your repository, create a folder called `docs`
2. Create a file `privacy-policy.html` in the `docs` folder
3. Copy the content from `PRIVACY_POLICY.md` and convert to HTML
4. Commit and push
5. Enable GitHub Pages in repository settings
6. Use this URL: `https://[username].github.io/[repo]/privacy-policy.html`

## Testing

Before submitting to Google Play:
1. Open the URL in a web browser
2. Verify it loads correctly
3. Ensure it's accessible without login
4. Check that all formatting is correct
5. Verify HTTPS is working

## Next Steps

After setting up your Privacy Policy URL:
1. Enter the URL in Google Play Console
2. Continue with other store listing requirements
3. Complete the Data Safety section
4. Submit your app for review

