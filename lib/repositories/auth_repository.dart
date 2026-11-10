import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_client.dart';

/// 인증 과정에서 발생하는 오류를 처리하기 위한 예외 클래스
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// 연동 로그인 지원 소셜 플랫폼 종류
enum SocialProvider {
  /// 카카오 계정 연동 로그인
  kakao,

  /// 구글 계정 연동 로그인
  google;

  /// 플랫폼 한국어 표시명
  String get displayName {
    switch (this) {
      case SocialProvider.kakao:
        return '카카오';
      case SocialProvider.google:
        return 'Google';
    }
  }
}

/// 회원가입, 로그인, 세션 유지 등 사용자 인증 데이터 처리를 전담하는 리포지토리
///
/// 명세서 개발 원칙:
/// 1. 모든 데이터 처리는 `repositories/` 클래스로만 하여 추후 백엔드 API로 교체하기 쉽게 설계
/// 2. 비밀번호는 SHA-256 해시로 저장 (평문 저장 금지)
/// 3. 모든 데이터를 사용자 ID 기준으로 분리 저장하여 타 사용자 데이터 접근 차단
class AuthRepository {
  // SharedPreferences 저장 키 상수
  static const String _currentUserIdKey = 'pipi_current_session_user_id';
  static const String _registeredUserIdsKey = 'pipi_registered_user_ids';
  static const String _userDataPrefix = 'pipi_user_data_';

  /// 사용자 ID별 격리된 데이터 키를 생성하는 유틸리티 메서드
  /// 명세서: "모든 데이터를 사용자 ID 기준으로 분리 저장해 다른 사용자의 데이터에 접근할 수 없게 한다."
  /// 예: 사용자 'alice'의 캐릭터 정보는 'user_alice_character' 키에 저장
  static String getUserStorageKey(String userId, String key) {
    return 'user_${userId}_$key';
  }

  /// 평문 비밀번호를 SHA-256 해시값으로 변환
  /// 
  /// 보안 요구사항: 평문 저장 금지, 암호학적 단방향 해시 적용
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 아이디 중복 여부 확인
  /// 반환값: true (사용 가능), false (이미 존재함)
  Future<bool> isIdAvailable(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final userJsonStr = prefs.getString('$_userDataPrefix$trimmedId');
    return userJsonStr == null;
  }

  /// 회원가입
  /// 
  /// [id]: 사용자 아이디 (공백 제거 후 처리)
  /// [password]: 평문 비밀번호 (SHA-256으로 해싱되어 저장됨)
  /// 
  /// 가입 성공 시 생성된 [User] 객체를 반환하며, 자동으로 로그인 상태가 유지됩니다.
  Future<User> signUp({
    required String id,
    required String password,
  }) async {
    final trimmedId = id.trim();

    // 1. 유효성 검증
    if (trimmedId.isEmpty) {
      throw const AuthException('아이디를 입력해주세요.');
    }
    if (trimmedId.length < 3) {
      throw const AuthException('아이디는 최소 3자 이상이어야 합니다.');
    }
    if (password.isEmpty) {
      throw const AuthException('비밀번호를 입력해주세요.');
    }
    if (password.length < 4) {
      throw const AuthException('비밀번호는 최소 4자 이상이어야 합니다.');
    }

    final prefs = await SharedPreferences.getInstance();

    // 백엔드 API 서버 연동 시도 (실행 중인 경우 DB에 영구 저장 + 토큰 발급)
    try {
      final apiRes = await ApiClient.instance.request(
        'POST',
        '/api/auth/signup',
        body: {'id': trimmedId, 'password': password},
        withAuth: false,
      );
      if (apiRes != null && apiRes['user'] is Map<String, dynamic>) {
        final token = apiRes['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await ApiClient.instance.saveToken(token);
        }
        final userMap = apiRes['user'] as Map<String, dynamic>;
        final apiUser = User.fromJson(userMap);
        await prefs.setString(
            '$_userDataPrefix$trimmedId', jsonEncode(apiUser.toJson()));
        final userIds = prefs.getStringList(_registeredUserIdsKey) ?? [];
        if (!userIds.contains(trimmedId)) {
          userIds.add(trimmedId);
          await prefs.setStringList(_registeredUserIdsKey, userIds);
        }
        await prefs.setString(_currentUserIdKey, trimmedId);
        return apiUser;
      }
    } on ApiHttpException catch (e) {
      throw AuthException(e.message);
    }

    // 2. 오프라인/로컬 폴백: 중복 아이디 검사
    final existingUserStr = prefs.getString('$_userDataPrefix$trimmedId');
    if (existingUserStr != null) {
      throw const AuthException('이미 사용 중인 아이디입니다.');
    }

    // 3. 비밀번호 SHA-256 해싱 및 User 인스턴스 생성
    final passwordHash = hashPassword(password);
    final newUser = User(
      id: trimmedId,
      passwordHash: passwordHash,
      createdAt: DateTime.now(),
    );

    // 4. 사용자 데이터 저장 (ID별 분리 저장)
    final userJson = jsonEncode(newUser.toJson());
    await prefs.setString('$_userDataPrefix$trimmedId', userJson);

    // 5. 등록된 전체 사용자 목록 갱신
    final userIds = prefs.getStringList(_registeredUserIdsKey) ?? [];
    if (!userIds.contains(trimmedId)) {
      userIds.add(trimmedId);
      await prefs.setStringList(_registeredUserIdsKey, userIds);
    }

    // 6. 로그인 상태 유지 (자동 로그인)
    await prefs.setString(_currentUserIdKey, trimmedId);

    return newUser;
  }

