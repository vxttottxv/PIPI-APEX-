import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lowercase_with_underscores/main.dart';
import 'package:lowercase_with_underscores/widgets/pipi_logo.dart';
import 'package:lowercase_with_underscores/widgets/custom_button.dart';
import 'package:lowercase_with_underscores/widgets/custom_text_field.dart';
import 'package:lowercase_with_underscores/screens/character_selection_screen.dart';
import 'package:lowercase_with_underscores/screens/home_screen.dart';
import 'package:lowercase_with_underscores/screens/intro_story_screen.dart';
import 'package:lowercase_with_underscores/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash -> Login -> SignUp -> CharacterSelection -> HomeScreen flow test', (WidgetTester tester) async {
    // 1. 앱 시작 (충분한 뷰포트 크기 설정)
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const PipiApp());

    // 스플래시 화면에 로고가 표시되는지 확인
    expect(find.byType(PipiLogo), findsOneWidget);

    // 1.5초 스플래시 시간 대기 후 로그인 화면 전환
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsWidgets);
    expect(find.text('회원가입'), findsOneWidget);

    // 2. 회원가입 화면으로 이동
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('새 계정 만들기'), findsOneWidget);

    // 3. 회원가입 정보 입력
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(3)); // 아이디, 비밀번호, 비밀번호 확인

    await tester.enterText(textFields.at(0), 'pipi_hero');
    await tester.enterText(textFields.at(1), 'password123');
    await tester.enterText(textFields.at(2), 'password123');

    // 4. 가입 완료 버튼 탭
    final submitButton = find.widgetWithText(CustomButton, '가입 완료하고 시작하기');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);

    // 4-1. 최초 회원가입 시 1회성 인트로 스토리 화면 노출 검증
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(IntroStoryScreen), findsOneWidget);

    // 대사 진행 탭 테스트 후 SKIP 눌러 캐릭터 선택 화면으로 전환
    await tester.tap(find.text('SKIP >>'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // 5. 인트로 완료 후 캐릭터 선택 화면(CharacterSelectionScreen) 노출 확인
    expect(find.byType(IntroStoryScreen), findsNothing);
    expect(find.byType(CharacterSelectionScreen), findsOneWidget);
    expect(find.text('캐릭터 선택'), findsOneWidget);
    expect(find.text('고양이'), findsWidgets);

    // 오른쪽 화살표 버튼 탭하여 '강아지'로 변경
    await tester.tap(find.byIcon(Icons.arrow_right_rounded));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('강아지'), findsWidgets);

    // 하단 픽셀 버튼 '선택하기' 탭
    await tester.tap(find.text('선택하기'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 6. 이름 설정 안내 확인 모달 노출 확인 (레퍼런스 2)
    expect(find.text('이름 설정 안내'), findsOneWidget);
    expect(find.text('한 번 정하면 변경할 수 없어요!'), findsOneWidget);
    expect(find.text('계속 진행할까요?'), findsOneWidget);

    // 모달 '확인' 탭하여 시작하기
    await tester.tap(find.text('확인'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // 7. 메인 홈 화면(HomeScreen) 진입 확인 (레퍼런스 3)
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('뭉치'), findsWidgets);
    expect(find.text('Lv.1'), findsWidgets);
    expect(find.text('애정도'), findsOneWidget);

    // 8. 캐릭터 상호작용 테스트: 밥 주기
    final feedButton = find.text('밥 주기');
    await tester.tap(feedButton);
    await tester.pump(const Duration(milliseconds: 200));

    // 간식 소모 및 스낵바 노출 확인
    expect(find.textContaining('간식을 주었습니다'), findsOneWidget);

    // 놀아주기 버튼 탭
    final playButton = find.text('놀아주기');
    await tester.tap(playButton);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('놀아주기'), findsWidgets);

    // 9. 로그아웃 수행 (우측 상단 픽셀 메뉴 탭)
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('로그아웃'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('정말 로그아웃 하시겠습니까?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, '로그아웃').last);
    await tester.pumpAndSettle();

    // 로그인 화면 복귀 확인 (캐릭터 선택 창으로 잘못 넘어가지 않는지 검증)
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CharacterSelectionScreen), findsNothing);
    expect(find.text('로그인'), findsWidgets);
  });

  testWidgets('User with existing fixed character directly enters HomeScreen on login', (WidgetTester tester) async {
    // 기존 유저 및 고정된 캐릭터 데이터 모킹
    SharedPreferences.setMockInitialValues({
      'pipi_registered_user_ids': ['existing_user'],
      'pipi_user_data_existing_user': '{"id":"existing_user","passwordHash":"5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"}',
      'user_existing_user_character_data': '{"type":"capybara","color":"#A67B5B","name":"바라","level":3,"exp":40,"stage":"baby","intimacy":70,"coins":250,"snacks":3,"ownedItems":[],"equippedItems":[],"lastVisit":"2026-11-02T12:00:00.000"}',
    });

    await tester.pumpWidget(const PipiApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // 로그인 진행
    final textFields = find.byType(CustomTextField);
    await tester.enterText(find.descendant(of: textFields.at(0), matching: find.byType(TextFormField)), 'existing_user');
    await tester.enterText(find.descendant(of: textFields.at(1), matching: find.byType(TextFormField)), 'password');

    await tester.tap(find.widgetWithText(CustomButton, '로그인하기'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // 캐릭터 선택 창 및 인트로를 건너뛰고 바로 고정된 캐릭터의 홈 화면으로 이동했는지 검증
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(IntroStoryScreen), findsNothing);
    expect(find.byType(CharacterSelectionScreen), findsNothing);
    expect(find.text('바라'), findsWidgets);
    expect(find.text('Lv.3'), findsWidgets);
    expect(find.text('애정도'), findsOneWidget);
  });

  testWidgets('IntroStoryScreen does not show again after being seen once', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'pipi_registered_user_ids': ['seen_user'],
      'pipi_user_data_seen_user': '{"id":"seen_user","passwordHash":"5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"}',
      'pipi_intro_seen_seen_user': true,
    });

    await tester.pumpWidget(const PipiApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final textFields = find.byType(CustomTextField);
    await tester.enterText(find.descendant(of: textFields.at(0), matching: find.byType(TextFormField)), 'seen_user');
    await tester.enterText(find.descendant(of: textFields.at(1), matching: find.byType(TextFormField)), 'password');

    await tester.tap(find.widgetWithText(CustomButton, '로그인하기'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // 이미 인트로를 본 유저는 인트로 없이 바로 캐릭터 선택 화면으로 진입
    expect(find.byType(IntroStoryScreen), findsNothing);
    expect(find.byType(CharacterSelectionScreen), findsOneWidget);
  });

  testWidgets('IntroStoryScreen adapts cleanly to small phone and wide desktop viewports', (WidgetTester tester) async {
    for (final size in [const Size(375, 667), const Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: IntroStoryScreen(userId: 'responsive_user'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(IntroStoryScreen), findsOneWidget);
      expect(find.text('SKIP >>'), findsOneWidget);
    }
    tester.view.resetPhysicalSize();
  });
}
