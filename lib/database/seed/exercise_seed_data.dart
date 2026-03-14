import 'package:drift/drift.dart';

import '../app_database.dart';

class ExerciseSeedData {
  static Future<void> seed(AppDatabase db) async {
    final dao = db.exerciseDao;
    if (await dao.hasExercises()) return;

    for (final e in _exercises) {
      final id = await dao.insertExercise(ExercisesCompanion.insert(
        name: e.name,
        nameKey: e.nameKey,
        instructions: Value(e.instructions),
        primaryMuscleGroup: e.muscleGroup,
        category: e.category,
      ));
      for (final eq in e.equipment) {
        await dao.insertEquipment(ExerciseEquipmentCompanion.insert(
          exerciseId: id,
          equipmentType: eq.name,
        ));
      }
    }
  }
}

enum _Eq {
  barbell,
  dumbbell,
  cable,
  machine,
  bodyweight,
  benchPress,
  latPulldown,
  legExtension,
  legCurl,
  seatedRow,
  shoulderPress,
  smithMachine,
  chestFly,
  rowingMachine,
  treadmill,
  stationaryBike,
  elliptical,
}

class _ExDef {
  final String name;
  final String nameKey;
  final String? instructions;
  final String muscleGroup;
  final String category;
  final List<_Eq> equipment;

  const _ExDef({
    required this.name,
    required this.nameKey,
    this.instructions,
    required this.muscleGroup,
    required this.category,
    required this.equipment,
  });
}

