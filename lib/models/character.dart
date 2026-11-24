import 'package:flutter/material.dart';

/// 캐릭터 종류 열거형
///
/// 명세서 4-2: 6종 (고양이, 강아지, 카피바라, 오리, 우파루파, 드래곤)
enum CharacterType {
  cat,
  dog,
  capybara,
  duck,
  axolotl,
  dragon;

  /// 문자열로부터 CharacterType 변환
  static CharacterType fromString(String value) {
    return CharacterType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CharacterType.cat,
    );
  }

  /// 캐릭터 한글 이름
  String get koreanName {
    switch (this) {
      case CharacterType.cat:
        return '고양이';
      case CharacterType.dog:
        return '강아지';
      case CharacterType.capybara:
        return '카피바라';
      case CharacterType.duck:
        return '오리';
      case CharacterType.axolotl:
        return '우파루파';
      case CharacterType.dragon:
        return '드래곤';
    }
  }

  /// 캐릭터 특징 요약 설명
  String get description {
    switch (this) {
      case CharacterType.cat:
        return '빨간 발바닥 방울 스카프를 맨 크림빛 아기 고양이';
      case CharacterType.dog:
        return '빨간 발바닥 반다나를 매고 혀를 내밀며 반기는 아기 강아지';
      case CharacterType.capybara:
        return '머리 위에 싱싱한 귤을 얹고 평온한 미소를 짓는 카피바라';
      case CharacterType.duck:
        return '노란 꽃 밀짚모자와 크로스백을 멘 귀여운 아기 오리';
      case CharacterType.axolotl:
        return '파스텔 하늘색 리본을 매고 방긋 웃는 분홍빛 우파루파';
      case CharacterType.dragon:
        return '분홍빛 뿔과 날개에 빨간 망토를 두른 반짝이는 아기 드래곤';
    }
  }

  /// 성격 태그
  String get tag {
    switch (this) {
      case CharacterType.cat:
        return '#도도포근 #골골송 #방울스카프';
      case CharacterType.dog:
        return '#충성에너지 #꼬리살랑 #빨간반다나';
      case CharacterType.capybara:
        return '#세상평온 #귤힐링 #온천마니아';
      case CharacterType.duck:
        return '#모험가 #꽃밀짚모자 #크로스백';
      case CharacterType.axolotl:
        return '#미소천사 #신비로움 #분홍아가미';
      case CharacterType.dragon:
        return '#용맹귀염 #분홍날개 #빨간망토';
    }
  }

  /// 명세서 4-8. 동물별 고유 놀아주기 활동
  String get playActivityName {
    switch (this) {
      case CharacterType.cat:
        return '장난감 흔들기';
      case CharacterType.dog:
        return '산책';
      case CharacterType.capybara:
        return '온천 보내주기';
      case CharacterType.duck:
        return '호수 보내주기';
      case CharacterType.dragon:
        return '비행하기';
      case CharacterType.axolotl:
        return '물속 헤엄치기';
    }
  }

  /// 터치 인터랙션 시 캐릭터 전용 대사 목록
  List<String> get speechQuotes {
    switch (this) {
      case CharacterType.cat:
        return [
          '골골골... 오늘 일정 하나 끝내면 안아줄게냥!',
          '방울 소리가 딸랑딸랑~ 집중할 시간이야!',
          '집사야, 계획표에 블록 채웠어? 냥!',
          '기지개 쭉 펴고 파이팅하자냥!',
        ];
      case CharacterType.dog:
        return [
          '멍멍! 주인이랑 함께라면 뭐든 할 수 있어!',
          '꼬리 흔드는 중! 오늘 할 일 다 부숴버리자!',
          '산책만큼 신나는 시간표 짜기!',
          '간식 주면 더 열심히 응원할 멍!',
        ];
      case CharacterType.capybara:
        return [
          '머리 위 귤이 떨어지지 않게... 천천히 꾸준히~',
          '따뜻한 온천에 몸을 담그듯 편안하게 해봐요.',
          '조급해할 필요 없어요. 하나씩 실천하면 돼요.',
          '오늘도 평화로운 하루가 될 거예요.',
        ];
      case CharacterType.duck:
        return [
          '꽉꽉! 항해를 시작할 준비는 끝났다!',
          '세일러 모자를 고쳐 쓰고 목표를 향해 출항!',
          '호수로 시원하게 다이빙하듯 집중해볼까?',
          '나침반이 가리키는 곳으로 가보자꽉!',
        ];
      case CharacterType.axolotl:
        return [
          '헤헤~ 웃으면 오늘 할 일도 술술 풀려요!',
          '분홍 아가미를 살랑살랑 흔들며 응원할게요!',
          '물속을 둥둥 헤엄치듯 가볍게 시작해요~',
          '주인님 미소 짓는 모습이 제일 좋아요!',
        ];
      case CharacterType.dragon:
        return [
          '크와앙! 오늘의 모든 일정을 불태우겠다!',
          '내 작은 보랏빛 날개로 하늘 높이 날아오를 거야!',
          '용의 심장으로 목표를 완벽하게 정복하자!',
          '주인님은 내가 지켜줄 테니 걱정 마!',
        ];
    }
  }

  /// 캐릭터 기본 에셋 경로 반환 (성장단계 및 맞춤형 팔레트 지원)
  String getAssetPath({String stage = 'baby', String? paletteKey}) {
    // 오리(duck)는 명세상 항상 기본 오리지널 에셋 유지
    if (this == CharacterType.duck) {
      return 'assets/characters/duck_$stage.png';
    }

    if (paletteKey != null && paletteKey.isNotEmpty) {
      final key = paletteKey.trim().toLowerCase();

      // 'default', 'none', '#default' 등 원래 색 옵션이거나 미지정인 경우 원본 에셋 반환
      if (key == 'default' || key == '#default' || key == 'none' || key == '#ffffff') {
        return 'assets/characters/${name}_$stage.png';
      }

      // paletteOptions 중 id 또는 hex가 일치하는 옵션 탐색
      final matched = paletteOptions.cast<CharacterPaletteOption?>().firstWhere(
        (opt) =>
            opt != null &&
            (opt.id.toLowerCase() == key ||
                opt.hex.toLowerCase() == key ||
                opt.hex.toLowerCase().replaceFirst('#', '') ==
                    key.replaceFirst('#', '')),
        orElse: () => null,
      );

      if (matched != null) {
        if (matched.id == 'default' || matched.isDefault) {
          return 'assets/characters/${name}_$stage.png';
        }
        return 'assets/characters/${name}_${matched.id}.png';
      }
    }

    // fallback: 원본 스프라이트 반환
    return 'assets/characters/${name}_$stage.png';
  }

  /// 캐릭터별 맞춤형 컬러 팔레트 선택지
  /// - 맨 첫 번째 옵션은 항상 '원래 색 (오리지널, default)'
  /// - 오리: 컬러 피커 미제공 (empty)
  /// - 카피바라: 원래 색 + 브라운 계열 4단계 명도 톤 조절
  /// - 드래곤 / 시바견 / 고양이: 원래 색 + 부위별 정밀 매핑 5대 팔레트
  List<CharacterPaletteOption> get paletteOptions {
    switch (this) {
      case CharacterType.cat:
        return const [
          CharacterPaletteOption(
            id: 'default',
            name: '원래 색 (오리지널)',
            hex: 'default',
            color: Color(0xFFFCF2EC),
            isDefault: true,
          ),
          CharacterPaletteOption(
            id: 'cheese_tabby',
            name: '치즈 태비',
            hex: '#FFD180',
            color: Color(0xFFFFD180),
          ),
          CharacterPaletteOption(
            id: 'tuxedo_black',
            name: '턱시도 블랙',
            hex: '#3D405B',
            color: Color(0xFF3D405B),
          ),
          CharacterPaletteOption(
            id: 'russian_blue',
            name: '러시안 블루',
            hex: '#B8C5D6',
            color: Color(0xFFB8C5D6),
          ),
          CharacterPaletteOption(
            id: 'lavender_siamese',
            name: '라벤더 샴',
            hex: '#EFE9F4',
            color: Color(0xFFEFE9F4),
          ),
          CharacterPaletteOption(
            id: 'cafe_mocha',
            name: '카페모카',
            hex: '#D4A373',
            color: Color(0xFFD4A373),
          ),
        ];
      case CharacterType.dog:
        return const [
          CharacterPaletteOption(
            id: 'default',
            name: '원래 색 (오리지널)',
            hex: 'default',
            color: Color(0xFFFBC091),
            isDefault: true,
          ),
          CharacterPaletteOption(
            id: 'honey_shiba',
            name: '허니 시바',
            hex: '#F6BD60',
            color: Color(0xFFF6BD60),
          ),
          CharacterPaletteOption(
            id: 'black_tan',
            name: '블랙탄',
            hex: '#424656',
            color: Color(0xFF424656),
          ),
          CharacterPaletteOption(
            id: 'white_snow',
            name: '백시바',
            hex: '#F2F4F8',
            color: Color(0xFFF2F4F8),
          ),
          CharacterPaletteOption(
            id: 'sesame',
            name: '세서미',
            hex: '#BC8A5F',
            color: Color(0xFFBC8A5F),
          ),
          CharacterPaletteOption(
            id: 'strawberry_milk',
            name: '스트로베리 밀크',
            hex: '#FFC2D1',
            color: Color(0xFFFFC2D1),
          ),
        ];
      case CharacterType.capybara:
        return const [
          CharacterPaletteOption(
            id: 'default',
            name: '원래 색 (오리지널)',
            hex: 'default',
            color: Color(0xFFF4A162),
            isDefault: true,
          ),
          CharacterPaletteOption(
            id: 'capy_light',
            name: '라이트 허니',
            hex: '#F8B880',
            color: Color(0xFFF8B880),
          ),
          CharacterPaletteOption(
            id: 'capy_caramel',
            name: '캐러멜 브라운',
            hex: '#DE8645',
            color: Color(0xFFDE8645),
          ),
          CharacterPaletteOption(
            id: 'capy_deep',
            name: '딥 체스넛',
            hex: '#BD6633',
            color: Color(0xFFBD6633),
          ),
          CharacterPaletteOption(
            id: 'capy_dark',
            name: '다크 에스프레소',
            hex: '#8C4724',
            color: Color(0xFF8C4724),
          ),
        ];
      case CharacterType.duck:
        // 명세: 오리는 컬러 피커 제거 및 항상 오리지널 에셋 유지
        return const [];
      case CharacterType.axolotl:
        return const [];
      case CharacterType.dragon:
        return const [
          CharacterPaletteOption(
            id: 'default',
            name: '원래 색 (오리지널)',
            hex: 'default',
            color: Color(0xFFFCE5D6),
            isDefault: true,
          ),
          CharacterPaletteOption(
            id: 'cream_peach',
            name: '크림 피치',
            hex: '#FFD8BE',
            color: Color(0xFFFFD8BE),
          ),
          CharacterPaletteOption(
            id: 'sunshine_gold',
            name: '썬샤인 골드',
            hex: '#FFE680',
            color: Color(0xFFFFE680),
          ),
          CharacterPaletteOption(
            id: 'lavender_sugar',
            name: '라벤더 슈가',
            hex: '#D8C3FF',
            color: Color(0xFFD8C3FF),
          ),
          CharacterPaletteOption(
            id: 'strawberry_milk',
            name: '스트로베리 밀크',
            hex: '#FFC2D1',
            color: Color(0xFFFFC2D1),
          ),
          CharacterPaletteOption(
            id: 'charcoal_black',
            name: '차콜 블랙',
            hex: '#3E4251',
            color: Color(0xFF3E4251),
          ),
        ];
    }
  }
}

