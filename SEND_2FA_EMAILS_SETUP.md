# Send 2FA Codes to Real Email - Setup Guide 📧

## What We Built

Your app now sends **beautiful HTML emails** with 6-digit verification codes to real email addresses!

## Quick Setup (5 Minutes)

### Step 1: Get Free Resend API Key

1. **Go to:** https://resend.com/
2. **Click:** "Start Building" or "Sign Up"
3. **Sign up** with your email (it's FREE!)
4. **Go to:** https://resend.com/api-keys
5. **Click:** "Create API Key"
6. **Copy** the key (starts with `re_...`)

### Step 2: Add API Key to Your App

Open: `lib/services/email_service.dart`

Find this line:
```dart
static const String _resendApiKey = 're_123456789_YOUR_API_KEY_HERE';
```

Replace with your actual key:
```dart
static const String _resendApiKey = 're_abcdefgh1234567890';
```

### Step 3: Test It!

1. **Hot restart** your app
2. Go to: Profile → Settings → Two-Factor Authentication
3. Click: "Email Verification"
4. Click: "Send Verification Code"
5. **Check your email inbox!** 📧
6. Enter the 6-digit code from the email
7. Done! ✅

---

## What the Email Looks Like

The email is **professionally designed** with:

✅ **Beautiful green gradient design**
✅ **Large 48px code display**
✅ **Security information**
✅ **Warning about not sharing code**
✅ **Mobile-responsive**
✅ **Keep It Clean branding**

### Email Preview:
```
┌─────────────────────────────────┐
│          🌱                     │
│                                  │
│  Two-Factor Authentication       │
│  Your security code for          │
│  Keep It Clean                   │
│                                  │
│  ┌───────────────────────┐      │
│  │                       │      │
│  │      1 2 3 4 5 6      │      │
│  │                       │      │
│  │  Enter this code in   │      │
│  │  the app              │      │
│  └───────────────────────┘      │
│                                  │
│  🔒 Security Information         │
│  • Code expires in 10 minutes    │
│  • Don't share with anyone       │
│  • We never ask via phone        │
│                                  │
│  ⚠️ Didn't request this?        │
│  Ignore this email and secure    │
│  your account immediately.       │
│                                  │
│  Keep It Clean                   │
│  © 2024 All rights reserved      │
└─────────────────────────────────┘
```

---

## Resend Free Tier

✅ **100 emails per day** (plenty for testing!)
✅ **No credit card required**
✅ **Perfect for development**
✅ **Professional email delivery**

For production with more emails:
- Paid plans start at $20/month for 50,000 emails

---

## Alternative Email Services

If you prefer other services:

### 1. SendGrid (Popular)
- Free: 100 emails/day
- Website: https://sendgrid.com/
- Setup: Similar to Resend

### 2. AWS SES (Amazon)
- Very cheap: $0.10 per 1,000 emails
- Website: https://aws.amazon.com/ses/
- Requires AWS account

### 3. Mailgun
- Free: 100 emails/day
- Website: https://www.mailgun.com/
- Good for transactional emails

### 4. Brevo (formerly Sendinblue)
- Free: 300 emails/day
- Website: https://www.brevo.com/
- European servers

---

## How to Switch Email Service

If you want to use a different service, just update `email_service.dart`:

### For SendGrid:
```dart
final response = await http.post(
  Uri.parse('https://api.sendgrid.com/v3/mail/send'),
  headers: {
    'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'personalizations': [{'to': [{'email': toEmail}]}],
    'from': {'email': 'noreply@yourdomain.com'},
    'subject': '🔐 Your Verification Code',
    'content': [{'type': 'text/html', 'value': _buildEmailTemplate(code)}],
  }),
);
```

### For AWS SES:
Use the `aws_ses_api` package:
```yaml
dependencies:
  aws_ses_api: ^1.0.0
```

---

## Testing Without API Key

If you don't want to set up an email service yet, you can test locally:

### Option 1: Show Code in Dialog (Quick Test)
```dart
void _sendEmailVerificationCode(String email) async {
  final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
  
  // Show code in a dialog for testing
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Test Code'),
      content: Text('Your code is: $code\n\nIn production, this would be sent to $email'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _showEmailVerificationDialog(email, code);
          },
          child: Text('Continue'),
        ),
      ],
    ),
  );
}
```

### Option 2: Use Console Output
Check the Flutter debug console for the code:
```dart
print('🔐 2FA Code for $email: $code');
```

---

## Production Checklist

Before going live:

✅ **Use your own domain** (not `onboarding@resend.dev`)
✅ **Verify your domain** in Resend dashboard
✅ **Add rate limiting** (max 3 attempts per hour)
✅ **Store codes in database** with expiry
✅ **Implement retry logic** for failed sends
✅ **Add analytics** to track email delivery
✅ **Test with multiple email providers** (Gmail, Outlook, Yahoo)
✅ **Add unsubscribe link** (if sending marketing emails)

---

## Verify Domain for Custom Email

To send from `noreply@keepitclean.com` instead of `onboarding@resend.dev`:

1. **Buy a domain** (e.g., from Namecheap, GoDaddy)
2. **Go to Resend Dashboard** → Domains
3. **Add your domain**
4. **Add DNS records** (provided by Resend)
5. **Wait for verification** (usually 5-30 minutes)
6. **Update email_service.dart:**
   ```dart
   static const String _fromEmail = 'noreply@keepitclean.com';
   ```

---

## Troubleshooting

### Email not arriving?
1. ✅ Check spam/junk folder
2. ✅ Verify API key is correct
3. ✅ Check Resend dashboard → Logs
4. ✅ Try different email address
5. ✅ Check Flutter debug console for errors

### "Failed to send email" error?
1. ✅ Make sure you hot restarted (not just hot reload)
2. ✅ Check API key has `re_` prefix
3. ✅ Verify internet connection
4. ✅ Check Resend API status: https://status.resend.com/

### Code showing "Test code" in snackbar?
- This means email sending failed
- Check API key in `email_service.dart`
- Make sure you replaced `re_123456789_YOUR_API_KEY_HERE`

---

## Security Best Practices

### 1. Store API Key Securely
Don't commit API keys to GitHub:

**Add to .gitignore:**
```
.env
```

**Create .env file:**
```
RESEND_API_KEY=re_your_actual_key_here
```

**Load in code:**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static String get _resendApiKey => dotenv.env['RESEND_API_KEY'] ?? '';
```

### 2. Use Backend API (Production)
For production, don't expose API keys in Flutter app:

```
Flutter App → Your Backend API → Resend
```

Create a backend endpoint:
```
POST /api/send-2fa-code
Body: { "email": "user@example.com", "code": "123456" }
```

---

## Cost Estimate

### Development (100 users):
- Resend Free: **$0/month** ✅
- 100 emails/day = 3,000/month (plenty!)

### Production (1,000 users):
- Resend: **$20/month** (50,000 emails)
- AWS SES: **$5/month** (50,000 emails)

### Large Scale (100,000 users):
- Resend: **$80/month** (500,000 emails)
- AWS SES: **$50/month** (500,000 emails)

---

## Summary

✅ **Setup Time:** 5 minutes  
✅ **Cost:** FREE (100 emails/day)  
✅ **Email Design:** Professional HTML template  
✅ **Delivery:** Fast and reliable  
✅ **Easy Integration:** Just add API key  

---

## Quick Start Commands

```bash
# 1. Get API key from Resend
open https://resend.com/api-keys

# 2. Add to email_service.dart
# Replace: re_123456789_YOUR_API_KEY_HERE

# 3. Hot restart
flutter run -d chrome

# 4. Test
# Profile → Settings → Two-Factor Auth → Email Verification
```

---

🎉 **You're all set!** Your app now sends professional 2FA emails! 📧

Check your inbox for the beautiful verification code email! ✨
