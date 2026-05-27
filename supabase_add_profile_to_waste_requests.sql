-- Add profile_image_url column to waste_requests table
ALTER TABLE waste_requests ADD COLUMN IF NOT EXISTS profile_image_url TEXT DEFAULT '';
