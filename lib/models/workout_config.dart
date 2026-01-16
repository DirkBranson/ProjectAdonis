class WorkoutConfig {
  static final Map<String, Map<String, dynamic>> categories = {
    'Free Weights': {
      'workouts': [
        'Bench Press',
        'Bicep Curl R',
        'Bicep Curl L',
        'Tricep Extension R',
        'Tricep Extension L',
        'Dead Lift',
        'RDL',
        'Squat',
        'Overhead Press 2H',
        'Overhead Press 1H',
        'Single Row R',
        'Single Row L',
        'Bentover Row',
        'Vertical Arm Raise',
        'Horizontal Arm Raise',
        'Flies',
        'Lunges',
        'Calf Raises',
      ],
      'fields': ['Weight (kg)', 'Reps'],
    },
    'Machines': {
      'workouts': [
        'Leg Press',
        'Lat Pulldown',
        'Chest Press',
        'Cable Flies',
        'Tricep Extensions',
        'Hamstring Curl',
      ],
      'fields': ['Weight (kg)', 'Reps'],
    },
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
        'Pike Push Ups',
        'Squats',
      ],
      'fields': ['Weight (kg)', 'Reps'],
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
    'Sports': {
      'workouts': ['Tag Rugby', 'Tennis'],
      'fields': ['My Score', 'Team Score'],
    },
  };

  static List<String> get categoryList => categories.keys.toList();

  static List<String> getWorkouts(String category) =>
      List<String>.from(categories[category]?['workouts'] ?? []);

  // Added this helper back in case your UI needs it to generate text fields
  static List<String> getFields(String category) =>
      List<String>.from(categories[category]?['fields'] ?? []);
}