/// 캐릭터 컬러 옵션 클래스
class CharacterPaletteOption {
  final String id;
  final String name;
  final String hex;
  final Color color;
  final bool isDefault;

  const CharacterPaletteOption({
    required this.id,
    required this.name,
    required this.hex,
    required this.color,
    this.isDefault = false,
  });
}

/// PIPI 캐릭터 데이터 모델
///
/// 명세서 5. 데이터 모델:
/// - type: 캐릭터 종류 (cat, dog, capybara, duck, axolotl, dragon)
/// - color: 선택한 품종/색상 (HEX 코드 또는 옵션명)
/// - name: 사용자가 직접 지어준 캐릭터 이름
/// - level: 레벨 (기본값 1)
/// - exp: 경험치 (기본값 0, 100마다 레벨업)
/// - stage: 성장 단계 ('baby': 새끼, 'teen': 청소년, 'adult': 성체)
/// - intimacy: 친밀감 수치 (0 ~ 100, 기본값 50)
/// - coins: 보유 코인 (기본값 100)
/// - snacks: 보유 간식 개수 (기본값 5)
/// - ownedItems: 구매/보유한 아이템 목록
/// - equippedItems: 현재 착용한 아이템 목록
/// - lastVisit: 마지막 접속 일시
class Character {
  final String type;
  final String color;
  final String name;
  final int level;
  final int exp;
  final String stage;
  final int intimacy;
  final int coins;
  final int snacks;
  final List<String> ownedItems;
  final List<String> equippedItems;
  final DateTime lastVisit;

