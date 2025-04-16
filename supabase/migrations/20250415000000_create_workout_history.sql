-- Create workout history table
CREATE TABLE IF NOT EXISTS workout_history (
  id UUID PRIMARY KEY,
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  workout_name TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  completed_at TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER NOT NULL,
  calories_burned INTEGER NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create workout history sets table
CREATE TABLE IF NOT EXISTS workout_history_sets (
  id UUID PRIMARY KEY,
  workout_history_id UUID NOT NULL REFERENCES workout_history(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id),
  set_number INTEGER NOT NULL,
  weight NUMERIC NOT NULL,
  reps INTEGER NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_workout_history_user_id ON workout_history(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_history_workout_id ON workout_history(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_history_sets_history_id ON workout_history_sets(workout_history_id);

-- Row-level security policies
ALTER TABLE workout_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_history_sets ENABLE ROW LEVEL SECURITY;

-- Policy for workout history: users can only view and edit their own workout history
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workout_history' 
        AND policyname = 'workout_history_user_policy'
    ) THEN
        CREATE POLICY workout_history_user_policy ON workout_history
          FOR ALL
          USING (auth.uid() = user_id);
    END IF;
END
$$;

-- Policy for workout history sets: users can access sets related to their workout history
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workout_history_sets' 
        AND policyname = 'workout_history_sets_policy'
    ) THEN
        CREATE POLICY workout_history_sets_policy ON workout_history_sets
          FOR ALL
          USING (
            workout_history_id IN (
              SELECT id FROM workout_history WHERE user_id = auth.uid()
            )
          );
    END IF;
END
$$;