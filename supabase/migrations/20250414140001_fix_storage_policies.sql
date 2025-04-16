-- Fix storage policies for the exercise-images bucket
-- This migration addresses the 400 error when accessing uploaded images

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public exercise images are viewable by everyone" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload exercise images to their own folder" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own exercise images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own exercise images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage all exercise images" ON storage.objects;

-- Make sure the bucket exists
DO $$
BEGIN
  INSERT INTO storage.buckets (id, name) 
  VALUES ('exercise-images', 'exercise-images') 
  ON CONFLICT (id) DO NOTHING;
EXCEPTION WHEN OTHERS THEN
  -- Bucket might already exist, which is fine
END;
$$;

-- Set up proper RLS policies for storage
-- Anyone can view exercise images (public read access)
CREATE POLICY "Public exercise images are viewable by everyone"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'exercise-images');

-- Users can upload images to their own folder (folder name = user id)
CREATE POLICY "Users can upload to their own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'exercise-images' AND
    (auth.uid()::text = (storage.foldername(name))[1] OR 
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
  );

-- Users can update their own images
CREATE POLICY "Users can update their own images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'exercise-images' AND
    (auth.uid()::text = (storage.foldername(name))[1] OR 
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
  );

-- Users can delete their own images
CREATE POLICY "Users can delete their own images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'exercise-images' AND
    (auth.uid()::text = (storage.foldername(name))[1] OR 
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'))
  );

-- Set bucket to public to allow anonymous access
UPDATE storage.buckets
SET public = TRUE
WHERE id = 'exercise-images';