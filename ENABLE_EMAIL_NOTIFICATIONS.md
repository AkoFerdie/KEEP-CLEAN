# Enable Real Email Notifications - Quick Setup Guide

## ✅ Code Updated Successfully!

Your app is now configured to send REAL emails using Supabase's built-in email system.

## 📧 Enable Email in Supabase Dashboard

Follow these steps to start receiving emails on your phone:

### Step 1: Open Supabase Dashboard
1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Select your project (Keep It Clean)

### Step 2: Enable Email Auth
1. Click **"Authentication"** in the left sidebar
2. Click **"Providers"** tab
3. Find **"Email"** in the list
4. Make sure **"Enable Email provider"** is toggled ON ✅
5. Enable **"Confirm email"** if you want (optional)

### Step 3: Configure Email Settings
1. Still in Authentication section, click **"Email Templates"**
2. Find the **"Magic Link"** template (this is used for OTP codes)
3. You can customize the email template if you want

### Step 4: Set Up Email Provider (Important!)

By default, Supabase uses their own email service which has rate limits.

**For Testing (Default - Already Working):**
- Supabase sends emails for free
- Limited to 3 emails per hour for free tier
- Good enough for testing!

**For Production (Recommended):**
1. Go to **Project Settings** → **Auth** → **SMTP Settings**
2. Enable **"Enable Custom SMTP"**
3. Configure with your email provider:
   - **Gmail**: Use your Gmail + App Password
   - **SendGrid**: Use SendGrid SMTP credentials
   - **AWS SES**: Use AWS SMTP credentials

### Gmail Setup (Easiest for Testing):
```
SMTP Host: smtp.gmail.com
SMTP Port: 587
SMTP Username: your-email@gmail.com
SMTP Password: [Create App Password from Google]
Sender Email: your-email@gmail.com
Sender Name: Keep It Clean
```

**To create Gmail App Password:**
1. Go to Google Account → Security
2. Enable 2-Step Verification
3. Search "App passwords"
4. Create new app password for "Mail"
5. Copy the password and paste in Supabase

---

## 🧪 Test It Now!

1. **Hot Restart your Flutter app** (Stop and run again)
2. Go to Settings → Privacy & Security → Two-Factor Authentication
3. Click **"Email Verification"**
4. Click **"Send Verification Code"**
5. **Check your email inbox!** 📬
   - Subject: "Magic Link"
   - Look for the 6-digit code
6. Enter the code in the app
7. Click "Verify"

---

## 📱 Receiving Emails on Your Phone

Make sure:
- ✅ Your phone has email app installed (Gmail, Outlook, etc.)
- ✅ You're logged into the email account associated with your Keep It Clean account
- ✅ Check spam/junk folder if you don't see the email
- ✅ Internet connection is active on your phone

---

## ⚠️ Troubleshooting

### "Failed to send code"
- Check your internet connection
- Verify the email address is correct
- Check Supabase dashboard for errors

### Email not arriving
- **Check spam folder**
- Wait 1-2 minutes (emails can be delayed)
- Check you're using the same email as your account
- Verify Supabase email provider is enabled
- Check Supabase rate limits (3/hour on free tier)

### Still not working?
1. Go to Supabase Dashboard → Logs
2. Look for email-related errors
3. Check if SMTP is configured correctly

---

## 🎉 What Changed

**Before:**
- Test codes shown in snackbar
- No actual emails sent

**Now:**
- Real emails sent via Supabase
- Codes arrive in your email inbox
- Works on your phone! 📱

---

## 💡 Pro Tips

1. **Check Email Immediately**: Codes typically arrive in 10-30 seconds
2. **Look for "Magic Link" Subject**: That's the Supabase email
3. **The Code is 6 Digits**: Easy to spot in the email
4. **Valid for 60 seconds**: Enter it quickly!
5. **Can Resend**: Click "Resend Code" if needed

---

## Next Steps

Once email works, you can:
- ✅ Set up SMS verification (requires Twilio)
- ✅ Customize email templates in Supabase
- ✅ Add your company branding to emails
- ✅ Set up custom domain for emails

Enjoy secure 2FA with real email notifications! 🔐
