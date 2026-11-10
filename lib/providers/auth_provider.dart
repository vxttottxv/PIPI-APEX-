import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

/// 앱 전역의 인증 상태(로그인 여부, 현재 사용자, 로딩 상태 등)를 관리하는 Provider
///
/// 명세서 2. 개발 환경:
/// - 상태 관리: Provider
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  /// 현재 로그인된 사용자 정보 (미로그인 시 null)
  User? _currentUser;
  User? get currentUser => _currentUser;

  /// 로그인 여부 확인 getter
  bool get isAuthenticated => _currentUser != null;

  /// 인증 처리 진행 중 여부 (로딩 스피너 제어)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 최근 발생한 에러 메시지 (화면 표시용)
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 앱 시작 시 저장된 세션을 확인하여 자동 로그인 수행
  /// 
  /// 반환값: 자동 로그인 성공 여부 (true: 홈으로 이동, false: 로그인 화면으로 이동)
  Future<bool> checkAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepository.getCurrentUser();
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 로그인 처리
  /// 
  /// 성공 시 true, 실패 시 false 반환 및 [errorMessage] 설정
  Future<bool> login({
    required String id,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(
        id: id,
        password: password,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 회원가입 처리
  /// 
  /// 성공 시 자동 로그인되며 true 반환, 실패 시 false 반환 및 [errorMessage] 설정
  Future<bool> signUp({
    required String id,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signUp(
        id: id,
        password: password,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '회원가입 중 오류가 발생했습니다. 다시 시도해주세요.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 소셜 연동 로그인 (카카오 / 구글)
  /// 
  /// [provider]: 소셜 플랫폼 구분 ([SocialProvider.kakao] 또는 [SocialProvider.google])
  /// 성공 시 true, 실패 시 false 반환 및 [errorMessage] 설정
  Future<bool> loginWithSocial(SocialProvider provider) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.loginWithSocial(provider: provider);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '${provider.displayName} 로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 로그아웃 처리
  /// 
  /// 로컬 세션을 제거하고 상태를 초기화합니다.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
    } finally {
      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 현재 로그인 계정 회원 탈퇴
  Future<void> deleteCurrentAccount() async {
    final userId = _currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.deleteAccount(userId);
    } finally {
      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}
