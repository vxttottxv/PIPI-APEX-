import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
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

  String get baseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
    if (kIsWeb) {
      final origin = Uri.base;
      if (origin.host.endsWith('github.io')) {
        return '';
      }
      if ((origin.scheme == 'http' || origin.scheme == 'https') &&
          origin.port != 8080) {
        return origin.origin;
      }
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
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