  /// 로그인
  /// 
  /// [id]: 사용자 아이디
  /// [password]: 비밀번호
  /// 
  /// 로그인 성공 시 [User] 객체를 반환하고 세션을 유지합니다.
  Future<User> login({
    required String id,
    required String password,
  }) async {
    final trimmedId = id.trim();

    if (trimmedId.isEmpty) {
      throw const AuthException('아이디를 입력해주세요.');
    }
    if (password.isEmpty) {
      throw const AuthException('비밀번호를 입력해주세요.');
    }

    final prefs = await SharedPreferences.getInstance();

    // 백엔드 API 로그인 우선 시도
    try {
      final apiRes = await ApiClient.instance.request(
        'POST',
        '/api/auth/login',
        body: {'id': trimmedId, 'password': password},
        withAuth: false,
      );
      if (apiRes != null && apiRes['user'] is Map<String, dynamic>) {
        final token = apiRes['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await ApiClient.instance.saveToken(token);
        }
        final userMap = apiRes['user'] as Map<String, dynamic>;
        final apiUser = User.fromJson(userMap);
        await prefs.setString(
            '$_userDataPrefix$trimmedId', jsonEncode(apiUser.toJson()));
        await prefs.setString(_currentUserIdKey, trimmedId);
        return apiUser;
      }
    } on ApiHttpException catch (e) {
      if (trimmedId != 'pipi_hero') {
        throw AuthException(e.message);
      }
    }

    // 1. 오프라인/로컬 폴백: 사용자 데이터 조회
    String? userJsonStr = prefs.getString('$_userDataPrefix$trimmedId');
    // 테스트 편의 계정: pipi_hero 계정이 아직 없으면 기본 생성
    if (userJsonStr == null && trimmedId == 'pipi_hero') {
      final defaultTestUser = User(
        id: 'pipi_hero',
        passwordHash: hashPassword('1234'),
        createdAt: DateTime.now(),
      );
      await prefs.setString('$_userDataPrefix$trimmedId', jsonEncode(defaultTestUser.toJson()));
      userJsonStr = prefs.getString('$_userDataPrefix$trimmedId');
    }

    if (userJsonStr == null) {
      throw const AuthException('가입되지 않은 아이디입니다.');
    }

    // 2. 비밀번호 해시 일치 여부 확인
    final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
    final storedUser = User.fromJson(userMap);
    final inputPasswordHash = hashPassword(password);

    if (storedUser.passwordHash != inputPasswordHash) {
      throw const AuthException('비밀번호가 올바르지 않습니다.');
    }

    // 3. 로그인 세션 저장 (로그인 상태 유지)
    await prefs.setString(_currentUserIdKey, trimmedId);

    return storedUser;
  }

