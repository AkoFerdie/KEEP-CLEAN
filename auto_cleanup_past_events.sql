-- =====================================================
-- AUTO-DELETE PAST EVENTS FROM DATABASE
-- =====================================================
-- This will automatically clean up events from the database
-- after their date has passed, so you never need to manually delete

-- Step 1: Create a function that deletes events older than 1 day
CREATE OR REPLACE FUNCTION auto_cleanup_past_campaigns()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete campaigns where the date has passed
  DELETE FROM public.campaigns 
  WHERE date < CURRENT_DATE;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create a trigger that runs the cleanup when viewing campaigns
-- This ensures past events get deleted whenever anyone queries the table
DROP TRIGGER IF EXISTS trigger_cleanup_campaigns ON public.campaigns;
CREATE TRIGGER trigger_cleanup_campaigns
  AFTER SELECT ON public.campaigns
  FOR EACH STATEMENT
  EXECUTE FUNCTION auto_cleanup_past_campaigns();

-- =====================================================
-- ALTERNATIVE: Manual cleanup for RIGHT NOW
-- =====================================================
-- Run this once to delete all current past events:
DELETE FROM public.campaigns WHERE date < CURRENT_DATE;

-- Or if dates are stored as text like "May 23, 2025":
-- You'll need to check and delete manually by looking at the dates

-- Check what format your dates are in:
SELECT id, location, date, time FROM public.campaigns LIMIT 5;

-- =====================================================
-- BEST SOLUTION: Use Supabase Edge Function (Advanced)
-- =====================================================
-- For automatic scheduled cleanup, you can:
-- 1. Create a Supabase Edge Function
-- 2. Use Supabase Cron Jobs (requires pg_cron extension)
-- 3. Run it daily at midnight

-- First, enable pg_cron extension (if not enabled):
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Then schedule daily cleanup at 2 AM:
-- SELECT cron.schedule(
--   'cleanup-past-events',
--   '0 2 * * *',
--   $$ DELETE FROM public.campaigns WHERE date < CURRENT_DATE; $$
-- );
