-- Migration: Add Gym Strength Training Exercises
-- This migration adds a comprehensive set of gym strength training exercises
-- with a focus on weight machines and free weights

-- Script to add gym strength training exercises to the fitness app
DO $$
DECLARE
    admin_id uuid;
    
    -- Free Weight Exercise IDs
    barbell_bench_press_id uuid;
    incline_bench_press_id uuid;
    decline_bench_press_id uuid;
    dumbbell_fly_id uuid;
    barbell_deadlift_id uuid;
    romanian_deadlift_id uuid;
    barbell_squat_id uuid;
    front_squat_id uuid;
    hack_squat_id uuid;
    overhead_press_id uuid;
    dumbbell_lateral_raise_id uuid;
    upright_row_id uuid;
    barbell_bent_over_row_id uuid;
    t_bar_row_id uuid;
    dumbbell_row_id uuid;
    barbell_curl_id uuid;
    preacher_curl_id uuid;
    hammer_curl_id uuid;
    skull_crusher_id uuid;
    cable_push_down_id uuid;
    close_grip_bench_id uuid;
    barbell_shrug_id uuid;
    dumbbell_shrug_id uuid;
    good_morning_id uuid;
    barbell_lunge_id uuid;
    
    -- Machine Exercise IDs
    chest_press_machine_id uuid;
    pec_deck_id uuid;
    leg_press_machine_id uuid;
    leg_extension_machine_id uuid;
    seated_leg_curl_id uuid;
    lying_leg_curl_id uuid;
    calf_raise_machine_id uuid;
    seated_calf_raise_id uuid;
    lat_pulldown_machine_id uuid;
    cable_row_id uuid;
    chest_supported_row_id uuid;
    shoulder_press_machine_id uuid;
    lateral_raise_machine_id uuid;
    cable_face_pull_id uuid;
    assisted_pull_up_id uuid;
    assisted_dip_id uuid;
    bicep_curl_machine_id uuid;
    cable_curl_id uuid;
    tricep_extension_machine_id uuid;
    cable_tricep_extension_id uuid;
    ab_crunch_machine_id uuid;
    rotary_torso_id uuid;
    back_extension_id uuid;
    hip_abductor_id uuid;
    hip_adductor_id uuid;
    
    -- Workout IDs
    upper_body_machine_id uuid;
    lower_body_machine_id uuid;
    push_pull_free_weights_id uuid;
    full_body_machine_circuit_id uuid;
    
