-- Create tables for exercises and workouts
-- This migration sets up the exercise and workout system with public and user-specific workouts

-- Create exercises table
CREATE TABLE IF NOT EXISTS public.exercises (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  name text NOT NULL,
  description text NOT NULL,
  sets integer NOT NULL DEFAULT 3,
  reps integer NOT NULL DEFAULT 10,
  duration text NOT NULL DEFAULT '45s',
  image_url text NOT NULL DEFAULT 'assets/images/workout1.png',
  equipment text[] NOT NULL DEFAULT '{}',
  target_muscles text[] NOT NULL DEFAULT '{}',
  difficulty text NOT NULL DEFAULT 'intermediate',
  is_public boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create workouts table
CREATE TABLE IF NOT EXISTS public.workouts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  name text NOT NULL,
  description text NOT NULL,
  type text NOT NULL DEFAULT 'Strength',
  image_url text NOT NULL DEFAULT 'assets/images/workout1.png',
  duration text NOT NULL DEFAULT '30 min',
  difficulty text NOT NULL DEFAULT 'intermediate',
  calories_burned integer NOT NULL DEFAULT 300,
  is_public boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create junction table for workouts and exercises
CREATE TABLE IF NOT EXISTS public.workout_exercises (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id uuid NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
  exercise_id uuid NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  order_index integer NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  UNIQUE(workout_id, exercise_id)
);

-- Add RLS policies for secure access
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;

-- Policies for workouts with IF NOT EXISTS checks
DO $$
BEGIN
    -- Allow users to view all public workouts and their own workouts
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workouts' 
        AND policyname = 'View public workouts and own workouts'
    ) THEN
        CREATE POLICY "View public workouts and own workouts"
          ON public.workouts FOR SELECT
          USING (is_public = true OR auth.uid() = created_by);
    END IF;

    -- Allow users to insert their own workouts
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workouts' 
        AND policyname = 'Users can create their own workouts'
    ) THEN
        CREATE POLICY "Users can create their own workouts"
          ON public.workouts FOR INSERT
          WITH CHECK (auth.uid() = created_by);
    END IF;

    -- Allow users to update their own workouts
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workouts' 
        AND policyname = 'Users can update their own workouts'
    ) THEN
        CREATE POLICY "Users can update their own workouts"
          ON public.workouts FOR UPDATE
          USING (auth.uid() = created_by);
    END IF;

    -- Allow users to delete their own workouts
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workouts' 
        AND policyname = 'Users can delete their own workouts'
    ) THEN
        CREATE POLICY "Users can delete their own workouts"
          ON public.workouts FOR DELETE
          USING (auth.uid() = created_by);
    END IF;
END
$$;

-- Policies for exercises with IF NOT EXISTS checks
DO $$
BEGIN
    -- Allow users to view all public exercises and their own exercises
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'exercises' 
        AND policyname = 'View public exercises and own exercises'
    ) THEN
        CREATE POLICY "View public exercises and own exercises"
          ON public.exercises FOR SELECT
          USING (is_public = true OR auth.uid() = created_by);
    END IF;

    -- Allow users to insert their own exercises
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'exercises' 
        AND policyname = 'Users can create their own exercises'
    ) THEN
        CREATE POLICY "Users can create their own exercises"
          ON public.exercises FOR INSERT
          WITH CHECK (auth.uid() = created_by);
    END IF;

    -- Allow users to update their own exercises
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'exercises' 
        AND policyname = 'Users can update their own exercises'
    ) THEN
        CREATE POLICY "Users can update their own exercises"
          ON public.exercises FOR UPDATE
          USING (auth.uid() = created_by);
    END IF;

    -- Allow users to delete their own exercises
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'exercises' 
        AND policyname = 'Users can delete their own exercises'
    ) THEN
        CREATE POLICY "Users can delete their own exercises"
          ON public.exercises FOR DELETE
          USING (auth.uid() = created_by);
    END IF;
END
$$;

-- Policies for workout_exercises with IF NOT EXISTS checks
DO $$
BEGIN
    -- Users can view exercise details for visible workouts
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workout_exercises' 
        AND policyname = 'Users can view exercise details for visible workouts'
    ) THEN
        CREATE POLICY "Users can view exercise details for visible workouts"
          ON public.workout_exercises FOR SELECT
          USING (
            (SELECT is_public FROM public.workouts WHERE id = workout_id) = true OR
            (SELECT created_by FROM public.workouts WHERE id = workout_id) = auth.uid()
          );
    END IF;

    -- Users can add exercises to their workouts
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workout_exercises' 
        AND policyname = 'Users can add exercises to their workouts'
    ) THEN
        CREATE POLICY "Users can add exercises to their workouts"
          ON public.workout_exercises FOR INSERT
          WITH CHECK (
            (SELECT created_by FROM public.workouts WHERE id = workout_id) = auth.uid()
          );
    END IF;

    -- Users can update exercise details in their workouts
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workout_exercises' 
        AND policyname = 'Users can update exercise details in their workouts'
    ) THEN
        CREATE POLICY "Users can update exercise details in their workouts"
          ON public.workout_exercises FOR UPDATE
          USING (
            (SELECT created_by FROM public.workouts WHERE id = workout_id) = auth.uid()
          );
    END IF;

    -- Users can remove exercises from their workouts
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'workout_exercises' 
        AND policyname = 'Users can remove exercises from their workouts'
    ) THEN
        CREATE POLICY "Users can remove exercises from their workouts"
          ON public.workout_exercises FOR DELETE
          USING (
            (SELECT created_by FROM public.workouts WHERE id = workout_id) = auth.uid()
          );
    END IF;
