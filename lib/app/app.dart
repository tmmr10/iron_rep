import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
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
      // Resume workout if paused when navigating back from notification
      if (route == '/active-workout') {
        final workout = ref.read(activeWorkoutProvider);
        if (workout.isActive && workout.isPaused) {
          ref.read(activeWorkoutProvider.notifier).togglePause();
          _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Training fortgesetzt'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      router.go(route);
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
    } else if (state == AppLifecycleState.resumed) {
      TimerService.dismissWorkoutNotification();
    }
  }

  void _showWorkoutNotificationIfActive() {
    final workout = ref.read(activeWorkoutProvider);
    if (!workout.isActive) return;

    final info = ref.read(workoutNotificationInfoProvider);
    final elapsed = workout.elapsed;
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    final timeStr = '${m}m ${s.toString().padLeft(2, '0')}s';

    String title;
    String body;

    if (info.exerciseName != null && info.totalSets > 0) {
      title = info.exerciseName!;
      body = 'Satz ${info.currentSetIndex + 1}/${info.totalSets} · $timeStr';
    } else {
      title = 'Training';
      body = 'Aktiv · $timeStr';
    }

    TimerService.showWorkoutNotification(title: title, body: body);
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
