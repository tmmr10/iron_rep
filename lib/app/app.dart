import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../providers/timer_providers.dart';
import '../providers/workout_providers.dart';
import '../services/plan_sharing_service.dart';
import '../services/timer_service.dart';
import '../shared/design_system.dart';
import 'router.dart';

final _deepLinkProvider = Provider<void>((ref) {
  final appLinks = AppLinks();
  final router = ref.watch(routerProvider);

  final sub = appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'ironrep' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'plan' &&
        uri.pathSegments.length > 1) {
      final data = uri.pathSegments[1];
      final plan = PlanSharingService.decodePlan(data);
      if (plan != null) {
        router.go('/import-plan', extra: plan);
      }
    }
  });

  ref.onDispose(() => sub.cancel());
});

class IronRepApp extends ConsumerStatefulWidget {
  const IronRepApp({super.key});

  @override
  ConsumerState<IronRepApp> createState() => _IronRepAppState();
}

final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class _IronRepAppState extends ConsumerState<IronRepApp>
    with WidgetsBindingObserver {
  static const _backupChannel = MethodChannel('com.tmmr.iron_rep/backup');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backupChannel.setMethodCallHandler(_handleBackupChannel);
    TimerService.onNavigateTo = (route) {
      final router = ref.read(routerProvider);
      // Navigate to workout screen without auto-resuming
      final currentLocation = router.routerDelegate.currentConfiguration.last.matchedLocation;
      if (currentLocation != route) {
        router.push(route);
      }
    };
  }

  @override
  void dispose() {
    _backupChannel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<dynamic> _handleBackupChannel(MethodCall call) async {
    if (call.method == 'backupFileOpened') {
      final path = call.arguments as String;
      final router = ref.read(routerProvider);
      router.push('/backup-import', extra: path);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _showWorkoutNotificationIfActive();
      _ensureLiveActivityIfActive();
    } else if (state == AppLifecycleState.resumed) {
      final workout = ref.read(activeWorkoutProvider);
      // Don't dismiss notification if paused (keep showing "Training pausiert")
      if (!workout.isPaused) {
        TimerService.dismissWorkoutNotification();
      }
      // Sync rest timer with real clock after background
      ref.read(restTimerProvider.notifier).syncWithClock();
    }
  }

  void _ensureLiveActivityIfActive() {
    final workout = ref.read(activeWorkoutProvider);
    if (!workout.isActive) return;

    final info = ref.read(workoutNotificationInfoProvider);
    // Re-start Live Activity if it was dismissed by the user
    TimerService.startWorkoutActivity(
      workoutName: workout.planName ?? 'Training',
      startedAtMs: workout.startedAt?.millisecondsSinceEpoch,
    ).then((_) {
      if (info.exerciseName != null) {
        TimerService.updateWorkoutActivity(
          exerciseName: info.exerciseName!,
          nextExerciseName: info.nextExerciseName,
          currentSet: info.currentSetIndex + 1,
          totalSets: info.totalSets,
        );
      }
    });
  }

  void _showWorkoutNotificationIfActive() {
    // On iOS, Live Activity handles everything — no regular notification needed
    if (Platform.isIOS) return;
    final workout = ref.read(activeWorkoutProvider);
    if (!workout.isActive) return;
    // Don't show ongoing notification while rest timer is active (avoid duplicate)
    if (ref.read(restTimerProvider).isRunning) return;

    // If paused, show paused notification without chronometer
    if (workout.isPaused) {
      final elapsed = workout.elapsed;
      final m = elapsed.inMinutes;
      final s = elapsed.inSeconds % 60;
      TimerService.showWorkoutNotification(
        title: 'Training pausiert',
        body: '${m}m ${s.toString().padLeft(2, '0')}s',
      );
      return;
    }

    final info = ref.read(workoutNotificationInfoProvider);

    String title;
    String body;

    if (info.exerciseName != null && info.totalSets > 0) {
      title = '${info.exerciseName} · Satz ${info.currentSetIndex + 1}/${info.totalSets}';
      body = info.nextExerciseName != null
          ? 'Nächste: ${info.nextExerciseName}'
          : 'Letzte Übung';
    } else {
      title = 'Training';
      body = workout.planName ?? 'Aktiv';
    }

    TimerService.showWorkoutNotification(
      title: title,
      body: body,
      startedAtMs: workout.startedAt?.millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    ref.watch(_deepLinkProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'IronRep',
      theme: IronRepTheme.lightTheme,
      darkTheme: IronRepTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
