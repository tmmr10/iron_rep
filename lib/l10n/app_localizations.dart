import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @navWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navActivity.
  ///
  /// In de, this message translates to:
  /// **'Aktivität'**
  String get navActivity;

  /// No description provided for @navProgress.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get navProgress;

  /// No description provided for @navMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get navMore;

  /// No description provided for @welcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei IronRep'**
  String get welcomeTitle;

  /// No description provided for @whatsYourName.
  ///
  /// In de, this message translates to:
  /// **'Wie heißt du?'**
  String get whatsYourName;

  /// No description provided for @yourNameHint.
  ///
  /// In de, this message translates to:
  /// **'Dein Name'**
  String get yourNameHint;

  /// No description provided for @letsGo.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get letsGo;

  /// No description provided for @later.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get later;

  /// No description provided for @greetingMorning.
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In de, this message translates to:
  /// **'Guten Tag'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In de, this message translates to:
  /// **'Guten Abend'**
  String get greetingEvening;

  /// No description provided for @motivationStreakRunning1.
  ///
  /// In de, this message translates to:
  /// **'Dein Streak läuft – bleib dran!'**
  String get motivationStreakRunning1;

  /// No description provided for @motivationStreakRunning2.
  ///
  /// In de, this message translates to:
  /// **'Konstanz schlägt Perfektion.'**
  String get motivationStreakRunning2;

  /// No description provided for @motivationWeekGreat1.
  ///
  /// In de, this message translates to:
  /// **'Was für eine Woche – Respekt!'**
  String get motivationWeekGreat1;

  /// No description provided for @motivationWeekGreat2.
  ///
  /// In de, this message translates to:
  /// **'Du bist on fire diese Woche!'**
  String get motivationWeekGreat2;

  /// No description provided for @motivationWeekGreat3.
  ///
  /// In de, this message translates to:
  /// **'Absolute Bestform!'**
  String get motivationWeekGreat3;

  /// No description provided for @motivationWeekGood1.
  ///
  /// In de, this message translates to:
  /// **'Guter Rhythmus, bleib dran!'**
  String get motivationWeekGood1;

  /// No description provided for @motivationWeekGood2.
  ///
  /// In de, this message translates to:
  /// **'Starke Woche bisher!'**
  String get motivationWeekGood2;

  /// No description provided for @motivationWeekOne1.
  ///
  /// In de, this message translates to:
  /// **'Guter Start diese Woche!'**
  String get motivationWeekOne1;

  /// No description provided for @motivationWeekOne2.
  ///
  /// In de, this message translates to:
  /// **'Eins geschafft – kommt noch mehr?'**
  String get motivationWeekOne2;

  /// No description provided for @motivationWeekOne3.
  ///
  /// In de, this message translates to:
  /// **'Der erste Schritt ist getan.'**
  String get motivationWeekOne3;

  /// No description provided for @motivationMorning1.
  ///
  /// In de, this message translates to:
  /// **'Perfekter Start in den Tag – trainier los!'**
  String get motivationMorning1;

  /// No description provided for @motivationMorning2.
  ///
  /// In de, this message translates to:
  /// **'Morgens trainieren, den ganzen Tag profitieren.'**
  String get motivationMorning2;

  /// No description provided for @motivationMorning3.
  ///
  /// In de, this message translates to:
  /// **'Dein Körper wartet auf dich.'**
  String get motivationMorning3;

  /// No description provided for @motivationMorning4.
  ///
  /// In de, this message translates to:
  /// **'Ein Morgen-Workout setzt den Ton.'**
  String get motivationMorning4;

  /// No description provided for @motivationDay1.
  ///
  /// In de, this message translates to:
  /// **'Bereit für dein Training?'**
  String get motivationDay1;

  /// No description provided for @motivationDay2.
  ///
  /// In de, this message translates to:
  /// **'Zeit für eine Session?'**
  String get motivationDay2;

  /// No description provided for @motivationDay3.
  ///
  /// In de, this message translates to:
  /// **'Jeder Satz zählt.'**
  String get motivationDay3;

  /// No description provided for @motivationDay4.
  ///
  /// In de, this message translates to:
  /// **'Stärker als gestern.'**
  String get motivationDay4;

  /// No description provided for @motivationEvening1.
  ///
  /// In de, this message translates to:
  /// **'Noch Zeit für ein Abend-Workout?'**
  String get motivationEvening1;

  /// No description provided for @motivationEvening2.
  ///
  /// In de, this message translates to:
  /// **'Der Tag ist noch nicht vorbei.'**
  String get motivationEvening2;

  /// No description provided for @motivationEvening3.
  ///
  /// In de, this message translates to:
  /// **'Abends trainieren, besser schlafen.'**
  String get motivationEvening3;

  /// No description provided for @motivationEvening4.
  ///
  /// In de, this message translates to:
  /// **'Letzte Chance heute – mach was draus!'**
  String get motivationEvening4;

  /// No description provided for @motivationStrongStreak1.
  ///
  /// In de, this message translates to:
  /// **'Maschine. Einfach Maschine.'**
  String get motivationStrongStreak1;

  /// No description provided for @motivationStrongStreak2.
  ///
  /// In de, this message translates to:
  /// **'Nicht zu stoppen – 4+ Wochen Streak!'**
  String get motivationStrongStreak2;

  /// No description provided for @motivationStrongStreak3.
  ///
  /// In de, this message translates to:
  /// **'Disziplin zahlt sich aus.'**
  String get motivationStrongStreak3;

  /// No description provided for @yourStats.
  ///
  /// In de, this message translates to:
  /// **'Deine Statistik'**
  String get yourStats;

  /// No description provided for @yourWorkouts.
  ///
  /// In de, this message translates to:
  /// **'Deine Workouts'**
  String get yourWorkouts;

  /// No description provided for @createFirstPlanTitle.
  ///
  /// In de, this message translates to:
  /// **'Erstelle deinen ersten Trainingsplan'**
  String get createFirstPlanTitle;

  /// No description provided for @createFirstPlanSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle deine Übungen, lege die Sets fest und starte dein Training.'**
  String get createFirstPlanSubtitle;

  /// No description provided for @createPlan.
  ///
  /// In de, this message translates to:
  /// **'Workout erstellen'**
  String get createPlan;

  /// No description provided for @newPlan.
  ///
  /// In de, this message translates to:
  /// **'Neues Workout'**
  String get newPlan;

  /// No description provided for @thisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get thisWeek;

  /// No description provided for @workoutCompleted.
  ///
  /// In de, this message translates to:
  /// **'Workout abgeschlossen!'**
  String get workoutCompleted;

  /// No description provided for @duration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get duration;

  /// No description provided for @exercises.
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get exercises;

  /// No description provided for @sets.
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get sets;

  /// No description provided for @volume.
  ///
  /// In de, this message translates to:
  /// **'Volumen'**
  String get volume;

  /// No description provided for @skipped.
  ///
  /// In de, this message translates to:
  /// **'übersprungen'**
  String get skipped;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get skip;

  /// No description provided for @nextSet.
  ///
  /// In de, this message translates to:
  /// **'Nächster Satz'**
  String get nextSet;

  /// No description provided for @nextExercise.
  ///
  /// In de, this message translates to:
  /// **'Nächste Übung'**
  String get nextExercise;

  /// No description provided for @addSet.
  ///
  /// In de, this message translates to:
  /// **'Set hinzufügen'**
  String get addSet;

  /// No description provided for @exerciseOf.
  ///
  /// In de, this message translates to:
  /// **'Übung {current} von {total}'**
  String exerciseOf(int current, int total);

  /// No description provided for @nextExerciseLabel.
  ///
  /// In de, this message translates to:
  /// **'Nächste: {name}'**
  String nextExerciseLabel(String name);

  /// No description provided for @completeSet.
  ///
  /// In de, this message translates to:
  /// **'Satz abschließen'**
  String get completeSet;

  /// No description provided for @showAllExercises.
  ///
  /// In de, this message translates to:
  /// **'Alle Übungen anzeigen'**
  String get showAllExercises;

  /// No description provided for @allExercisesCompleted.
  ///
  /// In de, this message translates to:
  /// **'Alle Übungen abgeschlossen!'**
  String get allExercisesCompleted;

  /// No description provided for @confirmEndWorkout.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du das Workout beenden?'**
  String get confirmEndWorkout;

  /// No description provided for @addExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung hinzufügen'**
  String get addExercise;

  /// No description provided for @noExercisesInPlan.
  ///
  /// In de, this message translates to:
  /// **'Keine Übungen im Workout'**
  String get noExercisesInPlan;

  /// No description provided for @createNewExercise.
  ///
  /// In de, this message translates to:
  /// **'Neue Übung erstellen'**
  String get createNewExercise;

  /// No description provided for @exerciseName.
  ///
  /// In de, this message translates to:
  /// **'Name der Übung'**
  String get exerciseName;

  /// No description provided for @exerciseNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Kurzhantel Seitheben'**
  String get exerciseNameHint;

  /// No description provided for @muscleGroup.
  ///
  /// In de, this message translates to:
  /// **'Muskelgruppe'**
  String get muscleGroup;

  /// No description provided for @equipmentOptional.
  ///
  /// In de, this message translates to:
  /// **'Gerät (optional)'**
  String get equipmentOptional;

  /// No description provided for @noEquipment.
  ///
  /// In de, this message translates to:
  /// **'Kein Gerät'**
  String get noEquipment;

  /// No description provided for @createExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung erstellen'**
  String get createExercise;

  /// No description provided for @searchExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung suchen...'**
  String get searchExercise;

  /// No description provided for @noExercisesFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Übungen gefunden'**
  String get noExercisesFound;

  /// No description provided for @noExercisesInCategory.
  ///
  /// In de, this message translates to:
  /// **'Keine Übungen in dieser Kategorie'**
  String get noExercisesInCategory;

  /// No description provided for @discardChanges.
  ///
  /// In de, this message translates to:
  /// **'Änderungen verwerfen?'**
  String get discardChanges;

  /// No description provided for @changesWillBeLost.
  ///
  /// In de, this message translates to:
  /// **'Deine Änderungen gehen verloren.'**
  String get changesWillBeLost;

  /// No description provided for @continueEditing.
  ///
  /// In de, this message translates to:
  /// **'Weiter bearbeiten'**
  String get continueEditing;

  /// No description provided for @discard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get discard;

  /// No description provided for @editExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung bearbeiten'**
  String get editExercise;

  /// No description provided for @nameInputLabel.
  ///
  /// In de, this message translates to:
  /// **'Name der Übung'**
  String get nameInputLabel;

  /// No description provided for @nameInputHint.
  ///
  /// In de, this message translates to:
  /// **'Name eingeben'**
  String get nameInputHint;

  /// No description provided for @instructionsLabel.
  ///
  /// In de, this message translates to:
  /// **'Anleitung (optional)'**
  String get instructionsLabel;

  /// No description provided for @instructionsHint.
  ///
  /// In de, this message translates to:
  /// **'Ausführung beschreiben'**
  String get instructionsHint;

  /// No description provided for @trackWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht erfassen'**
  String get trackWeight;

  /// No description provided for @equipment.
  ///
  /// In de, this message translates to:
  /// **'Geräte'**
  String get equipment;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @cameraPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get cameraPhoto;

  /// No description provided for @galleryPhoto.
  ///
  /// In de, this message translates to:
  /// **'Aus Galerie wählen'**
  String get galleryPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto entfernen'**
  String get removePhoto;

  /// No description provided for @addPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get addPhoto;

  /// No description provided for @deleteExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung löschen'**
  String get deleteExercise;

  /// No description provided for @deleteExerciseConfirm.
  ///
  /// In de, this message translates to:
  /// **'Übung löschen?'**
  String get deleteExerciseConfirm;

  /// No description provided for @deleteExerciseMessage.
  ///
  /// In de, this message translates to:
  /// **'Die Übung wird aus der Liste entfernt. Bestehende Workouts bleiben erhalten.'**
  String get deleteExerciseMessage;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @instructions.
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get instructions;

  /// No description provided for @progressButton.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt anzeigen'**
  String get progressButton;

  /// No description provided for @activity.
  ///
  /// In de, this message translates to:
  /// **'Aktivität'**
  String get activity;

  /// No description provided for @logManualWorkout.
  ///
  /// In de, this message translates to:
  /// **'Training manuell eintragen'**
  String get logManualWorkout;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Workouts'**
  String get noWorkoutsYet;

  /// No description provided for @completeFirstWorkout.
  ///
  /// In de, this message translates to:
  /// **'Schließe dein erstes Workout ab'**
  String get completeFirstWorkout;

  /// No description provided for @workoutNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Oberkörper'**
  String get workoutNameHint;

  /// No description provided for @planExercisesAutoImport.
  ///
  /// In de, this message translates to:
  /// **'Die Übungen des Plans werden automatisch übernommen. Sets kannst du im Edit-Modus hinzufügen.'**
  String get planExercisesAutoImport;

  /// No description provided for @manualExercisesAddLater.
  ///
  /// In de, this message translates to:
  /// **'Du kannst nach dem Anlegen Übungen und Sets über den Edit-Modus hinzufügen.'**
  String get manualExercisesAddLater;

  /// No description provided for @deleteWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout löschen'**
  String get deleteWorkout;

  /// No description provided for @deleteWorkoutConfirm.
  ///
  /// In de, this message translates to:
  /// **'Workout löschen?'**
  String get deleteWorkoutConfirm;

  /// No description provided for @deleteWorkoutMessage.
  ///
  /// In de, this message translates to:
  /// **'Das Workout und alle zugehörigen Daten werden unwiderruflich gelöscht.'**
  String get deleteWorkoutMessage;

  /// No description provided for @skippedCapital.
  ///
  /// In de, this message translates to:
  /// **'Übersprungen'**
  String get skippedCapital;

  /// No description provided for @progress.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get progress;

  /// No description provided for @yourProgress.
  ///
  /// In de, this message translates to:
  /// **'Deine Steigerung'**
  String get yourProgress;

  /// No description provided for @muscleDistribution.
  ///
  /// In de, this message translates to:
  /// **'Muskelverteilung'**
  String get muscleDistribution;

  /// No description provided for @strengthDevelopment.
  ///
  /// In de, this message translates to:
  /// **'Kraftentwicklung'**
  String get strengthDevelopment;

  /// No description provided for @yourExercises.
  ///
  /// In de, this message translates to:
  /// **'Deine Übungen'**
  String get yourExercises;

  /// No description provided for @completeWorkoutToSeeExercises.
  ///
  /// In de, this message translates to:
  /// **'Schließe ein Workout ab, um deine Übungen hier zu sehen'**
  String get completeWorkoutToSeeExercises;

  /// No description provided for @personalRecords.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Rekorde'**
  String get personalRecords;

  /// No description provided for @completeWorkoutToSeeStrength.
  ///
  /// In de, this message translates to:
  /// **'Schließe ein Workout ab, um Kraftentwicklung zu sehen'**
  String get completeWorkoutToSeeStrength;

  /// No description provided for @maxWeight.
  ///
  /// In de, this message translates to:
  /// **'Max. Gewicht'**
  String get maxWeight;

  /// No description provided for @maxReps.
  ///
  /// In de, this message translates to:
  /// **'Max. Wdh.'**
  String get maxReps;

  /// No description provided for @maxVolume.
  ///
  /// In de, this message translates to:
  /// **'Max. Volumen'**
  String get maxVolume;

  /// No description provided for @noRecordsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Rekorde'**
  String get noRecordsYet;

  /// No description provided for @currentWeight.
  ///
  /// In de, this message translates to:
  /// **'Aktuell: {weight} kg'**
  String currentWeight(String weight);

  /// No description provided for @allPlans.
  ///
  /// In de, this message translates to:
  /// **'Alle Pläne'**
  String get allPlans;

  /// No description provided for @perExercise.
  ///
  /// In de, this message translates to:
  /// **'Pro Übung'**
  String get perExercise;

  /// No description provided for @exercisesNotRecognized.
  ///
  /// In de, this message translates to:
  /// **'nicht erkannt — wird beim Import übersprungen'**
  String get exercisesNotRecognized;

  /// No description provided for @customExerciseCreated.
  ///
  /// In de, this message translates to:
  /// **'Wird als Custom-Übung angelegt'**
  String get customExerciseCreated;

  /// No description provided for @exerciseNotFound.
  ///
  /// In de, this message translates to:
  /// **'Übung nicht gefunden'**
  String get exerciseNotFound;

  /// No description provided for @planName.
  ///
  /// In de, this message translates to:
  /// **'Workout-Name'**
  String get planName;

  /// No description provided for @exercisesSectionHeader.
  ///
  /// In de, this message translates to:
  /// **'ÜBUNGEN'**
  String get exercisesSectionHeader;

  /// No description provided for @exercisesCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Übungen · {sets} Sets'**
  String exercisesCount(int count, int sets);

  /// No description provided for @enterPlanName.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Workout-Namen eingeben'**
  String get enterPlanName;

  /// No description provided for @addAtLeastOneExercise.
  ///
  /// In de, this message translates to:
  /// **'Mindestens eine Übung hinzufügen'**
  String get addAtLeastOneExercise;

  /// No description provided for @sharePlan.
  ///
  /// In de, this message translates to:
  /// **'Workout teilen'**
  String get sharePlan;

  /// No description provided for @deletePlan.
  ///
  /// In de, this message translates to:
  /// **'Workout löschen'**
  String get deletePlan;

  /// No description provided for @deletePlanConfirm.
  ///
  /// In de, this message translates to:
  /// **'Workout löschen?'**
  String get deletePlanConfirm;

  /// No description provided for @cannotBeUndone.
  ///
  /// In de, this message translates to:
  /// **'Das kann nicht rückgängig gemacht werden.'**
  String get cannotBeUndone;

  /// No description provided for @addExerciseEmptyState.
  ///
  /// In de, this message translates to:
  /// **'Jeder große Plan beginnt mit einer Übung.\nTippe auf + und leg los!'**
  String get addExerciseEmptyState;

  /// No description provided for @searchExercises.
  ///
  /// In de, this message translates to:
  /// **'Übungen suchen...'**
  String get searchExercises;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @name.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @notSet.
  ///
  /// In de, this message translates to:
  /// **'Nicht gesetzt'**
  String get notSet;

  /// No description provided for @weightUnit.
  ///
  /// In de, this message translates to:
  /// **'Gewichtseinheit'**
  String get weightUnit;

  /// No description provided for @defaultRestTime.
  ///
  /// In de, this message translates to:
  /// **'Standard-Pausenzeit'**
  String get defaultRestTime;

  /// No description provided for @appearance.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get appearance;

  /// No description provided for @design.
  ///
  /// In de, this message translates to:
  /// **'Design'**
  String get design;

  /// No description provided for @plansAndExercises.
  ///
  /// In de, this message translates to:
  /// **'Workouts & Übungen'**
  String get plansAndExercises;

  /// No description provided for @managePlans.
  ///
  /// In de, this message translates to:
  /// **'Workouts verwalten'**
  String get managePlans;

  /// No description provided for @manageExercises.
  ///
  /// In de, this message translates to:
  /// **'Übungen verwalten'**
  String get manageExercises;

  /// No description provided for @pro.
  ///
  /// In de, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @removeAds.
  ///
  /// In de, this message translates to:
  /// **'Werbung entfernen'**
  String get removeAds;

  /// No description provided for @about.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get about;

  /// No description provided for @version.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @openSourceLicenses.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get openSourceLicenses;

  /// No description provided for @dark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get light;

  /// No description provided for @system.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @createNewPlan.
  ///
  /// In de, this message translates to:
  /// **'Neues Workout erstellen'**
  String get createNewPlan;

  /// No description provided for @adFreeDescription.
  ///
  /// In de, this message translates to:
  /// **'Genieße ein werbefreies Erlebnis mit einem einmaligen Kauf.'**
  String get adFreeDescription;

  /// No description provided for @supportIndieDev.
  ///
  /// In de, this message translates to:
  /// **'Indie-Entwicklung unterstützen'**
  String get supportIndieDev;

  /// No description provided for @buyForPrice.
  ///
  /// In de, this message translates to:
  /// **'Für {price} kaufen'**
  String buyForPrice(String price);

  /// No description provided for @purchaseFailed.
  ///
  /// In de, this message translates to:
  /// **'Kauf fehlgeschlagen. Bitte versuche es erneut.'**
  String get purchaseFailed;

  /// No description provided for @noAdBanners.
  ///
  /// In de, this message translates to:
  /// **'Keine Werbebanner'**
  String get noAdBanners;

  /// No description provided for @fasterCleanerExperience.
  ///
  /// In de, this message translates to:
  /// **'Schnelleres, saubereres Erlebnis'**
  String get fasterCleanerExperience;

  /// No description provided for @restorePurchase.
  ///
  /// In de, this message translates to:
  /// **'Kauf wiederherstellen'**
  String get restorePurchase;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @all.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get all;

  /// No description provided for @error.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {message}'**
  String error(String message);

  /// No description provided for @noPlanFound.
  ///
  /// In de, this message translates to:
  /// **'Kein Plan gefunden'**
  String get noPlanFound;

  /// No description provided for @muscleChest.
  ///
  /// In de, this message translates to:
  /// **'Brust'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In de, this message translates to:
  /// **'Rücken'**
  String get muscleBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In de, this message translates to:
  /// **'Schultern'**
  String get muscleShoulders;

  /// No description provided for @muscleBiceps.
  ///
  /// In de, this message translates to:
  /// **'Bizeps'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In de, this message translates to:
  /// **'Trizeps'**
  String get muscleTriceps;

  /// No description provided for @muscleForearms.
  ///
  /// In de, this message translates to:
  /// **'Unterarme'**
  String get muscleForearms;

  /// No description provided for @muscleQuadriceps.
  ///
  /// In de, this message translates to:
  /// **'Quadrizeps'**
  String get muscleQuadriceps;

  /// No description provided for @muscleHamstrings.
  ///
  /// In de, this message translates to:
  /// **'Beinbeuger'**
  String get muscleHamstrings;

  /// No description provided for @muscleGlutes.
  ///
  /// In de, this message translates to:
  /// **'Gesäß'**
  String get muscleGlutes;

  /// No description provided for @muscleCalves.
  ///
  /// In de, this message translates to:
  /// **'Waden'**
  String get muscleCalves;

  /// No description provided for @muscleCore.
  ///
  /// In de, this message translates to:
  /// **'Bauch'**
  String get muscleCore;

  /// No description provided for @muscleFullBody.
  ///
  /// In de, this message translates to:
  /// **'Ganzkörper'**
  String get muscleFullBody;

  /// No description provided for @muscleCardio.
  ///
  /// In de, this message translates to:
  /// **'Ausdauer'**
  String get muscleCardio;

  /// No description provided for @equipBarbell.
  ///
  /// In de, this message translates to:
  /// **'Langhantel'**
  String get equipBarbell;

  /// No description provided for @equipDumbbell.
  ///
  /// In de, this message translates to:
  /// **'Kurzhantel'**
  String get equipDumbbell;

  /// No description provided for @equipCable.
  ///
  /// In de, this message translates to:
  /// **'Kabelzug'**
  String get equipCable;

  /// No description provided for @equipMachine.
  ///
  /// In de, this message translates to:
  /// **'Maschine'**
  String get equipMachine;

  /// No description provided for @equipBodyweight.
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht'**
  String get equipBodyweight;

  /// No description provided for @equipBenchPress.
  ///
  /// In de, this message translates to:
  /// **'Bankdrücken'**
  String get equipBenchPress;

  /// No description provided for @equipLatPulldown.
  ///
  /// In de, this message translates to:
  /// **'Latzug'**
  String get equipLatPulldown;

  /// No description provided for @equipLegExtension.
  ///
  /// In de, this message translates to:
  /// **'Beinstrecker'**
  String get equipLegExtension;

  /// No description provided for @equipLegCurl.
  ///
  /// In de, this message translates to:
  /// **'Beinbeuger'**
  String get equipLegCurl;

  /// No description provided for @equipSeatedRow.
  ///
  /// In de, this message translates to:
  /// **'Rudermaschine'**
  String get equipSeatedRow;

  /// No description provided for @equipShoulderPress.
  ///
  /// In de, this message translates to:
  /// **'Schulterpresse'**
  String get equipShoulderPress;

  /// No description provided for @equipSmithMachine.
  ///
  /// In de, this message translates to:
  /// **'Multipresse'**
  String get equipSmithMachine;

  /// No description provided for @equipChestFly.
  ///
  /// In de, this message translates to:
  /// **'Butterfly'**
  String get equipChestFly;

  /// No description provided for @equipRowingMachine.
  ///
  /// In de, this message translates to:
  /// **'Rudergerät'**
  String get equipRowingMachine;

  /// No description provided for @equipTreadmill.
  ///
  /// In de, this message translates to:
  /// **'Laufband'**
  String get equipTreadmill;

  /// No description provided for @equipStationaryBike.
  ///
  /// In de, this message translates to:
  /// **'Ergometer'**
  String get equipStationaryBike;

  /// No description provided for @equipElliptical.
  ///
  /// In de, this message translates to:
  /// **'Crosstrainer'**
  String get equipElliptical;

  /// No description provided for @equipBench.
  ///
  /// In de, this message translates to:
  /// **'Flachbank'**
  String get equipBench;

  /// No description provided for @equipInclineBench.
  ///
  /// In de, this message translates to:
  /// **'Schrägbank'**
  String get equipInclineBench;

  /// No description provided for @equipDipStation.
  ///
  /// In de, this message translates to:
  /// **'Dip-Station'**
  String get equipDipStation;

  /// No description provided for @equipPullUpBar.
  ///
  /// In de, this message translates to:
  /// **'Klimmzugstange'**
  String get equipPullUpBar;

  /// No description provided for @equipHyperextensionBench.
  ///
  /// In de, this message translates to:
  /// **'Hyperextension-Bank'**
  String get equipHyperextensionBench;

  /// No description provided for @equipPreacherCurlBench.
  ///
  /// In de, this message translates to:
  /// **'Preacher-Curl-Bank'**
  String get equipPreacherCurlBench;

  /// No description provided for @setTypeWarmup.
  ///
  /// In de, this message translates to:
  /// **'Aufwärmen'**
  String get setTypeWarmup;

  /// No description provided for @setTypeWorking.
  ///
  /// In de, this message translates to:
  /// **'Arbeitssatz'**
  String get setTypeWorking;

  /// No description provided for @setTypeDropset.
  ///
  /// In de, this message translates to:
  /// **'Drop Set'**
  String get setTypeDropset;

  /// No description provided for @setTypeFailure.
  ///
  /// In de, this message translates to:
  /// **'Bis Versagen'**
  String get setTypeFailure;

  /// No description provided for @paused.
  ///
  /// In de, this message translates to:
  /// **'Pausiert'**
  String get paused;

  /// No description provided for @tapToResume.
  ///
  /// In de, this message translates to:
  /// **'Tippe zum Fortsetzen'**
  String get tapToResume;

  /// No description provided for @training.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @startTraining.
  ///
  /// In de, this message translates to:
  /// **'Training starten'**
  String get startTraining;

  /// No description provided for @startWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout starten'**
  String get startWorkout;

  /// No description provided for @endWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout beenden'**
  String get endWorkout;

  /// No description provided for @discardWorkout.
  ///
  /// In de, this message translates to:
  /// **'Workout verwerfen'**
  String get discardWorkout;

  /// No description provided for @discardWorkoutConfirm.
  ///
  /// In de, this message translates to:
  /// **'Workout verwerfen?'**
  String get discardWorkoutConfirm;

  /// No description provided for @allProgressWillBeLost.
  ///
  /// In de, this message translates to:
  /// **'Alle Fortschritte gehen verloren.'**
  String get allProgressWillBeLost;

  /// No description provided for @continueTraining.
  ///
  /// In de, this message translates to:
  /// **'Weitermachen'**
  String get continueTraining;

  /// No description provided for @keepTraining.
  ///
  /// In de, this message translates to:
  /// **'Weiter trainieren'**
  String get keepTraining;

  /// No description provided for @setCompleted.
  ///
  /// In de, this message translates to:
  /// **'Satz abgeschlossen'**
  String get setCompleted;

  /// No description provided for @setOfTotal.
  ///
  /// In de, this message translates to:
  /// **'Satz {current} von {total}'**
  String setOfTotal(int current, int total);

  /// No description provided for @setOfTotalLoading.
  ///
  /// In de, this message translates to:
  /// **'Satz 1 von …'**
  String get setOfTotalLoading;

  /// No description provided for @noActiveWorkout.
  ///
  /// In de, this message translates to:
  /// **'Kein aktives Workout'**
  String get noActiveWorkout;

  /// No description provided for @setsCount.
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get setsCount;

  /// No description provided for @completedOfTotalSets.
  ///
  /// In de, this message translates to:
  /// **'{completed}/{total} Sätze'**
  String completedOfTotalSets(int completed, int total);

  /// No description provided for @restPause.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get restPause;

  /// No description provided for @timeAgoToday.
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get timeAgoToday;

  /// No description provided for @timeAgoYesterday.
  ///
  /// In de, this message translates to:
  /// **'gestern'**
  String get timeAgoYesterday;

  /// No description provided for @timeAgoDays.
  ///
  /// In de, this message translates to:
  /// **'vor {days} Tagen'**
  String timeAgoDays(int days);

  /// No description provided for @timeAgoWeeks.
  ///
  /// In de, this message translates to:
  /// **'vor {weeks} Wochen'**
  String timeAgoWeeks(int weeks);

  /// No description provided for @timeAgoMonths.
  ///
  /// In de, this message translates to:
  /// **'vor {months} Monaten'**
  String timeAgoMonths(int months);

  /// No description provided for @lastWorkout.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt {timeAgo}'**
  String lastWorkout(String timeAgo);

  /// No description provided for @completionOfPlanned.
  ///
  /// In de, this message translates to:
  /// **'{done}/{planned} Übungen'**
  String completionOfPlanned(int done, int planned);

  /// No description provided for @streak.
  ///
  /// In de, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @workouts.
  ///
  /// In de, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// No description provided for @avgDuration.
  ///
  /// In de, this message translates to:
  /// **'Ø Dauer'**
  String get avgDuration;

  /// No description provided for @prs.
  ///
  /// In de, this message translates to:
  /// **'PRs'**
  String get prs;

  /// No description provided for @pausedTime.
  ///
  /// In de, this message translates to:
  /// **'Pausiert · {time}'**
  String pausedTime(String time);

  /// No description provided for @skippedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} übersprungen'**
  String skippedCount(int count);

  /// No description provided for @workoutsThisWeekMotivation.
  ///
  /// In de, this message translates to:
  /// **'{count} Workouts diese Woche – weiter so!'**
  String workoutsThisWeekMotivation(int count);

  /// No description provided for @streakWeeksMotivation.
  ///
  /// In de, this message translates to:
  /// **'Nicht zu stoppen – {weeks} Wochen Streak!'**
  String streakWeeksMotivation(int weeks);

  /// No description provided for @setsLabel.
  ///
  /// In de, this message translates to:
  /// **'{count} Sets'**
  String setsLabel(int count);

  /// No description provided for @setsCompact.
  ///
  /// In de, this message translates to:
  /// **'{count} Sätze'**
  String setsCompact(int count);

  /// No description provided for @noDataYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Daten'**
  String get noDataYet;

  /// No description provided for @noActivityYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Aktivität'**
  String get noActivityYet;

  /// No description provided for @noPRsYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine persönlichen Rekorde'**
  String get noPRsYet;

  /// No description provided for @exerciseNumber.
  ///
  /// In de, this message translates to:
  /// **'Übung #{id}'**
  String exerciseNumber(int id);

  /// No description provided for @total.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get total;

  /// No description provided for @volumeLabel.
  ///
  /// In de, this message translates to:
  /// **'Volumen'**
  String get volumeLabel;

  /// No description provided for @weightLabel.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get weightLabel;

  /// No description provided for @importPlan.
  ///
  /// In de, this message translates to:
  /// **'Workout importieren'**
  String get importPlan;

  /// No description provided for @importPlanShareMessage.
  ///
  /// In de, this message translates to:
  /// **'Plan in IronRep importieren:\n{url}'**
  String importPlanShareMessage(String url);

  /// No description provided for @trainingPlanOptional.
  ///
  /// In de, this message translates to:
  /// **'Trainingsplan (optional)'**
  String get trainingPlanOptional;

  /// No description provided for @noPlan.
  ///
  /// In de, this message translates to:
  /// **'Kein Plan'**
  String get noPlan;

  /// No description provided for @dateLabel.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get dateLabel;

  /// No description provided for @startTime.
  ///
  /// In de, this message translates to:
  /// **'Startzeit'**
  String get startTime;

  /// No description provided for @durationMinutes.
  ///
  /// In de, this message translates to:
  /// **'Dauer: {minutes} Minuten'**
  String durationMinutes(int minutes);

  /// No description provided for @createWorkout.
  ///
  /// In de, this message translates to:
  /// **'Training anlegen'**
  String get createWorkout;

  /// No description provided for @noDataInPeriod.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Daten im Vergleichszeitraum. Trainiere weiter — die Steigerung wird sichtbar, sobald genug Verlauf vorhanden ist.'**
  String get noDataInPeriod;

  /// No description provided for @period1Week.
  ///
  /// In de, this message translates to:
  /// **'1 Woche'**
  String get period1Week;

  /// No description provided for @period2Weeks.
  ///
  /// In de, this message translates to:
  /// **'2 Wochen'**
  String get period2Weeks;

  /// No description provided for @period4Weeks.
  ///
  /// In de, this message translates to:
  /// **'4 Wochen'**
  String get period4Weeks;

  /// No description provided for @period8Weeks.
  ///
  /// In de, this message translates to:
  /// **'8 Wochen'**
  String get period8Weeks;

  /// No description provided for @period12Weeks.
  ///
  /// In de, this message translates to:
  /// **'12 Wochen'**
  String get period12Weeks;

  /// No description provided for @period6Months.
  ///
  /// In de, this message translates to:
  /// **'6 Monate'**
  String get period6Months;

  /// No description provided for @period1Year.
  ///
  /// In de, this message translates to:
  /// **'1 Jahr'**
  String get period1Year;

  /// No description provided for @defaultWorkoutName.
  ///
  /// In de, this message translates to:
  /// **'Workout'**
  String get defaultWorkoutName;

  /// No description provided for @adLabel.
  ///
  /// In de, this message translates to:
  /// **'Werbung'**
  String get adLabel;

  /// No description provided for @reps.
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen'**
  String get reps;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
