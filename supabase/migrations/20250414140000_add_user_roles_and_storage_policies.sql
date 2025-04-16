-- Add user roles and storage bucket policies
-- This migration adds a role field to profiles, upgrades the first user to admin,
-- and creates storage policies for the exercise-images bucket

-- Add role column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS role text DEFAULT 'user';

-- Create an index on the role field for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Update the first user to be an admin
-- This assumes the first user is you (the app creator)
UPDATE public.profiles
SET role = 'admin'
WHERE id = (SELECT id FROM public.profiles ORDER BY created_at ASC LIMIT 1);

-- Update functions to check for admin role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT role = 'admin'
    FROM public.profiles
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update exercise policies to allow admins to create public content
-- Allow admins to create public exercises regardless of ownership
CREATE POLICY "Admins can create public exercises"
  ON public.exercises FOR INSERT
  WITH CHECK (auth.uid() = created_by OR (is_public = true AND public.is_admin() = true));

-- Allow admins to update any exercise
CREATE POLICY "Admins can update any exercise"
  ON public.exercises FOR UPDATE
  USING (auth.uid() = created_by OR public.is_admin() = true);

-- Allow admins to delete any exercise
CREATE POLICY "Admins can delete any exercise"
  ON public.exercises FOR DELETE
  USING (auth.uid() = created_by OR public.is_admin() = true);

-- Update workout policies to allow admins to create public content
-- Allow admins to create public workouts
CREATE POLICY "Admins can create public workouts"
  ON public.workouts FOR INSERT
  WITH CHECK (auth.uid() = created_by OR (is_public = true AND public.is_admin() = true));

-- Allow admins to update any workout
CREATE POLICY "Admins can update any workout"
  ON public.workouts FOR UPDATE
  USING (auth.uid() = created_by OR public.is_admin() = true);

-- Allow admins to delete any workout
CREATE POLICY "Admins can delete any workout"
  ON public.workouts FOR DELETE
  USING (auth.uid() = created_by OR public.is_admin() = true);

-- Allow admins to manage workout exercises
CREATE POLICY "Admins can manage workout exercises"
  ON public.workout_exercises FOR ALL
  USING (
    (SELECT created_by FROM public.workouts WHERE id = workout_id) = auth.uid() 
    OR public.is_admin() = true
  );

-- Create exercise-images bucket if it doesn't exist
DO $$
BEGIN
  EXECUTE format('CREATE BUCKET IF NOT EXISTS "exercise-images"');
EXCEPTION WHEN OTHERS THEN
  -- Bucket might already exist, which is fine
END;
$$;

-- Set up storage policies for the exercise-images bucket
BEGIN;
  -- Anyone can view exercise images (they're public)
  CREATE POLICY "Public exercise images are viewable by everyone"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'exercise-images');

  -- Users can upload exercise images to their own folder
  CREATE POLICY "Users can upload exercise images to their own folder"
    ON storage.objects FOR INSERT
    WITH CHECK (
      bucket_id = 'exercise-images' AND
      (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin() = true)
    );

  -- Users can update their own exercise images
  CREATE POLICY "Users can update their own exercise images"
    ON storage.objects FOR UPDATE
    USING (
      bucket_id = 'exercise-images' AND
      (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin() = true)
    );

  -- Users can delete their own exercise images
  CREATE POLICY "Users can delete their own exercise images"
    ON storage.objects FOR DELETE
    USING (
      bucket_id = 'exercise-images' AND
      (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin() = true)
    );

  -- Admins can manage all exercise images
  CREATE POLICY "Admins can manage all exercise images"
    ON storage.objects FOR ALL
    USING (
      bucket_id = 'exercise-images' AND
      public.is_admin() = true
    );
COMMIT;