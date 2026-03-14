import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  RestTimerNotifier() : super(const RestTimerState());

  void start(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        state = const RestTimerState();
      } else {
        state = RestTimerState(
          remainingSeconds: state.remainingSeconds - 1,
          totalSeconds: state.totalSeconds,
          isRunning: true,
        );
      }
    });
  }

  void addTime(int seconds) {
    if (!state.isRunning) return;
    state = RestTimerState(
      remainingSeconds: state.remainingSeconds + seconds,
      totalSeconds: state.totalSeconds + seconds,
      isRunning: true,
    );
  }

  void skip() {
    _timer?.cancel();
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
