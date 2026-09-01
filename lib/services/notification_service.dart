import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/l10n/app_localizations.dart';

/// Schedules the reminders that are the entire point of the app.
///
/// iOS caps an app at 64 *pending* local notifications and silently drops the
/// rest, so we never schedule per-document in isolation. Instead every change
/// triggers a full reschedule: collect every reminder across every document,
/// sort by date, and schedule the soonest [_maxPending]. Anything further out
/// gets scheduled on a later pass, long before it is due.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Kept under the iOS limit of 64 with room for anything scheduled outside
  /// this path.
  static const _maxPending = 56;

  /// Reminders fire mid-morning local time — early enough to act on that day,
  /// late enough not to wake anyone.
  static const _hourOfDay = 9;

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;

    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        // Permission is requested explicitly after the user adds their first
        // document, not on a cold launch where the prompt has no context.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings);
    _initialised = true;
  }

  /// Asks for notification permission.
  ///
  /// Call this after the first document is saved. An app that asks on launch,
  /// before showing any value, gets denied — and a denied Elapsa is a useless
  /// Elapsa.
  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  /// Rebuilds the whole pending-notification set from the current documents.
  ///
  /// Takes the localisations explicitly rather than reaching for a
  /// BuildContext: this runs from a repository with no widget tree, and a
  /// reminder that fires in six months should be written in the language the
  /// user has chosen, not the one the phone happened to boot in.
  Future<void> rescheduleAll(
    List<TrackedDocument> docs,
    L l, {
    DateTime? now,
  }) async {
    await init();
    await _plugin.cancelAll();

    final pending = <_PendingReminder>[];
    for (final doc in docs) {
      for (final date in doc.reminderDates(now: now)) {
        pending.add(_PendingReminder(doc, date, l));
      }
    }

    pending.sort((a, b) => a.date.compareTo(b.date));

    var id = 0;
    for (final reminder in pending.take(_maxPending)) {
      await _schedule(id++, reminder);
    }

    if (kDebugMode) {
      debugPrint(
        'Elapsa: scheduled ${id.clamp(0, _maxPending)} of ${pending.length} '
        'reminders across ${docs.length} documents',
      );
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pending() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }

  Future<void> _schedule(int id, _PendingReminder reminder) async {
    final local = tz.TZDateTime.local(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      _hourOfDay,
    );

    // A reminder whose 9am slot has already passed today is not worth firing.
    if (!local.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      reminder.title,
      reminder.body,
      local,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'elapsa_reminders',
          reminder.l.notifyChannelName,
          channelDescription: reminder.l.notifyChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // Inexact is deliberate. A renewal reminder does not need second
      // accuracy, and asking for SCHEDULE_EXACT_ALARM invites a Play Store
      // policy review we do not need.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Reminders are anchored to a wall-clock date, so they should fire at
      // 9am wherever the user happens to be rather than tracking the timezone
      // the document was added in.
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      payload: reminder.doc.id,
    );
  }
}

class _PendingReminder {
  final TrackedDocument doc;
  final DateTime date;
  final L l;

  _PendingReminder(this.doc, this.date, this.l);

  int get daysBefore => doc.expiryDate.difference(date).inDays;

  /// The copy is the product. "Your passport expires in 270 days" sounds
  /// absurd; "Time to start renewing your passport" is the reason someone
  /// installed this.
  String get title {
    if (daysBefore >= doc.renewalLeadDays) {
      return l.notifyRenewTitle(doc.type.label(l));
    }
    // Always name the actual number of days. Two reminders that both say
    // "expires soon" are indistinguishable in a notification list.
    return l.notifyExpiresTitle(doc.label, daysBefore);
  }

  String get body {
    final when = _formatDate(doc.expiryDate);
    if (daysBefore >= doc.renewalLeadDays) return l.notifyRenewBody(when);
    if (doc.type.hasSixMonthTravelRule) return l.notifyTravelBody(when);
    return l.notifyPlainBody(when);
  }

  String _formatDate(DateTime d) => DateFormat.yMMMMd(l.localeName).format(d);
}
