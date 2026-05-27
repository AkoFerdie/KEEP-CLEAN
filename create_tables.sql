-- ============================================================
-- Keep It Clean - Create All Required Tables
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. USERS TABLE (if not already created)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  email TEXT,
  role TEXT DEFAULT 'user',
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. CAMPAIGNS TABLE
CREATE TABLE IF NOT EXISTS public.campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location TEXT NOT NULL,
  date TEXT,
  time TEXT,
  description TEXT,
  media_urls TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'active',
  likes INTEGER DEFAULT 0,
  comments JSONB DEFAULT '[]',
  registrations TEXT[] DEFAULT '{}',
  registration_count INTEGER DEFAULT 0,
  registration_details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. WASTE REQUESTS TABLE
CREATE TABLE IF NOT EXISTS public.waste_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location TEXT NOT NULL,
  phone TEXT,
  amount TEXT,
  pickup_time TIMESTAMPTZ,
  description TEXT,
  waste_type TEXT,
  image_urls TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  posted_by TEXT,
  profile_image_url TEXT,
  status TEXT DEFAULT 'open',
  accepted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  accepted_by_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. HYSACAM REPORTS TABLE
CREATE TABLE IF NOT EXISTS public.hysacam_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location TEXT NOT NULL,
  description TEXT,
  phone TEXT,
  reported_by TEXT,
  image_urls TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'open',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. PATROL SCHEDULE TABLE
CREATE TABLE IF NOT EXISTS public.patrol_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location TEXT NOT NULL,
  date TEXT,
  time TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. VOLUNTEERS TABLE
CREATE TABLE IF NOT EXISTS public.volunteers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  email TEXT,
  organizer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  campaigns_joined INTEGER DEFAULT 0,
  hours_contributed INTEGER DEFAULT 0,
  joined_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. SCHEDULED POSTS TABLE
CREATE TABLE IF NOT EXISTS public.scheduled_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  location TEXT,
  waste_type TEXT,
  description TEXT,
  image_urls TEXT[] DEFAULT '{}',
  scheduled_time TIMESTAMPTZ,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waste_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hysacam_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patrol_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_posts ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- DROP EXISTING POLICIES (to avoid duplicate errors)
-- ============================================================

-- USERS
DROP POLICY IF EXISTS "Users can read all profiles" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

-- CAMPAIGNS
DROP POLICY IF EXISTS "Anyone can read campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Authenticated users can create campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Users can update own campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Users can delete own campaigns" ON public.campaigns;

-- WASTE REQUESTS
DROP POLICY IF EXISTS "Anyone can read waste requests" ON public.waste_requests;
DROP POLICY IF EXISTS "Authenticated users can create waste requests" ON public.waste_requests;
DROP POLICY IF EXISTS "Users can update own waste requests" ON public.waste_requests;

-- HYSACAM REPORTS
DROP POLICY IF EXISTS "Anyone can read hysacam reports" ON public.hysacam_reports;
DROP POLICY IF EXISTS "Authenticated users can create hysacam reports" ON public.hysacam_reports;
DROP POLICY IF EXISTS "Authenticated users can update hysacam reports" ON public.hysacam_reports;

-- PATROL SCHEDULE
DROP POLICY IF EXISTS "Anyone can read patrol schedule" ON public.patrol_schedule;
DROP POLICY IF EXISTS "Authenticated users can create patrol schedule" ON public.patrol_schedule;
DROP POLICY IF EXISTS "Users can delete own patrol schedule" ON public.patrol_schedule;

-- VOLUNTEERS
DROP POLICY IF EXISTS "Anyone can read volunteers" ON public.volunteers;
DROP POLICY IF EXISTS "Authenticated users can add volunteers" ON public.volunteers;

-- SCHEDULED POSTS
DROP POLICY IF EXISTS "Users can read own scheduled posts" ON public.scheduled_posts;
DROP POLICY IF EXISTS "Users can create scheduled posts" ON public.scheduled_posts;
DROP POLICY IF EXISTS "Users can update own scheduled posts" ON public.scheduled_posts;
DROP POLICY IF EXISTS "Users can delete own scheduled posts" ON public.scheduled_posts;

-- ============================================================
-- CREATE RLS POLICIES
-- ============================================================

-- USERS
CREATE POLICY "Users can read all profiles" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- CAMPAIGNS
CREATE POLICY "Anyone can read campaigns" ON public.campaigns FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create campaigns" ON public.campaigns FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own campaigns" ON public.campaigns FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Users can delete own campaigns" ON public.campaigns FOR DELETE USING (auth.uid() = created_by);

-- WASTE REQUESTS
CREATE POLICY "Anyone can read waste requests" ON public.waste_requests FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create waste requests" ON public.waste_requests FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own waste requests" ON public.waste_requests FOR UPDATE USING (auth.uid() IS NOT NULL);

-- HYSACAM REPORTS
CREATE POLICY "Anyone can read hysacam reports" ON public.hysacam_reports FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create hysacam reports" ON public.hysacam_reports FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can update hysacam reports" ON public.hysacam_reports FOR UPDATE USING (auth.uid() IS NOT NULL);

-- PATROL SCHEDULE
CREATE POLICY "Anyone can read patrol schedule" ON public.patrol_schedule FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create patrol schedule" ON public.patrol_schedule FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can delete own patrol schedule" ON public.patrol_schedule FOR DELETE USING (auth.uid() = created_by);

-- VOLUNTEERS
CREATE POLICY "Anyone can read volunteers" ON public.volunteers FOR SELECT USING (true);
CREATE POLICY "Authenticated users can add volunteers" ON public.volunteers FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- SCHEDULED POSTS
CREATE POLICY "Users can read own scheduled posts" ON public.scheduled_posts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create scheduled posts" ON public.scheduled_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own scheduled posts" ON public.scheduled_posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own scheduled posts" ON public.scheduled_posts FOR DELETE USING (auth.uid() = user_id);
