# 📋 Firebase to Supabase Migration Checklist

## Pre-Migration ✅ COMPLETED
- [x] Backup Firebase data (if needed)
- [x] Create Supabase project
- [x] Update pubspec.yaml dependencies
- [x] Create enhanced SupabaseService
- [x] Create SQL setup scripts
- [x] Create migration documentation

## Database Setup ⏳ YOUR TURN
- [ ] Run `supabase_setup.sql` in Supabase SQL Editor
- [ ] Verify all tables created successfully
  - [ ] users
  - [ ] campaigns
  - [ ] waste_requests
  - [ ] hysacam_reports
  - [ ] patrol_schedule
- [ ] Verify all indexes created
- [ ] Verify all RLS policies active

## Storage Setup ⏳ YOUR TURN
- [ ] Create `campaigns` bucket (Public)
- [ ] Create `profile_pictures` bucket (Public)
- [ ] Create `waste_images` bucket (Public)
- [ ] Test upload to each bucket

## Configuration ⏳ YOUR TURN
- [ ] Update `.env` file with SUPABASE_URL
- [ ] Update `.env` file with SUPABASE_ANON_KEY
- [ ] Verify credentials are correct

## Code Cleanup ⏳ YOUR TURN
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Delete `lib/firebase_compatibility.dart` (optional)
- [ ] Delete `android/app/google-services.json` (optional)
- [ ] Delete `ios/Runner/GoogleService-Info.plist` (optional)

## Testing ⏳ YOUR TURN
- [ ] App builds successfully
- [ ] Sign up new user works
- [ ] Sign in works
- [ ] Sign out works
- [ ] Create campaign works
- [ ] View campaigns works
- [ ] Upload campaign images works
- [ ] Create waste request works
- [ ] View waste requests works
- [ ] Accept waste request works
- [ ] Profile page loads
- [ ] Profile image upload works
- [ ] Dashboard loads
- [ ] Hysacam dashboard works (if applicable)
- [ ] Volunteer dashboard works (if applicable)
- [ ] Patrol schedule works (if applicable)

## Post-Migration ⏳ YOUR TURN
- [ ] Test on Android device
- [ ] Test on iOS device (if applicable)
- [ ] Test on Web (if applicable)
- [ ] Update app documentation
- [ ] Update README.md
- [ ] Remove Firebase from build.gradle (Android)
- [ ] Remove Firebase from Podfile (iOS)
- [ ] Deploy to production

## Known Issues to Watch For
- [ ] Check for any remaining Firebase imports in code
- [ ] Verify all image uploads work correctly
- [ ] Verify real-time updates work
- [ ] Check RLS policies don't block legitimate operations
- [ ] Verify user roles work correctly

## Performance Checks
- [ ] App startup time acceptable
- [ ] Image loading speed acceptable
- [ ] Database queries fast enough
- [ ] No memory leaks
- [ ] No excessive API calls

## Security Checks
- [ ] RLS policies properly configured
- [ ] Storage buckets have correct permissions
- [ ] API keys not exposed in code
- [ ] User data properly protected
- [ ] Authentication working correctly

## Documentation
- [x] Migration guide created
- [x] Quick start guide created
- [x] SQL setup script created
- [ ] Update app README
- [ ] Document any custom changes
- [ ] Create user migration guide (if needed)

## Rollback Plan (Just in Case)
- [ ] Keep Firebase project active for 30 days
- [ ] Document rollback procedure
- [ ] Keep backup of Firebase data
- [ ] Test rollback procedure

---

## Progress Tracker

**Started:** [DATE]
**Completed:** [DATE]
**Time Taken:** [HOURS]

**Blockers/Issues:**
- 

**Notes:**
- 

---

## Quick Reference

### Supabase Dashboard URLs
- Project: https://supabase.com/dashboard/project/[your-project-id]
- SQL Editor: https://supabase.com/dashboard/project/[your-project-id]/sql
- Storage: https://supabase.com/dashboard/project/[your-project-id]/storage
- API Settings: https://supabase.com/dashboard/project/[your-project-id]/settings/api

### Important Files
- SQL Setup: `supabase_setup.sql`
- Quick Start: `QUICK_START_MIGRATION.md`
- Full Guide: `FIREBASE_TO_SUPABASE_MIGRATION.md`
- Service: `lib/services/supabase_service.dart`
- Config: `lib/supabase_config.dart`

### Commands
```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run app
flutter run

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web
```

---

**Good luck with your migration! 🚀**
