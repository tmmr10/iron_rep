import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../l10n/l10n_helper.dart';
import '../../../models/workout_history_item.dart';
import '../../../shared/design_system.dart';
import '../../../shared/widgets/tap_scale.dart';

class WorkoutCalendar extends ConsumerStatefulWidget {
  final List<WorkoutHistoryItem> workouts;

  const WorkoutCalendar({super.key, required this.workouts});

  @override
  ConsumerState<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends ConsumerState<WorkoutCalendar> {
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

  /// Returns ISO week entries for weeks overlapping the focused month.
  List<({int weekNumber, int count, bool isCurrent})> _monthWeeks() {
    final year = _focusedDay.year;
    final month = _focusedDay.month;
    final firstOfMonth = DateTime(year, month, 1);
    final lastOfMonth = DateTime(year, month + 1, 0);
    final now = DateTime.now();
    final currentMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    // Find Monday of the week containing the 1st
    var monday = firstOfMonth.subtract(
      Duration(days: (firstOfMonth.weekday - 1)),
    );

    final weeks = <({int weekNumber, int count, bool isCurrent})>[];
    while (monday.isBefore(lastOfMonth) ||
        monday.isAtSameMomentAs(lastOfMonth)) {
      // Count workouts in this week
      int count = 0;
      for (int d = 0; d < 7; d++) {
        final day = monday.add(Duration(days: d));
        final key = DateTime(day.year, day.month, day.day);
        count += _workoutsByDay[key]?.length ?? 0;
      }

      final isCurrent = monday.year == currentMonday.year &&
          monday.month == currentMonday.month &&
          monday.day == currentMonday.day;

      weeks.add((
        weekNumber: _isoWeekNumber(monday),
        count: count,
        isCurrent: isCurrent,
      ));

      monday = monday.add(const Duration(days: 7));
    }
    return weeks;
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  int get _monthWorkoutCount {
    final year = _focusedDay.year;
    final month = _focusedDay.month;
    int count = 0;
    for (final w in widget.workouts) {
      final date = w.completedAt ?? w.startedAt;
      if (date.year == year && date.month == month) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final selectedWorkouts = _selectedDay != null
        ? _getWorkoutsForDay(_selectedDay!)
        : <WorkoutHistoryItem>[];

    final weeks = _monthWeeks();
    final monthTotal = _monthWorkoutCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        // Custom header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: c.textSecondary),
              onPressed: () => setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month - 1,
                );
              }),
            ),
            Column(
              children: [
                Text(
                  _monthYearLabel(_focusedDay),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (monthTotal > 0)
                  Text(
                    '$monthTotal Workout${monthTotal == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: c.textSecondary),
              onPressed: () => setState(() {
                _focusedDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month + 1,
                );
              }),
            ),
          ],
        ),
        // KW week strip
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final w in weeks) _KWRing(week: w),
            ],
          ),
        ),
        TableCalendar<WorkoutHistoryItem>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getWorkoutsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: 'de_DE',
          headerVisible: false,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
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
                bottom: 1,
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
        ] else if (_selectedDay != null) ...[
          const SizedBox(height: IronRepSpacing.lg),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    color: c.textMuted.withValues(alpha: 0.4),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.noActivityYet,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _monthYearLabel(DateTime date) {
    return DateFormat.yMMMM(Localizations.localeOf(context).languageCode).format(date);
  }
}

class _KWRing extends StatelessWidget {
  final ({int weekNumber, int count, bool isCurrent}) week;

  const _KWRing({required this.week});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final count = week.count;
    final hasWorkouts = count > 0;

    // Ring opacity based on count
    final double ringAlpha = count == 0
        ? 0.2
        : count <= 2
            ? 0.6
            : 1.0;
    final double fillAlpha = count == 0
        ? 0.0
        : count <= 2
            ? 0.12
            : 0.22;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: hasWorkouts
                ? c.accent.withValues(alpha: fillAlpha)
                : null,
            shape: BoxShape.circle,
            border: Border.all(
              color: c.accent.withValues(
                alpha: week.isCurrent ? 1.0 : ringAlpha,
              ),
              width: week.isCurrent ? 2.0 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              color: hasWorkouts
                  ? c.accent
                  : c.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'KW${week.weekNumber}',
          style: TextStyle(
            color: week.isCurrent ? c.accent : c.textMuted,
            fontSize: 10,
            fontWeight: week.isCurrent ? FontWeight.w600 : FontWeight.normal,
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

    return TapScale(
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
