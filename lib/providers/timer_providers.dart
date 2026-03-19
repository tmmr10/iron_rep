import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/timer_service.dart';
import 'settings_providers.dart';

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;

  const RestTimerState({
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.isRunning = false,
  });

  double get progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;

  String get displayTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;
  String _exerciseName = 'Pause';
  String? _nextExerciseName;
  DateTime? _endTime;

  RestTimerNotifier() : super(const RestTimerState());

  void start(int seconds, {String exerciseName = 'Pause', String? nextExerciseName}) {
    _timer?.cancel();
    _endTime = DateTime.now().add(Duration(seconds: seconds));
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: true,
    );
    _exerciseName = exerciseName;
    _nextExerciseName = nextExerciseName;
    // Schedule background notification — fire-and-forget
    _scheduleNotification(seconds, exerciseName: exerciseName, nextExerciseName: nextExerciseName);
    // Dismiss workout notification while countdown is active (avoid double notification)
    TimerService.dismissWorkoutNotification();
    // Start live timer (Live Activity on iOS, chronometer handled by scheduleTimer on Android)
    TimerService.startLiveTimer(
      seconds: seconds,
      exerciseName: exerciseName,
      nextExerciseName: nextExerciseName,
    );
    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _endTime!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _timer?.cancel();
        _endTime = null;
        HapticFeedback.heavyImpact();
        TimerService.endLiveTimer();
        state = const RestTimerState();
      } else {
        state = RestTimerState(
          remainingSeconds: remaining,
          totalSeconds: state.totalSeconds,
          isRunning: true,
        );
      }
    });
  }

  /// Call when app resumes from background to sync timer with real clock
  void syncWithClock() {
    if (!state.isRunning || _endTime == null) return;
    final remaining = _endTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _timer?.cancel();
      _endTime = null;
      HapticFeedback.heavyImpact();
      TimerService.endLiveTimer();
      state = const RestTimerState();
    } else {
      state = RestTimerState(
        remainingSeconds: remaining,
        totalSeconds: state.totalSeconds,
        isRunning: true,
      );
    }
  }

  void addTime(int seconds) {
    if (!state.isRunning || _endTime == null) return;
    _endTime = _endTime!.add(Duration(seconds: seconds));
    final newRemaining = _endTime!.difference(DateTime.now()).inSeconds;
    if (newRemaining <= 0) {
      skip();
      return;
    }
    state = RestTimerState(
      remainingSeconds: newRemaining,
      totalSeconds: state.totalSeconds + seconds,
      isRunning: true,
    );
    _scheduleNotification(newRemaining, exerciseName: _exerciseName, nextExerciseName: _nextExerciseName);
    TimerService.startLiveTimer(seconds: newRemaining, exerciseName: _exerciseName, nextExerciseName: _nextExerciseName);
  }

  Future<void> _scheduleNotification(int seconds, {String exerciseName = 'Pause', String? nextExerciseName}) async {
    // On iOS, Live Activity handles the timer display — no regular notification needed
    if (Platform.isIOS) return;
    try {
      await TimerService.scheduleTimerEnd(
        seconds,
        exerciseName: exerciseName,
        nextExerciseName: nextExerciseName,
      );
    } catch (_) {}
  }

  void skip() {
    _timer?.cancel();
    _endTime = null;
    TimerService.cancelTimer();
    TimerService.endLiveTimer();
    state = const RestTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

final defaultRestSecondsProvider = FutureProvider<int>((ref) async {
  final settings = ref.watch(settingsProvider);
  return settings.whenOrNull(data: (s) => s.defaultRestSeconds) ?? 90;
});
