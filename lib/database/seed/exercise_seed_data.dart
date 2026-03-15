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
        trackWeight: Value(e.trackWeight),
      ));
      for (final eq in e.equipment) {
        await dao.insertEquipment(ExerciseEquipmentCompanion.insert(
          exerciseId: id,
          equipmentType: eq.name,
        ));
      }
    }
  }

  static Future<void> seedMissing(AppDatabase db) async {
    final dao = db.exerciseDao;
    for (final e in _exercises) {
      final existing = await dao.getByNameKey(e.nameKey);
      if (existing == null) {
        final id = await dao.insertExercise(ExercisesCompanion.insert(
          name: e.name,
          nameKey: e.nameKey,
          instructions: Value(e.instructions),
          primaryMuscleGroup: e.muscleGroup,
          category: e.category,
          trackWeight: Value(e.trackWeight),
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

  /// Map of English name → German name for migration
  static const nameTranslations = {
    'Bench Press': 'Bankdrücken',
    'Incline Bench Press': 'Schrägbankdrücken',
    'Dumbbell Chest Press': 'Kurzhantel-Brustdrücken',
    'Cable Fly': 'Kabelzug-Flys',
    'Machine Chest Press': 'Maschinen-Brustpresse',
    'Push-ups': 'Liegestütze',
    'Barbell Row': 'Langhantel-Rudern',
    'Lat Pulldown': 'Latzug',
    'Seated Cable Row': 'Kabelrudern sitzend',
    'Dumbbell Row': 'Kurzhantel-Rudern',
    'Pull-ups': 'Klimmzüge',
    'T-Bar Row': 'T-Bar-Rudern',
    'Overhead Press': 'Schulterdrücken',
    'Lateral Raise': 'Seitheben',
    'Front Raise': 'Frontheben',
    'Face Pull': 'Face Pull',
    'Machine Shoulder Press': 'Maschinen-Schulterdrücken',
    'Barbell Curl': 'Langhantel-Curls',
    'Dumbbell Curl': 'Kurzhantel-Curls',
    'Hammer Curl': 'Hammer-Curls',
    'Cable Curl': 'Kabelzug-Curls',
    'Tricep Pushdown': 'Trizepsdrücken am Kabel',
    'Overhead Tricep Extension': 'Trizepsdrücken über Kopf',
    'Skull Crusher': 'Skull Crusher',
    'Dips': 'Dips',
    'Barbell Squat': 'Kniebeuge',
    'Leg Press': 'Beinpresse',
    'Leg Extension': 'Beinstrecken',
    'Lunges': 'Ausfallschritte',
    'Front Squat': 'Frontkniebeuge',
    'Romanian Deadlift': 'Rumänisches Kreuzheben',
    'Leg Curl': 'Beinbeuger',
    'Good Morning': 'Good Morning',
    'Nordic Curl': 'Nordic Curl',
    'Hip Thrust': 'Hip Thrust',
    'Cable Kickback': 'Kabelzug-Kickback',
    'Glute Bridge': 'Glute Bridge',
    'Standing Calf Raise': 'Wadenheben stehend',
    'Seated Calf Raise': 'Wadenheben sitzend',
    'Plank': 'Plank',
    'Cable Crunch': 'Kabelzug-Crunch',
    'Hanging Leg Raise': 'Beinheben hängend',
    'Ab Rollout': 'Ab Rollout',
    'Deadlift': 'Kreuzheben',
    'Clean & Press': 'Umsetzen & Drücken',
    "Farmer's Walk": 'Farmers Walk',
    'Treadmill Run': 'Laufband',
    'Rowing Machine': 'Rudergerät',
    'Stationary Bike': 'Ergometer',
    'Elliptical': 'Crosstrainer',
  };
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
  final bool trackWeight;

  const _ExDef({
    required this.name,
    required this.nameKey,
    this.instructions,
    required this.muscleGroup,
    required this.category,
    required this.equipment,
    this.trackWeight = true,
  });
}

const _exercises = [
  // Brust (6)
  _ExDef(
    name: 'Bankdrücken',
    nameKey: 'bench_press',
    instructions: 'Flach auf Bank liegen, Stange etwas weiter als schulterbreit greifen, zur Brust senken und hochdrücken.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.barbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Schrägbankdrücken',
    nameKey: 'incline_bench_press',
    instructions: 'Bank auf 30-45 Grad stellen, Stange von der oberen Brust drücken.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.barbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Kurzhantel-Brustdrücken',
    nameKey: 'dumbbell_chest_press',
    instructions: 'Flach liegen, Kurzhanteln von Brusthöhe mit neutralem Griff hochdrücken.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.dumbbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Kabelzug-Flys',
    nameKey: 'cable_fly',
    instructions: 'Zwischen Kabelzügen stehen, Griffe in umarmender Bewegung zusammenführen.',
    muscleGroup: 'chest',
    category: 'isolation',
    equipment: [_Eq.cable, _Eq.chestFly],
  ),
  _ExDef(
    name: 'Maschinen-Brustpresse',
    nameKey: 'machine_chest_press',
    instructions: 'Aufrecht sitzen, Griffe nach vorn drücken bis Arme gestreckt sind.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.machine],
  ),
  _ExDef(
    name: 'Liegestütze',
    nameKey: 'push_ups',
    instructions: 'Hände schulterbreit aufsetzen, Brust zum Boden senken und hochdrücken.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.bodyweight],
    trackWeight: false,
  ),

  // Rücken (6)
  _ExDef(
    name: 'Langhantel-Rudern',
    nameKey: 'barbell_row',
    instructions: 'An der Hüfte beugen, Langhantel zur unteren Brust ziehen, Schulterblätter zusammendrücken.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Latzug',
    nameKey: 'lat_pulldown',
    instructions: 'Stange breit greifen, zur oberen Brust herunterziehen, leicht zurücklehnen.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.cable, _Eq.latPulldown],
  ),
  _ExDef(
    name: 'Kabelrudern sitzend',
    nameKey: 'seated_cable_row',
    instructions: 'Aufrecht sitzen, Griff zur unteren Brust ziehen, Schulterblätter zusammenpressen.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.cable, _Eq.seatedRow],
  ),
  _ExDef(
    name: 'Kurzhantel-Rudern',
    nameKey: 'dumbbell_row',
    instructions: 'Eine Hand auf Bank stützen, Kurzhantel mit der anderen Hand zur Hüfte ziehen.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Klimmzüge',
    nameKey: 'pull_ups',
    instructions: 'An Stange hängen im Obergriff, Kinn über die Stange ziehen.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.bodyweight],
    trackWeight: false,
  ),
  _ExDef(
    name: 'T-Bar-Rudern',
    nameKey: 't_bar_row',
    instructions: 'Über der Stange stehen, Griff zur Brust ziehen, Rücken gerade halten.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),

  // Schultern (5)
  _ExDef(
    name: 'Schulterdrücken',
    nameKey: 'overhead_press',
    instructions: 'Stange auf Schulterhöhe, über Kopf drücken bis zur Streckung.',
    muscleGroup: 'shoulders',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Seitheben',
    nameKey: 'lateral_raise',
    instructions: 'Kurzhanteln seitlich heben bis Arme parallel zum Boden.',
    muscleGroup: 'shoulders',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Frontheben',
    nameKey: 'front_raise',
    instructions: 'Kurzhanteln vor dem Körper bis Schulterhöhe heben, langsam senken.',
    muscleGroup: 'shoulders',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Face Pull',
    nameKey: 'face_pull',
    instructions: 'Seilgriff auf Gesichtshöhe ziehen, Hände auseinanderführen.',
    muscleGroup: 'shoulders',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),
  _ExDef(
    name: 'Maschinen-Schulterdrücken',
    nameKey: 'machine_shoulder_press',
    instructions: 'Aufrecht sitzen, Griffe über Kopf drücken bis zur vollen Streckung.',
    muscleGroup: 'shoulders',
    category: 'compound',
    equipment: [_Eq.machine, _Eq.shoulderPress],
  ),

  // Bizeps (4)
  _ExDef(
    name: 'Langhantel-Curls',
    nameKey: 'barbell_curl',
    instructions: 'Stange auf Oberschenkelhöhe, hochcurlen, Ellbogen fixiert halten.',
    muscleGroup: 'biceps',
    category: 'isolation',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Kurzhantel-Curls',
    nameKey: 'dumbbell_curl',
    instructions: 'Abwechselnd Kurzhanteln mit Untergriff curlen.',
    muscleGroup: 'biceps',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Hammer-Curls',
    nameKey: 'hammer_curl',
    instructions: 'Kurzhanteln mit neutralem Griff curlen, trainiert den Brachialis.',
    muscleGroup: 'biceps',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Kabelzug-Curls',
    nameKey: 'cable_curl',
    instructions: 'Kabelaufsatz von unten curlen, Ellbogen fixiert halten.',
    muscleGroup: 'biceps',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),

  // Trizeps (4)
  _ExDef(
    name: 'Trizepsdrücken am Kabel',
    nameKey: 'tricep_pushdown',
    instructions: 'Kabelstange nach unten drücken bis Arme voll gestreckt.',
    muscleGroup: 'triceps',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),
  _ExDef(
    name: 'Trizepsdrücken über Kopf',
    nameKey: 'overhead_tricep_extension',
    instructions: 'Kurzhantel über Kopf halten, hinter dem Kopf senken und wieder strecken.',
    muscleGroup: 'triceps',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Skull Crusher',
    nameKey: 'skull_crusher',
    instructions: 'Auf Bank liegen, Stange zur Stirn senken und Arme strecken.',
    muscleGroup: 'triceps',
    category: 'isolation',
    equipment: [_Eq.barbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Dips',
    nameKey: 'dips',
    instructions: 'Körper zwischen Parallelbarren senken, wieder hochdrücken bis zur Streckung.',
    muscleGroup: 'triceps',
    category: 'compound',
    equipment: [_Eq.bodyweight],
  ),

  // Oberschenkel vorn (5)
  _ExDef(
    name: 'Kniebeuge',
    nameKey: 'barbell_squat',
    instructions: 'Stange auf oberem Rücken, in die Hocke gehen, durch die Fersen hochdrücken.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Beinpresse',
    nameKey: 'leg_press',
    instructions: 'Füße schulterbreit auf Plattform, Schlitten auf 90 Grad senken und hochdrücken.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.machine],
  ),
  _ExDef(
    name: 'Beinstrecken',
    nameKey: 'leg_extension',
    instructions: 'Beine gegen das Polster strecken bis gerade, langsam senken.',
    muscleGroup: 'quadriceps',
    category: 'isolation',
    equipment: [_Eq.machine, _Eq.legExtension],
  ),
  _ExDef(
    name: 'Ausfallschritte',
    nameKey: 'lunges',
    instructions: 'Schritt nach vorn, hinteres Knie Richtung Boden senken, zurückdrücken.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.dumbbell, _Eq.bodyweight],
  ),
  _ExDef(
    name: 'Frontkniebeuge',
    nameKey: 'front_squat',
    instructions: 'Stange auf vorderer Schulter, Kniebeuge mit aufrechtem Oberkörper.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),

  // Oberschenkel hinten (4)
  _ExDef(
    name: 'Rumänisches Kreuzheben',
    nameKey: 'romanian_deadlift',
    instructions: 'An der Hüfte beugen mit leicht gebeugten Knien, Stange entlang der Beine senken.',
    muscleGroup: 'hamstrings',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Beinbeuger',
    nameKey: 'leg_curl',
    instructions: 'Bäuchlings liegen, Polster Richtung Gesäß curlen und langsam senken.',
    muscleGroup: 'hamstrings',
    category: 'isolation',
    equipment: [_Eq.machine, _Eq.legCurl],
  ),
  _ExDef(
    name: 'Good Morning',
    nameKey: 'good_morning',
    instructions: 'Stange auf Rücken, an der Hüfte nach vorn beugen, Rücken gerade halten.',
    muscleGroup: 'hamstrings',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Nordic Curl',
    nameKey: 'nordic_curl',
    instructions: 'Knien mit fixierten Füßen, Körper kontrolliert nach vorn senken.',
    muscleGroup: 'hamstrings',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
    trackWeight: false,
  ),

  // Gesäß (3)
  _ExDef(
    name: 'Hip Thrust',
    nameKey: 'hip_thrust',
    instructions: 'Rücken an Bank, Hüfte mit Stange auf dem Schoß nach oben drücken.',
    muscleGroup: 'glutes',
    category: 'compound',
    equipment: [_Eq.barbell, _Eq.benchPress],
  ),
  _ExDef(
    name: 'Kabelzug-Kickback',
    nameKey: 'cable_kickback',
    instructions: 'Fußmanschette anlegen, Bein gegen Kabelwiderstand nach hinten strecken.',
    muscleGroup: 'glutes',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),
  _ExDef(
    name: 'Glute Bridge',
    nameKey: 'glute_bridge',
    instructions: 'Flach liegen, Hüfte nach oben drücken, Gesäß oben anspannen.',
    muscleGroup: 'glutes',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
    trackWeight: false,
  ),

  // Waden (2)
  _ExDef(
    name: 'Wadenheben stehend',
    nameKey: 'standing_calf_raise',
    instructions: 'Unter Last auf die Zehenspitzen steigen, langsam senken für volle Dehnung.',
    muscleGroup: 'calves',
    category: 'isolation',
    equipment: [_Eq.machine, _Eq.smithMachine],
  ),
  _ExDef(
    name: 'Wadenheben sitzend',
    nameKey: 'seated_calf_raise',
    instructions: 'Sitzen mit Polster auf den Knien, Fersen so hoch wie möglich heben.',
    muscleGroup: 'calves',
    category: 'isolation',
    equipment: [_Eq.machine],
  ),

  // Rumpf (4)
  _ExDef(
    name: 'Plank',
    nameKey: 'plank',
    instructions: 'Liegestützposition auf Unterarmen halten, Körper gerade halten.',
    muscleGroup: 'core',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
    trackWeight: false,
  ),
  _ExDef(
    name: 'Crunches am Halbball',
    nameKey: 'bosu_crunch',
    instructions: 'Rücken auf dem Halbball (Bosu Ball), Bauchmuskeln anspannen und Oberkörper aufrollen.',
    muscleGroup: 'core',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
    trackWeight: false,
  ),
  _ExDef(
    name: 'Beinheben hängend',
    nameKey: 'hanging_leg_raise',
    instructions: 'An Stange hängen, Beine bis zur Horizontalen oder höher heben.',
    muscleGroup: 'core',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
    trackWeight: false,
  ),
  _ExDef(
    name: 'Ab Rollout',
    nameKey: 'ab_rollout',
    instructions: 'Knien mit Ab-Wheel, nach vorn rollen und mit der Rumpfmuskulatur zurückziehen.',
    muscleGroup: 'core',
    category: 'isolation',
    equipment: [_Eq.bodyweight],
    trackWeight: false,
  ),

  // Ganzkörper (3)
  _ExDef(
    name: 'Kreuzheben',
    nameKey: 'deadlift',
    instructions: 'Stange über Fußmitte, beugen und greifen, bis zur Streckung hochziehen.',
    muscleGroup: 'fullBody',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Umsetzen & Drücken',
    nameKey: 'clean_and_press',
    instructions: 'Stange explosiv zu den Schultern umsetzen, dann über Kopf drücken.',
    muscleGroup: 'fullBody',
    category: 'compound',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Farmers Walk',
    nameKey: 'farmers_walk',
    instructions: 'Schwere Kurzhanteln seitlich halten, mit aufrechter Haltung gehen.',
    muscleGroup: 'fullBody',
    category: 'compound',
    equipment: [_Eq.dumbbell],
  ),

  // Unterarme (2)
  _ExDef(
    name: 'Handgelenkscurls',
    nameKey: 'wrist_curl',
    instructions: 'Unterarme auf Bank ablegen, Handgelenke mit der Stange nach oben curlen.',
    muscleGroup: 'forearms',
    category: 'isolation',
    equipment: [_Eq.barbell],
  ),
  _ExDef(
    name: 'Reverse Curls',
    nameKey: 'reverse_curl',
    instructions: 'Stange im Obergriff greifen und mit fixierten Ellbogen curlen.',
    muscleGroup: 'forearms',
    category: 'isolation',
    equipment: [_Eq.barbell],
  ),

  // Zusätzliche Übungen
  _ExDef(
    name: 'Bulgarische Kniebeuge',
    nameKey: 'bulgarian_split_squat',
    instructions: 'Hinterer Fuß auf Bank ablegen, vorderes Bein in die Hocke gehen.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.dumbbell, _Eq.bodyweight],
  ),
  _ExDef(
    name: 'Latzug eng',
    nameKey: 'close_grip_lat_pulldown',
    instructions: 'Enge Griffstange am Latzug zur oberen Brust herunterziehen.',
    muscleGroup: 'back',
    category: 'compound',
    equipment: [_Eq.cable, _Eq.latPulldown],
  ),
  _ExDef(
    name: 'Reverse Fly',
    nameKey: 'reverse_fly',
    instructions: 'Vorgebeugt stehend, Kurzhanteln seitlich nach oben heben.',
    muscleGroup: 'shoulders',
    category: 'isolation',
    equipment: [_Eq.dumbbell],
  ),
  _ExDef(
    name: 'Kabel-Seitheben',
    nameKey: 'cable_lateral_raise',
    instructions: 'Am Kabelzug seitlich stehend, Arm seitlich bis Schulterhöhe heben.',
    muscleGroup: 'shoulders',
    category: 'isolation',
    equipment: [_Eq.cable],
  ),
  _ExDef(
    name: 'Brustdips',
    nameKey: 'chest_dips',
    instructions: 'Körper am Barren nach vorn neigen, tief senken und hochdrücken.',
    muscleGroup: 'chest',
    category: 'compound',
    equipment: [_Eq.bodyweight],
  ),
  _ExDef(
    name: 'Hackenschmidt-Kniebeuge',
    nameKey: 'hack_squat',
    instructions: 'An der Hackenschmidt-Maschine Schlitten nach oben drücken.',
    muscleGroup: 'quadriceps',
    category: 'compound',
    equipment: [_Eq.machine],
  ),

  // Ausdauer (4)
  _ExDef(
    name: 'Laufband',
    nameKey: 'treadmill_run',
    instructions: 'In gleichmäßigem Tempo auf dem Laufband laufen.',
    muscleGroup: 'cardio',
    category: 'cardio',
    equipment: [_Eq.treadmill],
    trackWeight: false,
  ),
  _ExDef(
    name: 'Rudergerät',
    nameKey: 'rowing_machine',
    instructions: 'Zuerst mit den Beinen drücken, dann Griff zur unteren Brust ziehen.',
    muscleGroup: 'cardio',
    category: 'cardio',
    equipment: [_Eq.rowingMachine],
    trackWeight: false,
  ),
  _ExDef(
    name: 'Ergometer',
    nameKey: 'stationary_bike',
    instructions: 'Mit gleichmäßiger Trittfrequenz und angemessenem Widerstand treten.',
    muscleGroup: 'cardio',
    category: 'cardio',
    equipment: [_Eq.stationaryBike],
    trackWeight: false,
  ),
  _ExDef(
    name: 'Crosstrainer',
    nameKey: 'elliptical',
    instructions: 'Gleichmäßig auf dem Crosstrainer bei moderater Intensität trainieren.',
    muscleGroup: 'cardio',
    category: 'cardio',
    equipment: [_Eq.elliptical],
    trackWeight: false,
  ),
];
