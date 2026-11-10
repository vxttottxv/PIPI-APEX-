import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lowercase_with_underscores/models/character.dart';
import 'package:lowercase_with_underscores/repositories/character_repository.dart';
import 'package:lowercase_with_underscores/providers/character_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Character Model Tests', () {
    test('Character model toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final char = Character(
        type: 'cat',
        color: '#FFFFFF',
        name: '눈송이',
        level: 1,
        exp: 20,
        stage: 'baby',
        intimacy: 60,
        coins: 120,
        snacks: 4,
        ownedItems: ['collar_red'],
        equippedItems: ['collar_red'],
        lastVisit: now,
      );

      final json = char.toJson();
      expect(json['type'], 'cat');
      expect(json['name'], '눈송이');
      expect(json['level'], 1);
      expect(json['coins'], 120);

      final restored = Character.fromJson(json);
      expect(restored.type, 'cat');
      expect(restored.name, '눈송이');
      expect(restored.level, 1);
      expect(restored.stageKoreanName, '새끼');
      expect(restored.characterType, CharacterType.cat);
    });

    test('All 6 character types have valid names, tags, and quotes', () {
      expect(CharacterType.values.length, 6);

      for (final type in CharacterType.values) {
        expect(type.koreanName.isNotEmpty, true);
        expect(type.description.isNotEmpty, true);
        expect(type.tag.isNotEmpty, true);
        expect(type.speechQuotes.isNotEmpty, true);
        expect(type.paletteOptions.length, greaterThanOrEqualTo(3));
        expect(type.playActivityName.isNotEmpty, true);
      }
    });
  });

  group('CharacterRepository Tests', () {
    late CharacterRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = CharacterRepository();
    });

    test('getCharacter returns null when user has no character', () async {
      final char = await repo.getCharacter('newbie');
      expect(char, isNull);
      expect(await repo.hasCharacter('newbie'), isFalse);
    });

    test('saveCharacter persists character per user ID', () async {
      final char1 = Character(
        type: 'dog',
        color: '#E8B872',
        name: '뭉치',
        lastVisit: DateTime.now(),
      );
      final char2 = Character(
        type: 'duck',
        color: '#FFFFFF',
        name: '마린이',
        lastVisit: DateTime.now(),
      );

      await repo.saveCharacter('user_a', char1);
      await repo.saveCharacter('user_b', char2);

      final loadedA = await repo.getCharacter('user_a');
      final loadedB = await repo.getCharacter('user_b');

      expect(loadedA?.name, '뭉치');
      expect(loadedA?.characterType, CharacterType.dog);

      expect(loadedB?.name, '마린이');
      expect(loadedB?.characterType, CharacterType.duck);
    });
  });

  group('CharacterProvider Tests', () {
    late CharacterRepository repo;
    late CharacterProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = CharacterRepository();
      provider = CharacterProvider(characterRepository: repo);
    });

    test('Select character locks in the chosen character and updates state', () async {
      expect(provider.hasCharacter, isFalse);

      final success = await provider.selectCharacter(
        userId: 'test_user',
        type: CharacterType.capybara,
        name: '바라',
        colorHex: '#A67B5B',
      );

      expect(success, isTrue);
      expect(provider.hasCharacter, isTrue);
      expect(provider.currentCharacter?.name, '바라');
      expect(provider.currentCharacter?.characterType, CharacterType.capybara);
      expect(provider.currentCharacter?.level, 1);
      expect(provider.currentCharacter?.snacks, 5);
      expect(provider.currentCharacter?.coins, 100);
    });

    test('feedSnack consumes snack, increases exp and intimacy, and triggers level up', () async {
      await provider.selectCharacter(
        userId: 'test_user',
        type: CharacterType.cat,
        name: '눈송이',
        colorHex: '#FFFFFF',
      );

      expect(provider.currentCharacter?.snacks, 5);
      expect(provider.currentCharacter?.exp, 0);

      // 1회 간식 주기
      final fed = await provider.feedSnack('test_user');
      expect(fed, isTrue);
      expect(provider.currentCharacter?.snacks, 4);
      expect(provider.currentCharacter?.exp, 20);
      expect(provider.currentCharacter?.intimacy, 55);

      // 4회 더 간식 주어 레벨업 (총 100 EXP 달성)
      await provider.feedSnack('test_user'); // 40
      await provider.feedSnack('test_user'); // 60
      await provider.feedSnack('test_user'); // 80
      await provider.feedSnack('test_user'); // 100 -> Lv 2, 0 EXP

      expect(provider.currentCharacter?.level, 2);
      expect(provider.currentCharacter?.exp, 0);
      expect(provider.currentCharacter?.snacks, 0);

      // 간식 부족 시 실패
      final noSnack = await provider.feedSnack('test_user');
      expect(noSnack, isFalse);
    });

    test('playActivity awards exp and coins', () async {
      await provider.selectCharacter(
        userId: 'test_user',
        type: CharacterType.dragon,
        name: '용용이',
        colorHex: '#4A3B52',
      );

      final initialCoins = provider.currentCharacter!.coins;
      await provider.playActivity('test_user');

      expect(provider.currentCharacter?.coins, initialCoins + 10);
      expect(provider.currentCharacter?.exp, 15);
    });
  });
}
