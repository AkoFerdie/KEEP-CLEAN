# Fix "This browser or app may not be secure" Error

## Problem
Google shows: "Couldn't sign you in - This browser or app may not be secure"

## Root Cause
Google OAuth requires proper redirect URIs to be configured in both:
1. Google Cloud Console
2. Supabase Dashboard

---

## Solution: Configure Google OAuth Properly

### Step 1: Find Your Supabase Project URL

1. Go to https://supabase.com/dashboard
2. Select your project
3. Copy your project URL (looks like: `https://xxxxx.supabase.co`)
4. Note the project ref ID (the `xxxxx` part)

---

### Step 2: Configure Google Cloud Console

1. **Go to Google Cloud Console:**
   - https://console.cloud.google.com/apis/credentials

2. **Find Your OAuth 2.0 Client ID:**
   - Look for the client ID: `988746847535-h3e8d7o9iusebo307mqvmo0nplthh6uc.apps.googleusercontent.com`
   - Click to edit it

3. **Add Authorized JavaScript Origins:**
   ```
   http://localhost
   http://localhost:3000
   http://localhost:5000
   http://127.0.0.1:3000
   https://YOUR_PROJECT_REF.supabase.co
   ```

4. **Add Authorized Redirect URIs:**
   ```
   http://localhost
   http://localhost:3000
   http://localhost:5000
   http://127.0.0.1:3000
   https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
   ```

   **IMPORTANT:** Replace `YOUR_PROJECT_REF` with your actual Supabase project reference!

5. **Click Save**

---

### Step 3: Configure Supabase Dashboard

1. **Go to Supabase Dashboard:**
   - https://supabase.com/dashboard
   - Select your project

2. **Navigate to Authentication:**
   - Click **Authentication** in left sidebar
   - Click **Providers**

3. **Configure Google Provider:**
   - Find **Google** in the list
   - Toggle it **ON** if not already enabled
   - Enter your Google credentials:
     - **Client ID:** `988746847535-h3e8d7o9iusebo307mqvmo0nplthh6uc.apps.googleusercontent.com`
     - **Client Secret:** (get this from Google Cloud Console)

4. **Add Redirect URLs:**
   - Under **Redirect URLs**, add:
     ```
     http://localhost:3000/
     http://localhost:5000/
     http://127.0.0.1:3000/
     ```

5. **Click Save**

---

### Step 4: Test Again

1. **Hot restart your Flutter app:**
   ```bash
   flutter run -d chrome
   ```

2. **Click "Continue with Google"**

3. **Should work now!** ✅

---

## Alternative: Use a Real Browser (Chrome)

If you're still having issues with Flutter's web view, you can test in a real Chrome browser:

1. Build for web:
   ```bash
   flutter build web
   ```

2. Serve it:
   ```bash
   cd build/web
   python -m http.server 8080
   ```

3. Open Chrome:
   ```
   http://localhost:8080
   ```

4. Try Google sign-in again

---

## Common Issues

### Issue: "redirect_uri_mismatch"
**Solution:** Make sure the redirect URI in Google Cloud Console **exactly matches** what Supabase is sending. Check the error URL for the actual redirect URI being used.

### Issue: Still showing "not secure"
**Solution:** 
- Wait 5-10 minutes after saving Google Cloud Console settings (propagation delay)
- Clear browser cache
- Try in incognito mode

### Issue: Works in Chrome but not in Flutter debug
**Solution:** This is normal for development. Deploy to a real domain for production, or add `--web-hostname=localhost` flag:
```bash
flutter run -d chrome --web-hostname=localhost --web-port=3000
```

---

## Production Setup

For production, you'll need:

1. **Deploy your app to a real domain** (e.g., Vercel, Netlify, Firebase Hosting)
2. **Add production URLs to Google Cloud Console:**
   ```
   https://yourdomain.com
   https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
   ```
3. **Add to Supabase Redirect URLs:**
   ```
   https://yourdomain.com/
   ```

---

## Quick Test Command

Run with specific port:
```bash
flutter run -d chrome --web-hostname=localhost --web-port=3000
```

Then add to Google Cloud Console:
```
http://localhost:3000
```

---

## Expected Flow After Fix

1. Click "Continue with Google" ✅
2. Google popup opens instantly (1-2s) ⚡
3. Select your Google account
4. **No "not secure" error** ✅
5. Redirects back to your app
6. Navigates to home page ✅

---

## Need Help?

Check Supabase logs:
- Dashboard → Logs → Auth Logs
- Look for OAuth errors

Check browser console:
- F12 → Console tab
- Look for redirect_uri errors

---

✅ Once configured, Google OAuth will work smoothly!
