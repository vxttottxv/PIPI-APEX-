import 'package:flutter/material.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';

/// 일정(Task) 상태 관리 프로바이더
///
/// 명세서 4-3, 4-4, 4-6, 4-10 연계:
/// - 일정 CRUD
/// - 시간표 드래그 앤 드롭 배치 및 보관함 회수
/// - 30분 단위 블록 정렬 및 겹침 감지 (conflict detection)
/// - 하루 12시간 가용 시간 초과 경고
/// - 사진 인증 및 완료 상태 변경
class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;

  TaskProvider({TaskRepository? repository})
      : _repository = repository ?? TaskRepository();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 시간표에서 현재 조회 중인 날짜 (기본값: 오늘)
  DateTime _selectedDate = DateTime.now();

  // 하루 가용 시간 (기본 12시간, 720분)
  int _dailyCapacityHours = 12;

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  int get dailyCapacityHours => _dailyCapacityHours;

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setDailyCapacityHours(int hours) {
    _dailyCapacityHours = hours;
    notifyListeners();
  }

  /// 보관함에 보관 중인 (시간표에 아직 배치되지 않은) 블록 목록
  List<Task> get storageTasks {
    return _tasks
        .where((t) =>
            t.status == TaskStatus.inStorage ||
            t.placedDate == null ||
            t.startTime == null)
        .toList();
  }

  /// 특정 날짜에 시간표에 배치된 블록 목록
  List<Task> getPlacedTasksForDate(DateTime date) {
    return _tasks.where((t) {
      if (t.placedDate == null || t.startTime == null) return false;
      return t.placedDate!.year == date.year &&
          t.placedDate!.month == date.month &&
          t.placedDate!.day == date.day;
    }).toList();
  }

  /// 캘린더용: 특정 날짜에 배치되었거나 해당 날짜 범위에 포함되는 일정 목록
  List<Task> getTasksForCalendarDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    return _tasks.where((t) {
      if (t.placedDate != null) {
        final p =
            DateTime(t.placedDate!.year, t.placedDate!.month, t.placedDate!.day);
        if (p == target) return true;
      }
      final s = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
      final e = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
      return !target.isBefore(s) && !target.isAfter(e);
    }).toList();
  }

  /// 특정 날짜의 총 배치된 시간(분)
  int getTotalPlacedMinutesForDate(DateTime date) {
    final placed = getPlacedTasksForDate(date);
    return placed.fold<int>(0, (sum, t) => sum + t.durationMin);
  }

  /// 하루 가용 시간(기본 12시간) 초과 여부
  bool isOverCapacity(DateTime date) {
    return getTotalPlacedMinutesForDate(date) > (_dailyCapacityHours * 60);
  }

  /// 특정 날짜의 블록 간 시간 겹침(Conflict) 검사
  /// 겹치는 태스크들의 ID Set 반환
  Set<String> getConflictingTaskIdsForDate(DateTime date) {
    final placed = getPlacedTasksForDate(date);
    final Set<String> conflictingIds = {};

    // 30분 단위 슬롯 (06:00 ~ 24:00 -> 36슬롯)
    // 각 슬롯을 점유하고 있는 태스크 ID 목록 매핑
    final Map<int, List<String>> slotOccupancy = {};

    for (final task in placed) {
      if (task.startTime == null) continue;
      final parts = task.startTime!.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final startSlot = (hour * 60 + minute) ~/ 30;
      final slotCount = task.slotCount;

      for (int i = 0; i < slotCount; i++) {
        final slot = startSlot + i;
        slotOccupancy.putIfAbsent(slot, () => []).add(task.id);
      }
    }

    // 2개 이상의 태스크가 점유한 슬롯이 있다면 해당 태스크들을 겹침으로 등록
    for (final entry in slotOccupancy.entries) {
      if (entry.value.length > 1) {
        conflictingIds.addAll(entry.value);
      }
    }

    return conflictingIds;
  }

  /// 타임라인용: 완료된 일정 목록 (최신순 정렬)
  List<Task> get completedTasks {
    final list = _tasks.where((t) => t.status == TaskStatus.completed).toList();
    list.sort((a, b) =>
        (b.completedAt ?? DateTime.now()).compareTo(a.completedAt ?? DateTime.now()));
    return list;
  }

  /// 타임라인용: 전체 일정 (과거순/최신순)
  List<Task> get allHistoryTasks {
    final list = List<Task>.from(_tasks);
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  /// 총 목표 달성 개수
  int get totalCompletedCount =>
      _tasks.where((t) => t.status == TaskStatus.completed).length;

  /// 달성률 (%)
  double get achievementRate {
    if (_tasks.isEmpty) return 0.0;
    return (totalCompletedCount / _tasks.length) * 100;
  }

  /// 사용자 일정 전체 불러오기
  Future<void> loadTasks(String userId, {bool seedIfEmpty = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks(userId, seedIfEmpty: seedIfEmpty);
    } catch (e) {
      _errorMessage = '일정을 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 일정 추가 (명세서 4-3)
  Future<bool> createTask(String userId, Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.saveTask(userId, task);
      if (success) {
        _tasks.add(task);
      }
      return success;
    } catch (e) {
      _errorMessage = '일정을 생성하지 못했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 일정 수정
  Future<bool> updateTask(String userId, Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.saveTask(userId, task);
      if (success) {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index >= 0) {
          _tasks[index] = task;
        }
      }
      return success;
    } catch (e) {
      _errorMessage = '일정을 수정하지 못했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 일정 삭제
  Future<bool> deleteTask(String userId, String taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.deleteTask(userId, taskId);
      if (success) {
        _tasks.removeWhere((t) => t.id == taskId);
        await NotificationService.instance.cancelNotification(taskId);
      }
      return success;
    } catch (e) {
      _errorMessage = '일정을 삭제하지 못했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 블록을 시간표에 배치 (명세서 4-4)
  Future<bool> placeTask({
    required String userId,
    required String taskId,
    required DateTime placedDate,
    required String startTime,
  }) async {
    try {
      final success = await _repository.placeTask(
        userId: userId,
        taskId: taskId,
        placedDate: placedDate,
        startTime: startTime,
      );
      if (success) {
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index >= 0) {
          _tasks[index] = _tasks[index].copyWith(
            placedDate: placedDate,
            startTime: startTime,
            status: TaskStatus.placed,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = '블록을 시간표에 배치하지 못했습니다: $e';
      return false;
    }
  }

  /// 시간표의 블록을 보관함으로 회수 (배치 취소)
  Future<bool> unplaceTask({
    required String userId,
    required String taskId,
  }) async {
    try {
      final success = await _repository.unplaceTask(
        userId: userId,
        taskId: taskId,
      );
      if (success) {
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index >= 0) {
          _tasks[index] = _tasks[index].copyWith(
            clearPlacement: true,
            status: TaskStatus.inStorage,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = '블록을 보관함으로 회수하지 못했습니다: $e';
      return false;
    }
  }

  /// 로그아웃 등 사용자 전환 시 메모리 상태 초기화
  void clear() {
    _tasks = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// 일정 수행 및 사진 인증 완료
  Future<bool> completeTask({
    required String userId,
    required String taskId,
    required String proofImagePath,
  }) async {
    try {
      final success = await _repository.completeTask(
        userId: userId,
        taskId: taskId,
        proofImagePath: proofImagePath,
      );
      if (success) {
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index >= 0) {
          _tasks[index] = _tasks[index].copyWith(
            status: TaskStatus.completed,
            proofImagePath: proofImagePath,
            completedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = '인증 처리에 실패했습니다: $e';
      return false;
    }
  }
}