END
$$;

-- Function to insert initial public exercises and workouts for all users
CREATE OR REPLACE FUNCTION public.create_default_public_workouts()
RETURNS void AS $$
DECLARE
  admin_id uuid;
  exercise_ids uuid[] := '{}'::uuid[];
  workout_id uuid;
  exercise_count integer;
BEGIN
  -- Check if we already have public workouts
  SELECT COUNT(*) INTO exercise_count FROM public.exercises WHERE is_public = true;
  
  -- Only create default data if no public exercises exist
  IF exercise_count = 0 THEN
    -- Get admin user (can create public content)
    SELECT id INTO admin_id FROM auth.users LIMIT 1;
    IF admin_id IS NULL THEN
      RAISE EXCEPTION 'No admin user found to create default workouts';
    END IF;

    -- Create default exercises (8 standard ones)
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES
      ('Push-up', 'Start in a plank position with your hands slightly wider than your shoulders. Lower your body until your chest nearly touches the floor, then push back up.', 3, 12, '45s', ARRAY['None'], ARRAY['Chest', 'Shoulders', 'Triceps'], 'intermediate', true, admin_id),
      ('Dumbbell Bench Press', 'Lie on a flat bench holding a dumbbell in each hand. Press the weights upward until your arms are extended.', 4, 10, '1m', ARRAY['Dumbbells', 'Bench'], ARRAY['Chest', 'Triceps'], 'intermediate', true, admin_id),
      ('Barbell Squat', 'Place a barbell across your upper back, bend your knees and lower your body until your thighs are parallel to the ground.', 4, 8, '1m 30s', ARRAY['Barbell', 'Squat Rack'], ARRAY['Quadriceps', 'Hamstrings', 'Glutes'], 'advanced', true, admin_id),
      ('Bodyweight Squats', 'Stand with your feet shoulder-width apart. Bend your knees and lower your body until your thighs are parallel to the ground.', 3, 15, '45s', ARRAY['None'], ARRAY['Quadriceps', 'Hamstrings', 'Glutes'], 'beginner', true, admin_id),
      ('Dumbbell Row', 'Bend over with a flat back, holding a dumbbell in one hand. Pull the dumbbell up to your side, then lower it back down.', 3, 12, '45s', ARRAY['Dumbbells'], ARRAY['Back', 'Biceps'], 'intermediate', true, admin_id),
      ('Pull-ups', 'Hang from a bar with your palms facing away from you. Pull your body up until your chin clears the bar.', 3, 8, '1m', ARRAY['Pull-up Bar'], ARRAY['Back', 'Biceps', 'Shoulders'], 'advanced', true, admin_id),
      ('Plank', 'Get into a pushup position, but rest on your forearms. Keep your body in a straight line from head to heels.', 3, 1, '1m', ARRAY['None'], ARRAY['Core', 'Shoulders'], 'beginner', true, admin_id),
      ('Russian Twists', 'Sit on the floor with your knees bent and feet lifted. Twist your torso from side to side.', 3, 20, '45s', ARRAY['None', 'Optional: Dumbbell or Medicine Ball'], ARRAY['Core', 'Obliques'], 'intermediate', true, admin_id)
    RETURNING id INTO exercise_ids;

    -- Create first public workout (Full Body Strength)
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES ('Full Body Strength', 'A complete body workout targeting all major muscle groups', 'Strength', '45 min', 'Intermediate', 350, true, admin_id)
    RETURNING id INTO workout_id;

    -- Add exercises to workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
      (workout_id, exercise_ids[1], 1),
      (workout_id, exercise_ids[3], 2),
      (workout_id, exercise_ids[5], 3),
      (workout_id, exercise_ids[7], 4);

    -- Create second public workout (HIIT Cardio Blast)
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES ('HIIT Cardio Blast', 'High-intensity interval training to maximize calorie burn', 'Cardio', '30 min', 'Advanced', 400, true, admin_id)
    RETURNING id INTO workout_id;

    -- Add exercises to workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
      (workout_id, exercise_ids[1], 1),
      (workout_id, exercise_ids[4], 2),
      (workout_id, exercise_ids[7], 3),
      (workout_id, exercise_ids[8], 4);
  END IF;
END;
$$ LANGUAGE plpgsql;