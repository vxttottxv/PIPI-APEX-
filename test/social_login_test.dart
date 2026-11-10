import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lowercase_with_underscores/providers/auth_provider.dart';
import 'package:lowercase_with_underscores/providers/character_provider.dart';
import 'package:lowercase_with_underscores/repositories/auth_repository.dart';
import 'package:lowercase_with_underscores/screens/login_screen.dart';
import 'package:lowercase_with_underscores/widgets/social_login_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestLoginWidget({AuthProvider? authProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProvider<CharacterProvider>(
          create: (_) => CharacterProvider(),
        ),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('SocialLoginButton Unit Widget Tests', () {
    testWidgets('renders Kakao button with correct styling and text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              type: SocialLoginType.kakao,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('카카오 로그인'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is KakaoLogoPainter),
        findsOneWidget,
      );
    });

    testWidgets('renders Google button with correct styling and text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              type: SocialLoginType.google,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Google로 로그인'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is GoogleLogoPainter),
        findsOneWidget,
      );
    });

    testWidgets('shows loading spinner when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              type: SocialLoginType.kakao,
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('카카오 로그인'), findsNothing);
    });
  });

  group('LoginScreen Social Login Tests', () {
    testWidgets('displays both Kakao and Google login buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestLoginWidget());
      await tester.pumpAndSettle();

      // 간편 로그인 구분선 및 버튼 노출 확인
      expect(find.text('또는 SNS 간편 로그인'), findsOneWidget);
      expect(find.text('카카오 로그인'), findsOneWidget);
      expect(find.text('Google로 로그인'), findsOneWidget);
      expect(find.byType(SocialLoginButton), findsNWidgets(2));
    });

    testWidgets('tapping Kakao button opens consent dialog and logs in per account', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepository = AuthRepository();
      final authProvider = AuthProvider(authRepository: authRepository);

      await tester.pumpWidget(buildTestLoginWidget(authProvider: authProvider));
      await tester.pumpAndSettle();

      final kakaoButton = find.widgetWithText(SocialLoginButton, '카카오 로그인');
      expect(kakaoButton, findsOneWidget);

      await tester.ensureVisible(kakaoButton);
      await tester.tap(kakaoButton);
      await tester.pumpAndSettle();

      // 바로 로그인되지 않고 카카오 계정 로그인/동의 창이 먼저 열려야 함
      expect(authProvider.isAuthenticated, isFalse);
      expect(find.text('카카오계정으로 로그인'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).last, 'demo@kakao.com');
      await tester.tap(find.text('동의하고 계속하기'));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 입력한 카카오 계정별로 분리 인증 성공 여부 확인
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.id, equals('kakao_demo@kakao.com'));
    });

    testWidgets('tapping Google button opens consent dialog and logs in per account', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepository = AuthRepository();
      final authProvider = AuthProvider(authRepository: authRepository);

      await tester.pumpWidget(buildTestLoginWidget(authProvider: authProvider));
      await tester.pumpAndSettle();

      final googleButton = find.widgetWithText(SocialLoginButton, 'Google로 로그인');
      expect(googleButton, findsOneWidget);

      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      // 바로 로그인되지 않고 Google 계정 선택/동의 창이 먼저 열려야 함
      expect(authProvider.isAuthenticated, isFalse);
      expect(find.text('Google 계정으로 로그인'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).last, 'demo@gmail.com');
      await tester.tap(find.text('계정으로 계속하기'));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 입력한 구글 계정별로 분리 인증 성공 여부 확인
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.id, equals('google_demo@gmail.com'));
    });

    testWidgets('cancelling social login dialog does not authenticate', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authRepository = AuthRepository();
      final authProvider = AuthProvider(authRepository: authRepository);

      await tester.pumpWidget(buildTestLoginWidget(authProvider: authProvider));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SocialLoginButton, '카카오 로그인'));
      await tester.pumpAndSettle();
      expect(find.text('카카오계정으로 로그인'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
    });
  });
}
