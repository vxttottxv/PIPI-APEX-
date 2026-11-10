import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lowercase_with_underscores/models/character.dart';
import 'package:lowercase_with_underscores/models/task.dart';
import 'package:lowercase_with_underscores/providers/auth_provider.dart';
import 'package:lowercase_with_underscores/providers/character_provider.dart';
import 'package:lowercase_with_underscores/providers/task_provider.dart';
import 'package:lowercase_with_underscores/repositories/auth_repository.dart';
import 'package:lowercase_with_underscores/repositories/character_repository.dart';
import 'package:lowercase_with_underscores/repositories/task_repository.dart';
import 'package:lowercase_with_underscores/screens/calendar_screen.dart';
import 'package:lowercase_with_underscores/screens/home_screen.dart';
import 'package:lowercase_with_underscores/screens/timeline_screen.dart';
import 'package:lowercase_with_underscores/services/notification_service.dart';
import 'package:lowercase_with_underscores/widgets/pixel_animal_view.dart';
import 'package:lowercase_with_underscores/widgets/pixel_ui_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'pipi_registered_user_ids': ['test_user'],
      'pipi_user_data_test_user':
          '{"id":"test_user","passwordHash":"5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"}',
      'user_test_user_character_data':
          '{"type":"cat","color":"#FFFFFF","name":"눈송이","level":1,"exp":0,"stage":"baby","intimacy":50,"coins":100,"snacks":3,"ownedItems":[],"equippedItems":[],"lastVisit":"2026-11-08T12:00:00.000"}',
    });
  });

  Future<Widget> createTestApp({required Widget home}) async {
    final authRepo = AuthRepository();
    final charRepo = CharacterRepository();
    final taskRepo = TaskRepository();

    final authProvider = AuthProvider(authRepository: authRepo);
    final charProvider = CharacterProvider(characterRepository: charRepo);
    final taskProvider = TaskProvider(repository: taskRepo);

    await authProvider.login(id: 'test_user', password: 'password');
    await charProvider.loadCharacter('test_user');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CharacterProvider>.value(value: charProvider),
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
      ],
      child: MaterialApp(
        home: home,
      ),
    );
  }

  group('CalendarScreen Tests', () {
    testWidgets('renders calendar header, month navigator, and week days',
        (tester) async {
      final app = await createTestApp(
        home: CalendarScreen(
          initialDate: DateTime(2026, 11, 8),
        ),
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // 헤더 및 월 네비게이터 검증
      expect(find.text('캘린더 보기'), findsOneWidget);
      expect(find.text('2026년 11월'), findsOneWidget);

      // 요일 헤더 검증
      expect(find.text('일'), findsOneWidget);
      expect(find.text('월'), findsOneWidget);
      expect(find.text('화'), findsOneWidget);
      expect(find.text('수'), findsOneWidget);
      expect(find.text('목'), findsOneWidget);
      expect(find.text('금'), findsOneWidget);
      expect(find.text('토'), findsOneWidget);

      // 범례 검증
      expect(find.textContaining('일정이 있는 날'), findsOneWidget);
      expect(find.textContaining('공부/집중'), findsOneWidget);
      expect(find.textContaining('운동'), findsOneWidget);
      expect(find.textContaining('건강관리'), findsOneWidget);

      // 기본 상태에서는 샘플 데이터 없이 비어있음 검증
      expect(find.text('11/08 오늘의 일정'), findsOneWidget);
      expect(find.text('0개'), findsOneWidget);
      expect(find.text('이 날짜에 등록된 일정이 없습니다.'), findsOneWidget);
    });

    testWidgets('displays only user-created tasks on calendar', (tester) async {
      final authRepo = AuthRepository();
      final charRepo = CharacterRepository();
      final taskRepo = TaskRepository();
      final authProvider = AuthProvider(authRepository: authRepo);
      final charProvider = CharacterProvider(characterRepository: charRepo);
      final taskProvider = TaskProvider(repository: taskRepo);

      await authProvider.login(id: 'test_user', password: 'password');
      await charProvider.loadCharacter('test_user');
      await taskProvider.createTask(
        'test_user',
        Task(
          id: 'custom_1',
          title: '내 일정 테스트',
          goal: '',
          durationMin: 30,
          startDate: DateTime(2026, 11, 8),
          endDate: DateTime(2026, 11, 8),
          placedDate: DateTime(2026, 11, 8),
          startTime: '17:00',
          category: TaskCategory.personal,
          status: TaskStatus.placed,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<CharacterProvider>.value(value: charProvider),
            ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: CalendarScreen(initialDate: DateTime(2026, 11, 8)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1개'), findsOneWidget);
      expect(find.text('내 일정 테스트'), findsOneWidget);
      expect(find.text('오후 05:00'), findsOneWidget);
    });

    testWidgets('changes month when chevron buttons are tapped',
        (tester) async {
      final app = await createTestApp(
        home: CalendarScreen(
          initialDate: DateTime(2026, 11, 8),
        ),
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('2026년 11월'), findsOneWidget);

      // 다음 달 클릭 -> 2026년 12월
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('2026년 12월'), findsOneWidget);

      // 이전 달 2회 클릭 -> 2026년 10월
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      expect(find.text('2026년 10월'), findsOneWidget);
    });
  });

  group('HomeScreen Speech Bubble Menu Tests', () {
    testWidgets('tapping + toggles speech bubble popup menu and options',
        (tester) async {
      final app = await createTestApp(home: const HomeScreen());
      await tester.pumpWidget(app);
      // HomeScreen has CharacterView animation, use pump instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

      // 처음에는 말풍선 메뉴가 닫혀있음
      expect(find.byType(PixelSpeechBubbleMenu), findsNothing);

      // 하단 '+' 버튼 탭
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pump(const Duration(milliseconds: 100));

      // 말풍선 메뉴 열림 및 3개 메뉴 확인
      expect(find.byType(PixelSpeechBubbleMenu), findsOneWidget);
      expect(find.text('일정 추가하기'), findsOneWidget);
      expect(find.text('캘린더 보기'), findsOneWidget);
      expect(find.text('타임라인 보기'), findsOneWidget);

      // 닫기 아이콘(x)으로 변경 확인
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // 닫기 아이콘 탭하면 다시 닫힘
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PixelSpeechBubbleMenu), findsNothing);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('tapping 캘린더 보기 navigates to CalendarScreen',
        (tester) async {
      final app = await createTestApp(home: const HomeScreen());
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 100));

      // '+' 버튼 탭하여 말풍선 열기
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pump(const Duration(milliseconds: 100));

      // '캘린더 보기' 탭
      await tester.tap(find.text('캘린더 보기'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      // CalendarScreen 진입 검증
      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(find.text('캘린더 보기'), findsWidgets);
    });
  });

  group('PixelButton Press Animation Tests', () {
    testWidgets('PixelButton depresses downward on press down and pops back up',
        (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PixelButton(
                text: '눌림 테스트',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.text('눌림 테스트');
      final initialCenter = tester.getCenter(buttonFinder);

      // 누르고 있는 상태 (press down)
      final gesture = await tester.startGesture(initialCenter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final pressedCenter = tester.getCenter(buttonFinder);
      expect(pressedCenter.dy, greaterThan(initialCenter.dy));

      // 떼기 (release)
      await gesture.up();
      await tester.pumpAndSettle();

      final releasedCenter = tester.getCenter(buttonFinder);
      expect(releasedCenter.dy, equals(initialCenter.dy));
      expect(tapped, isTrue);
    });
  });

  group('TimelineScreen Pixel UI Tests', () {
    testWidgets('renders pixel sky header and summary stats', (tester) async {
      final app = await createTestApp(home: const TimelineScreen());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('타임라인 보기'), findsOneWidget);
      expect(find.text('나의 실천 기록'), findsOneWidget);
      expect(find.text('총 달성 목표'), findsOneWidget);
      expect(find.text('전체 일정'), findsOneWidget);
      expect(find.text('목표 달성률'), findsOneWidget);
    });
  });

  group('PixelAnimalView Dynamic Motion Tests', () {
    testWidgets(
        'changes to different click reactions on tap and triggers idle behavior after 3+ seconds',
        (tester) async {
      final observedBehaviors = <PetBehavior>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PixelAnimalView(
                characterType: CharacterType.cat,
                size: 180,
                enableRoam: true,
                onBehaviorChanged: observedBehaviors.add,
              ),
            ),
          ),
        ),
      );

      // 1. 첫 번째 클릭 -> 클릭 리액션 모션 발동
      await tester.tap(find.byType(PixelAnimalView));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(observedBehaviors, isNotEmpty);
      final firstClickMotion = observedBehaviors.last;
      expect(
        [
          PetBehavior.happyJump,
          PetBehavior.spinTwirl,
          PetBehavior.loveySquish,
          PetBehavior.dashZigzag,
        ],
        contains(firstClickMotion),
      );

      // 2. 두 번째 클릭 -> 이전 모션과 다른 랜덤 클릭 모션으로 전환
      await tester.tap(find.byType(PixelAnimalView));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final secondClickMotion = observedBehaviors.last;
      expect(secondClickMotion, isNot(equals(firstClickMotion)));

      // 3. 액션 종료(1초) 후 아무것도 클릭하지 않고 3.2초 이상 대기 -> 자율 랜덤 모션 발동
      observedBehaviors.clear();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 3200));
      await tester.pump();

      expect(
        observedBehaviors.any((b) => [
              PetBehavior.roamWalk,
              PetBehavior.restSquish,
              PetBehavior.curiousLook,
              PetBehavior.groomOrNap,
              PetBehavior.idle,
            ].contains(b)),
        isTrue,
      );
    });
  });

  group('NotificationService Alarm Tests', () {
    test('schedules and cancels exact time notification cleanly', () async {
      final svc = NotificationService.instance;
      final targetTime = DateTime.now().add(const Duration(minutes: 15));

      await svc.scheduleTaskNotification(
        taskId: 'alarm_test_1',
        taskTitle: '물 마시기',
        characterName: '눈송이',
        taskStartTime: targetTime,
        alertBeforeMin: 0,
      );

      expect(
        svc.scheduledNotifications.any((n) => n.taskId == 'alarm_test_1'),
        isTrue,
      );

      await svc.cancelNotification('alarm_test_1');
      expect(
        svc.scheduledNotifications.any((n) => n.taskId == 'alarm_test_1'),
        isFalse,
      );
    });
  });
}
