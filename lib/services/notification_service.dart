import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../core/constants/api_constants.dart';
import '../models/app_models.dart';
import 'api_services.dart';

/// Background Workmanager task names
const String kVideoCheckTask = 'saifi_new_video_check';
const String kDailyMaintenanceTask = 'saifi_daily_maintenance';

@pragma('vm:entry-point')
void notificationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await NotificationService.ensureInitializedForBackground();

      switch (task) {
        case kVideoCheckTask:
          await NotificationService.checkForNewVideos();
          await NotificationService.checkZikrReminder();
          break;
        case kDailyMaintenanceTask:
          await NotificationService.runDailyMaintenance();
          break;
        default:
          await NotificationService.checkForNewVideos();
          await NotificationService.checkZikrReminder();
      }
      return true;
    } catch (e, st) {
      debugPrint('Workmanager error: $e\n$st');
      return false;
    }
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Notification IDs
  static const int _idJummah = 100;
  static const int _idHadith = 101;
  static const int _idZikr = 102;
  static const int _idNewVideoBase = 200;
  static const int _idPrayerBase = 300; // 300-304 for 5 prayers
  static const int _idWelcome = 1;

  // Preference keys
  static const String prefMinutesBefore = 'notif_prayer_minutes';
  static const String prefPrayerPrefix = 'notif_prayer_';
  static const String prefJummah = 'notif_jummah_enabled';
  static const String prefHadith = 'notif_hadith_enabled';
  static const String prefZikr = 'notif_zikr_enabled';
  static const String prefNewVideo = 'notif_new_video_enabled';
  static const String prefWelcomeShown = 'notif_welcome_shown';
  static const String prefLastVideoPrefix = 'last_video_id_';
  static const String prefHadithHour = 'notif_hadith_hour';
  static const String prefZikrHour = 'notif_zikr_hour';

  static const List<String> prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static const Map<String, String> prayerLabels = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  static const Map<String, String> zikrLabels = {
    'qalb': 'Qalb',
    'ruh': 'Ruh',
    'sirri': 'Sirri',
    'khaffi': 'Khaffi',
    'akhfa': 'Akhfa',
    'nufs': 'Nafs',
    'sultan': 'Sultan al-Azkar',
    'nafi_asbat': 'Nafi Asbat',
  };

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      // Pakistan-focused app; falls back gracefully if zone missing
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _ensureDefaults();
    await Workmanager().initialize(notificationCallbackDispatcher);

    await scheduleJummahReminder();
    await scheduleHadithReminder();
    await registerBackgroundTasks();

    // Seed last-known video IDs so the first poll doesn't spam old videos
    await _seedLastVideoIds();

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(prefWelcomeShown) ?? false)) {
      await showLocalNotification(
        id: _idWelcome,
        title: 'Saifi TV Reminders On',
        body:
            'Prayer, Jummah, Hadith, Zikr aur new video alerts active hain.',
        payload: 'welcome',
      );
      await prefs.setBool(prefWelcomeShown, true);
    }

    _initialized = true;
  }

  /// Lightweight init for Workmanager isolates
  static Future<void> ensureInitializedForBackground() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );
    _initialized = true;
  }

  static Future<void> _ensureDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(prefMinutesBefore)) {
      await prefs.setInt(prefMinutesBefore, 15);
    }
    for (final key in prayerKeys) {
      if (!prefs.containsKey('$prefPrayerPrefix$key')) {
        await prefs.setBool('$prefPrayerPrefix$key', true);
      }
    }
    if (!prefs.containsKey(prefJummah)) await prefs.setBool(prefJummah, true);
    if (!prefs.containsKey(prefHadith)) await prefs.setBool(prefHadith, true);
    if (!prefs.containsKey(prefZikr)) await prefs.setBool(prefZikr, true);
    if (!prefs.containsKey(prefNewVideo)) {
      await prefs.setBool(prefNewVideo, true);
    }
    if (!prefs.containsKey(prefHadithHour)) {
      await prefs.setInt(prefHadithHour, 7); // 7 AM
    }
    if (!prefs.containsKey(prefZikrHour)) {
      await prefs.setInt(prefZikrHour, 20); // 8 PM
    }
  }

  static AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        'saifi_tv_channel_id',
        'Saifi TV Notifications',
        channelDescription:
            'Notifications for new naats, bayanat, and Islamic reminders',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

  static NotificationDetails get _details =>
      NotificationDetails(android: _androidDetails);

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(id, title, body, _details, payload: payload);
  }

  // ── Settings helpers ──────────────────────────────────────────────────────

  static Future<int> getMinutesBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(prefMinutesBefore) ?? 15;
  }

  static Future<void> setMinutesBefore(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefMinutesBefore, minutes.clamp(5, 60));
  }

  static Future<bool> isPrayerEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$prefPrayerPrefix$key') ?? true;
  }

  static Future<void> setPrayerEnabled(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$prefPrayerPrefix$key', enabled);
  }

  static Future<bool> isEnabled(String prefKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKey) ?? true;
  }

  static Future<void> setEnabled(String prefKey, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, enabled);
  }

  // ── Background tasks ─────────────────────────────────────────────────────

  static Future<void> registerBackgroundTasks() async {
    await Workmanager().registerPeriodicTask(
      kVideoCheckTask,
      kVideoCheckTask,
      frequency: const Duration(minutes: 60),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    await Workmanager().registerPeriodicTask(
      kDailyMaintenanceTask,
      kDailyMaintenanceTask,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  static Future<void> runDailyMaintenance() async {
    // Re-fetch prayer times & reschedule; check zikr near evening
    final prayerData = await PrayerTimesService.fetchPrayerData();
    if (prayerData.times != null) {
      await schedulePrayerReminders(prayerData.times!);
    }
    await scheduleJummahReminder();
    await scheduleHadithReminder();
    await checkZikrReminder();
  }

  // ── New video polling (local replacement for Firebase Cloud Function) ─────

  static Future<void> _seedLastVideoIds() async {
    final prefs = await SharedPreferences.getInstance();
    final channels = {
      ...ApiConstants.approvedNaatChannels,
      ...ApiConstants.approvedBayanatChannels,
    };

    for (final ch in channels) {
      final channelId = ch['channelId']!;
      final key = '$prefLastVideoPrefix$channelId';
      if (prefs.containsKey(key)) continue;

      try {
        final videos = await YouTubeService.fetchChannelVideos(
          channelId: channelId,
          maxResults: 1,
          hardLimit: 1,
        );
        if (videos.isNotEmpty) {
          await prefs.setString(key, videos.first.youtubeVideoId);
        }
      } catch (e) {
        debugPrint('Seed video id failed for $channelId: $e');
      }
    }
  }

  static Future<void> checkForNewVideos() async {
    if (!await isEnabled(prefNewVideo)) return;

    final prefs = await SharedPreferences.getInstance();
    final channels = <Map<String, String>>[];
    final seen = <String>{};
    for (final ch in [
      ...ApiConstants.approvedNaatChannels,
      ...ApiConstants.approvedBayanatChannels,
    ]) {
      final id = ch['channelId']!;
      if (seen.add(id)) channels.add(ch);
    }

    var notifOffset = 0;
    for (final ch in channels) {
      final channelId = ch['channelId']!;
      final channelName = ch['name'] ?? 'Saifi TV';
      final key = '$prefLastVideoPrefix$channelId';

      try {
        final videos = await YouTubeService.fetchChannelVideos(
          channelId: channelId,
          maxResults: 1,
          hardLimit: 1,
        );
        if (videos.isEmpty) continue;

        final latest = videos.first;
        final lastId = prefs.getString(key);

        if (lastId == null) {
          await prefs.setString(key, latest.youtubeVideoId);
          continue;
        }

        if (latest.youtubeVideoId != lastId) {
          await prefs.setString(key, latest.youtubeVideoId);
          await showLocalNotification(
            id: _idNewVideoBase + notifOffset,
            title: 'New Video Uploaded',
            body: latest.title,
            payload: 'video:${latest.youtubeVideoId}',
          );
          notifOffset++;
          debugPrint('New video from $channelName: ${latest.title}');
        }
      } catch (e) {
        debugPrint('Video check failed for $channelId: $e');
      }
    }
  }

  // ── Prayer reminders ──────────────────────────────────────────────────────

  static DateTime? _parsePrayerTime(String raw, DateTime day) {
    try {
      final timeString = raw.split(' ').first;
      final parts = timeString.split(':');
      return DateTime(
        day.year,
        day.month,
        day.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  static tz.TZDateTime _toTz(DateTime dt) {
    return tz.TZDateTime(
      tz.local,
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
    );
  }

  static Future<void> schedulePrayerReminders(PrayerTimes times) async {
    final minutesBefore = await getMinutesBefore();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final prayerTimes = {
      'fajr': times.fajr,
      'dhuhr': times.dhuhr,
      'asr': times.asr,
      'maghrib': times.maghrib,
      'isha': times.isha,
    };

    for (var i = 0; i < prayerKeys.length; i++) {
      final key = prayerKeys[i];
      final notifId = _idPrayerBase + i;

      // Cancel previous
      await _plugin.cancel(notifId);

      if (!await isPrayerEnabled(key)) continue;

      final prayerDt = _parsePrayerTime(prayerTimes[key]!, today);
      if (prayerDt == null) continue;

      var remindAt = prayerDt.subtract(Duration(minutes: minutesBefore));

      // If today's reminder already passed, schedule for tomorrow (approx same time)
      if (!remindAt.isAfter(now)) {
        remindAt = remindAt.add(const Duration(days: 1));
      }

      final label = prayerLabels[key]!;
      await _plugin.zonedSchedule(
        notifId,
        '$label Prayer Soon',
        '$label namaz $minutesBefore minutes mein hai. Tayyar ho jaein.',
        _toTz(remindAt),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'prayer:$key',
      );
    }
  }

  // ── Jummah — Surah Kahf reminder every Friday 8 AM ────────────────────────

  static Future<void> scheduleJummahReminder() async {
    await _plugin.cancel(_idJummah);
    if (!await isEnabled(prefJummah)) return;

    final now = tz.TZDateTime.now(tz.local);
    // Friday = DateTime.friday = 5
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);
    while (scheduled.weekday != DateTime.friday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idJummah,
      'Jummah Reminder',
      'Aaj Jummah hai — Surah Al-Kahf parhne ka sawab hasil karein.',
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'jummah',
    );
  }

  // ── Daily Hadith — morning fixed time ─────────────────────────────────────

  static Future<void> scheduleHadithReminder() async {
    await _plugin.cancel(_idHadith);
    if (!await isEnabled(prefHadith)) return;

    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(prefHadithHour) ?? 7;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idHadith,
      'Aaj ka Hadith Ready Hai',
      'Rozana hadith padhein — Saifi TV pe tap karein.',
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'hadith',
    );
  }

  // ── Zikr reminder — evening if daily target incomplete ────────────────────

  static Future<void> checkZikrReminder() async {
    if (!await isEnabled(prefZikr)) return;

    final prefs = await SharedPreferences.getInstance();
    final zikrHour = prefs.getInt(prefZikrHour) ?? 20;
    final now = DateTime.now();

    // Only fire in the evening window (zikrHour .. zikrHour+1)
    if (now.hour != zikrHour) return;

    final incomplete = <String>[];
    for (final entry in zikrLabels.entries) {
      final count = prefs.getInt('zikr_${entry.key}') ?? 0;
      final target = prefs.getInt('target_${entry.key}') ?? 100;
      // Started but not finished, OR custom target with zero progress near day end
      if (count > 0 && count < target) {
        incomplete.add(entry.value);
      } else if (count == 0 && target != 100 && target > 0) {
        // User explicitly set a custom target
        incomplete.add(entry.value);
      }
    }

    if (incomplete.isEmpty) return;

    // Avoid spamming more than once per day
    final todayKey =
        'zikr_reminded_${now.year}_${now.month}_${now.day}';
    if (prefs.getBool(todayKey) ?? false) return;

    final names = incomplete.take(3).join(', ');
    final extra = incomplete.length > 3 ? ' aur ${incomplete.length - 3} aur' : '';

    await showLocalNotification(
      id: _idZikr,
      title: 'Zikr Reminder',
      body: 'Aaj ka target abhi incomplete hai: $names$extra. Thoda waqt nikalain.',
      payload: 'zikr',
    );
    await prefs.setBool(todayKey, true);
  }

  /// Reschedule all recurring reminders after settings change
  static Future<void> refreshAllSchedules() async {
    await scheduleJummahReminder();
    await scheduleHadithReminder();
    final prayerData = await PrayerTimesService.fetchPrayerData();
    if (prayerData.times != null) {
      await schedulePrayerReminders(prayerData.times!);
    }
  }
}