BEGIN
    -- Get admin user (can create public content)
    SELECT id INTO admin_id FROM auth.users LIMIT 1;
    
    IF admin_id IS NULL THEN
        RAISE EXCEPTION 'No users found to create gym strength exercises';
    END IF;
    
    -- Create Free Weight Exercises
    
    -- Chest Free Weight Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Barbell Bench Press', 
        'Lie on a flat bench, grip the barbell with hands slightly wider than shoulder-width. Lower the bar to your chest, then press back up to full arm extension.',
        4, 
        8, 
        '1m', 
        ARRAY['Barbell', 'Bench', 'Weight Plates'], 
        ARRAY['Chest', 'Triceps', 'Shoulders'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO barbell_bench_press_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Incline Bench Press', 
        'Lie on an incline bench set to 30-45 degrees, grip the barbell with hands slightly wider than shoulder-width. Lower the bar to your upper chest, then press back up.',
        4, 
        8, 
        '1m', 
        ARRAY['Barbell', 'Incline Bench', 'Weight Plates'], 
        ARRAY['Upper Chest', 'Triceps', 'Shoulders'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO incline_bench_press_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Decline Bench Press', 
        'Lie on a decline bench with feet secured, grip the barbell with hands slightly wider than shoulder-width. Lower the bar to your lower chest, then press back up.',
        4, 
        8, 
        '1m', 
        ARRAY['Barbell', 'Decline Bench', 'Weight Plates'], 
        ARRAY['Lower Chest', 'Triceps'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO decline_bench_press_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Dumbbell Fly', 
        'Lie on a flat bench holding dumbbells above your chest with palms facing each other. With a slight bend in your elbows, lower weights out to sides in an arc motion, then bring them back together.',
        3, 
        12, 
        '45s', 
        ARRAY['Dumbbells', 'Bench'], 
        ARRAY['Chest', 'Shoulders'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO dumbbell_fly_id;
    
    -- Back Free Weight Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Barbell Deadlift', 
        'Stand with feet hip-width apart, the barbell over your midfoot. Hinge at the hips, grip the bar, flatten your back, then drive through your heels to stand up with the weight.',
        4, 
        6, 
        '1m 30s', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Lower Back', 'Hamstrings', 'Glutes', 'Traps'], 
        'advanced', 
        true, 
        admin_id
    ) RETURNING id INTO barbell_deadlift_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Romanian Deadlift', 
        'Stand holding a barbell at hip level. Keep your back straight and knees slightly bent, hinge at the hips to lower the bar along your legs until you feel a stretch in your hamstrings, then return to standing.',
        4, 
        10, 
        '1m', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Hamstrings', 'Glutes', 'Lower Back'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO romanian_deadlift_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Barbell Bent Over Row', 
        'Bend at your hips and knees with a barbell in your hands. Keep your back flat and core tight, pull the bar to your lower ribcage, then lower it with control.',
        4, 
        10, 
        '1m', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Upper Back', 'Lats', 'Biceps', 'Rear Deltoids'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO barbell_bent_over_row_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'T-Bar Row', 
        'Place one end of a barbell in a corner or use a T-bar row machine. Straddle the bar, bend at the waist, grasp the handles, and pull the weight toward your torso while keeping your back flat.',
        4, 
        10, 
        '1m', 
        ARRAY['T-Bar Row Machine', 'Weight Plates'], 
        ARRAY['Middle Back', 'Lats', 'Biceps'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO t_bar_row_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Single-Arm Dumbbell Row', 
        'Place one knee and hand on a bench, with the other foot on the floor. Hold a dumbbell in your free hand, pull it to your hip while keeping your back flat, then lower with control.',
        3, 
        12, 
        '45s', 
        ARRAY['Dumbbell', 'Bench'], 
        ARRAY['Upper Back', 'Lats', 'Biceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO dumbbell_row_id;
    
    -- Leg Free Weight Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Barbell Back Squat', 
        'Rest a barbell on your upper back, feet shoulder-width apart. Bend your knees and hips to lower your body until your thighs are parallel to the ground, then drive through your heels to stand back up.',
        4, 
        8, 
        '1m 30s', 
        ARRAY['Barbell', 'Squat Rack', 'Weight Plates'], 
        ARRAY['Quadriceps', 'Glutes', 'Hamstrings', 'Lower Back'], 
        'advanced', 
        true, 
        admin_id
    ) RETURNING id INTO barbell_squat_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Front Squat', 
        'Rest a barbell across your front deltoids and collarbone, with elbows high. Squat down until thighs are parallel to the floor, then stand back up.',
        4, 
        8, 
        '1m 30s', 
        ARRAY['Barbell', 'Squat Rack', 'Weight Plates'], 
        ARRAY['Quadriceps', 'Core', 'Upper Back'], 
        'advanced', 
        true, 
        admin_id
    ) RETURNING id INTO front_squat_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Hack Squat', 
        'Using a hack squat machine or barbell behind your legs, squat down until knees are at 90 degrees, then push back up through your heels.',
        4, 
        10, 
        '1m', 
        ARRAY['Hack Squat Machine', 'Weight Plates'], 
        ARRAY['Quadriceps', 'Glutes'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO hack_squat_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Barbell Lunge', 
        'Hold a barbell across your upper back. Step forward with one leg and lower your body until both knees are at 90-degree angles, then push back to starting position. Alternate legs.',
        3, 
        10, 
        '1m', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Quadriceps', 'Glutes', 'Hamstrings'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO barbell_lunge_id;
    
    -- Shoulder Free Weight Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Overhead Press', 
        'Stand holding a barbell at shoulder height, grip slightly wider than shoulders. Press the weight overhead until arms are fully extended, then lower back to shoulders.',
        4, 
        8, 
        '1m', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Shoulders', 'Triceps', 'Upper Chest'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO overhead_press_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Dumbbell Lateral Raise', 
        'Stand with dumbbells at your sides, palms facing in. Keep your arms nearly straight as you raise the weights out to your sides until they reach shoulder level, then lower with control.',
        3, 
        12, 
        '45s', 
        ARRAY['Dumbbells'], 
        ARRAY['Lateral Deltoids'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO dumbbell_lateral_raise_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Upright Row', 
        'Stand holding a barbell or dumbbells in front of your thighs. Pull the weight up along your body until it reaches upper chest level, with elbows leading the movement, then lower back down.',
        3, 
        12, 
        '45s', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Shoulders', 'Traps', 'Biceps'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO upright_row_id;
    
    -- Arm Free Weight Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Barbell Curl', 
        'Stand holding a barbell with an underhand grip, arms extended. Keeping your upper arms stationary, curl the weight up to your shoulders, then lower back down with control.',
        3, 
        12, 
        '45s', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Biceps', 'Forearms'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO barbell_curl_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Preacher Curl', 
        'Sit at a preacher bench with your arms against the pad, holding an EZ bar or dumbbells. Curl the weight up, then lower back down with control.',
        3, 
        12, 
        '45s', 
        ARRAY['EZ Curl Bar', 'Weight Plates', 'Preacher Bench'], 
        ARRAY['Biceps'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO preacher_curl_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Hammer Curl', 
        'Stand holding dumbbells with palms facing each other. Curl the weights toward your shoulders while maintaining the neutral grip, then lower back down.',
        3, 
        12, 
        '45s', 
        ARRAY['Dumbbells'], 
        ARRAY['Biceps', 'Brachialis', 'Forearms'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO hammer_curl_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Skull Crusher', 
        'Lie on a bench holding an EZ bar or dumbbells above your chest. Bend at the elbows to lower the weight toward your forehead, then extend your arms back up.',
        3, 
        12, 
        '45s', 
        ARRAY['EZ Curl Bar', 'Weight Plates', 'Bench'], 
        ARRAY['Triceps'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO skull_crusher_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Cable Push-Down', 
        'Stand in front of a cable machine with a straight or V-bar attachment at head height. Push the bar down by extending your elbows, then return to the starting position.',
        3, 
        15, 
        '45s', 
        ARRAY['Cable Machine', 'Push-Down Bar'], 
        ARRAY['Triceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO cable_push_down_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Close-Grip Bench Press', 
        'Lie on a bench and grip a barbell with hands about shoulder-width apart. Lower the bar to your lower chest, then press it back up, focusing on using your triceps.',
        3, 
        10, 
        '1m', 
        ARRAY['Barbell', 'Weight Plates', 'Bench'], 
        ARRAY['Triceps', 'Chest', 'Shoulders'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO close_grip_bench_id;
    
    -- Additional Free Weight Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Barbell Shrug', 
        'Stand holding a barbell in front of your thighs. Elevate your shoulders as high as possible without using your biceps, then lower with control.',
        3, 
        15, 
        '45s', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Trapezius', 'Upper Back'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO barbell_shrug_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Dumbbell Shrug', 
        'Stand holding dumbbells at your sides. Raise your shoulders as high as possible without bending your elbows, then lower with control.',
        3, 
        15, 
        '45s', 
        ARRAY['Dumbbells'], 
        ARRAY['Trapezius', 'Upper Back'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO dumbbell_shrug_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Good Morning', 
        'Place a barbell across your upper back. With a slight bend in your knees, hinge at the hips to lower your torso toward the floor while keeping your back flat, then return to standing.',
        3, 
        10, 
        '1m', 
        ARRAY['Barbell', 'Weight Plates'], 
        ARRAY['Hamstrings', 'Lower Back', 'Glutes'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO good_morning_id;
    
    -- Machine Exercises
    
    -- Chest Machine Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Chest Press Machine', 
        'Sit on the machine with your back against the pad. Grasp the handles at chest level, push forward until your arms are extended, then return to starting position.',
        3, 
        12, 
        '45s', 
        ARRAY['Chest Press Machine'], 
        ARRAY['Chest', 'Triceps', 'Shoulders'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO chest_press_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Pec Deck/Butterfly Machine', 
        'Sit on the machine with your back against the pad. Place your forearms against the vertical pads, bring the pads together in front of you, then slowly return to the starting position.',
        3, 
        12, 
        '45s', 
        ARRAY['Pec Deck Machine'], 
        ARRAY['Chest', 'Anterior Deltoids'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO pec_deck_id;
    
    -- Leg Machine Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Leg Press Machine', 
        'Sit on the machine with your back against the pad and feet on the platform. Push the platform away by extending your legs, then return to starting position.',
        4, 
        12, 
        '1m', 
        ARRAY['Leg Press Machine'], 
        ARRAY['Quadriceps', 'Glutes', 'Hamstrings'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO leg_press_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Leg Extension Machine', 
        'Sit on the machine with your back against the pad and shins behind the padded bar. Extend your legs until they are straight, then lower back down.',
        3, 
        15, 
        '45s', 
        ARRAY['Leg Extension Machine'], 
        ARRAY['Quadriceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO leg_extension_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Seated Leg Curl', 
        'Sit on the machine with your back against the pad and legs extended with the padded bar on top of your ankles. Curl your legs toward your buttocks, then return to starting position.',
        3, 
        12, 
        '45s', 
        ARRAY['Seated Leg Curl Machine'], 
        ARRAY['Hamstrings'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO seated_leg_curl_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Lying Leg Curl', 
        'Lie face down on the machine with the padded bar at the back of your ankles. Curl your legs toward your buttocks, then lower back down.',
        3, 
        12, 
        '45s', 
        ARRAY['Lying Leg Curl Machine'], 
        ARRAY['Hamstrings'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO lying_leg_curl_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Standing Calf Raise Machine', 
        'Stand on the platform with your shoulders under the pads. Raise your heels as high as possible, then lower back down below platform level for a full stretch.',
        4, 
        15, 
        '45s', 
        ARRAY['Calf Raise Machine'], 
        ARRAY['Calves'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO calf_raise_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Seated Calf Raise', 
        'Sit on the machine with the balls of your feet on the platform and knees under the pad. Raise your heels as high as possible, then lower them below platform level.',
        4, 
        15, 
        '45s', 
        ARRAY['Seated Calf Raise Machine'], 
        ARRAY['Calves', 'Soleus'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO seated_calf_raise_id;
    
    -- Back Machine Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Lat Pulldown', 
        'Sit at the machine with thighs under the supports. Grasp the bar with a wide grip and pull it down to your upper chest, then slowly return to the starting position.',
        4, 
        12, 
        '45s', 
        ARRAY['Lat Pulldown Machine'], 
        ARRAY['Lats', 'Biceps', 'Middle Back'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO lat_pulldown_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Seated Cable Row', 
        'Sit at the machine with feet against the platform and knees slightly bent. Grab the handle, pull it toward your lower abs while keeping your back straight, then return to start.',
        4, 
        12, 
        '45s', 
        ARRAY['Cable Row Machine'], 
        ARRAY['Middle Back', 'Lats', 'Biceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO cable_row_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Chest Supported Row Machine', 
        'Lie face down on the pad, grab the handles, and pull them up toward your chest while squeezing your shoulder blades together, then lower back down.',
        3, 
        12, 
        '45s', 
        ARRAY['Chest Supported Row Machine'], 
        ARRAY['Middle Back', 'Rhomboids', 'Rear Deltoids'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO chest_supported_row_id;
    
    -- Shoulder Machine Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Shoulder Press Machine', 
        'Sit on the machine with back against the pad. Grasp the handles at shoulder level and press them overhead until arms are extended, then lower back down.',
        3, 
        12, 
        '45s', 
        ARRAY['Shoulder Press Machine'], 
        ARRAY['Shoulders', 'Triceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO shoulder_press_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Lateral Raise Machine', 
        'Sit on the machine with arms positioned on the pads. Push the pads upward and outward until your arms are at shoulder level, then lower back down.',
        3, 
        15, 
        '45s', 
        ARRAY['Lateral Raise Machine'], 
        ARRAY['Lateral Deltoids'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO lateral_raise_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Cable Face Pull', 
        'Set a cable pulley to upper-chest height with a rope attachment. Pull the rope toward your face with elbows high, squeezing your shoulder blades together.',
        3, 
        15, 
        '45s', 
        ARRAY['Cable Machine', 'Rope Attachment'], 
        ARRAY['Rear Deltoids', 'Rotator Cuff', 'Upper Back'], 
        'intermediate', 
        true, 
        admin_id
    ) RETURNING id INTO cable_face_pull_id;
    
    -- Assisted Machine Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Assisted Pull-up Machine', 
        'Kneel on the platform and grasp the handles with a wide grip. Let the weight assist you as you pull yourself up until your chin is over the bar, then lower back down.',
        3, 
        10, 
        '1m', 
        ARRAY['Assisted Pull-up Machine'], 
        ARRAY['Lats', 'Biceps', 'Middle Back'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO assisted_pull_up_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Assisted Dip Machine', 
        'Kneel on the platform and grasp the dip bars. Let the weight assist you as you lower your body by bending your elbows, then push back up.',
        3, 
        10, 
        '1m', 
        ARRAY['Assisted Dip Machine'], 
        ARRAY['Chest', 'Triceps', 'Shoulders'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO assisted_dip_id;
    
    -- Arm Machine Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Bicep Curl Machine', 
        'Sit at the machine with your arms extended against the pads. Curl your arms upward, then lower back to the starting position.',
        3, 
        12, 
        '45s', 
        ARRAY['Bicep Curl Machine'], 
        ARRAY['Biceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO bicep_curl_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Cable Bicep Curl', 
        'Stand in front of a low pulley with a straight or EZ bar attached. Curl the bar up toward your shoulders, keeping elbows at your sides, then lower back down.',
        3, 
        12, 
        '45s', 
        ARRAY['Cable Machine', 'Straight Bar or EZ Bar Attachment'], 
        ARRAY['Biceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO cable_curl_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Tricep Extension Machine', 
        'Sit at the machine with elbows positioned on the pad. Extend your arms downward until they are straight, then return to the starting position.',
        3, 
        12, 
        '45s', 
        ARRAY['Tricep Extension Machine'], 
        ARRAY['Triceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO tricep_extension_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Cable Overhead Tricep Extension', 
        'Face away from a high pulley with a rope attachment. Hold the rope behind your head with elbows bent. Extend your arms overhead, then return to starting position.',
        3, 
        12, 
        '45s', 
        ARRAY['Cable Machine', 'Rope Attachment'], 
        ARRAY['Triceps'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO cable_tricep_extension_id;
    
    -- Core Machine Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Ab Crunch Machine', 
        'Sit on the machine with your chest against the pad and hands on the handles. Crunch forward to compress the abs, then return to the starting position.',
        3, 
        15, 
        '45s', 
        ARRAY['Ab Crunch Machine'], 
        ARRAY['Abs'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO ab_crunch_machine_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Rotary Torso Machine', 
        'Sit on the machine with your torso against the pad. Rotate your torso to one side against the resistance, then to the other side.',
        3, 
        12, 
        '45s', 
        ARRAY['Rotary Torso Machine'], 
        ARRAY['Obliques', 'Core'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO rotary_torso_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Back Extension Machine', 
        'Sit on the machine with your lower back against the pad. Extend your back against the resistance, then return to the starting position.',
        3, 
        15, 
        '45s', 
        ARRAY['Back Extension Machine'], 
        ARRAY['Lower Back', 'Erector Spinae'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO back_extension_id;
    
    -- Hip Machine Exercises
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Hip Abductor Machine', 
        'Sit on the machine with legs together and pads against the outside of your thighs. Push your legs apart against the resistance, then return to the starting position.',
        3, 
        15, 
        '45s', 
        ARRAY['Hip Abductor Machine'], 
        ARRAY['Hip Abductors', 'Outer Thighs'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO hip_abductor_id;
    
    INSERT INTO public.exercises (name, description, sets, reps, duration, equipment, target_muscles, difficulty, is_public, created_by)
    VALUES (
        'Hip Adductor Machine', 
        'Sit on the machine with legs apart and pads against the inside of your thighs. Pull your legs together against the resistance, then return to the starting position.',
        3, 
        15, 
        '45s', 
        ARRAY['Hip Adductor Machine'], 
        ARRAY['Hip Adductors', 'Inner Thighs'], 
        'beginner', 
        true, 
        admin_id
    ) RETURNING id INTO hip_adductor_id;
    
    -- Create strength training workouts from the exercises
    -- 1. Upper Body Machine Workout
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'Upper Body Machine Circuit', 
        'Complete upper body workout using machines for chest, back, shoulders, and arms', 
        'Strength', 
        '50 min', 
        'Beginner', 
        350, 
        true, 
        admin_id
    ) RETURNING id INTO upper_body_machine_id;
    
    -- Add exercises to upper body machine workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (upper_body_machine_id, chest_press_machine_id, 1),
        (upper_body_machine_id, pec_deck_id, 2),
        (upper_body_machine_id, lat_pulldown_machine_id, 3),
        (upper_body_machine_id, cable_row_id, 4),
        (upper_body_machine_id, chest_supported_row_id, 5),
        (upper_body_machine_id, shoulder_press_machine_id, 6),
        (upper_body_machine_id, lateral_raise_machine_id, 7),
        (upper_body_machine_id, bicep_curl_machine_id, 8),
        (upper_body_machine_id, tricep_extension_machine_id, 9);
    
    -- 2. Lower Body Machine Workout
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'Lower Body Machine Circuit', 
        'Complete lower body workout using machines for quads, hamstrings, glutes, and calves', 
        'Strength', 
        '45 min', 
        'Beginner', 
        400, 
        true, 
        admin_id
    ) RETURNING id INTO lower_body_machine_id;
    
    -- Add exercises to lower body machine workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (lower_body_machine_id, leg_press_machine_id, 1),
        (lower_body_machine_id, leg_extension_machine_id, 2),
        (lower_body_machine_id, seated_leg_curl_id, 3),
        (lower_body_machine_id, lying_leg_curl_id, 4),
        (lower_body_machine_id, calf_raise_machine_id, 5),
        (lower_body_machine_id, seated_calf_raise_id, 6),
        (lower_body_machine_id, hip_abductor_id, 7),
        (lower_body_machine_id, hip_adductor_id, 8);
    
    -- 3. Push/Pull Free Weights Workout
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'Push/Pull Free Weight Workout', 
        'Comprehensive strength workout using barbells and dumbbells for a complete push and pull routine', 
        'Strength', 
        '60 min', 
        'Intermediate', 
        450, 
        true, 
        admin_id
    ) RETURNING id INTO push_pull_free_weights_id;
    
    -- Add exercises to Push/Pull Free Weights workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (push_pull_free_weights_id, barbell_bench_press_id, 1),
        (push_pull_free_weights_id, incline_bench_press_id, 2),
        (push_pull_free_weights_id, overhead_press_id, 3),
        (push_pull_free_weights_id, barbell_bent_over_row_id, 4),
        (push_pull_free_weights_id, t_bar_row_id, 5),
        (push_pull_free_weights_id, barbell_deadlift_id, 6),
        (push_pull_free_weights_id, barbell_curl_id, 7),
        (push_pull_free_weights_id, skull_crusher_id, 8);
    
    -- 4. Full Body Machine Circuit Workout
    INSERT INTO public.workouts (name, description, type, duration, difficulty, calories_burned, is_public, created_by)
    VALUES (
        'Full Body Machine Circuit', 
        'Complete full-body workout using strength training machines to hit all major muscle groups', 
        'Strength', 
        '55 min', 
        'Beginner', 
        380, 
        true, 
        admin_id
    ) RETURNING id INTO full_body_machine_circuit_id;
    
    -- Add exercises to Full Body Machine Circuit workout
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index)
    VALUES 
        (full_body_machine_circuit_id, chest_press_machine_id, 1),
        (full_body_machine_circuit_id, lat_pulldown_machine_id, 2),
        (full_body_machine_circuit_id, shoulder_press_machine_id, 3),
        (full_body_machine_circuit_id, leg_press_machine_id, 4),
        (full_body_machine_circuit_id, leg_extension_machine_id, 5),
        (full_body_machine_circuit_id, seated_leg_curl_id, 6),
        (full_body_machine_circuit_id, cable_row_id, 7),
        (full_body_machine_circuit_id, bicep_curl_machine_id, 8),
        (full_body_machine_circuit_id, tricep_extension_machine_id, 9),
        (full_body_machine_circuit_id, ab_crunch_machine_id, 10);
        
    RAISE NOTICE 'Successfully added 50 gym strength training exercises and 4 new workouts';
END $$;
