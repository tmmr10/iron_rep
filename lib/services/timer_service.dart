import 'dart:io';

import 'package:flutter/services.dart';

class TimerService {
  static const _channel = MethodChannel('com.tmmr.iron_rep/notifications');
  static bool _permissionGranted = false;
  static void Function(String route)? onNavigateTo;
  static bool _liveActivitySupported = true;

  static Future<void> initialize() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'navigateTo' && onNavigateTo != null) {
        onNavigateTo!(call.arguments as String);
      }
    });
  }

  static Future<bool> ensurePermission() async {
    if (_permissionGranted) return true;
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      _permissionGranted = granted ?? false;
      return _permissionGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<void> scheduleTimerEnd(
    int seconds, {
    String exerciseName = 'Pause',
    String? nextExerciseName,
  }) async {
    try {
      final hasPermission = await ensurePermission();
      if (!hasPermission) return;

      final title = nextExerciseName != null && nextExerciseName.isNotEmpty
          ? 'Weiter: $nextExerciseName'
          : 'Weiter geht\'s! 💪';
      await _channel.invokeMethod<bool>('scheduleTimer', {
        'seconds': seconds,
        'title': title,
        'body': '$exerciseName abgeschlossen',
        'exerciseName': exerciseName,
        'nextExerciseName': nextExerciseName ?? '',
      });
    } catch (_) {
    }
  }

  static Future<void> cancelTimer() async {
    try {
      await _channel.invokeMethod('cancelTimer');
    } catch (_) {}
  }

  static Future<void> showWorkoutNotification({
    required String title,
    required String body,
    int? startedAtMs,
  }) async {
    try {
      final hasPermission = await ensurePermission();
      if (!hasPermission) return;
      await _channel.invokeMethod('showOngoingNotification', {
        'title': title,
        'body': body,
        if (startedAtMs != null) 'startedAtMs': startedAtMs,
      });
    } catch (_) {
    }
  }

  static Future<void> dismissWorkoutNotification() async {
    try {
      await _channel.invokeMethod('dismissOngoingNotification');
    } catch (_) {}
  }

  static Future<void> startLiveTimer({
    required int seconds,
    String exerciseName = 'Pause',
    String? nextExerciseName,
  }) async {
    if (Platform.isIOS) {
      try {
        final started = await _channel.invokeMethod<bool>('startLiveActivity', {
          'seconds': seconds,
          'exerciseName': exerciseName,
          'nextExerciseName': nextExerciseName ?? '',
        });
        _liveActivitySupported = started ?? false;
      } catch (_) {
        _liveActivitySupported = false;
      }
    }
  }

  static Future<void> endLiveTimer() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('endLiveActivity');
      } catch (_) {
      }
    }
  }

  static bool get isLiveActivitySupported => _liveActivitySupported;

  static Future<bool> isLiveActivityEnabled() async {
    if (!Platform.isIOS) return false;
    try {
      final enabled = await _channel.invokeMethod<bool>('isLiveActivityEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> startWorkoutActivity({
    required String workoutName,
    int? startedAtMs,
  }) async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('startWorkoutActivity', {
          'workoutName': workoutName,
          'startedAtMs': startedAtMs ?? DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {
      }
    }
  }

  static Future<void> updateWorkoutActivity({
    required String exerciseName,
    String? nextExerciseName,
    int currentSet = 0,
    int totalSets = 0,
  }) async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('updateWorkoutActivity', {
          'exerciseName': exerciseName,
          'nextExerciseName': nextExerciseName ?? '',
          'currentSet': currentSet,
          'totalSets': totalSets,
        });
      } catch (_) {
      }
    }
  }

  static Future<void> pauseWorkoutActivity({required int elapsedSeconds}) async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('pauseWorkoutActivity', {
          'elapsedSeconds': elapsedSeconds,
        });
      } catch (_) {
      }
    } else if (Platform.isAndroid) {
      // Update notification to show paused state
      final m = elapsedSeconds ~/ 60;
      final s = elapsedSeconds % 60;
      showWorkoutNotification(
        title: 'Training pausiert',
        body: '${m}m ${s.toString().padLeft(2, '0')}s',
      );
    }
  }

  static Future<void> resumeWorkoutActivity({required int elapsedSeconds}) async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('resumeWorkoutActivity', {
          'elapsedSeconds': elapsedSeconds,
        });
      } catch (_) {
      }
    } else if (Platform.isAndroid) {
      // Resume notification with chronometer from correct time
      final startedAtMs = DateTime.now().subtract(Duration(seconds: elapsedSeconds)).millisecondsSinceEpoch;
      showWorkoutNotification(
        title: 'Training',
        body: 'Aktiv',
        startedAtMs: startedAtMs,
      );
    }
  }

  static Future<void> endWorkoutActivity() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('endWorkoutActivity');
      } catch (_) {
      }
    }
  }
}
