# Volunteer Event Registration System - Testing Guide

## Overview
This guide walks you through testing the complete event registration flow for your Flutter app.

## Implementation Summary

### What We've Implemented

#### 1. **Enhanced Registration Data Storage** (`supabase_service.dart`)
- Updated `registerForCampaign()` to automatically capture:
  - ✅ User registration timestamp (`registeredAt`)
  - ✅ Event ID (`eventId`)
  - ✅ Event location (`eventLocation`)
  - ✅ Event date and time (`eventDate`, `eventTime`)
  - ✅ Registration status (`registrationStatus`)
  - ✅ All form data: name, phone, email, t-shirt size, experience level, transportation

#### 2. **Enhanced Volunteer Dashboard** (`volunteer_dashboard.dart`)
- Updated `_buildVolunteersTab()` to display:
  - ✅ Volunteer name and email with avatar
  - ✅ Registration time (e.g., "Registered 2 hours ago")
  - ✅ Event details (location, date, time)
  - ✅ Contact information (phone)
  - ✅ T-shirt size, experience level, and transportation info
  - ✅ Enhanced card layout with event details section

#### 3. **Registration Form** (`engage_page.dart`)
- Already has working registration form with:
  - ✅ Full Name (required)
  - ✅ Phone Number (required)
  - ✅ Email Address
  - ✅ T-Shirt Size dropdown
  - ✅ Experience Level dropdown
  - ✅ Transportation checkbox

---

## Testing Steps

### Step 1: Create an Event (As a Volunteer)
1. **Log in as a Volunteer account**
2. **Navigate to Engage Page** (Events)
3. **Switch to "Create Event" tab**
4. **Fill in event details:**
   - Location: "Main Park - Downtown"
   - Date: Pick tomorrow's date
   - Time: Pick a time (e.g., 09:00 AM)
   - Description: "Beach cleanup event"
5. **Optional:** Add images for the event
6. **Click "Post Event"**
   - Expected: See success message "✅ Event posted successfully!"

### Step 2: Register for Event (As a Regular User)
1. **Log in as a Regular User account** (different from volunteer)
2. **Navigate to Engage Page**
3. **Browse Events tab** - You should see the event you just created
4. **Click the "Register" button** on the event card
5. **Fill in Registration Form:**
   - Full Name: "John Smith"
   - Phone: "+1-555-0123"
   - Email: "john@example.com"
   - T-Shirt Size: "L"
   - Experience: "Beginner"
   - Transportation: ✓ Check the box if you have transport
6. **Click "Register" button**
   - Expected: See success message "🎉 Successfully registered for event!"

### Step 3: View Registrations in Volunteer Dashboard
1. **Log back in as the Volunteer** (who created the event)
2. **Go to Volunteer Dashboard**
3. **Click on "Volunteers" tab**
4. **Verify you can see:**
   - ✅ John Smith's name with avatar
   - ✅ His email (john@example.com)
   - ✅ "Registered X minutes ago" status
   - ✅ Event details (location, date, time)
   - ✅ Phone number
   - ✅ T-shirt size "L"
   - ✅ Experience level "Beginner"
   - ✅ Transportation indicator "🚗 Has Transport"

### Step 4: Test Multiple Registrations
1. **Create another event** as the Volunteer
2. **Log in as a different Regular User** (or same user)
3. **Register for the new event** with different details
4. **Go back to Volunteer Dashboard**
5. **In Volunteers tab, you should see:**
   - ✅ Both registered users listed
   - ✅ Each with their respective event details
   - ✅ All registration details preserved

### Step 5: Test Unregistration
1. **In Engage Page** (as the registered user)
2. **Find an event you registered for**
3. **Click the "Registered" button** (should show green with checkmark)
4. **Confirm unregistration**
   - Expected: See message "✅ Unregistered from event"
5. **Go back to Volunteer Dashboard**
6. **Verify the volunteer is removed** from the Volunteers tab

---

## Expected Data Structure in Supabase

### campaigns table - registration_details field
```json
{
  "user-uuid-1": {
    "name": "John Smith",
    "phone": "+1-555-0123",
    "email": "john@example.com",
    "tshirtSize": "L",
    "experience": "Beginner",
    "hasTransport": true,
    "registeredAt": "2024-05-27T14:30:00Z",
    "eventId": "campaign-uuid",
    "eventLocation": "Main Park - Downtown",
    "eventDate": "2024-05-28",
    "eventTime": "09:00 AM",
    "registrationStatus": "registered"
  },
  "user-uuid-2": {
    "name": "Jane Doe",
    "phone": "+1-555-0124",
    "email": "jane@example.com",
    "tshirtSize": "M",
    "experience": "Expert",
    "hasTransport": false,
    "registeredAt": "2024-05-27T15:00:00Z",
    "eventId": "campaign-uuid",
    "eventLocation": "Main Park - Downtown",
    "eventDate": "2024-05-28",
    "eventTime": "09:00 AM",
    "registrationStatus": "registered"
  }
}
```

---

## Troubleshooting

### Issue: Volunteers tab is empty
**Solution:**
1. Verify event was created successfully (should appear in Events tab)
2. Verify registration form was submitted (should see success message)
3. Check Supabase console → campaigns table → registration_details field
4. Make sure you're logged in as the volunteer who created the event

### Issue: Registration form doesn't appear
**Solution:**
1. Make sure you're logged in as a non-volunteer user
2. Make sure you haven't already registered for the event
3. Refresh the app and try again

### Issue: Data not showing in Supabase
**Solution:**
1. Open Supabase console
2. Go to campaigns table
3. Check the registration_details column (should be JSON)
4. Verify the data is being saved with correct structure

### Issue: Timestamp shows "Unknown Date"
**Solution:**
1. This means registration_details doesn't have eventDate/eventTime
2. Old registrations made before our update won't have this field
3. Make new registrations after code deployment
4. (Optional) Manually migrate old data in Supabase

---

## Features Added

✅ **Automatic Timestamps** - Know exactly when volunteers registered
✅ **Event Information** - See which event each volunteer registered for
✅ **Enhanced UI** - Better visual organization of volunteer information
✅ **Complete Data** - All form data preserved and displayed
✅ **Real-time Updates** - Volunteers tab updates instantly when registrations occur

---

## Next Steps (Optional Enhancements)

1. **Add volunteer status tracking:**
   - Change status to "checked-in" when volunteer arrives
   - Track "completed" status when cleanup is done

2. **Add volunteer notes:**
   - Volunteer can leave notes about their availability
   - Volunteer coordinator can add notes about performance

3. **Export volunteers list:**
   - CSV export for volunteer management
   - Print-friendly volunteer list

4. **Send notifications:**
   - Email confirmation when volunteer registers
   - SMS reminder before event starts

5. **Volunteer history:**
   - Track total events participated
   - Track total hours contributed
   - Show volunteer badges/achievements

---

## Database Columns Reference

**campaigns table fields:**
- `id` - Campaign/Event UUID
- `created_by` - Volunteer's user ID
- `location` - Event location
- `date` - Event date
- `time` - Event time
- `registrations` - Array of registered user IDs
- `registration_count` - Count of registrations
- `registration_details` - JSONB with detailed volunteer info
- `status` - Event status (active, completed, etc.)

---

## Questions?

If you encounter any issues:
1. Check the console for error messages
2. Verify Supabase connection is working
3. Ensure all users are properly authenticated
4. Check that role-based access is correctly set

