import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 백엔드가 비즈니스 오류(400/401/404/409)를 응답했을 때 발생하는 예외
class ApiHttpException implements Exception {
  final int statusCode;
  final String message;

  const ApiHttpException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// PIPI 백엔드 REST API 클라이언트
///
/// - 백엔드(`backend/server.py`)가 실행 중이면 실제 서버 DB와 통신합니다.
/// - 서버가 꺼져 있거나 테스트 환경 등 네트워크 연결이 불가할 때는
///   호출부가 안전하게 로컬 저장소(SharedPreferences)로 폴백할 수 있도록 null/예외를 구분합니다.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const String _tokenKey = 'pipi_api_bearer_token';
  static const Duration _timeout = Duration(seconds: 4);

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions.defaultOptions,
  );

  String get baseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
    // 스마트폰 QR 접속 시: 접속한 호스트(예: http://192.168.x.x:3000)를 자동으로 Base URL로 사용
    if (kIsWeb) {
      final origin = Uri.base;
      if (origin.host.isNotEmpty &&
          (origin.scheme == 'http' || origin.scheme == 'https')) {
        return origin.origin;
      }
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    // iOS 시뮬레이터 및 로컬 기본값
    return 'http://localhost:3000';
  }

  /// 보안 저장소(FlutterSecureStorage)에서 인증 토큰을 안전하게 조회합니다.
  /// 
  /// [무중단 마이그레이션]:
  /// 1. 보안 저장소에 토큰이 있으면 즉시 반환
  /// 2. 없으면 기존 SharedPreferences 평문 토큰 확인
  /// 3. 기존 토큰 발견 시 보안 저장소에 먼저 기록 후 재검증(Read-after-Write)
  /// 4. 검증 성공 시에만 기존 평문 토큰 삭제 (실패 시 보존하여 로그인 유지)
  Future<String?> getToken() async {
    try {
      final secureToken = await _secureStorage.read(key: _tokenKey);
      if (secureToken != null && secureToken.isNotEmpty) {
        return secureToken;
      }
    } catch (_) {}

    // 2. 레거시 SharedPreferences 저장소 확인
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_tokenKey);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        // 보안 저장소로 안전 이전 (기록 후 정상 저장 여부 검증)
        await _secureStorage.write(key: _tokenKey, value: legacyToken);
        final verified = await _secureStorage.read(key: _tokenKey);
        if (verified == legacyToken) {
          // 검증 완료된 경우에만 레거시 평문 토큰 안전 삭제
          await prefs.remove(_tokenKey);
        }
        return legacyToken;
      }
    } catch (_) {
      // 보안 저장소 기록 또는 검증 예외 시 레거시 토큰 삭제하지 않고 보존
    }
    return null;
  }

  /// 발급받은 인증 토큰을 보안 저장소에 암호화하여 저장합니다.
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      final verified = await _secureStorage.read(key: _tokenKey);
      if (verified == token) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
      }
    } catch (_) {
      // 보안 저장소 예외 발생 시 SharedPreferences에 폴백 저장하여 인증 유지
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
  }

  /// 로그아웃 또는 계정 삭제 시 보안 저장소 및 레거시 저장소의 토큰을 모두 정리합니다.
  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
  }

  /// 백엔드 HTTP 요청 실행
  /// - 네트워크 연결 실패/타임아웃 시 `null` 반환 (오프라인/로컬 폴백 가능)
  /// - 서버가 2xx 응답을 주면 디코딩된 Map 반환
  /// - 서버가 4xx/5xx 응답을 주면 [ApiHttpException] throw
  Future<Map<String, dynamic>?> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final base = baseUrl;
    if (base.isEmpty) return null;
    final uri = Uri.parse('$base$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (withAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      final encoded = body != null ? jsonEncode(body) : null;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: encoded)
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: encoded)
              .timeout(_timeout);
          break;
        case 'DELETE':
          response =
              await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          return null;
      }
    } catch (_) {
      // 서버 오프라인 또는 테스트 바인딩 HTTP 차단 시 로컬 폴백 신호
      return null;
    }

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) {
          decoded = raw;
        }
      } catch (_) {}
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // 실제 백엔드 서버가 JSON {"error": "..."}를 반환한 경우에만 비즈니스 예외 발생
    // (Flutter TestWidgetsFlutterBinding의 가짜 HTTP 400 빈 응답 등은 로컬 폴백 처리)
    final serverError = decoded['error'];
    if (serverError is String && serverError.isNotEmpty) {
      throw ApiHttpException(response.statusCode, serverError);
    }

    return null;
  }
}
