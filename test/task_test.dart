import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lowercase_with_underscores/models/task.dart';
import 'package:lowercase_with_underscores/providers/auth_provider.dart';
import 'package:lowercase_with_underscores/providers/character_provider.dart';
import 'package:lowercase_with_underscores/providers/task_provider.dart';
import 'package:lowercase_with_underscores/repositories/auth_repository.dart';
import 'package:lowercase_with_underscores/repositories/character_repository.dart';
import 'package:lowercase_with_underscores/repositories/task_repository.dart';
import 'package:lowercase_with_underscores/screens/task_edit_screen.dart';
import 'package:lowercase_with_underscores/screens/timeline_screen.dart';
import 'package:lowercase_with_underscores/screens/timetable_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task Model & Repository Tests', () {
    test('Task model toJson and fromJson work correctly', () {
      final task = Task(
        id: 'task_1',
        title: '알고리즘 문제 풀기',
        durationMin: 90,
        goal: '3문제 완풀',
        startDate: DateTime(2026, 11, 8),
        endDate: DateTime(2026, 11, 30),
        alertBefore: 10,
        priority: TaskPriority.high,
        category: TaskCategory.study,
        placedDate: DateTime(2026, 11, 8),
        startTime: '09:00',
        status: TaskStatus.placed,
      );

      final json = task.toJson();
      final restored = Task.fromJson(json);

      expect(restored.id, 'task_1');
      expect(restored.title, '알고리즘 문제 풀기');
      expect(restored.durationMin, 90);
      expect(restored.slotCount, 3);
      expect(restored.durationString, '1시간 30분');
      expect(restored.endTime, '10:30');
      expect(restored.priority, TaskPriority.high);
      expect(restored.category, TaskCategory.study);
    });

    test('TaskRepository performs CRUD and placement correctly', () async {
      final repo = TaskRepository();
      const userId = 'user_test';

      final task = Task(
        id: 't_1',
        title: '헬스 운동',
        durationMin: 60,
        goal: '하체 루틴',
        startDate: DateTime(2026, 11, 8),
        endDate: DateTime(2026, 11, 30),
      );

      // 1. 저장
      final saved = await repo.saveTask(userId, task);
      expect(saved, isTrue);

      // 2. 조회
      var tasks = await repo.getTasks(userId);
      expect(tasks.length, 1);
      expect(tasks.first.title, '헬스 운동');

      // 3. 시간표 배치
      final placed = await repo.placeTask(
        userId: userId,
        taskId: 't_1',
        placedDate: DateTime(2026, 11, 8),
        startTime: '14:00',
      );
      expect(placed, isTrue);

      tasks = await repo.getTasks(userId);
      expect(tasks.first.status, TaskStatus.placed);
      expect(tasks.first.startTime, '14:00');

      // 4. 보관함 회수
      final unplaced = await repo.unplaceTask(userId: userId, taskId: 't_1');
      expect(unplaced, isTrue);

      tasks = await repo.getTasks(userId);
      expect(tasks.first.status, TaskStatus.inStorage);
      expect(tasks.first.startTime, isNull);

      // 5. 완료 처리
      final completed = await repo.completeTask(
        userId: userId,
        taskId: 't_1',
        proofImagePath: 'mock_proof_img',
      );
      expect(completed, isTrue);

      tasks = await repo.getTasks(userId);
      expect(tasks.first.status, TaskStatus.completed);
      expect(tasks.first.proofImagePath, 'mock_proof_img');
    });

    test('TaskProvider detects overlaps and daily capacity overage', () async {
      final repo = TaskRepository();
      final provider = TaskProvider(repository: repo);
      const userId = 'user_calc';

      final today = DateTime(2026, 11, 8);

      final taskA = Task(
        id: 'a',
        title: 'Task A',
        durationMin: 120, // 2시간 (09:00 ~ 11:00)
        goal: '',
        startDate: today,
        endDate: today,
        placedDate: today,
        startTime: '09:00',
        status: TaskStatus.placed,
      );

      final taskB = Task(
        id: 'b',
        title: 'Task B',
        durationMin: 60, // 1시간 (10:00 ~ 11:00, A와 겹침!)
        goal: '',
        startDate: today,
        endDate: today,
        placedDate: today,
        startTime: '10:00',
        status: TaskStatus.placed,
      );

      await provider.createTask(userId, taskA);
      await provider.createTask(userId, taskB);

      // 겹침 검사
      final conflicts = provider.getConflictingTaskIdsForDate(today);
      expect(conflicts.contains('a'), isTrue);
      expect(conflicts.contains('b'), isTrue);

      // 가용 시간 초과 검사 (기본 12시간)
      expect(provider.isOverCapacity(today), isFalse);

      // 12시간 초과 설정 시뮬레이션
      provider.setDailyCapacityHours(2); // 가용 시간 2시간으로 축소
      expect(provider.isOverCapacity(today), isTrue); // 총 3시간이므로 초과!
    });
  });

  group('Frontend Screens Widget Tests', () {
    Widget createTestApp(Widget child) {
      final authRepo = AuthRepository();
      final charRepo = CharacterRepository();
      final taskRepo = TaskRepository();

      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => AuthProvider(authRepository: authRepo)),
          ChangeNotifierProvider(
              create: (_) =>
                  CharacterProvider(characterRepository: charRepo)),
          ChangeNotifierProvider(
              create: (_) => TaskProvider(repository: taskRepo)),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('TaskEditScreen renders form fields correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const TaskEditScreen()));
      await tester.pumpAndSettle();

      expect(find.text('일정 추가하기'), findsOneWidget);
      expect(find.text('목표이름'), findsOneWidget);
      expect(find.text('기간'), findsOneWidget);
      expect(find.text('알림시간'), findsOneWidget);
      expect(find.text('일정추가'), findsOneWidget);
    });

    testWidgets('TimetableScreen renders time grid and storage tray',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const TimetableScreen()));
      await tester.pumpAndSettle();

      expect(find.text('실천 시간표'), findsOneWidget);
      expect(find.text('06:00'), findsOneWidget);
      expect(find.textContaining('블록 보관함'), findsOneWidget);
    });

    testWidgets('TimelineScreen renders pixel sky header and statistics',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const TimelineScreen()));
      await tester.pumpAndSettle();

      expect(find.text('타임라인 보기'), findsOneWidget);
      expect(find.text('총 달성 목표'), findsOneWidget);
      expect(find.text('목표 달성률'), findsOneWidget);
    });
  });
}
