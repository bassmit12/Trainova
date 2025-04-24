-- Add custom sets and reps to workout_exercises table
-- This migration adds support for customizing sets and reps per workout

-- First check if columns already exist
DO $$
BEGIN
    -- Add custom_sets column if it doesn't exist
    IF NOT EXISTS(
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'workout_exercises' AND column_name = 'custom_sets'
    ) THEN
        ALTER TABLE public.workout_exercises ADD COLUMN custom_sets integer;
    END IF;

    -- Add custom_reps column if it doesn't exist
    IF NOT EXISTS(
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'workout_exercises' AND column_name = 'custom_reps'
    ) THEN
        ALTER TABLE public.workout_exercises ADD COLUMN custom_reps integer;
    END IF;

    -- Update existing entries to use the base exercise sets/reps as defaults
    UPDATE public.workout_exercises we
    SET 
        custom_sets = (SELECT sets FROM public.exercises WHERE id = we.exercise_id),
        custom_reps = (SELECT reps FROM public.exercises WHERE id = we.exercise_id)
    WHERE custom_sets IS NULL OR custom_reps IS NULL;
END
$$;

-- Update the unique constraint to allow the same exercise in a workout multiple times
-- This is useful for supersets or different variations of the same exercise
ALTER TABLE public.workout_exercises DROP CONSTRAINT IF EXISTS workout_exercises_workout_id_exercise_id_key;
ALTER TABLE public.workout_exercises ADD CONSTRAINT workout_exercises_workout_id_exercise_id_order_key UNIQUE(workout_id, exercise_id, order_index);

COMMENT ON COLUMN public.workout_exercises.custom_sets IS 'Custom number of sets for this exercise in this specific workout';
COMMENT ON COLUMN public.workout_exercises.custom_reps IS 'Custom number of reps for this exercise in this specific workout';