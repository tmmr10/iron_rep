// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navWorkout => 'Workout';

  @override
  String get navActivity => 'Activity';

  @override
  String get navProgress => 'Progress';

  @override
  String get navMore => 'More';

  @override
  String get welcomeTitle => 'Welcome to IronRep';

  @override
  String get whatsYourName => 'What\'s your name?';

  @override
  String get yourNameHint => 'Your name';

  @override
  String get welcomeTagline => 'Your workout tracker for real progress.';

  @override
  String get welcomeFeature1 => 'Track workouts & log sets';

  @override
  String get welcomeFeature2 => 'Progress & personal records';

  @override
  String get welcomeFeature3 => 'Create & share plans';

  @override
  String get letsGo => 'Let\'s go';

  @override
  String get later => 'Later';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get motivationStreakRunning1 => 'Your streak is going – keep it up!';

  @override
  String get motivationStreakRunning2 => 'Consistency beats perfection.';

  @override
  String get motivationWeekGreat1 => 'What a week – respect!';

  @override
  String get motivationWeekGreat2 => 'You\'re on fire this week!';

  @override
  String get motivationWeekGreat3 => 'Absolute peak form!';

  @override
  String get motivationWeekGood1 => 'Good rhythm, keep it up!';

  @override
  String get motivationWeekGood2 => 'Strong week so far!';

  @override
  String get motivationWeekOne1 => 'Good start this week!';

  @override
  String get motivationWeekOne2 => 'One done – more to come?';

  @override
  String get motivationWeekOne3 => 'The first step is done.';

  @override
  String get motivationMorning1 =>
      'Perfect way to start the day – get training!';

  @override
  String get motivationMorning2 => 'Train in the morning, benefit all day.';

  @override
  String get motivationMorning3 => 'Your body is waiting for you.';

  @override
  String get motivationMorning4 => 'A morning workout sets the tone.';

  @override
  String get motivationDay1 => 'Ready for your training?';

  @override
  String get motivationDay2 => 'Time for a session?';

  @override
  String get motivationDay3 => 'Every set counts.';

  @override
  String get motivationDay4 => 'Stronger than yesterday.';

  @override
  String get motivationEvening1 => 'Still time for an evening workout?';

  @override
  String get motivationEvening2 => 'The day isn\'t over yet.';

  @override
  String get motivationEvening3 => 'Train in the evening, sleep better.';

  @override
  String get motivationEvening4 => 'Last chance today – make it count!';

  @override
  String get motivationStrongStreak1 => 'Machine. Just machine.';

  @override
  String get motivationStrongStreak2 => 'Unstoppable – 4+ weeks streak!';

  @override
  String get motivationStrongStreak3 => 'Discipline pays off.';

  @override
  String get yourStats => 'Your stats';

  @override
  String get yourWorkouts => 'Your workouts';

  @override
  String get createFirstPlanTitle => 'Create your first training plan';

  @override
  String get createFirstPlanSubtitle =>
      'Choose your exercises, set the number of sets, and start your training.';

  @override
  String get createPlan => 'Create workout';

  @override
  String get newPlan => 'New workout';

  @override
  String get thisWeek => 'This week';

  @override
  String get workoutCompleted => 'Workout completed!';

  @override
  String get duration => 'Duration';

  @override
  String get exercises => 'Exercises';

  @override
  String get sets => 'Sets';

  @override
  String get volume => 'Volume';

  @override
  String get skipped => 'skipped';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String get nextSet => 'Next set';

  @override
  String get nextExercise => 'Next exercise';

  @override
  String get addSet => 'Add set';

  @override
  String exerciseOf(int current, int total) {
    return 'Exercise $current of $total';
  }

  @override
  String nextExerciseLabel(String name) {
    return 'Next: $name';
  }

  @override
  String get completeSet => 'Complete set';

  @override
  String get showAllExercises => 'Show all exercises';

  @override
  String get allExercisesCompleted => 'All exercises completed!';

  @override
  String get confirmEndWorkout => 'Do you want to end the workout?';

  @override
  String get addExercise => 'Add exercise';

  @override
  String get noExercisesInPlan => 'No exercises in workout';

  @override
  String get createNewExercise => 'Create new exercise';

  @override
  String get exerciseName => 'Exercise name';

  @override
  String get exerciseNameHint => 'e.g. Dumbbell lateral raise';

  @override
  String get muscleGroup => 'Muscle group';

  @override
  String get equipmentOptional => 'Equipment (optional)';

  @override
  String get noEquipment => 'No equipment';

  @override
  String get createExercise => 'Create exercise';

  @override
  String get searchExercise => 'Search exercise...';

  @override
  String get noExercisesFound => 'No exercises found';

  @override
  String get noExercisesInCategory => 'No exercises in this category';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get changesWillBeLost => 'Your changes will be lost.';

  @override
  String get continueEditing => 'Continue editing';

  @override
  String get discard => 'Discard';

  @override
  String get editExercise => 'Edit exercise';

  @override
  String get nameInputLabel => 'Exercise name';

  @override
  String get nameInputHint => 'Enter name';

  @override
  String get instructionsLabel => 'Instructions (optional)';

  @override
  String get instructionsHint => 'Describe execution';

  @override
  String get trackWeight => 'Track weight';

  @override
  String get equipment => 'Equipment';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get cameraPhoto => 'Take photo';

  @override
  String get galleryPhoto => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get deleteExercise => 'Delete exercise';

  @override
  String get deleteExerciseConfirm => 'Delete exercise?';

  @override
  String get deleteExerciseMessage =>
      'The exercise will be removed from the list. Existing workouts will be retained.';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get instructions => 'Instructions';

  @override
  String get progressButton => 'Show progress';

  @override
  String get activity => 'Activity';

  @override
  String get logManualWorkout => 'Log workout manually';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get completeFirstWorkout => 'Complete your first workout';

  @override
  String get workoutNameHint => 'e.g. Upper body';

  @override
  String get planExercisesAutoImport =>
      'The exercises from the plan will be imported automatically. You can add sets in edit mode.';

  @override
  String get manualExercisesAddLater =>
      'You can add exercises and sets in edit mode after creation.';

  @override
  String get deleteWorkout => 'Delete workout';

  @override
  String get deleteWorkoutConfirm => 'Delete workout?';

  @override
  String get deleteWorkoutMessage =>
      'The workout and all associated data will be permanently deleted.';

  @override
  String get skippedCapital => 'Skipped';

  @override
  String get progress => 'Progress';

  @override
  String get yourProgress => 'Your progress';

  @override
  String get muscleDistribution => 'Muscle distribution';

  @override
  String get strengthDevelopment => 'Strength development';

  @override
  String get yourExercises => 'Your exercises';

  @override
  String get completeWorkoutToSeeExercises =>
      'Complete a workout to see your exercises here';

  @override
  String get personalRecords => 'Personal records';

  @override
  String get completeWorkoutToSeeStrength =>
      'Complete a workout to see strength development';

  @override
  String get maxWeight => 'Max weight';

  @override
  String get maxReps => 'Max reps';

  @override
  String get maxVolume => 'Max volume';

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String currentWeight(String weight) {
    return 'Current: $weight kg';
  }

  @override
  String get allPlans => 'All plans';

  @override
  String get perExercise => 'Per exercise';

  @override
  String get exercisesNotRecognized =>
      'not recognized – will be skipped during import';

  @override
  String get customExerciseCreated => 'Will be created as custom exercise';

  @override
  String get exerciseNotFound => 'Exercise not found';

  @override
  String get planName => 'Workout name';

  @override
  String get exercisesSectionHeader => 'EXERCISES';

  @override
  String exercisesCount(int count, int sets) {
    return '$count exercises · $sets sets';
  }

  @override
  String get enterPlanName => 'Please enter a workout name';

  @override
  String get addAtLeastOneExercise => 'Add at least one exercise';

  @override
  String get sharePlan => 'Share workout';

  @override
  String get deletePlan => 'Delete workout';

  @override
  String get deletePlanConfirm => 'Delete workout?';

  @override
  String get cannotBeUndone => 'This cannot be undone.';

  @override
  String get addExerciseEmptyState =>
      'Every great plan starts with one exercise.\nTap + and get started!';

  @override
  String get searchExercises => 'Search exercises...';

  @override
  String get settings => 'Settings';

  @override
  String get name => 'Name';

  @override
  String get notSet => 'Not set';

  @override
  String get weightUnit => 'Weight unit';

  @override
  String get defaultRestTime => 'Default rest time';

  @override
  String get appearance => 'Appearance';

  @override
  String get design => 'Design';

  @override
  String get plansAndExercises => 'Workouts & Exercises';

  @override
  String get managePlans => 'Manage workouts';

  @override
  String get manageExercises => 'Manage exercises';

  @override
  String get pro => 'Pro';

  @override
  String get removeAds => 'Remove ads';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get system => 'System';

  @override
  String get createNewPlan => 'Create new workout';

  @override
  String get adFreeDescription =>
      'Enjoy an ad-free experience with a one-time purchase.';

  @override
  String get supportIndieDev => 'Support indie development';

  @override
  String buyForPrice(String price) {
    return 'Buy for $price';
  }

  @override
  String get purchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get noAdBanners => 'No ad banners';

  @override
  String get fasterCleanerExperience => 'Faster, cleaner experience';

  @override
  String get restorePurchase => 'Restore purchase';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get all => 'All';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get noPlanFound => 'No plan found';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleBack => 'Back';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get muscleQuadriceps => 'Quadriceps';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleCore => 'Core';

  @override
  String get muscleFullBody => 'Full body';

  @override
  String get muscleCardio => 'Cardio';

  @override
  String get equipBarbell => 'Barbell';

  @override
  String get equipDumbbell => 'Dumbbell';

  @override
  String get equipCable => 'Cable';

  @override
  String get equipMachine => 'Machine';

  @override
  String get equipBodyweight => 'Bodyweight';

  @override
  String get equipBenchPress => 'Bench press';

  @override
  String get equipLatPulldown => 'Lat pulldown';

  @override
  String get equipLegExtension => 'Leg extension';

  @override
  String get equipLegCurl => 'Leg curl';

  @override
  String get equipSeatedRow => 'Seated row';

  @override
  String get equipShoulderPress => 'Shoulder press';

  @override
  String get equipSmithMachine => 'Smith machine';

  @override
  String get equipChestFly => 'Chest fly';

  @override
  String get equipRowingMachine => 'Rowing machine';

  @override
  String get equipTreadmill => 'Treadmill';

  @override
  String get equipStationaryBike => 'Stationary bike';

  @override
  String get equipElliptical => 'Elliptical';

  @override
  String get equipBench => 'Flat bench';

  @override
  String get equipInclineBench => 'Incline bench';

  @override
  String get equipDipStation => 'Dip station';

  @override
  String get equipPullUpBar => 'Pull-up bar';

  @override
  String get equipHyperextensionBench => 'Hyperextension bench';

  @override
  String get equipPreacherCurlBench => 'Preacher curl bench';

  @override
  String get setTypeWarmup => 'Warm-up';

  @override
  String get setTypeWorking => 'Working set';

  @override
  String get setTypeDropset => 'Drop set';

  @override
  String get setTypeFailure => 'To failure';

  @override
  String get paused => 'Paused';

  @override
  String get tapToResume => 'Tap to resume';

  @override
  String get training => 'Training';

  @override
  String get startTraining => 'Start training';

  @override
  String get startWorkout => 'Start workout';

  @override
  String get endWorkout => 'End workout';

  @override
  String get finishWorkout => 'Finish Workout';

  @override
  String get switchToGuidedMode => 'Switch to Guided Mode';

  @override
  String get discardWorkout => 'Discard workout';

  @override
  String get discardWorkoutConfirm => 'Discard workout?';

  @override
  String get allProgressWillBeLost => 'All progress will be lost.';

  @override
  String get continueTraining => 'Continue';

  @override
  String get keepTraining => 'Keep training';

  @override
  String get setCompleted => 'Set completed';

  @override
  String setOfTotal(int current, int total) {
    return 'Set $current of $total';
  }

  @override
  String get setOfTotalLoading => 'Set 1 of …';

  @override
  String get noActiveWorkout => 'No active workout';

  @override
  String get setsCount => 'Sets';

  @override
  String completedOfTotalSets(int completed, int total) {
    return '$completed/$total sets';
  }

  @override
  String get restPause => 'Rest';

  @override
  String get timeAgoToday => 'today';

  @override
  String get timeAgoYesterday => 'yesterday';

  @override
  String timeAgoDays(int days) {
    return '$days days ago';
  }

  @override
  String timeAgoWeeks(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String timeAgoMonths(int months) {
    return '$months months ago';
  }

  @override
  String lastWorkout(String timeAgo) {
    return 'Last $timeAgo';
  }

  @override
  String completionOfPlanned(int done, int planned) {
    return '$done/$planned exercises';
  }

  @override
  String get streak => 'Streak';

  @override
  String get workouts => 'Workouts';

  @override
  String get avgDuration => 'Avg. duration';

  @override
  String get prs => 'PRs';

  @override
  String pausedTime(String time) {
    return 'Paused · $time';
  }

  @override
  String skippedCount(int count) {
    return '$count skipped';
  }

  @override
  String workoutsThisWeekMotivation(int count) {
    return '$count workouts this week – keep it up!';
  }

  @override
  String streakWeeksMotivation(int weeks) {
    return 'Unstoppable – $weeks weeks streak!';
  }

  @override
  String setsLabel(int count) {
    return '$count sets';
  }

  @override
  String setsCompact(int count) {
    return '$count sets';
  }

  @override
  String get noDataYet => 'No data yet';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get noPRsYet => 'No personal records yet';

  @override
  String exerciseNumber(int id) {
    return 'Exercise #$id';
  }

  @override
  String get total => 'Total';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get weightLabel => 'Weight';

  @override
  String get importPlan => 'Import workout';

  @override
  String importPlanShareMessage(String url) {
    return 'Open in IronRep:\n$url';
  }

  @override
  String get trainingPlanOptional => 'Training plan (optional)';

  @override
  String get noPlan => 'No plan';

  @override
  String get dateLabel => 'Date';

  @override
  String get startTime => 'Start time';

  @override
  String durationMinutes(int minutes) {
    return 'Duration: $minutes minutes';
  }

  @override
  String get createWorkout => 'Create workout';

  @override
  String get noDataInPeriod =>
      'No data in the comparison period yet. Keep training — your progress will show once there is enough history.';

  @override
  String get period1Week => '1 week';

  @override
  String get period2Weeks => '2 weeks';

  @override
  String get period4Weeks => '4 weeks';

  @override
  String get period8Weeks => '8 weeks';

  @override
  String get period12Weeks => '12 weeks';

  @override
  String get period6Months => '6 months';

  @override
  String get period1Year => '1 year';

  @override
  String get defaultWorkoutName => 'Workout';

  @override
  String get adLabel => 'Ad';

  @override
  String get reps => 'Reps';

  @override
  String get backupData => 'Data';

  @override
  String get backupExport => 'Export data';

  @override
  String get backupImport => 'Import data';

  @override
  String get backupImportPreview => 'Backup preview';

  @override
  String backupExportedAt(String date) {
    return 'Exported on $date';
  }

  @override
  String get backupPlans => 'Plans';

  @override
  String get backupImportPlans => 'Import plans';

  @override
  String get backupImportWorkouts => 'Import workouts';

  @override
  String get backupNoDuplicates =>
      'Existing data will not be overwritten. Duplicates are detected automatically.';

  @override
  String get backupExportPreview => 'Export data';

  @override
  String get backupExportSelectHint => 'Choose what you want to export.';

  @override
  String get backupExportStart => 'Start export';

  @override
  String get backupExportSuccess => 'Export completed';

  @override
  String get backupExportCustomExercises => 'Custom exercises';

  @override
  String get backupExportProgress => 'Creating backup...';

  @override
  String get backupImportProgress => 'Importing data...';

  @override
  String get backupImportStart => 'Start import';

  @override
  String get backupImportSuccess => 'Import completed';

  @override
  String backupWorkoutsImported(int count) {
    return '$count workouts imported';
  }

  @override
  String backupPlansImported(int count) {
    return '$count plans imported';
  }

  @override
  String backupExercisesImported(int count) {
    return '$count exercises imported';
  }

  @override
  String backupRecordsImported(int count) {
    return '$count records imported';
  }
}
