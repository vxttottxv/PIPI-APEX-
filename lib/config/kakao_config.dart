/// 카카오 SDK 및 웹 OAuth 2.0 설정 관리
///
/// [보안 및 키 분리 규칙]:
/// - 모바일 SDK: [nativeAppKey] 사용
/// - 웹 JavaScript SDK 초기화: [javascriptAppKey] 사용
/// - 웹 OAuth 2.0 인가 요청 (client_id): [restApiKey] 사용
/// - 백엔드 토큰 교환: 백엔드 환경 변수(KAKAO_REST_API_KEY) 사용
class KakaoConfig {
  KakaoConfig._();

  /// 모바일 네이티브 앱 키 (Android / iOS)
  static const String nativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: '768138760b29ce3818e6e5cb87e07a38',
  );

  /// 웹 플랫폼 JavaScript 키 (공식 Web JS SDK 초기화 전용)
  static const String javascriptAppKey = String.fromEnvironment(
    'KAKAO_JAVASCRIPT_APP_KEY',
    defaultValue: '5dd0c016007aa9afefa01213f35c5e7b',
  );

  /// 카카오 REST API 키 (웹 OAuth 2.0 인가 요청 client_id)
  /// 빌드 시 `--dart-define=KAKAO_REST_API_KEY=실제_REST_API_키`로 주입합니다.
  static const String restApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
    defaultValue: '',
  );

  /// 웹 OAuth 2.0 리다이렉트 URI (기본값: https://pipi-app.pages.dev/)
  static const String customRedirectUri = String.fromEnvironment(
    'KAKAO_REDIRECT_URI',
    defaultValue: 'https://pipi-app.pages.dev/',
  );

  /// 실제 적용할 Web Redirect URI 계산 (예: https://pipi-app.pages.dev/ 또는 로컬 테스트 시 http://localhost:3000/)
  static String getEffectiveRedirectUri() {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      final host = base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1') {
        return '${base.origin}/';
      }
    }
    if (customRedirectUri.isNotEmpty) {
      return customRedirectUri;
    }
    if (base.scheme == 'http' || base.scheme == 'https') {
      return '${base.origin}/';
    }
    return 'https://pipi-app.pages.dev/';
  }

  /// 카카오 공식 OAuth 2.0 인가 코드 요청 URL 생성
  /// [client_id]는 카카오 공식 REST API OAuth 명세에 따라 REST API 키를 사용합니다.
  static String getAuthorizeUrl(String redirectUri) {
    final trimmedKey = restApiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const FormatException(
        '카카오 REST API 키가 설정되지 않았습니다. --dart-define=KAKAO_REST_API_KEY 빌드 설정을 확인해주세요.',
      );
    }
    final query = Uri(queryParameters: {
      'client_id': trimmedKey,
      'redirect_uri': redirectUri,
      'response_type': 'code',
    }).query;
    return 'https://kauth.kakao.com/oauth/authorize?$query';
  }
}
