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

    testWidgets('tapping Kakao button logs in with kakao_user', (WidgetTester tester) async {
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
      
      // 비동기 처리 및 화면 전환 대기
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 카카오 계정으로 인증 성공 여부 확인
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.id, equals('kakao_user'));
    });

    testWidgets('tapping Google button logs in with google_user', (WidgetTester tester) async {
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

      // 비동기 처리 및 화면 전환 대기
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 구글 계정으로 인증 성공 여부 확인
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.id, equals('google_user'));
    });
  });
}
