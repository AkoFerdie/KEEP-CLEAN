-- Check what's in waste_requests vs users
SELECT wr.id, wr.posted_by, wr.created_by, u.username, u.email
FROM waste_requests wr
LEFT JOIN users u ON wr.created_by::text = u.id::text;

-- Fix all existing posts with correct username
UPDATE waste_requests wr
SET 
  posted_by = COALESCE(u.username, u.email, 'Anonymous'),
  profile_image_url = COALESCE(u.profile_image_url, '')
FROM users u
WHERE wr.created_by::text = u.id::text;
