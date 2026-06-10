# 📱 SMS 2FA - Quick Reference

## Test NOW (Without Twilio)

You can test immediately:

1. Run app: `flutter run -d chrome`
2. Go to: Profile → Settings → Two-Factor Auth
3. Click "SMS Verification"
4. Enter any phone: `+1234567890`
5. Click "Send Code"
6. **Check Flutter console** for code
7. Enter code in app
8. Works! ✅

---

## Setup Real SMS (10 Minutes)

### 1. Get Twilio (5 min)
```
https://www.twilio.com/try-twilio
→ Sign up FREE
→ Get $15 credit (~500 SMS)
→ Copy: Account SID, Auth Token, Phone Number
```

### 2. Add to Code (2 min)
**File:** `lib/services/sms_service.dart`

**Lines 6-8:**
```dart
static const String _twilioAccountSid = 'YOUR_SID_HERE';
static const String _twilioAuthToken = 'YOUR_TOKEN_HERE';
static const String _twilioPhoneNumber = '+1234567890';
```

### 3. Test (1 min)
```bash
flutter run -d chrome
```

**SMS arrives on your phone!** 📱

---

## Twilio Dashboard

- **Get Credentials:** https://www.twilio.com/console
- **Verify Numbers:** https://www.twilio.com/console/phone-numbers/verified
- **Check Logs:** https://www.twilio.com/console/sms/logs

---

## SMS Message Format

```
Keep It Clean - Verification Code

Your 2FA code is: 123456

This code expires in 10 minutes.
Don't share this code with anyone.

- Keep It Clean Team
```

---

## Phone Number Formats

All these work:
- `+1234567890` ✅
- `(123) 456-7890` ✅
- `123-456-7890` ✅
- `1234567890` ✅ (auto-adds +1)

---

## Free Trial Limits

✅ $15 credit (FREE)
✅ ~500 SMS messages
⚠️ Only to verified numbers
⚠️ Shows "trial account" message

**Upgrade for unlimited!**

---

## Cost After Trial

| SMS Count | Cost |
|-----------|------|
| 100 | ~$2 |
| 1,000 | ~$20 |
| 10,000 | ~$200 |

**Very affordable!** 💰

---

## Files

- `lib/services/sms_service.dart` - Add credentials here
- `SMS_2FA_SETUP_GUIDE.md` - Full guide

---

🎉 SMS 2FA ready to use!
