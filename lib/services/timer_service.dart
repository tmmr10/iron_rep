import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TimerService {
  static const _channel = MethodChannel('com.tmmr.iron_rep/notifications');
  static bool _permissionGranted = false;
  static void Function(String route)? onNavigateTo;

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
      debugPrint('TimerService: permission=$_permissionGranted');
      return _permissionGranted;
    } catch (e) {
      debugPrint('TimerService permission error: $e');
      return false;
    }
  }

  static Future<void> scheduleTimerEnd(int seconds) async {
    try {
      final hasPermission = await ensurePermission();
      if (!hasPermission) return;

      final result = await _channel.invokeMethod<bool>('scheduleTimer', {
        'seconds': seconds,
        'title': 'Pausentimer',
        'body': 'Weiter geht\'s! 💪',
      });
      debugPrint('TimerService: scheduled=$result (${seconds}s)');
    } catch (e) {
      debugPrint('TimerService schedule error: $e');
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
  }) async {
    try {
      final hasPermission = await ensurePermission();
      if (!hasPermission) return;
      await _channel.invokeMethod('showOngoingNotification', {
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('TimerService showWorkoutNotification error: $e');
    }
  }

  static Future<void> dismissWorkoutNotification() async {
    try {
      await _channel.invokeMethod('dismissOngoingNotification');
    } catch (_) {}
  }
}
