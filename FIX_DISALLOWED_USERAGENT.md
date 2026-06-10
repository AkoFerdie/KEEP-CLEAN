# Fix: Error 403 - disallowed_useragent

## The Real Problem

Google is blocking OAuth because your OAuth Consent Screen is in **"Testing" mode** and only allows specific test users.

## Solution: Publish OAuth Consent Screen

### Step 1: Go to Google Cloud Console

1. Open: https://console.cloud.google.com/apis/credentials/consent
2. Make sure you're in the correct project

### Step 2: Edit OAuth Consent Screen

1. Click **"EDIT APP"** button
2. Scroll through all the pages (you can skip most fields)
3. At the bottom, find **"Publishing status"**

### Step 3: Publish the App

**Option A: Publish (Recommended for Development)**
1. Click **"PUBLISH APP"** button
2. Confirm the dialog
3. Your app will be publicly available for OAuth (but still needs verification for production)

**Option B: Add Test Users (Quick Fix)**
1. Stay in "Testing" mode
2. Go to **"Test users"** section
3. Click **"+ ADD USERS"**
4. Add your email: `akoferdie3@gmail.com`
5. Click **"SAVE"**

### Step 4: Wait 5 Minutes

Google needs time to propagate the changes.

### Step 5: Try Again

1. Clear browser cache
2. Hot restart your Flutter app
3. Try "Continue with Google" again
4. Should work now! ✅

---

## Alternative: Use Email/Password for Development

While fixing Google OAuth, you can use email/password authentication:

1. Create account with email/password
2. Test your app features
3. Come back to Google OAuth later

---

## For Production (Later)

When deploying to production:

1. Submit your app for **Google Verification**
2. Add a privacy policy
3. Add terms of service
4. Deploy to a real domain (not localhost)

---

## Quick Test

After making changes, test with this command:

```bash
flutter run -d chrome --web-hostname=localhost --web-port=5000
```

Then try Google sign-in again.

---

✅ Publishing the OAuth consent screen will fix the issue!
