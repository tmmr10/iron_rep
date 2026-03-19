import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/welcome_screen.dart';
import '../features/workout/workout_tab.dart';
import '../features/workout/active_workout_screen.dart';
import '../features/workout/workout_complete_screen.dart';
import '../features/history/history_tab.dart';
import '../features/history/workout_detail_screen.dart';
import '../features/exercises/exercise_detail_screen.dart';
import '../features/exercises/exercises_screen.dart';
import '../features/plans/plan_editor_screen.dart';
import '../features/plans/plan_import_screen.dart';
import '../features/backup/backup_export_screen.dart';
import '../features/backup/backup_import_screen.dart';
import '../services/plan_sharing_service.dart';
import '../features/progress/progress_tab.dart';
import '../features/progress/exercise_progress_screen.dart';
import '../features/settings/settings_tab.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/remove_ads_screen.dart';
import '../providers/settings_providers.dart';
import '../shared/design_system.dart';
import '../shared/widgets/ad_banner.dart';
import '../shared/widgets/tap_scale.dart';
import '../l10n/l10n_helper.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
SharedPlan? _pendingPlan;

final routerProvider = Provider<GoRouter>((ref) {
  // Notifier that triggers router redirect re-evaluation when settings change.
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(settingsLoadedProvider, (_, __) => refreshNotifier.value++);
  ref.listen(userNameProvider, (_, __) => refreshNotifier.value++);
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/workout',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Handle ironrep:// deep links — redirect to import-plan route
      final fullUri = state.uri.toString();
      if (fullUri.startsWith('ironrep://plan/')) {
        final data = fullUri.substring('ironrep://plan/'.length);
        final plan = PlanSharingService.decodePlan(data);
        if (plan != null) {
          // Store plan in a static field for the import screen to pick up
          _pendingPlan = plan;
          return '/import-plan-pending';
        }
        return '/workout';
      }

      final loaded = ref.read(settingsLoadedProvider);
      if (!loaded) {
        // While settings are loading, show welcome (blank-ish) instead of
        // briefly flashing the main shell.
        if (state.uri.path != '/welcome') return '/welcome';
        return null;
      }

      final userName = ref.read(userNameProvider);
      if (userName == null && state.uri.path != '/welcome') {
        return '/welcome';
      }
      if (userName != null && state.uri.path == '/welcome') {
        return '/workout';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workout',
                builder: (context, state) => const WorkoutTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsTab(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/active-workout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        path: '/workout-complete',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WorkoutCompleteScreen(
            planName: extra?['planName'] as String?,
            exerciseCount: extra?['exerciseCount'] ?? 0,
            totalSets: extra?['totalSets'] ?? 0,
            totalVolume: extra?['totalVolume'] ?? 0.0,
            durationSeconds: extra?['durationSeconds'] ?? 0,
            skippedCount: extra?['skippedCount'] ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/plan-editor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final planId = state.extra as int?;
          return PlanEditorScreen(planId: planId);
        },
      ),
      GoRoute(
        path: '/workout-detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return WorkoutDetailScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/exercises',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExercisesScreen(),
      ),
      GoRoute(
        path: '/exercise-detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ExerciseDetailScreen(exerciseId: id);
        },
      ),
      GoRoute(
        path: '/exercise-progress/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ExerciseProgressScreen(exerciseId: id);
        },
      ),
      GoRoute(
        path: '/import-plan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final plan = state.extra as SharedPlan;
          return PlanImportScreen(plan: plan);
        },
      ),
      GoRoute(
        path: '/import-plan-pending',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final plan = _pendingPlan;
          _pendingPlan = null;
          if (plan == null) {
            return Scaffold(
              body: Center(child: Text(context.l10n.noPlanFound)),
            );
          }
          return PlanImportScreen(plan: plan);
        },
      ),
      GoRoute(
        path: '/backup-export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BackupExportScreen(),
      ),
      GoRoute(
        path: '/backup-import',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final filePath = state.extra as String;
          return BackupImportScreen(filePath: filePath);
        },
      ),
      GoRoute(
        path: '/remove-ads',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RemoveAdsScreen(),
      ),
      GoRoute(
        path: '/licenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LicensesScreen(),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          Container(
            margin: EdgeInsets.fromLTRB(32, 8, 32, MediaQuery.of(context).padding.bottom + 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: c.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavIcon(Icons.fitness_center_outlined, Icons.fitness_center, 0, context.l10n.navWorkout, navigationShell, c),
                _NavIcon(Icons.calendar_month_outlined, Icons.calendar_month, 1, context.l10n.navActivity, navigationShell, c),
                _NavIcon(Icons.insights_outlined, Icons.insights, 2, context.l10n.navProgress, navigationShell, c),
                _NavIcon(Icons.tune_outlined, Icons.tune, 3, context.l10n.navMore, navigationShell, c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final String label;
  final StatefulNavigationShell shell;
  final AppColors c;

  const _NavIcon(this.icon, this.activeIcon, this.index, this.label, this.shell, this.c);

  @override
  Widget build(BuildContext context) {
    final selected = shell.currentIndex == index;
    return TapScale(
      onTap: () => shell.goBranch(index, initialLocation: index == shell.currentIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? c.accent : c.textMuted,
              size: 22,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: c.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

