# 🚀 Firebase to Supabase Migration Guide

## Why Supabase?
- ✅ **FREE image storage** (1GB free tier)
- ✅ **FREE database** (500MB free tier)  
- ✅ **FREE authentication** (50,000 monthly active users)
- ✅ **Real-time subscriptions** included
- ✅ **No credit card required** for free tier
- ✅ **PostgreSQL** (more powerful than Firestore)

## 📋 Setup Steps

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project" 
3. Sign up with GitHub/Google (free)
4. Click "New Project"
5. Choose organization and enter:
   - **Name**: `keep-it-clean`
   - **Database Password**: (create a strong password)
   - **Region**: Choose closest to your users
6. Click "Create new project" (takes ~2 minutes)

### 2. Get API Credentials
1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. Update Environment Variables
Open `.env` file and replace:
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-anon-key-here
```

### 4. Create Database Tables
In Supabase dashboard, go to **SQL Editor** and run this:

```sql
-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Users table
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'User',
  phone TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Waste reports table
CREATE TABLE hysacam_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  location TEXT NOT NULL,
  phone TEXT NOT NULL,
  pickup_time TIMESTAMP WITH TIME ZONE NOT NULL,
  description TEXT,
  image_urls TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES users(id) NOT NULL,
  reported_by TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  report_type TEXT DEFAULT 'waste_report',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Posts/Campaigns table
CREATE TABLE posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT NOT NULL,
  event_date TIMESTAMP WITH TIME ZONE NOT NULL,
  image_urls TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE hysacam_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Enable insert for authenticated users" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for hysacam_reports
CREATE POLICY "Anyone can view reports" ON hysacam_reports
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create reports" ON hysacam_reports
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own reports" ON hysacam_reports
  FOR UPDATE USING (auth.uid() = created_by);

-- RLS Policies for posts
CREATE POLICY "Anyone can view posts" ON posts
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own posts" ON posts
  FOR UPDATE USING (auth.uid() = created_by);
```

### 5. Setup Storage Buckets
1. Go to **Storage** in Supabase dashboard
2. Click "Create bucket"
3. Create these buckets:
   - **Name**: `waste-images` (Public bucket)
   - **Name**: `profile-images` (Public bucket)
   - **Name**: `post-images` (Public bucket)

### 6. Install Dependencies
Run this command:
```bash
flutter pub get
```

## 🔄 Migration Checklist

### ✅ Completed
- [x] Updated `pubspec.yaml` with Supabase dependencies
- [x] Created `SupabaseConfig` class
- [x] Created `SupabaseService` with all methods
- [x] Updated `main.dart` to initialize Supabase
- [x] Updated `.env` with Supabase credentials

### 🔄 Next Steps (Manual)
- [ ] Set up Supabase project and get credentials
- [ ] Update `.env` with real Supabase URL and key
- [ ] Run SQL schema in Supabase dashboard
- [ ] Create storage buckets
- [ ] Update authentication screens to use SupabaseService
- [ ] Update database operations to use SupabaseService
- [ ] Test image upload functionality

## 📱 Key Differences

### Authentication
```dart
// OLD (Firebase)
FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password)

// NEW (Supabase)
SupabaseService.signIn(email: email, password: password)
```

### Database Operations
```dart
// OLD (Firebase)
FirebaseFirestore.instance.collection('users').doc(uid).set(data)

// NEW (Supabase)
SupabaseService.client.from('users').insert(data)
```

### File Upload
```dart
// OLD (Firebase) - PAID
FirebaseStorage.instance.ref().child(path).putFile(file)

// NEW (Supabase) - FREE
SupabaseService.uploadImage(imageFile: file, bucket: 'waste-images')
```

## 🎯 Benefits After Migration
- ✅ **Free image uploads** (no more payment required)
- ✅ **Real-time updates** (see reports instantly)
- ✅ **Better performance** (PostgreSQL is faster)
- ✅ **More storage** (1GB vs Firebase's limited free tier)
- ✅ **SQL queries** (more powerful than Firestore)

## 🆘 Need Help?
If you encounter issues:
1. Check Supabase dashboard logs
2. Verify API credentials in `.env`
3. Ensure RLS policies are set correctly
4. Check network connectivity

## 🚀 Ready to Deploy!
Once setup is complete, your app will have:
- Free image storage for waste reports
- Real-time updates for all users
- Better performance and reliability
- No more Firebase billing surprises!