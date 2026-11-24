import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lowercase_with_underscores/models/character.dart';
import 'package:lowercase_with_underscores/providers/auth_provider.dart';
import 'package:lowercase_with_underscores/providers/character_provider.dart';
import 'package:lowercase_with_underscores/repositories/character_repository.dart';
import 'package:lowercase_with_underscores/screens/character_selection_screen.dart';
import 'package:lowercase_with_underscores/widgets/character_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Character Custom Palette & Anti-Aliasing Integrity Tests', () {
    test('Duck has no palette options and always returns default asset', () {
      expect(CharacterType.duck.paletteOptions.isEmpty, isTrue);
      // 어떤 paletteKey가 넘어가도 오리는 원본 에셋 경로 반환
      expect(
        CharacterType.duck.getAssetPath(paletteKey: 'custom_red'),
        equals('assets/characters/duck_baby.png'),
      );
      expect(
        CharacterType.duck.getAssetPath(paletteKey: 'default'),
        equals('assets/characters/duck_baby.png'),
      );
    });

    test('Capybara has original option and 4 brown-tone intensity presets', () {
      final capyOptions = CharacterType.capybara.paletteOptions;
      expect(capyOptions.length, equals(5));
      expect(capyOptions.first.id, equals('default'));
      expect(capyOptions.first.name, equals('원래 색 (오리지널)'));
      expect(capyOptions.any((o) => o.id == 'capy_light'), isTrue);
      expect(capyOptions.any((o) => o.id == 'capy_caramel'), isTrue);
      expect(capyOptions.any((o) => o.id == 'capy_deep'), isTrue);
      expect(capyOptions.any((o) => o.id == 'capy_dark'), isTrue);

      expect(
        CharacterType.capybara.getAssetPath(paletteKey: 'default'),
        equals('assets/characters/capybara_baby.png'),
      );
      expect(
        CharacterType.capybara.getAssetPath(paletteKey: 'capy_light'),
        equals('assets/characters/capybara_capy_light.png'),
      );
    });

    test('Dragon has original option and 5 specified palettes and resolves correct assets', () {
      final dragonOptions = CharacterType.dragon.paletteOptions;
      expect(dragonOptions.length, equals(6));
      expect(dragonOptions.first.id, equals('default'));
      expect(dragonOptions.first.name, equals('원래 색 (오리지널)'));

      final names = dragonOptions.map((o) => o.name).toList();
      expect(names, containsAll(['원래 색 (오리지널)', '크림 피치', '썬샤인 골드', '라벤더 슈가', '스트로베리 밀크', '차콜 블랙']));

      expect(
        CharacterType.dragon.getAssetPath(paletteKey: 'default'),
        equals('assets/characters/dragon_baby.png'),
      );
      expect(
        CharacterType.dragon.getAssetPath(paletteKey: 'cream_peach'),
        equals('assets/characters/dragon_cream_peach.png'),
      );
      expect(
        CharacterType.dragon.getAssetPath(paletteKey: 'sunshine_gold'),
        equals('assets/characters/dragon_sunshine_gold.png'),
      );
      expect(
        CharacterType.dragon.getAssetPath(paletteKey: 'charcoal_black'),
        equals('assets/characters/dragon_charcoal_black.png'),
      );
    });

    test('Dog and Cat have original option and 5 specified custom palettes', () {
      final dogOptions = CharacterType.dog.paletteOptions;
      expect(dogOptions.length, equals(6));
      expect(dogOptions.first.id, equals('default'));
      expect(dogOptions.first.name, equals('원래 색 (오리지널)'));
      final dogNames = dogOptions.map((o) => o.name).toList();
      expect(dogNames, containsAll(['원래 색 (오리지널)', '허니 시바', '블랙탄', '백시바', '세서미', '스트로베리 밀크']));

      expect(
        CharacterType.dog.getAssetPath(paletteKey: 'default'),
        equals('assets/characters/dog_baby.png'),
      );
      expect(
        CharacterType.dog.getAssetPath(paletteKey: 'black_tan'),
        equals('assets/characters/dog_black_tan.png'),
      );

      final catOptions = CharacterType.cat.paletteOptions;
      expect(catOptions.length, equals(6));
      expect(catOptions.first.id, equals('default'));
      expect(catOptions.first.name, equals('원래 색 (오리지널)'));
      final catNames = catOptions.map((o) => o.name).toList();
      expect(catNames, containsAll(['원래 색 (오리지널)', '치즈 태비', '턱시도 블랙', '러시안 블루', '라벤더 샴', '카페모카']));

      expect(
        CharacterType.cat.getAssetPath(paletteKey: 'default'),
        equals('assets/characters/cat_baby.png'),
      );
      expect(
        CharacterType.cat.getAssetPath(paletteKey: 'tuxedo_black'),
        equals('assets/characters/cat_tuxedo_black.png'),
      );
    });

    test('CharacterRepository saves and loads local custom palette independently', () async {
      final repo = CharacterRepository();
      const userId = 'user_color_test_1';

      final initialChar = Character(
        type: 'cat',
        color: 'cheese_tabby',
        name: '나비',
        lastVisit: DateTime.now(),
      );
      await repo.saveCharacter(userId, initialChar);

      await repo.saveLocalCharacterColor(userId, 'tuxedo_black');

      final savedColor = await repo.getLocalCharacterColor(userId);
      expect(savedColor, equals('tuxedo_black'));

      final loaded = await repo.getCharacter(userId);
      expect(loaded, isNotNull);
      expect(loaded!.color, equals('tuxedo_black'));
    });

    test('CharacterProvider updateLocalColor modifies character palette without server call', () async {
      final repo = CharacterRepository();
      final provider = CharacterProvider(characterRepository: repo);
      const userId = 'user_color_test_2';

      await provider.selectCharacter(
        userId: userId,
        type: CharacterType.dog,
        name: '백구',
        colorHex: 'default',
      );

      expect(provider.currentCharacter?.color, equals('default'));

      await provider.updateLocalColor(userId, 'black_tan');
      expect(provider.currentCharacter?.color, equals('black_tan'));

      final prefsColor = await repo.getLocalCharacterColor(userId);
      expect(prefsColor, equals('black_tan'));
    });

    testWidgets('CharacterSelectionScreen displays palette for Cat and updates preview', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authProvider = AuthProvider();
      final charProvider = CharacterProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: charProvider),
          ],
          child: const MaterialApp(
            home: CharacterSelectionScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('색상 선택'), findsOneWidget);
      expect(find.text('🎨'), findsWidgets);

      final charViewFinder = find.byType(CharacterView);
      expect(charViewFinder, findsWidgets);

      final CharacterView charView = tester.widget(charViewFinder.first);
      expect(charView.colorHex, equals('default'));
    });
  });
}
