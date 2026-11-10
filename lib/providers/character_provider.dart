import 'package:flutter/foundation.dart';
import '../models/character.dart';
import '../repositories/character_repository.dart';

/// 캐릭터 상태를 관리하는 Provider
///
/// 명세서 4-2 및 사용자 요구사항:
/// - 처음 시작 시 캐릭터 선택 창에서 선택
/// - 선택 후에는 하나의 캐릭터만 나오며, 이 캐릭터로 고정되어 계속 육성
/// - 리포지토리를 통해 사용자 ID별로 분리 저장되며 추후 백엔드 API 연동이 용이하도록 구성
class CharacterProvider with ChangeNotifier {
  final CharacterRepository _characterRepository;

  Character? _character;
  bool _isLoading = false;
  String? _errorMessage;

  CharacterProvider({CharacterRepository? characterRepository})
      : _characterRepository = characterRepository ?? CharacterRepository();

  /// 현재 선택 및 고정된 캐릭터 객체 (미선택 시 null)
  Character? get currentCharacter => _character;

  /// 캐릭터 선택 완료 여부 (true면 고정된 캐릭터 육성 화면으로 진입)
  bool get hasCharacter => _character != null;

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 오류 메시지
  String? get errorMessage => _errorMessage;

  /// 사용자의 저장된 캐릭터 정보를 불러옴
  Future<void> loadCharacter(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _character = await _characterRepository.getCharacter(userId);
    } catch (e) {
      _errorMessage = '캐릭터 정보를 불러오는 데 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 캐릭터 최초 선택 및 고정 저장
  ///
  /// 사용자 요구: "캐릭터 선택하면 하나의 캐릭터만 나오게 그리고 그 캐릭터를 키우는거라 그 캐릭터로 고정되는 설정도 해"
  Future<bool> selectCharacter({
    required String userId,
    required CharacterType type,
    required String name,
    required String colorHex,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = '캐릭터 이름을 입력해주세요.';
      notifyListeners();
      return false;
    }
    if (trimmedName.length > 8) {
      _errorMessage = '캐릭터 이름은 최대 8자까지 가능합니다.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newCharacter = Character(
        type: type.name,
        color: colorHex,
        name: trimmedName,
        level: 1,
        exp: 0,
        stage: 'baby',
        intimacy: 50,
        coins: 100,
        snacks: 5,
        ownedItems: const [],
        equippedItems: const [],
        lastVisit: DateTime.now(),
      );

      await _characterRepository.saveCharacter(userId, newCharacter);
      _character = newCharacter;
      return true;
    } catch (e) {
      _errorMessage = '캐릭터 저장 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 간식 주기 (명세서 4-8, 4-9)
  /// 간식을 소모하여 친밀감과 경험치를 획득
  Future<bool> feedSnack(String userId) async {
    if (_character == null) return false;
    if (_character!.snacks <= 0) {
      _errorMessage = '간식이 부족합니다!';
      notifyListeners();
      return false;
    }

    int newExp = _character!.exp + 20;
    int newLevel = _character!.level;
    String newStage = _character!.stage;

    // 레벨업 판별 (100 경험치당 1레벨)
    if (newExp >= 100) {
      newLevel += newExp ~/ 100;
      newExp = newExp % 100;
      if (newLevel >= 10) {
        newStage = 'adult';
      } else if (newLevel >= 5) {
        newStage = 'teen';
      }
    }

    final updated = _character!.copyWith(
      snacks: _character!.snacks - 1,
      exp: newExp,
      level: newLevel,
      stage: newStage,
      intimacy: (_character!.intimacy + 5).clamp(0, 100),
      lastVisit: DateTime.now(),
    );

    await _characterRepository.updateCharacter(userId, updated);
    _character = updated;
    notifyListeners();
    return true;
  }

  /// 고유 놀아주기 활동 (명세서 4-8)
  Future<void> playActivity(String userId) async {
    if (_character == null) return;

    int newExp = _character!.exp + 15;
    int newLevel = _character!.level;
    String newStage = _character!.stage;

    if (newExp >= 100) {
      newLevel += newExp ~/ 100;
      newExp = newExp % 100;
      if (newLevel >= 10) {
        newStage = 'adult';
      } else if (newLevel >= 5) {
        newStage = 'teen';
      }
    }

    final updated = _character!.copyWith(
      exp: newExp,
      level: newLevel,
      stage: newStage,
      intimacy: (_character!.intimacy + 3).clamp(0, 100),
      coins: _character!.coins + 10,
      lastVisit: DateTime.now(),
    );

    await _characterRepository.updateCharacter(userId, updated);
    _character = updated;
    notifyListeners();
  }

  /// 명세서 4-7: 일정 인증 완료 보상 지급 (EXP, 코인, 간식)
  /// 레벨업 발생 여부 반환 (축하 애니메이션 트리거용)
  Future<bool> addRewards({
    required String userId,
    required int exp,
    required int coins,
    required int snacks,
  }) async {
    if (_character == null) return false;

    int newExp = _character!.exp + exp;
    int newLevel = _character!.level;
    String newStage = _character!.stage;
    bool leveledUp = false;

    if (newExp >= 100) {
      newLevel += newExp ~/ 100;
      newExp = newExp % 100;
      leveledUp = true;
      if (newLevel >= 10) {
        newStage = 'adult';
      } else if (newLevel >= 5) {
        newStage = 'teen';
      }
    }

    final updated = _character!.copyWith(
      exp: newExp,
      level: newLevel,
      stage: newStage,
      coins: _character!.coins + coins,
      snacks: _character!.snacks + snacks,
      intimacy: (_character!.intimacy + 4).clamp(0, 100),
      lastVisit: DateTime.now(),
    );

    await _characterRepository.updateCharacter(userId, updated);
    _character = updated;
    notifyListeners();
    return leveledUp;
  }

  /// 명세서 4-8: 아이템(모자, 리본, 목걸이 등) 구매 및 착용
  Future<bool> buyAndEquipItem({
    required String userId,
    required String itemId,
    required int cost,
  }) async {
    if (_character == null) return false;
    if (_character!.coins < cost) {
      _errorMessage = '코인이 부족합니다!';
      notifyListeners();
      return false;
    }

    final owned = List<String>.from(_character!.ownedItems);
    if (!owned.contains(itemId)) {
      owned.add(itemId);
    }

    final equipped = List<String>.from(_character!.equippedItems);
    if (!equipped.contains(itemId)) {
      equipped.add(itemId);
    }

    final updated = _character!.copyWith(
      coins: _character!.coins - cost,
      ownedItems: owned,
      equippedItems: equipped,
    );

    await _characterRepository.updateCharacter(userId, updated);
    _character = updated;
    notifyListeners();
    return true;
  }

  /// 착용한 아이템 탈착
  Future<void> toggleEquipItem({
    required String userId,
    required String itemId,
  }) async {
    if (_character == null) return;

    final equipped = List<String>.from(_character!.equippedItems);
    if (equipped.contains(itemId)) {
      equipped.remove(itemId);
    } else {
      equipped.add(itemId);
    }

    final updated = _character!.copyWith(equippedItems: equipped);
    await _characterRepository.updateCharacter(userId, updated);
    _character = updated;
    notifyListeners();
  }

  /// 명세서 4-9: 병원 치료 (친밀감이 매우 낮을 때 코인 50 소모하여 회복)
  Future<bool> healAtHospital(String userId) async {
    if (_character == null) return false;
    if (_character!.coins < 50) {
      _errorMessage = '치료비(50 코인)가 부족합니다!';
      notifyListeners();
      return false;
    }

    final updated = _character!.copyWith(
      coins: _character!.coins - 50,
      intimacy: 60, // 보통 상태로 회복
      lastVisit: DateTime.now(),
    );

    await _characterRepository.updateCharacter(userId, updated);
    _character = updated;
    notifyListeners();
    return true;
  }

  /// 개발/테스트용: 캐릭터 초기화
  Future<void> resetCharacterForTesting(String userId) async {
    await _characterRepository.resetCharacter(userId);
    _character = null;
    notifyListeners();
  }

  /// 로그아웃 시 메모리 내 캐릭터 상태 초기화
  void clear() {
    _character = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
