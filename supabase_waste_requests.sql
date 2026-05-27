-- Create waste_requests table
CREATE TABLE IF NOT EXISTS waste_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  posted_by TEXT NOT NULL,
  location TEXT NOT NULL,
  phone TEXT NOT NULL,
  pickup_time TIMESTAMP WITH TIME ZONE,
  description TEXT,
  waste_type TEXT,
  amount TEXT,
  image_urls TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'taken', 'done')),
  accepted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  accepted_by_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE waste_requests ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Anyone can view waste requests" ON waste_requests;
CREATE POLICY "Anyone can view waste requests"
ON waste_requests FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated users can create waste requests" ON waste_requests;
CREATE POLICY "Authenticated users can create waste requests"
ON waste_requests FOR INSERT
WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Users can update own waste requests" ON waste_requests;
CREATE POLICY "Users can update own waste requests"
ON waste_requests FOR UPDATE
USING (auth.uid() = created_by OR auth.uid() = accepted_by);

DROP POLICY IF EXISTS "Users can delete own waste requests" ON waste_requests;
CREATE POLICY "Users can delete own waste requests"
ON waste_requests FOR DELETE
USING (auth.uid() = created_by);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_waste_requests_status ON waste_requests(status);
CREATE INDEX IF NOT EXISTS idx_waste_requests_created_at ON waste_requests(created_at DESC);
