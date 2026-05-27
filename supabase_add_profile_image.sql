-- Add profile_image_url column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_url TEXT DEFAULT '';

-- Create profile_pictures storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile_pictures', 'profile_pictures', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for profile_pictures bucket
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile_pictures');

DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'profile_pictures' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update own profile picture" ON storage.objects;
CREATE POLICY "Users can update own profile picture"
ON storage.objects FOR UPDATE
USING (bucket_id = 'profile_pictures' AND auth.uid()::text = (string_to_array(name, '/'))[1]);

DROP POLICY IF EXISTS "Users can delete own profile picture" ON storage.objects;
CREATE POLICY "Users can delete own profile picture"
ON storage.objects FOR DELETE
USING (bucket_id = 'profile_pictures' AND auth.uid()::text = (string_to_array(name, '/'))[1]);
