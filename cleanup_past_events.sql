-- =====================================================
-- DELETE PAST EVENTS: Clean up old events from campaigns
-- =====================================================

-- Option 1: Delete all events before today
DELETE FROM public.campaigns 
WHERE date < CURRENT_DATE;

-- Option 2: Delete specific old events (replace dates as needed)
-- DELETE FROM public.campaigns WHERE date = '2025-05-23';
-- DELETE FROM public.campaigns WHERE date LIKE 'May%2025';

-- Option 3: View all campaigns to see what needs cleaning
-- SELECT id, location, date, time, created_at FROM public.campaigns ORDER BY date;

-- Option 4: Delete campaigns from specific date range
-- DELETE FROM public.campaigns WHERE date BETWEEN '2025-01-01' AND '2025-05-31';

-- =====================================================
-- AUTOMATIC CLEANUP: Create function to auto-delete past events
-- =====================================================

-- Create function to delete events that are 7 days past
CREATE OR REPLACE FUNCTION delete_old_campaigns()
RETURNS void AS $$
BEGIN
  DELETE FROM public.campaigns 
  WHERE date < (CURRENT_DATE - INTERVAL '7 days');
END;
$$ LANGUAGE plpgsql;

-- Schedule this to run daily (requires pg_cron extension)
-- SELECT cron.schedule('delete-old-campaigns', '0 2 * * *', 'SELECT delete_old_campaigns();');

-- Or manually run it anytime:
-- SELECT delete_old_campaigns();
