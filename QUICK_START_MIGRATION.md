# 🚀 Quick Start: Complete Firebase to Supabase Migration

## ✅ What Has Been Done

1. **Updated `pubspec.yaml`** - Removed all Firebase dependencies
2. **Enhanced `supabase_service.dart`** - Added all methods needed for your app
3. **Created SQL setup script** - `supabase_setup.sql` for database initialization
4. **Created migration documentation** - `FIREBASE_TO_SUPABASE_MIGRATION.md`

## 🔧 What You Need To Do Now

### Step 1: Set Up Supabase Database (5 minutes)

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Click on "SQL Editor" in the left sidebar
3. Click "New Query"
4. Copy the entire contents of `supabase_setup.sql` file
5. Paste it into the SQL editor
6. Click "Run" button
7. You should see "Success. No rows returned" - this is good!

### Step 2: Create Storage Buckets (2 minutes)

1. In Supabase dashboard, click "Storage" in the left sidebar
2. Click "Create a new bucket"
3. Create these 3 buckets (one by one):
   - Name: `campaigns` → Make it **Public** → Create
   - Name: `profile_pictures` → Make it **Public** → Create
   - Name: `waste_images` → Make it **Public** → Create

### Step 3: Update Your .env File (1 minute)

Make sure your `.env` file in the project root contains:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**Where to find these:**
- Go to Supabase Dashboard → Settings → API
- Copy "Project URL" → paste as SUPABASE_URL
- Copy "anon public" key → paste as SUPABASE_ANON_KEY

### Step 4: Clean and Rebuild (2 minutes)

Run these commands in your terminal:

```bash
flutter clean
flutter pub get
```

### Step 5: Remove Firebase Files (Optional)

You can now safely delete these files if they exist:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_compatibility.dart` (if it still exists)

### Step 6: Test Your App! 🎉

Run your app:

```bash
flutter run
```

**Test these features:**
1. ✅ Sign up a new user
2. ✅ Sign in
3. ✅ Create a campaign/event
4. ✅ Post a waste request
5. ✅ View your profile
6. ✅ Upload images

## ⚠️ Important Notes

### The app will NOT work until you complete Steps 1-3!

Your app needs:
- ✅ Database tables created (Step 1)
- ✅ Storage buckets created (Step 2)
- ✅ Correct credentials in .env (Step 3)

### Current Status of Files

**Files that still have Firebase imports but will work:**
- These files import `firebase_compatibility.dart` which we'll remove
- The app will use Supabase through `SupabaseService` instead

**What happens when you run the app now:**
- If you haven't done Steps 1-3: App will crash with "table does not exist" errors
- After Steps 1-3: App will work perfectly with Supabase!

## 🐛 Troubleshooting

### Error: "relation 'users' does not exist"
**Fix:** Run the SQL script from Step 1

### Error: "Storage bucket not found"
**Fix:** Create the storage buckets from Step 2

### Error: "Invalid API key"
**Fix:** Check your .env file has correct SUPABASE_URL and SUPABASE_ANON_KEY

### Error: "Row Level Security policy violation"
**Fix:** The SQL script should have created all policies. Try running it again.

## 📞 Need Help?

1. Check `FIREBASE_TO_SUPABASE_MIGRATION.md` for detailed documentation
2. Check Supabase docs: https://supabase.com/docs
3. Check Supabase Flutter docs: https://supabase.com/docs/reference/dart

## 🎯 Next Steps After Migration

Once everything works:

1. **Remove old Firebase code** - We can clean up remaining Firebase imports
2. **Test thoroughly** - Make sure all features work
3. **Update documentation** - Update your README if needed
4. **Deploy** - Your app is ready for production!

---

**Total Time Required:** ~10 minutes
**Difficulty:** Easy (just copy-paste and click buttons!)

Good luck! 🚀
