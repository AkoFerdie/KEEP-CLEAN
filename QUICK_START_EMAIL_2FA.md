# 📧 Send 2FA Codes to Email - Quick Start

## 3 Simple Steps

### 1️⃣ Get Free API Key (2 minutes)

```
Go to: https://resend.com/
Sign up → Get API key → Copy it
```

It looks like: `re_AbCd1234EfGh5678`

---

### 2️⃣ Add API Key to App (1 minute)

**Open file:** `lib/services/email_service.dart`

**Find line 7:**
```dart
static const String _resendApiKey = 're_123456789_YOUR_API_KEY_HERE';
```

**Replace with your key:**
```dart
static const String _resendApiKey = 're_AbCd1234EfGh5678';
```

**Save file!** (Ctrl + S or Cmd + S)

---

### 3️⃣ Test It! (2 minutes)

```bash
# Hot restart your app
r
```

Then in the app:
```
Profile → Settings → Two-Factor Auth
  ↓
Click "Email Verification"
  ↓
Click "Send Verification Code"
  ↓
Check your email inbox! 📧
```

---

## What You'll Receive

A beautiful email with:
- 🌱 Keep It Clean branding
- 🔢 Large 6-digit code
- 🔒 Security information
- ⚠️ Warning about phishing

---

## Resend Free Tier

✅ 100 emails per day (FREE forever!)
✅ No credit card required
✅ Professional delivery
✅ Perfect for testing

---

## If Email Doesn't Arrive

1. ✅ Check spam/junk folder
2. ✅ Verify API key is correct (starts with `re_`)
3. ✅ Make sure you hot restarted (not hot reload)
4. ✅ Check Flutter console for errors

---

## File Location

```
flutter_application_1/
  └── lib/
      └── services/
          └── email_service.dart  ← Add API key here!
```

---

## Support

- Resend Docs: https://resend.com/docs
- Get API Key: https://resend.com/api-keys
- Full Guide: See `SEND_2FA_EMAILS_SETUP.md`

---

🎉 That's it! Your app now sends real emails!

**Total time:** 5 minutes  
**Cost:** FREE  
**Result:** Professional 2FA emails ✨
