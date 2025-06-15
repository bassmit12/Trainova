class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  // Fitness profile properties
  final double? weight;
  final double? height;
  final String? weightUnit; // 'kg' or 'lbs'
  final String? heightUnit; // 'cm' or 'ft'
  final String? fitnessGoal; // 'weight_loss', 'muscle_gain', 'endurance', etc.
  final int? workoutsPerWeek;
  final List<String>?
      preferredWorkoutTypes; // 'cardio', 'strength', 'yoga', etc.
  final String? experienceLevel; // 'beginner', 'intermediate', 'advanced'
  final bool isProfileComplete;

  UserModel({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    this.createdAt,
    this.metadata,
    this.weight,
    this.height,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.fitnessGoal,
    this.workoutsPerWeek,
    this.preferredWorkoutTypes,
    this.experienceLevel,
    this.isProfileComplete = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['user_metadata']?['full_name'] ??
          json['user_metadata']?['name'] ??
          json['full_name'] ??
          json['name'],
      avatarUrl: json['user_metadata']?['avatar_url'] ?? json['avatar_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      metadata: json['user_metadata'] ?? json['metadata'],

      // Fitness profile data
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      weightUnit: json['weight_unit'] ?? 'kg',
      heightUnit: json['height_unit'] ?? 'cm',
      fitnessGoal: json['fitness_goal'],
      workoutsPerWeek: json['workouts_per_week'],
      preferredWorkoutTypes: json['preferred_workout_types'] != null
          ? List<String>.from(json['preferred_workout_types'])
          : null,
      experienceLevel: json['experience_level'],
      isProfileComplete: json['is_profile_complete'] ?? false,
    );
  }

  // Factory constructor for Map data (alias for fromJson for consistency)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'metadata': metadata,
      'weight': weight,
      'height': height,
      'weight_unit': weightUnit,
      'height_unit': heightUnit,
      'fitness_goal': fitnessGoal,
      'workouts_per_week': workoutsPerWeek,
      'preferred_workout_types': preferredWorkoutTypes,
      'experience_level': experienceLevel,
      'is_profile_complete': isProfileComplete,
    };
  }

  // Create a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    double? weight,
    double? height,
    String? weightUnit,
    String? heightUnit,
    String? fitnessGoal,
    int? workoutsPerWeek,
    List<String>? preferredWorkoutTypes,
    String? experienceLevel,
    bool? isProfileComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      workoutsPerWeek: workoutsPerWeek ?? this.workoutsPerWeek,
      preferredWorkoutTypes:
          preferredWorkoutTypes ?? this.preferredWorkoutTypes,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}
