import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lowercase_with_underscores/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('ApiClient Secure Storage & Migration Tests', () {
    const tokenKey = 'pipi_api_bearer_token';
    const testToken = 'secure_bearer_token_xyz_123';

    test('saveToken writes to FlutterSecureStorage and removes legacy SharedPreferences token', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, 'old_plain_token');

      await ApiClient.instance.saveToken(testToken);

      final token = await ApiClient.instance.getToken();
      expect(token, equals(testToken));

      // SharedPreferences 레거시 키는 삭제되어야 함
      expect(prefs.containsKey(tokenKey), isFalse);
    });

    test('getToken migrates legacy token from SharedPreferences to FlutterSecureStorage when verified', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, 'legacy_user_token_999');

      // 처음에는 secure storage가 비어있음
      // getToken() 호출 시 자동 마이그레이션 실행
      final retrievedToken = await ApiClient.instance.getToken();
      expect(retrievedToken, equals('legacy_user_token_999'));

      // 마이그레이션 검증 완료 후 SharedPreferences의 레거시 토큰은 삭제되어야 함
      expect(prefs.containsKey(tokenKey), isFalse);

      // 이후 다시 조회해도 secure storage에서 정상적으로 반환되어야 함
      final secondRetrieve = await ApiClient.instance.getToken();
      expect(secondRetrieve, equals('legacy_user_token_999'));
    });

    test('clearToken removes token from both FlutterSecureStorage and SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, 'orphan_token');
      await ApiClient.instance.saveToken('new_secure_token');

      await ApiClient.instance.clearToken();

      final currentToken = await ApiClient.instance.getToken();
      expect(currentToken, isNull);
      expect(prefs.containsKey(tokenKey), isFalse);
    });
  });
}