  /// 소셜 연동 로그인 (카카오 / 구글)
  /// 
  /// 명세서 개발 원칙:
  /// - 모든 데이터 처리는 `repositories/` 클래스로만 하여 나중에 백엔드 API로 교체하기 쉽게 설계
  /// 
  /// [provider]: 소셜 플랫폼 구분 ([SocialProvider.kakao] 또는 [SocialProvider.google])
  /// 
  /// 💡 작동 방식 (현재 로컬 목업 단계):
  /// 1. 카카오 로그인: 'kakao_user' 고유 ID 생성 또는 기존 계정 조회
  /// 2. 구글 로그인: 'google_user' 고유 ID 생성 또는 기존 계정 조회
  /// 3. 사용자별 격리 저장소에 계정 정보 등록 및 로그인 세션 저장
  /// 
  /// 🔗 추후 백엔드 API 및 실제 SDK 연동 시:
  /// - kakao_flutter_sdk / google_sign_in 패키지를 통해 OAuth 토큰을 발급받고
  /// - 백엔드 서버(POST /api/auth/social)로 토큰을 전송하여 검증 및 세션 토큰을 발급받도록 이 메서드 내부만 교체합니다.
  Future<User> loginWithSocial({
    required SocialProvider provider,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final socialId = provider == SocialProvider.kakao ? 'kakao_user' : 'google_user';

    // 백엔드 API 소셜 로그인 우선 시도
    try {
      final apiRes = await ApiClient.instance.request(
        'POST',
        '/api/auth/social',
        body: {'provider': provider.name},
        withAuth: false,
      );
      if (apiRes != null && apiRes['user'] is Map<String, dynamic>) {
        final token = apiRes['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await ApiClient.instance.saveToken(token);
        }
        final userMap = apiRes['user'] as Map<String, dynamic>;
        final apiUser = User.fromJson(userMap);
        await prefs.setString(
            '$_userDataPrefix$socialId', jsonEncode(apiUser.toJson()));
        await prefs.setString(_currentUserIdKey, socialId);
        return apiUser;
      }
    } on ApiHttpException catch (e) {
      throw AuthException(e.message);
    }

    final userJsonStr = prefs.getString('$_userDataPrefix$socialId');

    User user;
    if (userJsonStr != null) {
      // 1. 기존에 연동된 소셜 계정이 있는 경우 로드
      final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
      user = User.fromJson(userMap);
    } else {
      // 2. 최초 소셜 로그인 시 신규 계정 생성 및 저장
      user = User(
        id: socialId,
        passwordHash: hashPassword('${socialId}_social_oauth_salt'),
        createdAt: DateTime.now(),
      );

      final userJson = jsonEncode(user.toJson());
      await prefs.setString('$_userDataPrefix$socialId', userJson);

      // 등록 사용자 목록에 추가
      final userIds = prefs.getStringList(_registeredUserIdsKey) ?? [];
      if (!userIds.contains(socialId)) {
        userIds.add(socialId);
        await prefs.setStringList(_registeredUserIdsKey, userIds);
      }
    }

    // 3. 로그인 세션 저장 (로그인 상태 유지)
    await prefs.setString(_currentUserIdKey, socialId);

    return user;
  }

  /// 현재 로그인된 사용자 정보 조회 (자동 로그인 지원)
  /// 
  /// 저장된 세션이 유효하면 [User]를 반환하고, 없으면 null을 반환합니다.
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(_currentUserIdKey);

    if (currentUserId == null || currentUserId.isEmpty) {
      return null;
    }

    final userJsonStr = prefs.getString('$_userDataPrefix$currentUserId');
    if (userJsonStr == null) {
      // 세션은 있으나 사용자 데이터가 없는 비정상 상태 시 세션 정리
      await prefs.remove(_currentUserIdKey);
      return null;
    }

    try {
      final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
      return User.fromJson(userMap);
    } catch (_) {
      await prefs.remove(_currentUserIdKey);
      return null;
    }
  }

  /// 로그아웃
  /// 
  /// 현재 사용자의 로그인 세션 정보를 삭제합니다. (사용자의 데이터는 유지됨)
  Future<void> logout() async {
    try {
      await ApiClient.instance.request('POST', '/api/auth/logout');
    } catch (_) {}
    await ApiClient.instance.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  /// 계정 삭제 (사용자 탈퇴 시 계정·캐릭터·일정·인트로 기록 모두 제거)
  Future<void> deleteAccount(String userId) async {
    try {
      await ApiClient.instance.request('DELETE', '/api/auth/account');
    } catch (_) {}
    await ApiClient.instance.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_userDataPrefix$userId');
    await prefs.remove('user_${userId}_character_data');
    await prefs.remove('user_tasks_$userId');
    await prefs.remove('pipi_intro_seen_$userId');

    final currentUserId = prefs.getString(_currentUserIdKey);
    if (currentUserId == userId) {
      await prefs.remove(_currentUserIdKey);
    }

    final userIds = prefs.getStringList(_registeredUserIdsKey) ?? [];
    userIds.remove(userId);
    await prefs.setStringList(_registeredUserIdsKey, userIds);
  }
}
