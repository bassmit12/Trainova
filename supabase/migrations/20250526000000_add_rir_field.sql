-- Add RIR (Reps in Reserve) field to workout_history_sets table
ALTER TABLE public.workout_history_sets
ADD COLUMN IF NOT EXISTS rir integer;

-- Add a comment explaining what RIR is
COMMENT ON COLUMN public.workout_history_sets.rir IS 'Reps in Reserve - how many more reps the user could have performed before failure';