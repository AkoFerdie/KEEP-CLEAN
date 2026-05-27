-- ============================================
-- Keep It Clean - Supabase Database Setup
-- ============================================
-- Run this script in your Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'User',
  profile_image_url TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all profiles" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Create policies
CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. CAMPAIGNS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  location TEXT NOT NULL,
  date TEXT NOT NULL,
  time TEXT NOT NULL,
  description TEXT,
  media_urls TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status TEXT DEFAULT 'active',
  likes INTEGER DEFAULT 0,
  comments JSONB DEFAULT '[]',
  registrations TEXT[] DEFAULT '{}',
  registration_count INTEGER DEFAULT 0,
  registration_details JSONB DEFAULT '{}'
);

-- Enable RLS
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view campaigns" ON campaigns;
DROP POLICY IF EXISTS "Authenticated users can create campaigns" ON campaigns;
DROP POLICY IF EXISTS "Users can update own campaigns" ON campaigns;
DROP POLICY IF EXISTS "Users can delete own campaigns" ON campaigns;

-- Create policies
CREATE POLICY "Anyone can view campaigns" ON campaigns FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create campaigns" ON campaigns FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update own campaigns" ON campaigns FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Users can delete own campaigns" ON campaigns FOR DELETE USING (auth.uid() = created_by);
CREATE POLICY "Users can update campaign registrations" ON campaigns FOR UPDATE USING (true);

-- ============================================
-- 3. WASTE REQUESTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS waste_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  location TEXT NOT NULL,
  phone TEXT NOT NULL,
  amount TEXT NOT NULL,
  pickup_time TEXT NOT NULL,
  description TEXT,
  waste_type TEXT,
  image_urls TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES users(id) ON DELETE CASCADE,
  posted_by TEXT NOT NULL,
  status TEXT DEFAULT 'open',
  accepted_by UUID REFERENCES users(id) ON DELETE SET NULL,
  accepted_by_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE waste_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view waste requests" ON waste_requests;
DROP POLICY IF EXISTS "Authenticated users can create requests" ON waste_requests;
DROP POLICY IF EXISTS "Users can update requests" ON waste_requests;

-- Create policies
CREATE POLICY "Anyone can view waste requests" ON waste_requests FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create requests" ON waste_requests FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update requests" ON waste_requests FOR UPDATE USING (true);

-- ============================================
-- 4. HYSACAM REPORTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS hysacam_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  location TEXT NOT NULL,
  phone TEXT,
  description TEXT,
  image_urls TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES users(id) ON DELETE CASCADE,
  reported_by TEXT NOT NULL,
  status TEXT DEFAULT 'open',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE hysacam_reports ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view reports" ON hysacam_reports;
DROP POLICY IF EXISTS "Authenticated users can create reports" ON hysacam_reports;
DROP POLICY IF EXISTS "Hysacam users can update reports" ON hysacam_reports;

-- Create policies
CREATE POLICY "Anyone can view reports" ON hysacam_reports FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create reports" ON hysacam_reports FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Hysacam users can update reports" ON hysacam_reports FOR UPDATE USING (true);

-- ============================================
-- 5. PATROL SCHEDULE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS patrol_schedule (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  location TEXT NOT NULL,
  date TEXT NOT NULL,
  time TEXT NOT NULL,
  created_by UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE patrol_schedule ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view schedules" ON patrol_schedule;
DROP POLICY IF EXISTS "Hysacam users can create schedules" ON patrol_schedule;
DROP POLICY IF EXISTS "Hysacam users can delete schedules" ON patrol_schedule;

-- Create policies
CREATE POLICY "Anyone can view schedules" ON patrol_schedule FOR SELECT USING (true);
CREATE POLICY "Hysacam users can create schedules" ON patrol_schedule FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Hysacam users can delete schedules" ON patrol_schedule FOR DELETE USING (auth.uid() = created_by);

-- ============================================
-- 6. CREATE INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_campaigns_created_by ON campaigns(created_by);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status);
CREATE INDEX IF NOT EXISTS idx_campaigns_created_at ON campaigns(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_waste_requests_created_by ON waste_requests(created_by);
CREATE INDEX IF NOT EXISTS idx_waste_requests_status ON waste_requests(status);
CREATE INDEX IF NOT EXISTS idx_waste_requests_created_at ON waste_requests(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_hysacam_reports_location ON hysacam_reports(location);
CREATE INDEX IF NOT EXISTS idx_hysacam_reports_status ON hysacam_reports(status);
CREATE INDEX IF NOT EXISTS idx_hysacam_reports_created_at ON hysacam_reports(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_patrol_schedule_created_at ON patrol_schedule(created_at DESC);

-- ============================================
-- 7. CREATE UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to tables with updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_campaigns_updated_at ON campaigns;
CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- Next steps:
-- 1. Create storage buckets: campaigns, profile_pictures, waste_images
-- 2. Make all buckets public
-- 3. Update your .env file with Supabase credentials
-- ============================================
