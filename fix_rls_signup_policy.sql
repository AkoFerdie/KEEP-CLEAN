-- =====================================================
-- FIX RLS POLICY: Allow user signup in users table
-- =====================================================
-- This fixes the error: "new row violates row-level security policy"

-- 1. Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;

-- 2. Create new policies that allow signup
-- Allow anyone to INSERT their own user record during signup
CREATE POLICY "Allow signup insert"
ON public.users
FOR INSERT
WITH CHECK (auth.uid() = id);

-- Allow users to view their own profile
CREATE POLICY "Users can view own profile"
ON public.users
FOR SELECT
USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON public.users
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 3. Make sure RLS is enabled on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- ALTERNATIVE: If signup still fails, temporarily disable RLS
-- =====================================================
-- ONLY use this for testing, then re-enable RLS after signup works
-- ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- After testing signup, re-enable it:
-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Check current policies
-- =====================================================
-- SELECT * FROM pg_policies WHERE tablename = 'users';
