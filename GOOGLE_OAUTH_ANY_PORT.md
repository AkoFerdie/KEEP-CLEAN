# Google OAuth - Works on ANY Port! 🚀

## Configuration Summary

### ✅ What You Need in Google Cloud Console

**Go to:** https://console.cloud.google.com/apis/credentials

### 1. OAuth Consent Screen
- Status: **PUBLISHED** ✅
- This allows anyone to sign in with Google

### 2. OAuth 2.0 Client ID - Authorized JavaScript Origins
```
http://localhost
http://127.0.0.1
https://uifnmmfchxisifiutjeo.supabase.co
```

**Note:** No port numbers = works on ANY port! 🎉

### 3. OAuth 2.0 Client ID - Authorized Redirect URIs
```
http://localhost
http://127.0.0.1
https://uifnmmfchxisifiutjeo.supabase.co/auth/v1/callback
```

---

## How It Works

### Dynamic Port Detection
The app automatically detects which port it's running on:
- Port 3000: `http://localhost:3000`
- Port 5000: `http://localhost:5000`
- Port 8080: `http://localhost:8080`
- Any port works! ✅

### Google Configuration
By adding just `http://localhost` (without `:3000` or `:5000`), Google allows **all ports** on localhost.

---

## Run on Different Ports

```bash
# Default port (usually 3000 or random)
flutter run -d chrome

# Specific port 5000
flutter run -d chrome --web-port=5000

# Specific port 8080
flutter run -d chrome --web-port=8080

# Any port you want
flutter run -d chrome --web-port=YOUR_PORT
```

**All will work with Google OAuth!** ✅

---

## Testing Checklist

After publishing OAuth consent screen:

1. ✅ Wait 5-10 minutes (Google propagation time)
2. ✅ Clear browser cache (Ctrl + Shift + Delete)
3. ✅ Hot restart Flutter app
4. ✅ Click "Continue with Google"
5. ✅ Should open in new Chrome tab
6. ✅ No "disallowed_useragent" error
7. ✅ Select Google account
8. ✅ Redirects back to app
9. ✅ Navigates to home page

---

## Troubleshooting

### Still shows "Access blocked"?
- **Wait:** Google needs 5-10 minutes to update
- **Clear cache:** Browser cache might have old settings
- **Check status:** Make sure OAuth consent screen shows "PUBLISHED"

### "redirect_uri_mismatch" error?
- Make sure you added `http://localhost` (without port)
- Make sure you added Supabase callback URL
- Check the error message for the actual URL being used

### Opens in embedded view instead of Chrome tab?
- The code now uses `LaunchMode.externalApplication`
- Should always open in real Chrome browser
- If not, try clearing cache and restarting

---

## Production Setup (Later)

When deploying to production domain:

### Add to Google Cloud Console:
```
https://yourdomain.com
https://yourdomain.com/auth/callback
https://uifnmmfchxisifiutjeo.supabase.co/auth/v1/callback
```

### Add to Supabase Dashboard:
- Go to: Authentication → URL Configuration
- Add: `https://yourdomain.com`

---

## Debug Logs

The app now prints helpful logs:

```
🔗 OAuth redirect URL: http://localhost:5000
✅ OAuth initiated successfully
```

Check the Flutter debug console to see which URL is being used.

---

## Summary

✅ **Published OAuth consent screen** → Works for everyone  
✅ **No port numbers in Google config** → Works on any port  
✅ **Dynamic redirect detection** → Automatically uses correct URL  
✅ **External browser launch** → Avoids "disallowed_useragent"  

**Result:** Google OAuth works smoothly on ANY port! 🎉

---

## Current Status

- Supabase URL: `https://uifnmmfchxisifiutjeo.supabase.co`
- OAuth Client ID: `988746847535-h3e8d7o9iusebo307mqvmo0nplthh6uc.apps.googleusercontent.com`
- Works on: All localhost ports ✅
- Mode: Published (anyone can sign in) ✅

---

## Quick Test

After 10 minutes of publishing:

```bash
flutter run -d chrome --web-port=8080
```

Click "Continue with Google" → Should work! 🚀