const _exercises = [
  // Chest (6)
  _ExDef(
    name: 'Bench Press',
    nameKey: 'bench_press',
    instructions: 'Lie flat on bench, grip bar slightly wider than shoulders, lower to chest and press up.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.barbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Incline Bench Press',
    nameKey: 'incline_bench_press',
    instructions: 'Set bench to 30-45 degrees, press bar from upper chest.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.barbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Dumbbell Chest Press',
    nameKey: 'dumbbell_chest_press',
    instructions: 'Lie flat, press dumbbells up from chest level with neutral grip.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.dumbbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Cable Fly',
    nameKey: 'cable_fly',
    instructions: 'Stand between cable pulleys, bring handles together in hugging motion.',
    muscleGroup: 'chest',
    category: 'isolation',
    equipment: [_Eq.cable, _Eq.chestFly],
  ),
  _ExDef(
    name: 'Machine Chest Press',
    nameKey: 'machine_chest_press',
    instructions: 'Sit upright, press handles forward until arms are extended.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.machine],
  ),
  _ExDef(
    name: 'Push-ups',
    nameKey: 'push_ups',
    instructions: 'Hands shoulder-width apart, lower chest to floor and push back up.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.bodyweight],
  ),

  // Back (6)
  _ExDef(
    name: 'Barbell Row',
    nameKey: 'barbell_row',
    instructions: 'Hinge at hips, pull barbell to lower chest, squeeze shoulder blades.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Lat Pulldown',
    nameKey: 'lat_pulldown',
    instructions: 'Grip bar wide, pull down to upper chest while leaning slightly back.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.cable, _Eq.latPulldown],
  ),
  _ExDef(
    name: 'Seated Cable Row',
    nameKey: 'seated_cable_row',
    instructions: 'Sit upright, pull handle to lower chest, squeeze shoulder blades together.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.cable, _Eq.seatedRow],
  ),
  _ExDef(
    name: 'Dumbbell Row',
    nameKey: 'dumbbell_row',
    instructions: 'One hand on bench, pull dumbbell to hip with other arm.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Pull-ups',
    nameKey: 'pull_ups',
    instructions: 'Hang from bar with overhand grip, pull chin above bar.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.bodyweight],
  ),
  _ExDef(
    name: 'T-Bar Row',
    nameKey: 't_bar_row',
    instructions: 'Straddle bar, pull handle to chest keeping back straight.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),

  // Shoulders (5)
  _ExDef(
    name: 'Overhead Press',
    nameKey: 'overhead_press',
    instructions: 'Stand with bar at shoulders, press overhead to lockout.',
    muscleGroup: 'shoulders',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Lateral Raise',
    nameKey: 'lateral_raise',
    instructions: 'Raise dumbbells to sides until arms are parallel to floor.',
    muscleGroup: 'shoulders',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Front Raise',
    nameKey: 'front_raise',
    instructions: 'Raise dumbbells in front to shoulder height, lower slowly.',
    muscleGroup: 'shoulders',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Face Pull',
    nameKey: 'face_pull',
    instructions: 'Pull rope attachment to face level, spreading hands apart.',
    muscleGroup: 'shoulders',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),
  _ExDef(
    name: 'Machine Shoulder Press',
    nameKey: 'machine_shoulder_press',
    instructions: 'Sit upright, press handles overhead to full extension.',
    muscleGroup: 'shoulders',
    category: 'compound',
    equipment: [_Eq.machine, _Eq.shoulderPress],
  ),

  // Biceps (4)
  _ExDef(
    name: 'Barbell Curl',
    nameKey: 'barbell_curl',
    instructions: 'Stand with bar at thighs, curl up keeping elbows stationary.',
    muscleGroup: 'biceps',
    category: 'isolation',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Dumbbell Curl',
    nameKey: 'dumbbell_curl',
    instructions: 'Alternate curling dumbbells with supinated grip.',
    muscleGroup: 'biceps',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Hammer Curl',
    nameKey: 'hammer_curl',
    instructions: 'Curl dumbbells with neutral (hammer) grip targeting brachialis.',
    muscleGroup: 'biceps',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Cable Curl',
    nameKey: 'cable_curl',
    instructions: 'Curl cable attachment from low position, keep elbows pinned.',
    muscleGroup: 'biceps',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),

  // Triceps (4)
  _ExDef(
    name: 'Tricep Pushdown',
    nameKey: 'tricep_pushdown',
    instructions: 'Push cable bar down until arms are fully extended.',
    muscleGroup: 'triceps',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),
  _ExDef(
    name: 'Overhead Tricep Extension',
    nameKey: 'overhead_tricep_extension',
    instructions: 'Hold dumbbell overhead, lower behind head and extend back up.',
    muscleGroup: 'triceps',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Skull Crusher',
    nameKey: 'skull_crusher',
    instructions: 'Lie on bench, lower bar to forehead and extend arms.',
    muscleGroup: 'triceps',
    category: 'isolation',
    equipment: [_Eq.barbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Dips',
    nameKey: 'dips',
    instructions: 'Lower body between parallel bars, press back up to lockout.',
    muscleGroup: 'triceps',
    category: 'compound',
    equipment: [_Eq.bodyweight],
  ),

  // Quadriceps (5)
  _ExDef(
    name: 'Barbell Squat',
    nameKey: 'barbell_squat',
    instructions: 'Bar on upper back, squat to parallel or below, drive up through heels.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Leg Press',
    nameKey: 'leg_press',
    instructions: 'Feet shoulder-width on platform, lower sled to 90 degrees and press up.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.machine],
  ),
  _ExDef(
    name: 'Leg Extension',
    nameKey: 'leg_extension',
    instructions: 'Extend legs against pad until straight, lower slowly.',
    muscleGroup: 'quadriceps',
    category: 'isolation',
    equipment: [_Eq.machine, _Eq.legExtension],
  ),
  _ExDef(
    name: 'Lunges',
    nameKey: 'lunges',
    instructions: 'Step forward, lower back knee toward floor, push back to start.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.dumbbell, _Eq.bodyweight],
  ),
  _ExDef(
    name: 'Front Squat',
    nameKey: 'front_squat',
    instructions: 'Bar on front deltoids, squat keeping torso upright.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),

  // Hamstrings (4)
  _ExDef(
    name: 'Romanian Deadlift',
    nameKey: 'romanian_deadlift',
    instructions: 'Hinge at hips with slight knee bend, lower bar along legs.',
    muscleGroup: 'hamstrings',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Leg Curl',
    nameKey: 'leg_curl',
    instructions: 'Lie face down, curl pad toward glutes and lower slowly.',
    muscleGroup: 'hamstrings',
    category: 'isolation',
    equipment: [_Eq.machine, _Eq.legCurl],
  ),
  _ExDef(
    name: 'Good Morning',
    nameKey: 'good_morning',
    instructions: 'Bar on back, hinge forward at hips keeping back straight.',
    muscleGroup: 'hamstrings',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Nordic Curl',
    nameKey: 'nordic_curl',
    instructions: 'Kneel with feet anchored, lower body forward under control.',
    muscleGroup: 'hamstrings',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
  ),

  // Glutes (3)
  _ExDef(
    name: 'Hip Thrust',
    nameKey: 'hip_thrust',
    instructions: 'Back on bench, drive hips up with bar across lap.',
    muscleGroup: 'glutes',
    category: 'compound',
    equipment: [_Eq.barbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Cable Kickback',
    nameKey: 'cable_kickback',
    instructions: 'Attach ankle cuff, kick leg back against cable resistance.',
    muscleGroup: 'glutes',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),
  _ExDef(
    name: 'Glute Bridge',
    nameKey: 'glute_bridge',
    instructions: 'Lie flat, drive hips up squeezing glutes at top.',
    muscleGroup: 'glutes',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
  ),

  // Calves (2)
  _ExDef(
    name: 'Standing Calf Raise',
    nameKey: 'standing_calf_raise',
    instructions: 'Rise onto toes under load, lower slowly for full stretch.',
    muscleGroup: 'calves',
    category: 'isolation',
    equipment: [_Eq.machine, _Eq.smithMachine],
  ),
  _ExDef(
    name: 'Seated Calf Raise',
    nameKey: 'seated_calf_raise',
    instructions: 'Sit with pad on knees, raise heels as high as possible.',
    muscleGroup: 'calves',
    category: 'isolation',
    equipment: [_Eq.machine],
  ),

  // Core (4)
  _ExDef(
    name: 'Plank',
    nameKey: 'plank',
    instructions: 'Hold push-up position on forearms, keep body straight.',
    muscleGroup: 'core',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
  ),
  _ExDef(
    name: 'Cable Crunch',
    nameKey: 'cable_crunch',
    instructions: 'Kneel at cable, crunch down bringing elbows to knees.',
    muscleGroup: 'core',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),
  _ExDef(
    name: 'Hanging Leg Raise',
    nameKey: 'hanging_leg_raise',
    instructions: 'Hang from bar, raise legs to horizontal or above.',
    muscleGroup: 'core',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
  ),
  _ExDef(
    name: 'Ab Rollout',
    nameKey: 'ab_rollout',
    instructions: 'Kneel with ab wheel, roll forward and pull back using core.',
    muscleGroup: 'core',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
  ),

  // Full Body (3)
  _ExDef(
    name: 'Deadlift',
    nameKey: 'deadlift',
    instructions: 'Stand with bar over mid-foot, hinge and grip, drive up to lockout.',
    muscleGroup: 'fullBody',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Clean & Press',
    nameKey: 'clean_and_press',
    instructions: 'Clean bar to shoulders explosively, then press overhead.',
    muscleGroup: 'fullBody',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: "Farmer's Walk",
    nameKey: 'farmers_walk',
    instructions: 'Hold heavy dumbbells at sides, walk with upright posture.',
    muscleGroup: 'fullBody',
    category: 'compound',
    equipment: [_Eq.dumbbell],
  ),

  // Cardio (4)
  _ExDef(
    name: 'Treadmill Run',
    nameKey: 'treadmill_run',
    instructions: 'Run at steady pace on treadmill for desired duration.',
    muscleGroup: 'cardio',
    category: 'cardio',
    equipment: [_Eq.treadmill],
  ),
  _ExDef(
    name: 'Rowing Machine',
    nameKey: 'rowing_machine',
    instructions: 'Drive with legs first, then pull handle to lower chest.',
    muscleGroup: 'cardio',
    category: 'cardio',
    equipment: [_Eq.rowingMachine],
  ),
  _ExDef(
    name: 'Stationary Bike',
    nameKey: 'stationary_bike',
    instructions: 'Pedal at steady cadence with appropriate resistance.',
    muscleGroup: 'cardio',
    category: 'cardio',
    equipment: [_Eq.stationaryBike],
  ),
  _ExDef(
    name: 'Elliptical',
    nameKey: 'elliptical',
    instructions: 'Stride smoothly on elliptical machine at moderate intensity.',
    muscleGroup: 'cardio',
    category: 'cardio',
    equipment: [_Eq.elliptical],
  ),
];
