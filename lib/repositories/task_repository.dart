import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_client.dart';

/// 일정(Task) 데이터 접근 저장소
///
/// 명세서 2 개발 원칙:
/// - 모든 데이터 처리는 `repositories/` 클래스로만 하여 나중에 백엔드 API로 교체하기 쉽게 설계
/// - 사용자 ID별 분리 저장 (`user_{userId}_tasks`)
class TaskRepository {
  static const String _tasksKeyPrefix = 'user_tasks_';

  String _getKey(String userId) => '$_tasksKeyPrefix$userId';

  /// 특정 사용자의 모든 일정 목록 조회 (직접 추가한 실제 일정만 반환)
  Future<List<Task>> getTasks(String userId, {bool seedIfEmpty = false}) async {
    final prefs = await SharedPreferences.getInstance();

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final apiRes = await ApiClient.instance.request('GET', '/api/tasks');
        if (apiRes != null && apiRes['tasks'] is List) {
          final remoteTasks = (apiRes['tasks'] as List)
              .map((item) => Task.fromJson(item as Map<String, dynamic>))
              .where((t) => !t.id.startsWith('sample_'))
              .toList();
          await prefs.setString(
            _getKey(userId),
            jsonEncode(remoteTasks.map((t) => t.toJson()).toList()),
          );
          return remoteTasks;
        }
      } catch (_) {}
    }

    final rawData = prefs.getString(_getKey(userId));
    if (rawData == null || rawData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(rawData);
      final tasks = jsonList
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .where((t) => !t.id.startsWith('sample_'))
          .toList();
      return tasks;
    } catch (_) {
      return [];
    }
  }

  static List<Task> generateSampleTasks() {
    return [
      Task(
        id: 'sample_1108_walk',
        title: '산책 30분',
        durationMin: 30,
        goal: '반려동물과 상쾌한 산책',
        startDate: DateTime(2026, 11, 8),
        endDate: DateTime(2026, 11, 8),
        placedDate: DateTime(2026, 11, 8),
        startTime: '17:00',
        category: TaskCategory.activity,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1108_water',
        title: '물 마시기',
        durationMin: 30,
        goal: '수분 보충 500ml',
        startDate: DateTime(2026, 11, 8),
        endDate: DateTime(2026, 11, 8),
        placedDate: DateTime(2026, 11, 8),
        startTime: '18:00',
        category: TaskCategory.personal,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1108_stretch',
        title: '스트레칭',
        durationMin: 30,
        goal: '저녁 피로 회복 스트레칭',
        startDate: DateTime(2026, 11, 8),
        endDate: DateTime(2026, 11, 8),
        placedDate: DateTime(2026, 11, 8),
        startTime: '21:00',
        category: TaskCategory.exercise,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1102',
        title: '주간 계획 세우기',
        durationMin: 30,
        goal: '',
        startDate: DateTime(2026, 11, 2),
        endDate: DateTime(2026, 11, 2),
        placedDate: DateTime(2026, 11, 2),
        startTime: '09:00',
        category: TaskCategory.personal,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1106',
        title: '근력 운동',
        durationMin: 60,
        goal: '',
        startDate: DateTime(2026, 11, 6),
        endDate: DateTime(2026, 11, 6),
        placedDate: DateTime(2026, 11, 6),
        startTime: '19:00',
        category: TaskCategory.exercise,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1110',
        title: '일정 점검',
        durationMin: 30,
        goal: '',
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 10),
        placedDate: DateTime(2026, 11, 10),
        startTime: '14:00',
        category: TaskCategory.personal,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1112',
        title: '공부 / 집중',
        durationMin: 60,
        goal: '',
        startDate: DateTime(2026, 11, 12),
        endDate: DateTime(2026, 11, 12),
        placedDate: DateTime(2026, 11, 12),
        startTime: '20:00',
        category: TaskCategory.study,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1118',
        title: '중간 회의',
        durationMin: 30,
        goal: '',
        startDate: DateTime(2026, 11, 18),
        endDate: DateTime(2026, 11, 18),
        placedDate: DateTime(2026, 11, 18),
        startTime: '15:00',
        category: TaskCategory.personal,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1120',
        title: '수분 섭취',
        durationMin: 30,
        goal: '',
        startDate: DateTime(2026, 11, 20),
        endDate: DateTime(2026, 11, 20),
        placedDate: DateTime(2026, 11, 20),
        startTime: '10:00',
        category: TaskCategory.personal,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1124',
        title: '홈 트레이닝',
        durationMin: 60,
        goal: '',
        startDate: DateTime(2026, 11, 24),
        endDate: DateTime(2026, 11, 24),
        placedDate: DateTime(2026, 11, 24),
        startTime: '19:30',
        category: TaskCategory.exercise,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1127',
        title: '자격증 복습',
        durationMin: 30,
        goal: '',
        startDate: DateTime(2026, 11, 27),
        endDate: DateTime(2026, 11, 27),
        placedDate: DateTime(2026, 11, 27),
        startTime: '21:00',
        category: TaskCategory.personal,
        status: TaskStatus.placed,
      ),
      Task(
        id: 'sample_1130',
        title: '반려동물 케어',
        durationMin: 60,
        goal: '',
        startDate: DateTime(2026, 11, 30),
        endDate: DateTime(2026, 11, 30),
        placedDate: DateTime(2026, 11, 30),
        startTime: '16:00',
        category: TaskCategory.activity,
        status: TaskStatus.placed,
      ),
    ];
  }

  /// 일정 추가 또는 수정
  Future<bool> saveTask(String userId, Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTasks = await getTasks(userId);

    final existingIndex = currentTasks.indexWhere((t) => t.id == task.id);
    if (existingIndex >= 0) {
      currentTasks[existingIndex] = task;
    } else {
      currentTasks.add(task);
    }

    final rawJson = jsonEncode(currentTasks.map((t) => t.toJson()).toList());
    final savedLocal = await prefs.setString(_getKey(userId), rawJson);

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        if (existingIndex >= 0) {
          await ApiClient.instance
              .request('PUT', '/api/tasks/${task.id}', body: task.toJson());
        } else {
          await ApiClient.instance
              .request('POST', '/api/tasks', body: task.toJson());
        }
      } catch (_) {}
    }
    return savedLocal;
  }

  /// 일정 삭제
  Future<bool> deleteTask(String userId, String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTasks = await getTasks(userId);

    currentTasks.removeWhere((t) => t.id == taskId);

    final rawJson = jsonEncode(currentTasks.map((t) => t.toJson()).toList());
    final savedLocal = await prefs.setString(_getKey(userId), rawJson);

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.instance.request('DELETE', '/api/tasks/$taskId');
      } catch (_) {}
    }
    return savedLocal;
  }

  /// 시간표에 블록 배치
  Future<bool> placeTask({
    required String userId,
    required String taskId,
    required DateTime placedDate,
    required String startTime,
  }) async {
    final currentTasks = await getTasks(userId);
    final index = currentTasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return false;

    currentTasks[index] = currentTasks[index].copyWith(
      placedDate: placedDate,
      startTime: startTime,
      status: TaskStatus.placed,
    );

    final prefs = await SharedPreferences.getInstance();
    final rawJson = jsonEncode(currentTasks.map((t) => t.toJson()).toList());
    final savedLocal = await prefs.setString(_getKey(userId), rawJson);

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.instance.request(
          'PUT',
          '/api/tasks/$taskId',
          body: currentTasks[index].toJson(),
        );
      } catch (_) {}
    }
    return savedLocal;
  }

  /// 시간표에서 보관함으로 회수 (배치 취소)
  Future<bool> unplaceTask({
    required String userId,
    required String taskId,
  }) async {
    final currentTasks = await getTasks(userId);
    final index = currentTasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return false;

    currentTasks[index] = currentTasks[index].copyWith(
      clearPlacement: true,
      status: TaskStatus.inStorage,
    );

    final prefs = await SharedPreferences.getInstance();
    final rawJson = jsonEncode(currentTasks.map((t) => t.toJson()).toList());
    final savedLocal = await prefs.setString(_getKey(userId), rawJson);

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.instance.request(
          'PUT',
          '/api/tasks/$taskId',
          body: currentTasks[index].toJson(),
        );
      } catch (_) {}
    }
    return savedLocal;
  }

  /// 일정 수행 및 사진 인증 완료 처리
  Future<bool> completeTask({
    required String userId,
    required String taskId,
    required String proofImagePath,
  }) async {
    final currentTasks = await getTasks(userId);
    final index = currentTasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return false;

    currentTasks[index] = currentTasks[index].copyWith(
      status: TaskStatus.completed,
      proofImagePath: proofImagePath,
      completedAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final rawJson = jsonEncode(currentTasks.map((t) => t.toJson()).toList());
    final savedLocal = await prefs.setString(_getKey(userId), rawJson);

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.instance.request(
          'POST',
          '/api/tasks/$taskId/complete',
          body: {'proofImagePath': proofImagePath},
        );
      } catch (_) {}
    }
    return savedLocal;
  }

  /// 전체 일정 초기화 (테스트용)
  Future<bool> clearAllTasks(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_getKey(userId));
  }
}
