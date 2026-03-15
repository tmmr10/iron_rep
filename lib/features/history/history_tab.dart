import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/empty_state.dart';
import 'manual_workout_sheet.dart';
import 'widgets/workout_calendar.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(enrichedWorkoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivität'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Training manuell eintragen',
            onPressed: () => _showManualWorkoutSheet(context),
          ),
        ],
      ),
      body: history.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'Noch keine Workouts',
              subtitle: 'Schließe dein erstes Workout ab',
            );
          }

          return WorkoutCalendar(workouts: workouts);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showManualWorkoutSheet(BuildContext context) async {
    final c = AppColors.of(context);
    final workoutId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ManualWorkoutSheet(),
    );
    if (workoutId != null && context.mounted) {
      context.push('/workout-detail/$workoutId');
    }
  }
}
