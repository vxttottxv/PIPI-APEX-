// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// 브라우저 페이지를 지정된 URL로 리다이렉트
void redirectBrowser(String url) {
  html.window.location.href = url;
}

/// 현재 브라우저 URL(쿼리스트링 및 해시 파라미터)에서 지정된 키의 파라미터 값 추출
String? getUrlQueryParam(String key) {
  try {
    // 1. Uri.base queryParameters 확인
    final baseUri = Uri.base;
    if (baseUri.queryParameters.containsKey(key)) {
      return baseUri.queryParameters[key];
    }

    // 2. window.location.href 전체 파싱 확인
    final currentHref = html.window.location.href;
    final parsedHref = Uri.parse(currentHref);
    if (parsedHref.queryParameters.containsKey(key)) {
      return parsedHref.queryParameters[key];
    }

    // 3. Flutter Web 해시 라우팅(#/?code=...) 처리
    final hash = html.window.location.hash;
    if (hash.contains('?')) {
      final hashQuery = hash.substring(hash.indexOf('?') + 1);
      final queryParams = Uri.splitQueryString(hashQuery);
      if (queryParams.containsKey(key)) {
        return queryParams[key];
      }
    }
  } catch (_) {}
  return null;
}

/// 브라우저 주소창에서 일회용 OAuth 쿼리스트링 제거 (URL 깔끔화 & 코드 재사용 방지)
void cleanUrlQueryParams() {
  try {
    final pathname = html.window.location.pathname ?? '/';
    final hash = html.window.location.hash;
    String cleanHash = '';
    if (hash.isNotEmpty) {
      final queryIdx = hash.indexOf('?');
      cleanHash = queryIdx != -1 ? hash.substring(0, queryIdx) : hash;
    }
    final cleanUrl = '$pathname$cleanHash';
    html.window.history.replaceState(null, '', cleanUrl);
  } catch (_) {}
}

/// 현재 브라우저 Origin(예: https://example.pages.dev 또는 http://localhost:3000) 반환
String getBrowserOrigin() {
  try {
    return html.window.location.origin;
  } catch (_) {
    return '';
  }
}
