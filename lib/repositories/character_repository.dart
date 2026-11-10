import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
import '../services/api_client.dart';
import 'auth_repository.dart';

/// 캐릭터 데이터 저장 및 조회를 전담하는 리포지토리
///
/// 명세서 개발 원칙:
/// 1. 모든 데이터 처리는 `repositories/` 클래스로만 하여 나중에 백엔드 API로 교체하기 쉽게 설계
///    (추후 백엔드 개발자: GET /api/v1/characters/me, POST /api/v1/characters 로 교체)
/// 2. 사용자 ID 기준으로 분리 저장하여 타 사용자 데이터 접근 차단
/// 3. 한번 선택된 캐릭터는 영구 고정되어 육성되므로 저장 유무를 정확하게 판별
class CharacterRepository {
  static const String _characterKeySuffix = 'character_data';

  /// 사용자 ID 기반 분리 저장 키 생성
  String _getUserCharacterKey(String userId) {
    return AuthRepository.getUserStorageKey(userId, _characterKeySuffix);
  }

  /// 사용자의 저장된 캐릭터 정보 조회
  ///
  /// 저장된 캐릭터가 없을 경우 null 반환 (캐릭터 선택 화면으로 유도)
  Future<Character?> getCharacter(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserCharacterKey(userId);

    // 백엔드 API 조회 시도 (토큰이 있는 로그인 세션일 때)
    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final apiRes = await ApiClient.instance.request('GET', '/api/character');
        if (apiRes != null) {
          final character = Character.fromJson(apiRes);
          await prefs.setString(key, jsonEncode(character.toJson()));
          return character;
        }
      } on ApiHttpException catch (e) {
        if (e.statusCode == 404) {
          await prefs.remove(key);
          return null;
        }
      }
    }

    final jsonStr = prefs.getString(key);

    if (jsonStr == null || jsonStr.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      return Character.fromJson(data);
    } catch (e) {
      // JSON 파싱 실패 시 안전하게 null 반환
      return null;
    }
  }

  /// 캐릭터 최초 생성 및 저장 (한번 저장 시 고정)
  ///
  /// [userId]: 현재 로그인된 사용자 ID
  /// [character]: 새로 선택된 캐릭터 객체
  Future<void> saveCharacter(String userId, Character character) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserCharacterKey(userId);
    final payload = character.toJson();
    await prefs.setString(key, jsonEncode(payload));

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.instance
            .request('POST', '/api/character', body: payload);
      } catch (_) {}
    }
  }

  /// 캐릭터 상태 업데이트 (경험치, 레벨, 친밀도, 간식 등)
  Future<void> updateCharacter(String userId, Character character) async {
    await saveCharacter(userId, character);
  }

  /// 해당 사용자가 이미 캐릭터를 선택했는지 확인
  Future<bool> hasCharacter(String userId) async {
    final character = await getCharacter(userId);
    return character != null;
  }

  /// 테스트 및 개발용: 캐릭터 초기화
  Future<void> resetCharacter(String userId) async {
    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.instance.request('DELETE', '/api/character');
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserCharacterKey(userId);
    await prefs.remove(key);
  }
}
