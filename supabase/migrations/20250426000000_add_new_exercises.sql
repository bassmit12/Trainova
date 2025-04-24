-- Migration: Add New Exercises - Machine Lat Row and Cable Tricep Extension
-- This migration adds two additional exercises to the fitness app database

-- Script to add new exercises to the fitness app
DO $$
DECLARE
    admin_id uuid;
    
    -- New Exercise IDs
    machine_lat_row_id uuid;
    cable_tricep_extension_id uuid;
    
BEGIN
    -- Get admin user (can create public content)
    SELECT id INTO admin_id FROM auth.users LIMIT 1;
    
    IF admin_id IS NULL THEN
        RAISE EXCEPTION 'No users found to create new exercises';
    END IF;
    
    -- Add Machine Lat Row Exercise
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Machine Lat Row', 
        'Sit at the lat row machine with your chest against the pad. Grasp the handles and pull them towards your body, squeezing your shoulder blades together, then slowly return to the starting position.',
        4, 
        12, 
        '45s', 
        ARRAY['Lat Row Machine'], 
        ARRAY['Lats', 'Rhomboids', 'Middle Back', 'Biceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO machine_lat_row_id;
    
    -- Add Cable Tricep Extension Exercise
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Cable Tricep Extension', 
        'Stand with your back to the cable machine and grasp a rope attachment connected to a high pulley. With elbows bent next to your head, extend your arms forward, then return to the starting position with control.',
        3, 
        15, 
        '45s', 
        ARRAY['Cable Machine', 'Rope Attachment'], 
        ARRAY['Triceps'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO cable_tricep_extension_id;
    
    RAISE NOTICE 'Successfully added 2 new exercises: Machine Lat Row and Cable Tricep Extension';
END $$;
