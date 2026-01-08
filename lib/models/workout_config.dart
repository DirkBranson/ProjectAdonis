class WorkoutConfig {
  static final Map<String, Map<String, dynamic>> categories = {
    'Free Weights': {
      'workouts': [
        'Bench Press',
        'Bicep Curl',
        'Dead Lift',
        'RDL',
        'Squat',
        'Overhead Press',
        'Single Row',
        'Barbell Row',
      ],
      'fields': ['Weight (kg)', 'Reps'],
    },
    // Inside WorkoutConfig class
    'Calisthenics': {
      'workouts': [
        'Muscle Ups',
        'Pull Ups',
        'Chin Ups',
        'Dips',
        'Pistol Squats',
        'Nordic Curls',
        'Ring Rows',
        'Ring Press Ups',
        'Archer Press Ups',
        'Press Ups',
      ],
      'fields': ['Weight (kg)', 'Reps'], // Removed 'Assistance'
    },
    'Isometrics': {
      'workouts': [
        'Handstand',
        'Hollow Body',
        'L-Sit',
        'Back Lever',
        'Front Lever',
        'Planche',
        'Frog Stand',
      ],
      'fields': ['Time (s)'],
    },
    'Eccentrics': {
      'workouts': [
        'Chin Ups',
        'Pull Ups',
        'Muscle Ups',
        'Pistol Squats',
        'Dips',
      ],
      'fields': ['Time (s)', 'Reps'],
    },
    'Distance Running': {
      'workouts': ['Run'],
      'fields': ['Distance (miles)', 'Pace (mins/mile)'],
    },
    'Track': {
      'workouts': ['3k', '1500m', '800m', '400m', '200m', '100m'],
      'fields': ['Distance (m)', 'Time (s)'],
    },
    'Flexibility': {
      'workouts': [
        'Box Splits',
        'Front Splits Right',
        'Front Splits Left',
        'Pancake',
      ],
      'fields': ['Time (s)', 'Stretch (cm)'],
    },
  };

  // Helper to get categories as a simple list
  static List<String> get categoryList => categories.keys.toList();

  // Helper to get workouts for a specific category
  static List<String> getWorkouts(String category) =>
      List<String>.from(categories[category]?['workouts'] ?? []);
}
