import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeService {
  static const MethodChannel _channel = MethodChannel('com.focuspath.app/native');

  /// Checks if system notification permission is granted
  static Future<bool> checkNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkNotificationPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.checkNotificationPermission failed: $e');
      return false;
    }
  }

  /// Prompts user to grant system notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.requestNotificationPermission failed: $e');
      return false;
    }
  }

  /// Displays an immediate native system notification with sound and vibration
  static Future<bool> showNotification({
    required String title,
    required String body,
    int id = 1001,
    String channelId = 'focuspath_study_reminders',
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('showNotification', {
        'id': id,
        'title': title,
        'body': body,
        'channelId': channelId,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.showNotification failed: $e');
      return false;
    }
  }

  /// Schedules a future native study session alarm with AlarmManager
  static Future<bool> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime triggerAt,
  }) async {
    try {
      final triggerAtMillis = triggerAt.millisecondsSinceEpoch;
      final result = await _channel.invokeMethod<bool>('scheduleAlarm', {
        'id': id,
        'title': title,
        'body': body,
        'triggerAtMillis': triggerAtMillis,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.scheduleAlarm failed: $e');
      return false;
    }
  }

  /// Cancels an existing scheduled alarm
  static Future<bool> cancelAlarm(int id) async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelAlarm', {'id': id});
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.cancelAlarm failed: $e');
      return false;
    }
  }

  /// Checks if Android Usage Stats access has been granted in System Settings
  static Future<bool> checkUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsageStatsPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.checkUsageStatsPermission failed: $e');
      return false;
    }
  }

  /// Opens the Android "Usage Access" settings page directly
  static Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (e) {
      debugPrint('NativeService.openUsageAccessSettings failed: $e');
    }
  }

  /// Queries UsageStats for active distraction app usage in the last 3 hours
  static Future<Map<String, dynamic>> checkDistractionUsage({
    required List<String> appNames,
    required int thresholdMinutes,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'checkDistractionUsage',
        {
          'appNames': appNames,
          'thresholdMinutes': thresholdMinutes,
        },
      );
      return result ?? {
        'permissionGranted': false,
        'totalMinutes': 0,
        'exceededThreshold': false,
        'mostUsedApp': '',
      };
    } catch (e) {
      debugPrint('NativeService.checkDistractionUsage failed: $e');
      return {
        'permissionGranted': false,
        'totalMinutes': 0,
        'exceededThreshold': false,
        'mostUsedApp': '',
      };
    }
  }

  /// Retrieves list of launchable user applications installed on device
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeListMethod<dynamic>('getInstalledApps');
      if (result == null) return [];
      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return {
          'name': map['name']?.toString() ?? '',
          'packageName': map['packageName']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('NativeService.getInstalledApps failed: $e');
      return [];
    }
  }

  /// Checks if Android Display over other apps (Overlay) permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.checkOverlayPermission failed: $e');
      return false;
    }
  }

  /// Opens Android Display over other apps settings
  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (e) {
      debugPrint('NativeService.openOverlaySettings failed: $e');
    }
  }

  /// Opens Google Calendar or default device calendar app to insert a study session event
  static Future<bool> addCalendarEvent({
    required String title,
    String description = '',
    String location = 'SPPU Study Zone',
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('addCalendarEvent', {
        'title': title,
        'description': description,
        'location': location,
        'startTimeMillis': startTime.millisecondsSinceEpoch,
        'endTimeMillis': endTime.millisecondsSinceEpoch,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.addCalendarEvent failed: $e');
      return false;
    }
  }

  /// Updates the Android home-screen widget with current streak, focus minutes, and next task
  static Future<bool> updateWidget({
    required int streak,
    required int focusMinutes,
    String nextSubject = 'SPPU Study Block',
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateWidget', {
        'streak': streak,
        'focusMinutes': focusMinutes,
        'nextSubject': nextSubject,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.updateWidget failed: $e');
      return false;
    }
  }

  /// Toggles native Android Do Not Disturb mode (Priority-only notifications)
  static Future<bool> setDnd(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>('setDndEnabled', {'enable': enabled});
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.setDnd failed: $e');
      return false;
    }
  }

  /// Checks if Android Do Not Disturb permission (Notification Policy Access) is granted
  static Future<bool> checkDndPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkDndPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeService.checkDndPermission failed: $e');
      return false;
    }
  }

  /// Opens Android Do Not Disturb / Notification Policy Access settings page
  static Future<void> openDndSettings() async {
    try {
      await _channel.invokeMethod('openDndSettings');
    } catch (e) {
      debugPrint('NativeService.openDndSettings failed: $e');
    }
  }

  /// Actively checks if user opened a blocked distraction app and enforces immediate block & return to Gradient
  static Future<Map<String, dynamic>> checkAndEnforceAppBlock(List<String> blockedApps) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'checkAndEnforceAppBlock',
        {'blockedApps': blockedApps},
      );
      return result ?? {'blocked': false, 'appName': ''};
    } catch (e) {
      debugPrint('NativeService.checkAndEnforceAppBlock failed: $e');
      return {'blocked': false, 'appName': ''};
    }
  }
}
