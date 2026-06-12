-- ============================================
-- POINTS SYSTEM DATABASE MIGRATION
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → Paste & Run
-- ============================================

-- 1. Add points column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 0;

-- 2. Create points_history table to track point transactions
CREATE TABLE IF NOT EXISTS points_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  points INTEGER NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_points_history_user_id ON points_history(user_id);
CREATE INDEX IF NOT EXISTS idx_points_history_created_at ON points_history(created_at DESC);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE points_history ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for points_history
CREATE POLICY "Users can view their own points history"
  ON points_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert points"
  ON points_history FOR INSERT
  WITH CHECK (true);

-- ============================================
-- VERIFICATION CODES TABLE (for 2FA)
-- ============================================

CREATE TABLE IF NOT EXISTS verification_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  phone TEXT,
  code TEXT NOT NULL,
  type TEXT NOT NULL, -- 'Enabled Two-Factor Authentication'
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verification_codes_email ON verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_verification_codes_user_id ON verification_codes(user_id);

ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own verification codes"
  ON verification_codes FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- DONE! Your database is ready for points system
-- ============================================
