import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lowercase_with_underscores/models/user.dart';
import 'package:lowercase_with_underscores/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Model Tests', () {
    test('toJson and fromJson correctly serialize and deserialize', () {
      final user = User(
        id: 'test_user',
        passwordHash: 'dummy_hash_123',
        createdAt: DateTime(2026, 1, 1),
      );

      final json = user.toJson();
      final fromJsonUser = User.fromJson(json);

      expect(fromJsonUser.id, equals('test_user'));
      expect(fromJsonUser.passwordHash, equals('dummy_hash_123'));
      expect(fromJsonUser.createdAt, equals(DateTime(2026, 1, 1)));
    });
  });

  group('AuthRepository Tests', () {
    late AuthRepository authRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authRepository = AuthRepository();
    });

    test('hashPassword converts plaintext into SHA-256 hex string', () {
      final hash1 = authRepository.hashPassword('pipi1234');
      final hash2 = authRepository.hashPassword('pipi1234');
      final hashDiff = authRepository.hashPassword('different_password');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals('pipi1234'))); // 절대 평문과 일치하지 않아야 함
      expect(hash1, isNot(equals(hashDiff)));
      expect(hash1.length, equals(64)); // SHA-256 출력 길이는 64자리 16진수
    });

    test('signUp creates user and persists session', () async {
      final user = await authRepository.signUp(
        id: 'newbie',
        password: 'password123',
      );

      expect(user.id, equals('newbie'));
      expect(user.passwordHash, isNot(equals('password123')));

      // 세션 유지 확인
      final currentUser = await authRepository.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser?.id, equals('newbie'));
    });

    test('signUp rejects duplicate user ID', () async {
      await authRepository.signUp(
        id: 'duplicate_user',
        password: 'password123',
      );

      expect(
        () => authRepository.signUp(
          id: 'duplicate_user',
          password: 'another_password',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('login succeeds with correct password', () async {
      await authRepository.signUp(
        id: 'login_tester',
        password: 'secret_password',
      );

      // 로그아웃 후 다시 로그인 시도
      await authRepository.logout();
      expect(await authRepository.getCurrentUser(), isNull);

      final user = await authRepository.login(
        id: 'login_tester',
        password: 'secret_password',
      );

      expect(user.id, equals('login_tester'));
      expect(await authRepository.getCurrentUser(), isNotNull);
    });

    test('login fails with wrong password', () async {
      await authRepository.signUp(
        id: 'secure_user',
        password: 'correct_password',
      );

      expect(
        () => authRepository.login(
          id: 'secure_user',
          password: 'wrong_password',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('getUserStorageKey generates isolated key per user ID', () {
      final keyUserA = AuthRepository.getUserStorageKey('alice', 'character');
      final keyUserB = AuthRepository.getUserStorageKey('bob', 'character');

      expect(keyUserA, equals('user_alice_character'));
      expect(keyUserB, equals('user_bob_character'));
      expect(keyUserA, isNot(equals(keyUserB)));
    });

    test('loginWithSocial kakao and google creates users and keeps session', () async {
      // 1. 카카오 로그인 테스트
      final kakaoUser = await authRepository.loginWithSocial(
        provider: SocialProvider.kakao,
      );
      expect(kakaoUser.id, equals('kakao_user'));

      var sessionUser = await authRepository.getCurrentUser();
      expect(sessionUser?.id, equals('kakao_user'));

      // 로그아웃
      await authRepository.logout();
      expect(await authRepository.getCurrentUser(), isNull);

      // 2. 구글 로그인 테스트
      final googleUser = await authRepository.loginWithSocial(
        provider: SocialProvider.google,
      );
      expect(googleUser.id, equals('google_user'));

      sessionUser = await authRepository.getCurrentUser();
      expect(sessionUser?.id, equals('google_user'));

      // 3. 다시 카카오 로그인 시 기존 계정 정상 유지
      final reKakao = await authRepository.loginWithSocial(
        provider: SocialProvider.kakao,
      );
      expect(reKakao.id, equals('kakao_user'));
      expect(reKakao.createdAt, equals(kakaoUser.createdAt));
    });
  });
}
