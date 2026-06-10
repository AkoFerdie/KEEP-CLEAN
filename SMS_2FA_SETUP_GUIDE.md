# SMS 2FA Setup Guide 📱

## What You'll Get

Send **real SMS messages** with 6-digit verification codes to any phone number!

## Quick Setup (10 Minutes)

### Step 1: Get Free Twilio Account (5 minutes)

1. **Go to:** https://www.twilio.com/try-twilio
2. **Sign up** (FREE - gets you $15 credit = ~500 SMS!)
3. **Verify your email**
4. **Verify your phone number** (required for trial)

### Step 2: Get Your Credentials (2 minutes)

After signing up, you'll see your dashboard:

1. **Account SID** - Copy this (looks like: `ACxxxxxxxxxxxxxxxxxxxx`)
2. **Auth Token** - Click "Show" and copy it
3. **Phone Number** - Click "Get a Trial Number" (looks like: `+1234567890`)

### Step 3: Add to Your Code (2 minutes)

Open: `lib/services/sms_service.dart`

**Find lines 6-8:**
```dart
static const String _twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID';
static const String _twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN';
static const String _twilioPhoneNumber = '+15017122661';
```

**Replace with your actual values:**
```dart
static const String _twilioAccountSid = 'AC1234567890abcdef';
static const String _twilioAuthToken = 'your_auth_token_here';
static const String _twilioPhoneNumber = '+12345678901';
```

**Save the file!**

### Step 4: Test It! (1 minute)

```bash
flutter run -d chrome
```

1. Go to: Profile → Settings → Two-Factor Auth
2. Click "SMS Verification"
3. Enter your phone number (with country code: +1234567890)
4. Click "Send Code"
5. **Check your phone!** 📱

---

## Twilio Free Trial Details

✅ **$15 credit** (plenty for testing!)
✅ **~500 SMS messages**
✅ **Can send to verified numbers**
✅ **Works worldwide**

### Trial Limitations:
- ⚠️ Can only send to **verified phone numbers**
- ⚠️ Messages include "Sent from your Twilio trial account"
- ⚠️ After $15 used, need to upgrade

### To Verify More Numbers:
1. Go to: https://www.twilio.com/console/phone-numbers/verified
2. Click "Add a new number"
3. Enter phone number
4. Verify via SMS

---

## SMS Message Format

The SMS your users receive:

```
Keep It Clean - Verification Code

Your 2FA code is: 123456

This code expires in 10 minutes.
Don't share this code with anyone.

- Keep It Clean Team

Sent from your Twilio trial account
```

---

## Testing Mode (Without Twilio)

If you don't have Twilio credentials yet, the app works in **TESTING MODE**:

1. Click "SMS Verification"
2. Enter any phone number
3. Check **Flutter console** for the code
4. Enter code in the app
5. Works! ✅

The console shows:
```
⚠️ TESTING MODE: No Twilio credentials set
🔐 TEST CODE for +1234567890: 123456
💡 Get free trial: https://www.twilio.com/try-twilio
```

---

## Phone Number Format

The app automatically formats phone numbers:

| You Enter | App Converts To |
|-----------|-----------------|
| `5551234567` | `+15551234567` |
| `(555) 123-4567` | `+15551234567` |
| `+1 555 123 4567` | `+15551234567` |
| `+44 20 1234 5678` | `+442012345678` |

**Always include country code for best results!**

---

## Production Setup

### For Live App (After Trial):

1. **Upgrade Twilio Account** (pay-as-you-go)
2. **Pricing:** ~$0.01-0.02 per SMS (depends on country)
3. **No more trial limitations**
4. **Can send to any number**
5. **No "trial account" message**

### Cost Estimates:

| Users | SMS/Month | Cost/Month |
|-------|-----------|------------|
| 100 | 200 | $3-4 |
| 1,000 | 2,000 | $30-40 |
| 10,000 | 20,000 | $300-400 |

---

## Alternative SMS Services

If you prefer other services:

### 1. Vonage (formerly Nexmo)
- Free: €2 credit
- Website: https://www.vonage.com/communications-apis/sms/
- Pricing: Similar to Twilio

### 2. AWS SNS (Amazon)
- Very cheap: $0.00645 per SMS (US)
- Website: https://aws.amazon.com/sns/
- Requires AWS account

### 3. Plivo
- Free trial: $15 credit
- Website: https://www.plivo.com/
- Good alternative to Twilio

---

## Troubleshooting

### SMS not arriving?
1. ✅ Check phone number format (+1234567890)
2. ✅ Verify Twilio credentials are correct
3. ✅ Check if phone number is verified (trial account)
4. ✅ Check Twilio logs: https://www.twilio.com/console/sms/logs
5. ✅ Check Flutter console for errors

### "Failed to send SMS" error?
1. ✅ Make sure you hot restarted (not just hot reload)
2. ✅ Verify Account SID starts with `AC`
3. ✅ Check Auth Token is correct
4. ✅ Verify phone number starts with `+`
5. ✅ Check Twilio account has credit

### Web CORS error?
- SMS sending from web has same CORS limitations as email
- **Solution:** Test on mobile/desktop OR use backend API
- Code will show in console for testing

---

## Security Best Practices

### 1. Don't Commit Credentials to GitHub

**Add to .gitignore:**
```
.env
lib/services/sms_service.dart
```

**Use environment variables:**
```dart
static String get _twilioAccountSid => dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
```

### 2. Use Backend API (Production)

For production:
```
Flutter App → Your Backend → Twilio
```

This keeps credentials secure on server.

### 3. Implement Rate Limiting

Prevent abuse:
- Max 3 SMS per phone number per hour
- Max 10 SMS per user per day
- Track failed attempts

### 4. Store Codes Securely

- Store in database with expiry (10 minutes)
- Hash codes before storing
- Delete after use

---

## Quick Start Commands

```bash
# 1. Get Twilio credentials
open https://www.twilio.com/try-twilio

# 2. Add to sms_service.dart
# Replace: YOUR_TWILIO_ACCOUNT_SID, YOUR_TWILIO_AUTH_TOKEN

# 3. Hot restart
flutter run -d chrome

# 4. Test
# Profile → Settings → Two-Factor Auth → SMS Verification
```

---

## Summary

✅ **Setup Time:** 10 minutes  
✅ **Cost:** FREE ($15 credit)  
✅ **SMS Messages:** Plain text format  
✅ **Delivery:** Fast and reliable  
✅ **Trial:** Can send to verified numbers  

---

🎉 **You're all set!** Your app now sends real SMS messages! 📱

Check your phone for the verification code! ✨
