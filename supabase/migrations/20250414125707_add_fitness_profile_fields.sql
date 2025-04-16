-- Add fitness profile fields to the profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS weight float,
ADD COLUMN IF NOT EXISTS height float,
ADD COLUMN IF NOT EXISTS weight_unit text DEFAULT 'kg',
ADD COLUMN IF NOT EXISTS height_unit text DEFAULT 'cm',
ADD COLUMN IF NOT EXISTS fitness_goal text,
ADD COLUMN IF NOT EXISTS workouts_per_week integer,
ADD COLUMN IF NOT EXISTS preferred_workout_types text[],
ADD COLUMN IF NOT EXISTS experience_level text,
ADD COLUMN IF NOT EXISTS is_profile_complete boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now();

-- Update the handle_new_user function to include the new fields
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (
    id, 
    full_name, 
    avatar_url,
    weight_unit,
    height_unit,
    is_profile_complete,
    created_at,
    updated_at
  )
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    new.raw_user_meta_data->>'avatar_url',
    'kg',
    'cm',
    false,
    now(),
    now()
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;