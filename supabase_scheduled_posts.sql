-- Create scheduled_posts table
CREATE TABLE IF NOT EXISTS scheduled_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  location TEXT NOT NULL,
  waste_type TEXT NOT NULL,
  description TEXT NOT NULL,
  image_urls TEXT[] NOT NULL,
  scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'posted', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE scheduled_posts ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own scheduled posts" ON scheduled_posts;
CREATE POLICY "Users can view own scheduled posts"
ON scheduled_posts FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create scheduled posts" ON scheduled_posts;
CREATE POLICY "Users can create scheduled posts"
ON scheduled_posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own scheduled posts" ON scheduled_posts;
CREATE POLICY "Users can update own scheduled posts"
ON scheduled_posts FOR UPDATE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own scheduled posts" ON scheduled_posts;
CREATE POLICY "Users can delete own scheduled posts"
ON scheduled_posts FOR DELETE
USING (auth.uid() = user_id);
