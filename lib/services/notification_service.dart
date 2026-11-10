import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, VoidCallback;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 푸시 알림 데이터 모델
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String? taskId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.taskId,
  });
}

/// 실제 휴대폰 OS 푸시 알람 및 인앱 스케줄링 서비스
///
/// - Android / iOS 실제 휴대폰에서는 `flutter_local_notifications` + `timezone (Asia/Seoul)`을 통해
///   앱이 꺼져 있거나 화면이 잠겨 있어도 사용자가 설정한 정확한 시각에 휴대폰 알람이 울립니다.
/// - Web 및 테스트 환경에서는 인앱 타이머 + 스트림 알림으로 안전하게 동작합니다.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final List<NotificationItem> _scheduledNotifications = [];
  final Map<String, Timer> _inAppTimers = {};
  final StreamController<NotificationItem> _notificationStreamController =
      StreamController<NotificationItem>.broadcast();

  Stream<NotificationItem> get onNotificationReceived =>
      _notificationStreamController.stream;

  List<NotificationItem> get scheduledNotifications =>
      List.unmodifiable(_scheduledNotifications);

  bool get _isMobileNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  int _notificationIdFor(String taskId) => taskId.hashCode & 0x7FFFFFFF;

  /// 서비스 초기화 및 휴대폰 알림 권한 요청
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // 타임존 로드 실패 시 기본 로컬 사용
    }

    if (!_isMobileNative) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(initSettings);

      // Android 13+ 알림 권한 및 정확한 알람 권한 요청
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {
      // 테스트 바인딩 등 플랫폼 채널 미지원 환경 안전 처리
    }
  }

  /// 캐릭터 성격에 맞는 알림 문구 생성
  String generateCharacterReminderText({
    required String characterName,
    required String taskTitle,
  }) {
    return '[$characterName]: "$taskTitle" 할 시간이야! 지금 바로 시작해볼까? 🐾';
  }

  /// 특정 일정에 대한 휴대폰 푸시 알람 예약
  Future<void> scheduleTaskNotification({
    required String taskId,
    required String taskTitle,
    required String characterName,
    required DateTime taskStartTime,
    int alertBeforeMin = 0,
  }) async {
    await initialize();
    await cancelNotification(taskId);

    DateTime notificationTime =
        taskStartTime.subtract(Duration(minutes: alertBeforeMin));

    // 이미 지난 시각이면 다음 날 같은 시각으로 자동 보정
    final now = DateTime.now();
    if (notificationTime.isBefore(now)) {
      notificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        notificationTime.hour,
        notificationTime.minute,
      );
      if (notificationTime.isBefore(now)) {
        notificationTime = notificationTime.add(const Duration(days: 1));
      }
    }

    final bodyText = generateCharacterReminderText(
      characterName: characterName,
      taskTitle: taskTitle,
    );

    final item = NotificationItem(
      id: taskId,
      title: '🐾 PIPI 일정 알람',
      body: bodyText,
      scheduledTime: notificationTime,
      taskId: taskId,
    );

    _scheduledNotifications.add(item);

    // 1. 실제 Android / iOS 휴대폰 OS 로컬 알람 등록
    if (_isMobileNative) {
      try {
        final tzTime = tz.TZDateTime.from(notificationTime, tz.local);
        const androidDetails = AndroidNotificationDetails(
          'pipi_task_alarm_channel',
          'PIPI 일정 알람',
          channelDescription: '설정한 일정 시각에 반려동물 캐릭터가 보내는 알람입니다.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _plugin.zonedSchedule(
          _notificationIdFor(taskId),
          item.title,
          item.body,
          tzTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // 에뮬레이터/권한 미허용 시에도 앱 동작이 멈추지 않도록 보호
      }
    }

    // 2. 앱 실행 중 포그라운드 인앱 알람 스트림 예약
    final delay = notificationTime.difference(DateTime.now());
    if (!delay.isNegative && delay.inDays < 7) {
      _inAppTimers[taskId] = Timer(delay, () {
        _notificationStreamController.add(item);
      });
    }
  }

  /// 특정 일정 알림 취소
  Future<void> cancelNotification(String taskId) async {
    _scheduledNotifications.removeWhere((item) => item.taskId == taskId);
    _inAppTimers.remove(taskId)?.cancel();

    if (_isMobileNative) {
      try {
        await _plugin.cancel(_notificationIdFor(taskId));
      } catch (_) {}
    }
  }

  /// 테스트용: "10초 뒤 알람 보내기"
  Future<void> sendTestNotificationIn10Seconds({
    required String characterName,
    VoidCallback? onTriggered,
  }) async {
    await scheduleTaskNotification(
      taskId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      taskTitle: '테스트 알람',
      characterName: characterName,
      taskStartTime: DateTime.now().add(const Duration(seconds: 10)),
      alertBeforeMin: 0,
    );
    Timer(const Duration(seconds: 10), () {
      onTriggered?.call();
    });
  }
}
