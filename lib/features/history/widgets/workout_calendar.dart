import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/workout_history_item.dart';
import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';

class WorkoutCalendar extends StatefulWidget {
  final List<WorkoutHistoryItem> workouts;

  const WorkoutCalendar({super.key, required this.workouts});

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  Map<DateTime, List<WorkoutHistoryItem>> get _workoutsByDay {
    final map = <DateTime, List<WorkoutHistoryItem>>{};
    for (final w in widget.workouts) {
      final date = w.completedAt ?? w.startedAt;
      final key = DateTime(date.year, date.month, date.day);
      map.putIfAbsent(key, () => []).add(w);
    }
    return map;
  }

  List<WorkoutHistoryItem> _getWorkoutsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _workoutsByDay[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final selectedWorkouts = _selectedDay != null
        ? _getWorkoutsForDay(_selectedDay!)
        : <WorkoutHistoryItem>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        TableCalendar<WorkoutHistoryItem>(
          firstDay: DateTime(2020),
          lastDay: DateTime.now().add(const Duration(days: 1)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getWorkoutsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: 'de_DE',
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(color: c.textPrimary),
            weekendTextStyle: TextStyle(color: c.textPrimary),
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.accent, width: 1.5),
            ),
            todayTextStyle: TextStyle(color: c.textPrimary),
            selectedDecoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? c.background
                  : Colors.white,
              fontWeight: FontWeight.w600,
            ),
            markersMaxCount: 0,
            cellMargin: const EdgeInsets.all(4),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon:
                Icon(Icons.chevron_left, color: c.textSecondary),
            rightChevronIcon:
                Icon(Icons.chevron_right, color: c.textSecondary),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: c.textMuted, fontSize: 12),
            weekendStyle: TextStyle(color: c.textMuted, fontSize: 12),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              final isSelected = isSameDay(_selectedDay, date);
              if (isSelected) return null;
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
        if (selectedWorkouts.isNotEmpty) ...[
          const SizedBox(height: IronRepSpacing.lg),
          ...selectedWorkouts.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: IronRepSpacing.sm),
                child: _CalendarWorkoutCard(workout: w),
              )),
        ],
        const SizedBox(height: IronRepSpacing.xl),
        const _WeeklyFrequencyStrip(),
      ],
    );
  }
}

class _WeeklyFrequencyStrip extends ConsumerWidget {
  const _WeeklyFrequencyStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final asyncWeeks = ref.watch(weeklyFrequencyProvider);

    return asyncWeeks.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (weeks) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Letzte 8 Wochen',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: IronRepSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < weeks.length; i++)
                  _FrequencyCircle(
                    count: weeks[i].count,
                    weekStart: weeks[i].weekStart,
                    isCurrentWeek: i == weeks.length - 1,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FrequencyCircle extends StatelessWidget {
  final int count;
  final DateTime weekStart;
  final bool isCurrentWeek;

  const _FrequencyCircle({
    required this.count,
    required this.weekStart,
    required this.isCurrentWeek,
  });

  int get _calendarWeek {
    final dayOfYear = weekStart.difference(DateTime(weekStart.year)).inDays + 1;
    return ((dayOfYear - weekStart.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasWorkouts = count > 0;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: hasWorkouts
                ? c.accent.withValues(alpha: isCurrentWeek ? 0.25 : 0.15)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasWorkouts
                  ? c.accent.withValues(alpha: isCurrentWeek ? 1.0 : 0.6)
                  : c.border,
              width: isCurrentWeek && hasWorkouts ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: hasWorkouts
              ? Text(
                  '$count',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          'KW$_calendarWeek',
          style: TextStyle(
            color: c.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _CalendarWorkoutCard extends StatelessWidget {
  final WorkoutHistoryItem workout;

  const _CalendarWorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final w = workout;

    return GestureDetector(
      onTap: () => context.push('/workout-detail/${w.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name ?? 'Workout',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildStats(w),
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  String _buildStats(WorkoutHistoryItem w) {
    final parts = <String>[];
    if (w.setCount > 0) parts.add('${w.setCount} Sätze');
    if (w.totalVolume > 0) {
      final vol = w.totalVolume >= 1000
          ? '${(w.totalVolume / 1000).toStringAsFixed(1)}k kg'
          : '${w.totalVolume.toStringAsFixed(0)} kg';
      parts.add(vol);
    }
    if (w.durationSeconds != null) parts.add('${w.durationSeconds! ~/ 60}min');
    return parts.join(' · ');
  }
}
