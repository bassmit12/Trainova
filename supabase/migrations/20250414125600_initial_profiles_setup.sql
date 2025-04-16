-- Initial setup for profiles table and user creation trigger
-- This should run before the 'add_fitness_profile_fields' migration

-- Create profiles table if not exists
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  updated_at timestamp with time zone,
  username text UNIQUE,
  full_name text,
  avatar_url text,
  website text,
  
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Create a secure RLS policy
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Set up access policies with IF NOT EXISTS checks
DO $$
BEGIN
    -- Check if policy exists before creating
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Public profiles are viewable by everyone.'
    ) THEN
        CREATE POLICY "Public profiles are viewable by everyone."
          ON profiles FOR SELECT
          USING (true);
    END IF;
    
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Users can insert their own profile.'
    ) THEN
        CREATE POLICY "Users can insert their own profile."
          ON profiles FOR INSERT
          WITH CHECK (auth.uid() = id);
    END IF;
    
    IF NOT EXISTS (
        SELECT FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Users can update own profile.'
    ) THEN
        CREATE POLICY "Users can update own profile."
          ON profiles FOR UPDATE
          USING (auth.uid() = id);
    END IF;
END
$$;

-- Create the trigger function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'avatar_url', 'user');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger that will fire the function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();