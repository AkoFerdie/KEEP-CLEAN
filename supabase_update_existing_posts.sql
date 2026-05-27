-- Update existing waste_requests to have proper usernames
UPDATE waste_requests wr
SET posted_by = COALESCE(u.username, u.email, 'Anonymous'),
    profile_image_url = COALESCE(u.profile_image_url, '')
FROM users u
WHERE wr.created_by = u.id
  AND wr.posted_by = 'Anonymous';
