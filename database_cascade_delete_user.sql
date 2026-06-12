-- =====================================================
-- CASCADE DELETE: Auto-delete user data when auth deleted
-- =====================================================
-- Run this in Supabase SQL Editor to automatically clean up
-- user data when you delete a user from Authentication

-- 1. Create function to delete user data when auth user is deleted
CREATE OR REPLACE FUNCTION public.handle_user_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete from users table
  DELETE FROM public.users WHERE id = OLD.id;
  
  -- Delete from points_history table
  DELETE FROM public.points_history WHERE user_id = OLD.id;
  
  -- Delete from verification_codes table
  DELETE FROM public.verification_codes WHERE user_id = OLD.id;
  
  -- You can add more tables here if needed
  -- DELETE FROM public.waste_reports WHERE user_id = OLD.id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_deleted ON auth.users;
CREATE TRIGGER on_auth_user_deleted
  AFTER DELETE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_user_deletion();

-- 3. Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO postgres, service_role;

-- =====================================================
-- MANUAL CLEANUP: Delete specific user data
-- =====================================================
-- If you need to manually delete a specific user's data right now,
-- replace 'USER_ID_HERE' with the actual user ID and run these:

-- DELETE FROM public.verification_codes WHERE user_id = 'USER_ID_HERE';
-- DELETE FROM public.points_history WHERE user_id = 'USER_ID_HERE';
-- DELETE FROM public.users WHERE id = 'USER_ID_HERE';
-- DELETE FROM auth.users WHERE id = 'USER_ID_HERE';

-- =====================================================
-- To check if user still exists in database:
-- =====================================================
-- SELECT * FROM public.users WHERE email = 'your-email@example.com';
