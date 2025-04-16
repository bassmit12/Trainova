-- Script to add public workouts to the fitness app
-- Run this in your Supabase SQL Editor

-- First, we need to get an admin user ID to associate with public workouts
-- Replace this with a specific user ID if you have a dedicated admin account
DO $$
DECLARE
    admin_id uuid;
    leg_day_id uuid;
    core_workout_id uuid;
    hiit_cardio_id uuid;
    upper_body_id uuid;
    beginner_full_body_id uuid;
    
    -- Exercise IDs
    lunges_id uuid;
    leg_press_id uuid;
    leg_extension_id uuid;
    calf_raises_id uuid;
    crunches_id uuid;
    leg_raises_id uuid;
    bicycle_crunches_id uuid;
    mountain_climbers_id uuid;
    burpees_id uuid;
    jumping_jacks_id uuid;
    high_knees_id uuid;
    jump_rope_id uuid;
    lat_pulldown_id uuid;
    shoulder_press_id uuid;
    tricep_dips_id uuid;
    bicep_curls_id uuid;
    squats_id uuid;
    modified_pushup_id uuid;
    glute_bridge_id uuid;
    wall_sit_id uuid;
BEGIN
    -- Get admin user (can create public content) - pick the first user
    SELECT id INTO admin_id FROM auth.users LIMIT 1;
    
    IF admin_id IS NULL THEN
        RAISE EXCEPTION 'No users found to create public workouts';
    END IF;
    
    -- Create new exercises
    
    -- Leg day exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Lunges', 
        'Take a step forward and lower your body until both knees form 90-degree angles. Push back up and repeat with the other leg.',
        3, 
        12, 
        '45s', 
        ARRAY['None'], 
        ARRAY['Quadriceps', 'Glutes', 'Hamstrings'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO lunges_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Leg Press', 
        'Sit on the leg press machine, place your feet on the platform, and push the weight away by extending your legs.',
        4, 
        10, 
        '1m', 
        ARRAY['Leg Press Machine'], 
        ARRAY['Quadriceps', 'Glutes', 'Hamstrings', 'Calves'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO leg_press_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Leg Extensions', 
        'Sit on the leg extension machine, hook your feet under the pad, and extend your legs to raise the weight.',
        3, 
        15, 
        '45s', 
        ARRAY['Leg Extension Machine'], 
        ARRAY['Quadriceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO leg_extension_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Standing Calf Raises', 
        'Stand with your feet shoulder-width apart, raise your heels off the ground, then lower back down.',
        4, 
        20, 
        '30s', 
        ARRAY['None', 'Optional: Dumbbells'], 
        ARRAY['Calves'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO calf_raises_id;
    
    -- Core workout exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Crunches', 
        'Lie on your back with knees bent, hands behind head. Lift your shoulders off the ground and then lower back down.',
        3, 
        15, 
        '30s', 
        ARRAY['None', 'Optional: Exercise Mat'], 
        ARRAY['Abs'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO crunches_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Leg Raises', 
        'Lie on your back, hands at your sides or under your lower back for support. Raise your legs until perpendicular to the floor, then lower slowly.',
        3, 
        12, 
        '45s', 
        ARRAY['None', 'Exercise Mat'], 
        ARRAY['Lower Abs', 'Hip Flexors'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO leg_raises_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Bicycle Crunches', 
        'Lie on your back with hands behind head. Bring one knee to your chest while twisting to touch it with the opposite elbow, alternate sides.',
        3, 
        20, 
        '45s', 
        ARRAY['None', 'Exercise Mat'], 
        ARRAY['Abs', 'Obliques'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO bicycle_crunches_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Mountain Climbers', 
        'Start in a plank position. Alternately bring each knee toward your chest in a running motion.',
        3, 
        30, 
        '45s', 
        ARRAY['None'], 
        ARRAY['Core', 'Shoulders', 'Chest'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO mountain_climbers_id;
    
    -- HIIT cardio exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Burpees', 
        'Start standing, drop to a squat position and place hands on the ground, kick feet back into a plank, perform a push-up, return feet to squat position, and jump up from the squat.',
        4, 
        10, 
        '45s', 
        ARRAY['None'], 
        ARRAY['Full Body'], 
        'advanced', 
        true, 
        admin_id
    ) RETURNING id INTO burpees_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Jumping Jacks', 
        'Start with feet together and arms at your sides, then jump to a position with legs spread wide and arms overhead, and back again.',
        4, 
        30, 
        '30s', 
        ARRAY['None'], 
        ARRAY['Shoulders', 'Calves', 'Cardiovascular System'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO jumping_jacks_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'High Knees', 
        'Run in place, bringing knees up to hip level with each step, pumping arms for maximum intensity.',
        4, 
        30, 
        '30s', 
        ARRAY['None'], 
        ARRAY['Abs', 'Quads', 'Cardiovascular System'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO high_knees_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Jump Rope', 
        'Jump over a rope swinging from hands positioned at hip level, continuous jumping with both feet.',
        3, 
        50, 
        '1m', 
        ARRAY['Jump Rope'], 
        ARRAY['Calves', 'Shoulders', 'Cardiovascular System'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO jump_rope_id;
    
    -- Upper body exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Lat Pulldown', 
        'Sit at a lat pulldown machine, grasp the bar with hands wider than shoulder width, and pull the bar down to chest level.',
        4, 
        12, 
        '45s', 
        ARRAY['Lat Pulldown Machine'], 
        ARRAY['Back', 'Biceps', 'Shoulders'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO lat_pulldown_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Shoulder Press', 
        'Hold dumbbells at shoulder height with palms facing forward. Press the weights overhead until arms are extended, then lower back down.',
        3, 
        12, 
        '45s', 
        ARRAY['Dumbbells'], 
        ARRAY['Shoulders', 'Triceps'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO shoulder_press_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Tricep Dips', 
        'Sit on edge of a bench or chair, hands gripping the edge. Lower your body by bending your elbows, then push back up.',
        3, 
        15, 
        '45s', 
        ARRAY['Bench', 'Chair'], 
        ARRAY['Triceps', 'Chest'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO tricep_dips_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Bicep Curls', 
        'Stand with dumbbells in hand, arms at sides, palms facing forward. Bend at the elbow to bring the weight toward shoulders, then lower.',
        3, 
        12, 
        '45s', 
        ARRAY['Dumbbells'], 
        ARRAY['Biceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO bicep_curls_id;
    
    -- Beginner exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Bodyweight Squats', 
        'Stand with feet shoulder-width apart. Bend knees and lower as if sitting in an imaginary chair, then stand back up.',
        3, 
        15, 
        '45s', 
        ARRAY['None'], 
        ARRAY['Quadriceps', 'Hamstrings', 'Glutes'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO squats_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Modified Push-ups', 
        'Place hands slightly wider than shoulders on a table or wall. Lower chest toward surface by bending elbows, then push back up.',
        3, 
        10, 
        '45s', 
        ARRAY['None'], 
        ARRAY['Chest', 'Shoulders', 'Triceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO modified_pushup_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Glute Bridge', 
        'Lie on back with knees bent, feet flat on floor. Push through heels to lift hips off ground, squeezing glutes at the top.',
        3, 
        15, 
        '30s', 
        ARRAY['None', 'Exercise Mat'], 
        ARRAY['Glutes', 'Hamstrings', 'Lower Back'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO glute_bridge_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Wall Sit', 
        'Stand with back against wall, lower into squat position with thighs parallel to ground. Hold position.',
        3, 
        1, 
        '30s', 
        ARRAY['None'], 
        ARRAY['Quadriceps', 'Glutes'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO wall_sit_id;

    -- Create workouts
    
    -- 1. Leg Day
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'Leg Day Blast', 
        'A comprehensive leg workout targeting all major muscles in the lower body', 
        'Strength', 
        '40 min', 
        'Intermediate', 
        320, 
        true, 
        admin_id
    ) RETURNING id INTO leg_day_id;
    
    -- Add exercises to leg day workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (leg_day_id, lunges_id, 1),
        (leg_day_id, leg_press_id, 2),
        (leg_day_id, leg_extension_id, 3),
        (leg_day_id, calf_raises_id, 4);
    
    -- 2. Core Crusher
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'Core Crusher', 
        'Intensive core workout to strengthen abs, obliques and build core stability', 
        'Strength', 
        '30 min', 
        'Intermediate', 
        250, 
        true, 
        admin_id
    ) RETURNING id INTO core_workout_id;
    
    -- Add exercises to core workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (core_workout_id, crunches_id, 1),
        (core_workout_id, leg_raises_id, 2),
        (core_workout_id, bicycle_crunches_id, 3),
        (core_workout_id, mountain_climbers_id, 4);
    
    -- 3. HIIT Cardio
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'HIIT Cardio Express', 
        'High-intensity interval training to boost metabolism and burn calories', 
        'Cardio', 
        '25 min', 
        'Advanced', 
        400, 
        true, 
        admin_id
    ) RETURNING id INTO hiit_cardio_id;
    
    -- Add exercises to HIIT workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (hiit_cardio_id, burpees_id, 1),
        (hiit_cardio_id, jumping_jacks_id, 2),
        (hiit_cardio_id, high_knees_id, 3),
        (hiit_cardio_id, jump_rope_id, 4);
    
    -- 4. Upper Body Sculptor
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'Upper Body Sculptor', 
        'Complete upper body workout targeting chest, back, shoulders and arms', 
        'Strength', 
        '45 min', 
        'Intermediate', 
        300, 
        true, 
        admin_id
    ) RETURNING id INTO upper_body_id;
    
    -- Add exercises to upper body workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (upper_body_id, lat_pulldown_id, 1),
        (upper_body_id, shoulder_press_id, 2),
        (upper_body_id, tricep_dips_id, 3),
        (upper_body_id, bicep_curls_id, 4);
    
    -- 5. Beginner Full Body
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'Beginner Full Body', 
        'Entry-level full body workout perfect for those new to fitness', 
        'Strength', 
        '30 min', 
        'Beginner', 
        200, 
        true, 
        admin_id
    ) RETURNING id INTO beginner_full_body_id;
    
    -- Add exercises to beginner workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (beginner_full_body_id, squats_id, 1),
        (beginner_full_body_id, modified_pushup_id, 2),
        (beginner_full_body_id, glute_bridge_id, 3),
        (beginner_full_body_id, wall_sit_id, 4);
        
    RAISE NOTICE 'Successfully added 5 public workouts with 20 new exercises';
END $$;