  const Character({
    required this.type,
    required this.color,
    required this.name,
    this.level = 1,
    this.exp = 0,
    this.stage = 'baby',
    this.intimacy = 50,
    this.coins = 100,
    this.snacks = 5,
    this.ownedItems = const [],
    this.equippedItems = const [],
    required this.lastVisit,
  });

  /// CharacterType 열거형 접근자
  CharacterType get characterType => CharacterType.fromString(type);

  /// 한글 성장 단계 이름
  String get stageKoreanName {
    switch (stage) {
      case 'teen':
        return '청소년';
      case 'adult':
        return '성체';
      case 'baby':
      default:
        return '새끼';
    }
  }

  /// 친밀감 상태 문구 (명세서 4-9)
  String get intimacyStatusText {
    if (intimacy >= 75) return '높음 (애교 가득)';
    if (intimacy >= 30) return '보통 (안정적)';
    return '낮음 (관심 필요)';
  }

  /// 다음 레벨까지 필요한 경험치 (기본 100)
  int get maxExpForCurrentLevel => 100;

  /// 현재 레벨 경험치 진행도 (0.0 ~ 1.0)
  double get expProgress => (exp % maxExpForCurrentLevel) / maxExpForCurrentLevel;

  /// 백엔드 API 및 SharedPreferences 저장을 위한 JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'color': color,
      'name': name,
      'level': level,
      'exp': exp,
      'stage': stage,
      'intimacy': intimacy,
      'coins': coins,
      'snacks': snacks,
      'ownedItems': ownedItems,
      'equippedItems': equippedItems,
      'lastVisit': lastVisit.toIso8601String(),
    };
  }

  /// JSON 객체로부터 Character 인스턴스를 역직렬화
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      type: json['type'] as String? ?? 'cat',
      color: json['color'] as String? ?? '#FFFFFF',
      name: json['name'] as String? ?? '피피',
      level: json['level'] as int? ?? 1,
      exp: json['exp'] as int? ?? 0,
      stage: json['stage'] as String? ?? 'baby',
      intimacy: json['intimacy'] as int? ?? 50,
      coins: json['coins'] as int? ?? 100,
      snacks: json['snacks'] as int? ?? 5,
      ownedItems: (json['ownedItems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      equippedItems: (json['equippedItems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastVisit: json['lastVisit'] != null
          ? DateTime.tryParse(json['lastVisit'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// 불변 객체 복사 생성
  Character copyWith({
    String? type,
    String? color,
    String? name,
    int? level,
    int? exp,
    String? stage,
    int? intimacy,
    int? coins,
    int? snacks,
    List<String>? ownedItems,
    List<String>? equippedItems,
    DateTime? lastVisit,
  }) {
    return Character(
      type: type ?? this.type,
      color: color ?? this.color,
      name: name ?? this.name,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      stage: stage ?? this.stage,
      intimacy: intimacy ?? this.intimacy,
      coins: coins ?? this.coins,
      snacks: snacks ?? this.snacks,
      ownedItems: ownedItems ?? this.ownedItems,
      equippedItems: equippedItems ?? this.equippedItems,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }

  @override
  String toString() =>
      'Character(name: $name, type: $type, level: $level, stage: $stage)';
}
