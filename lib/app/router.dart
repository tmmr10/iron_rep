import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/workout/workout_tab.dart';
import '../features/workout/active_workout_screen.dart';
import '../features/workout/workout_complete_screen.dart';
import '../features/history/history_tab.dart';
import '../features/history/workout_detail_screen.dart';
import '../features/exercises/exercises_tab.dart';
import '../features/exercises/exercise_detail_screen.dart';
import '../features/progress/progress_tab.dart';
import '../features/progress/exercise_progress_screen.dart';
import '../features/settings/settings_tab.dart';
import '../features/settings/remove_ads_screen.dart';
import '../shared/design_system.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/workout',
  routes: [
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
              path: '/exercises',
              builder: (context, state) => const ExercisesTab(),
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
          exerciseCount: extra?['exerciseCount'] ?? 0,
          totalSets: extra?['totalSets'] ?? 0,
          totalVolume: extra?['totalVolume'] ?? 0.0,
          durationSeconds: extra?['durationSeconds'] ?? 0,
        );
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
      path: '/remove-ads',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RemoveAdsScreen(),
    ),
  ],
);

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: IronRepColors.trueBlack,
        indicatorColor: IronRepColors.accentDim,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
