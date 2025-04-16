-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  type TEXT NOT NULL, -- workout_reminder, achievement, system, etc.
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  additional_data JSONB,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS (Row-Level Security) policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own notifications
CREATE POLICY "Users can view their own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Users can update (mark as read) their own notifications
CREATE POLICY "Users can update their own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id);

-- Create an index on user_id for faster queries
CREATE INDEX notifications_user_id_idx ON notifications(user_id);

-- Create an index on timestamp for sorting
CREATE INDEX notifications_timestamp_idx ON notifications(timestamp);

-- Create a function to auto-update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to call the function
CREATE TRIGGER update_notifications_updated_at
BEFORE UPDATE ON notifications
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create a function to clean up old notifications (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM notifications
    WHERE timestamp < NOW() - INTERVAL '30 days';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to clean up old notifications when new ones are inserted
CREATE TRIGGER cleanup_old_notifications_trigger
AFTER INSERT ON notifications
EXECUTE FUNCTION cleanup_old_notifications();

-- Insert demo notifications for testing
INSERT INTO notifications (user_id, title, message, type, timestamp)
SELECT 
  auth.uid(), 
  'Welcome to AI Fitness!', 
  'Thanks for joining our fitness community. Start your journey today by exploring workouts tailored to your goals.',
  'system',
  NOW()
WHERE EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid());

INSERT INTO notifications (user_id, title, message, type, timestamp, additional_data)
SELECT 
  auth.uid(), 
  'Time for your workout!', 
  'You have a scheduled strength training session today. Don''t miss it!',
  'workout_reminder',
  NOW() - INTERVAL '2 hours',
  '{"workout_id": "1", "workout_name": "Full Body Strength"}'::JSONB
WHERE EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid());

INSERT INTO notifications (user_id, title, message, type, timestamp)
SELECT 
  auth.uid(), 
  'Achievement unlocked!', 
  'Congratulations! You''ve completed 5 workouts this week.',
  'achievement',
  NOW() - INTERVAL '1 day'
WHERE EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid());