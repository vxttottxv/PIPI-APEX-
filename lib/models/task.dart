import 'package:flutter/material.dart';

/// 일정(Task) 카테고리 정의
enum TaskCategory {
  study, // 학업
  exercise, // 운동
  certificate, // 자격증
  activity, // 대외활동
  personal; // 개인

  String get koreanName {
    switch (this) {
      case TaskCategory.study:
        return '학업';
      case TaskCategory.exercise:
        return '운동';
      case TaskCategory.certificate:
        return '자격증';
      case TaskCategory.activity:
        return '대외활동';
      case TaskCategory.personal:
        return '개인';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.study:
        return const Color(0xFF4A90E2); // 세련된 블루
      case TaskCategory.exercise:
        return const Color(0xFFFF6B6B); // 에너지 코랄 레드
      case TaskCategory.certificate:
        return const Color(0xFFFFA502); // 골든 오렌지
      case TaskCategory.activity:
        return const Color(0xFF2ED573); // 싱그러운 그린
      case TaskCategory.personal:
        return const Color(0xFF9B59B6); // 포근한 퍼플
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.study:
        return Icons.menu_book_rounded;
      case TaskCategory.exercise:
        return Icons.fitness_center_rounded;
      case TaskCategory.certificate:
        return Icons.workspace_premium_rounded;
      case TaskCategory.activity:
        return Icons.groups_rounded;
      case TaskCategory.personal:
        return Icons.face_rounded;
    }
  }

  static TaskCategory fromString(String val) {
    return TaskCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.koreanName == val,
      orElse: () => TaskCategory.personal,
    );
  }
}

/// 일정(Task) 중요도
enum TaskPriority {
  high, // 상
  medium, // 중
  low; // 하

  String get koreanName {
    switch (this) {
      case TaskPriority.high:
        return '상';
      case TaskPriority.medium:
        return '중';
      case TaskPriority.low:
        return '하';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFE74C3C);
      case TaskPriority.medium:
        return const Color(0xFFF39C12);
      case TaskPriority.low:
        return const Color(0xFF27AE60);
    }
  }

  static TaskPriority fromString(String val) {
    return TaskPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.koreanName == val,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// 일정(Task) 상태
enum TaskStatus {
  inStorage, // 보관함 대기 중 (시간표에 미배치)
  placed, // 시간표에 배치됨
  completed, // 수행 및 사진 인증 완료
  failed; // 기한 만료 미인증

  String get koreanName {
    switch (this) {
      case TaskStatus.inStorage:
        return '보관함';
      case TaskStatus.placed:
        return '배치됨';
      case TaskStatus.completed:
        return '완료됨';
      case TaskStatus.failed:
        return '미인증';
    }
  }

  static TaskStatus fromString(String val) {
    return TaskStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.koreanName == val,
      orElse: () => TaskStatus.inStorage,
    );
  }
}

/// PIPI 일정(Task) 데이터 모델
///
/// 명세서 5. 데이터 모델:
/// - id: 고유 식별자
/// - title: 할 일 이름
/// - durationMin: 예상 소요 시간 (30분 단위: 30, 60, 90, 120, ...)
/// - goal: 목표 한 줄 텍스트
/// - startDate: 시작 날짜
/// - endDate: 종료 날짜
/// - alertBefore: 알림 시간 (시작 0분 / 10분 / 30분 전)
/// - priority: 중요도 (상 / 중 / 하)
/// - category: 카테고리 (학업, 운동, 자격증, 대외활동, 개인)
/// - placedDate: 시간표에 배치된 날짜
/// - startTime: 시간표 배치 시작 시각 (예: "09:00", 30분 단위)
/// - status: 상태 (in_storage / placed / completed / failed)
/// - proofImagePath: 인증 사진 파일 경로 또는 Base64/플레이스홀더
/// - completedAt: 인증 완료 일시
class Task {
  final String id;
  final String title;
  final int durationMin;
  final String goal;
  final DateTime startDate;
  final DateTime endDate;
  final int alertBefore;
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime? placedDate;
  final String? startTime;
  final TaskStatus status;
  final String? proofImagePath;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    required this.durationMin,
    required this.goal,
    required this.startDate,
    required this.endDate,
    this.alertBefore = 10,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
    this.placedDate,
    this.startTime,
    this.status = TaskStatus.inStorage,
    this.proofImagePath,
    this.completedAt,
  });

  /// 30분 슬롯 개수 (예: 60분 -> 2슬롯, 120분 -> 4슬롯)
  int get slotCount => (durationMin / 30).ceil().clamp(1, 48);

  /// 소요 시간 텍스트 포맷 (예: "1시간 30분", "30분")
  String get durationString {
    final hours = durationMin ~/ 60;
    final minutes = durationMin % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours시간 $minutes분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$minutes분';
    }
  }

  /// 종료 시각 계산 ("09:00" + 90분 -> "10:30")
  String? get endTime {
    if (startTime == null) return null;
    final parts = startTime!.split(':');
    if (parts.length != 2) return null;
    final startHour = int.tryParse(parts[0]) ?? 0;
    final startMin = int.tryParse(parts[1]) ?? 0;

    final totalMin = startHour * 60 + startMin + durationMin;
    final endHour = (totalMin ~/ 60).clamp(0, 24);
    final endMinute = totalMin % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  /// 보상 경험치 (EXP) 계산: 소요 시간 및 중요도 비례
  int get expReward {
    final baseExp = (durationMin / 30).round() * 15;
    switch (priority) {
      case TaskPriority.high:
        return baseExp + 10;
      case TaskPriority.medium:
        return baseExp;
      case TaskPriority.low:
        return (baseExp * 0.8).round();
    }
  }

  /// 보상 코인 계산
  int get coinReward => (durationMin / 30).round() * 20;

  /// 보상 간식 계산
  int get snackReward => 1;

  /// 명세서 4-6: 인증 가능 여부 검사
  /// "일정 시작 시간 이후에만 인증 버튼이 활성화되고, 종료 후 3시간이 지나면 인증할 수 없다."
  bool get canProveNow {
    if (status == TaskStatus.completed) return false;
    if (placedDate == null || startTime == null) return false;

    final parts = startTime!.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final startDateTime = DateTime(
      placedDate!.year,
      placedDate!.month,
      placedDate!.day,
      hour,
      minute,
    );

    final endDateTime = startDateTime.add(Duration(minutes: durationMin));
    final expireLimit = endDateTime.add(const Duration(hours: 3));

    final now = DateTime.now();
    return now.isAfter(startDateTime) && now.isBefore(expireLimit);
  }

  /// 종료 후 3시간이 지나 인증 불가(만료) 여부
  bool get isExpired {
    if (status == TaskStatus.completed) return false;
    if (placedDate == null || startTime == null) return false;

    final parts = startTime!.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final startDateTime = DateTime(
      placedDate!.year,
      placedDate!.month,
      placedDate!.day,
      hour,
      minute,
    );

    final endDateTime = startDateTime.add(Duration(minutes: durationMin));
    final expireLimit = endDateTime.add(const Duration(hours: 3));

    return DateTime.now().isAfter(expireLimit);
  }

  Task copyWith({
    String? id,
    String? title,
    int? durationMin,
    String? goal,
    DateTime? startDate,
    DateTime? endDate,
    int? alertBefore,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? placedDate,
    String? startTime,
    TaskStatus? status,
    String? proofImagePath,
    DateTime? completedAt,
    bool clearPlacement = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMin: durationMin ?? this.durationMin,
      goal: goal ?? this.goal,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertBefore: alertBefore ?? this.alertBefore,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      placedDate: clearPlacement ? null : (placedDate ?? this.placedDate),
      startTime: clearPlacement ? null : (startTime ?? this.startTime),
      status: status ?? this.status,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'durationMin': durationMin,
      'goal': goal,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'alertBefore': alertBefore,
      'priority': priority.name,
      'category': category.name,
      'placedDate': placedDate?.toIso8601String(),
      'startTime': startTime,
      'status': status.name,
      'proofImagePath': proofImagePath,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      durationMin: json['durationMin'] as int,
      goal: json['goal'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      alertBefore: json['alertBefore'] as int? ?? 10,
      priority: TaskPriority.fromString(json['priority'] as String? ?? 'medium'),
      category: TaskCategory.fromString(json['category'] as String? ?? 'personal'),
      placedDate: json['placedDate'] != null
          ? DateTime.parse(json['placedDate'] as String)
          : null,
      startTime: json['startTime'] as String?,
      status: TaskStatus.fromString(json['status'] as String? ?? 'inStorage'),
      proofImagePath: json['proofImagePath'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}
