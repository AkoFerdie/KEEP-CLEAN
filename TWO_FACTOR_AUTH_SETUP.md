# Two-Factor Authentication Setup Guide

## Current Status: Testing Mode ✅

The 2FA feature is currently in **testing mode**. When you request a verification code:
- A 6-digit code is generated
- The code appears in a **snackbar message** at the bottom of your screen
- **No actual email or SMS is sent**

Look for messages like:
```
"Code sent! (Test code: 123456)"
```

---

## Setting Up Real Email/SMS Sending 📧📱

To make 2FA actually send emails and SMS, you need to integrate with external services:

### Option 1: Email with Supabase (Recommended)

#### Step 1: Create a Supabase Edge Function

1. Install Supabase CLI:
```bash
npm install -g supabase
```

2. Create an edge function:
```bash
supabase functions new send-2fa-email
```

3. Add this code to `supabase/functions/send-2fa-email/index.ts`:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')

serve(async (req) => {
  const { email, code } = await req.json()

  const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SENDGRID_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{
        to: [{ email }],
        subject: 'Your 2FA Verification Code',
      }],
      from: { email: 'noreply@yourdomain.com' },
      content: [{
        type: 'text/html',
        value: `
          <h2>Your Verification Code</h2>
          <p>Your 2FA code is: <strong>${code}</strong></p>
          <p>This code will expire in 10 minutes.</p>
        `,
      }],
    }),
  })

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

4. Deploy the function:
```bash
supabase functions deploy send-2fa-email
```

5. Set your SendGrid API key:
```bash
supabase secrets set SENDGRID_API_KEY=your_api_key_here
```

#### Step 2: Update Flutter Code

In `lib/screens/two_factor_auth_page.dart`, update the `_sendEmailVerificationCode` method:

```dart
void _sendEmailVerificationCode(String email) async {
  _showSnack("Sending verification code to $email...");

  try {
    // Call Supabase edge function
    final response = await SupabaseService.client.functions.invoke(
      'send-2fa-email',
      body: {'email': email},
    );

    final code = response.data['code'] as String;
    
    if (mounted) {
      _showSnack("Verification code sent!");
      _showEmailVerificationDialog(code);
    }
  } catch (e) {
    _showSnack("Failed to send code. Please try again.");
  }
}
```

---

### Option 2: Email with SendGrid (Direct)

#### Step 1: Get SendGrid API Key
1. Sign up at [sendgrid.com](https://sendgrid.com)
2. Create an API key
3. Verify your sender email

#### Step 2: Add SendGrid Package
Add to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

#### Step 3: Create Email Service
Create `lib/services/email_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  static const String _apiKey = 'YOUR_SENDGRID_API_KEY';
  
  static Future<bool> send2FACode(String email, String code) async {
    final response = await http.post(
      Uri.parse('https://api.sendgrid.com/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [{
          'to': [{'email': email}],
          'subject': 'Your 2FA Verification Code',
        }],
        'from': {'email': 'noreply@yourdomain.com'},
        'content': [{
          'type': 'text/html',
          'value': '''
            <h2>Your Verification Code</h2>
            <p>Your 2FA code is: <strong>$code</strong></p>
            <p>This code will expire in 10 minutes.</p>
          ''',
        }],
      }),
    );
    
    return response.statusCode == 202;
  }
}
```

---

### Option 3: SMS with Twilio

#### Step 1: Get Twilio Account
1. Sign up at [twilio.com](https://www.twilio.com)
2. Get your Account SID and Auth Token
3. Get a Twilio phone number

#### Step 2: Add Twilio Package
```yaml
dependencies:
  twilio_flutter: ^0.0.9
```

#### Step 3: Create SMS Service
Create `lib/services/sms_service.dart`:

```dart
import 'package:twilio_flutter/twilio_flutter.dart';

class SMSService {
  static final TwilioFlutter _twilio = TwilioFlutter(
    accountSid: 'YOUR_ACCOUNT_SID',
    authToken: 'YOUR_AUTH_TOKEN',
    twilioNumber: 'YOUR_TWILIO_NUMBER',
  );

  static Future<bool> send2FACode(String phoneNumber, String code) async {
    try {
      await _twilio.sendSMS(
        toNumber: phoneNumber,
        messageBody: 'Your Keep It Clean 2FA code is: $code\nValid for 10 minutes.',
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

### Option 4: Use Supabase Auth (Simplest)

Supabase has built-in email verification:

```dart
// Send magic link or OTP
await SupabaseService.client.auth.signInWithOtp(
  email: email,
  emailRedirectTo: 'your-app://login',
);

// Verify OTP
await SupabaseService.client.auth.verifyOTP(
  email: email,
  token: code,
  type: OtpType.email,
);
```

---

## Database Setup

Create a `verification_codes` table in Supabase:

```sql
create table verification_codes (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id),
  email text,
  phone text,
  code text not null,
  type text not null, -- '2fa_email' or '2fa_sms'
  expires_at timestamp with time zone not null,
  created_at timestamp with time zone default now(),
  constraint unique_user_type unique (user_id, type)
);

-- Enable RLS
alter table verification_codes enable row level security;

-- Policy: Users can only manage their own codes
create policy "Users can manage own codes"
  on verification_codes
  for all
  using (auth.uid() = user_id);
```

---

## Testing the Current Implementation

For now, you can test 2FA like this:

1. Click "Email Verification" in 2FA settings
2. Click "Send Verification Code"
3. **Look at the snackbar at the bottom** - it shows: "Code sent! (Test code: 123456)"
4. Enter that code in the 6-digit input boxes
5. Click "Verify"

Same process works for SMS verification!

---

## Security Best Practices

1. **Never store API keys in code** - Use environment variables
2. **Use HTTPS** for all API calls
3. **Set code expiry** (10 minutes recommended)
4. **Rate limit** code generation (prevent spam)
5. **Delete codes after use**
6. **Log failed attempts**

---

## Need Help?

- SendGrid Docs: https://docs.sendgrid.com
- Twilio Docs: https://www.twilio.com/docs
- Supabase Docs: https://supabase.com/docs
