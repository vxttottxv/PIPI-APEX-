import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../providers/auth_provider.dart';
import '../providers/character_provider.dart';
import '../widgets/character_view.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_ui_kit.dart';
import 'home_screen.dart';

/// 레퍼런스 5 & 레퍼런스 2 디자인: 픽셀 캐릭터 선택 및 이름 확정 모달 화면
class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  final _nameController = TextEditingController();
  int _currentIndex = 0;

  CharacterType get _selectedType => CharacterType.values[_currentIndex];
  CharacterType get _nextType =>
      CharacterType.values[(_currentIndex + 1) % CharacterType.values.length];

  @override
  void initState() {
    super.initState();
    _nameController.text = _defaultNameFor(_selectedType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _defaultNameFor(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return '눈송이';
      case CharacterType.dog:
        return '뭉치';
      case CharacterType.capybara:
        return '바라';
      case CharacterType.duck:
        return '마린이';
      case CharacterType.axolotl:
        return '루파';
      case CharacterType.dragon:
        return '용용이';
    }
  }

  void _prevCharacter() {
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + CharacterType.values.length) %
          CharacterType.values.length;
      _nameController.text = _defaultNameFor(_selectedType);
    });
  }

  void _nextCharacter() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % CharacterType.values.length;
      _nameController.text = _defaultNameFor(_selectedType);
    });
  }

  /// 레퍼런스 2: 이름 설정 안내 팝업 모달
  Future<void> _handleSelect() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구의 이름을 입력해주세요!')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 팝업 본체 픽셀 카드
              PixelBox(
                step: 8.0,
                shadowOffset: 6.0,
                backgroundColor: const Color(0xFFF0F6FF),
                borderColor: PixelColors.borderDark,
                borderWidth: 2.8,
                margin: const EdgeInsets.only(top: 76),
                padding: const EdgeInsets.fromLTRB(20, 34, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 헤더 뱃지: 🐾 이름 설정 안내 🐾
                    PixelBox(
                      step: 4.5,
                      shadowOffset: 2.0,
                      lipHeight: 2.5,
                      backgroundColor: const Color(0xFFDDEBFD),
                      lipColor: const Color(0xFFB7D6FA),
                      borderColor: PixelColors.borderLight,
                      borderWidth: 2.0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 7),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelIcon(
                            PixelIconType.paw,
                            size: 16,
                            primaryColor: PixelColors.primaryBlueLight,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '이름 설정 안내',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: PixelColors.textDark,
                            ),
                          ),
                          SizedBox(width: 8),
                          PixelIcon(
                            PixelIconType.paw,
                            size: 16,
                            primaryColor: PixelColors.primaryBlueLight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 본문 문구
                    const Text(
                      '설정한 이름은',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: PixelColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 하이라이트 박스 + 하단 픽셀 지그재그 밑줄
                    Column(
                      children: [
                        PixelBox(
                          step: 3.5,
                          shadowOffset: 0.0,
                          enableBevel: false,
                          backgroundColor: const Color(0xFFDCEBFC),
                          borderColor: PixelColors.primaryBlueLight,
                          borderWidth: 1.5,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          child: const Text(
                            '한 번 정하면 변경할 수 없어요!',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: PixelColors.primaryBlueDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 140,
                          height: 6,
                          child: CustomPaint(
                            painter: _PixelZigzagUnderlinePainter(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      '계속 진행할까요?',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: PixelColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 취소 / 확인 픽셀 버튼 Row
                    Row(
                      children: [
                        Expanded(
                          child: PixelButton(
                            text: '취소',
                            isWhite: true,
                            withSparkle: false,
                            height: 48,
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PixelButton(
                            text: '확인',
                            withSparkle: false,
                            height: 48,
                            pixelIcon: const PixelIcon(
                              PixelIconType.paw,
                              size: 17,
                              primaryColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 상단 빼꼼 나와있는 새로 제작된 순수 투명 픽셀 고양이 + 반짝이!
              Positioned(
                top: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/pixel_ui/cat_peeking.png',
                      width: 112,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                    Positioned(
                      right: -18,
                      top: 6,
                      child: Transform.rotate(
                        angle: 0.45,
                        child: const PixelSparkle(
                          color: Color(0xFFFFC107),
                          pixelSize: 2.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final characterProvider = context.read<CharacterProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final defaultPalette = _selectedType.paletteOptions.first;
    final success = await characterProvider.selectCharacter(
      userId: userId,
      type: _selectedType,
      name: name,
      colorHex: defaultPalette.hex,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(characterProvider.errorMessage ?? '캐릭터 생성 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelColors.bgSky,
      body: SafeArea(
        child: PixelScreenBorder(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 1. 상단 리본 배너 ("🐾 캐릭터 선택 🐾")
                const PixelRibbonHeader(title: '캐릭터 선택'),

                const SizedBox(height: 24),

                // 2. 메인: 좌측 대형 캐릭터 카드 & 우측 컨트롤 컬럼
                Expanded(
                  child: Row(
                    children: [
                      // 좌측: 초대형 캐릭터 쇼케이스 픽셀 카드 (이중 픽셀 테두리)
                      Expanded(
                        flex: 6,
                        child: PixelBox(
                          step: 6.0,
                          shadowOffset: 5.0,
                          backgroundColor: Colors.white,
                          borderColor: PixelColors.primaryBlue,
                          borderWidth: 3.0,
                          doubleBorder: true,
                          innerBorderColor: PixelColors.primaryBlueLight,
                          child: Center(
                            child: CharacterView(
                              characterType: _selectedType,
                              size: 210,
                              animated: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // 우측: 동물 선택 버튼 & 다음 캐릭터 프리뷰
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 픽셀 반짝이 광선
                            const PixelSparkle(
                              color: PixelColors.primaryBlueLight,
                              pixelSize: 2.8,
                            ),
                            const SizedBox(height: 8),

                            // 캐릭터 스위처 픽셀 알약: [ ◀  고양이  ▶ ]
                            PixelBox(
                              height: 54,
                              step: 4.5,
                              shadowOffset: 3.5,
                              lipHeight: 3.5,
                              backgroundColor: const Color(0xFFEBF4FE),
                              lipColor: const Color(0xFFC5DDFB),
                              borderColor: PixelColors.borderDark,
                              borderWidth: 2.5,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  PixelBox(
                                    width: 32,
                                    height: 36,
                                    step: 2.5,
                                    shadowOffset: 1.5,
                                    backgroundColor:
                                        PixelColors.primaryBlueLight,
                                    lipColor: PixelColors.primaryBlue,
                                    borderColor: PixelColors.borderDark,
                                    borderWidth: 1.8,
                                    onTap: _prevCharacter,
                                    child: const Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          PixelIcon(PixelIconType.triangleLeft,
                                              size: 16),
                                          Opacity(
                                            opacity: 0.0,
                                            child: Icon(
                                                Icons.arrow_left_rounded,
                                                size: 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      _selectedType.koreanName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: PixelColors.textDark,
                                      ),
                                    ),
                                  ),
                                  PixelBox(
                                    width: 32,
                                    height: 36,
                                    step: 2.5,
                                    shadowOffset: 1.5,
                                    backgroundColor:
                                        PixelColors.primaryBlueLight,
                                    lipColor: PixelColors.primaryBlue,
                                    borderColor: PixelColors.borderDark,
                                    borderWidth: 1.8,
                                    onTap: _nextCharacter,
                                    child: const Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          PixelIcon(PixelIconType.triangleRight,
                                              size: 16),
                                          Opacity(
                                            opacity: 0.0,
                                            child: Icon(
                                                Icons.arrow_right_rounded,
                                                size: 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // 다음 캐릭터 뱃지 (시안 6번처럼 상단에 걸친 파란 라벨 + 흰색 알약 박스)
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.topCenter,
                              children: [
                                PixelBox(
                                  step: 3.5,
                                  shadowOffset: 2.5,
                                  lipHeight: 2.5,
                                  backgroundColor: Colors.white,
                                  lipColor: const Color(0xFFD8E9FC),
                                  borderColor: PixelColors.borderLight,
                                  borderWidth: 2.0,
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 14, 14, 10),
                                  onTap: _nextCharacter,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const PixelIcon(
                                        PixelIconType.paw,
                                        size: 16,
                                        primaryColor:
                                            PixelColors.primaryBlueLight,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _nextType.koreanName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: PixelColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const PixelIcon(
                                        PixelIconType.paw,
                                        size: 16,
                                        primaryColor:
                                            PixelColors.primaryBlueLight,
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -9,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 1.5),
                                    color: PixelColors.primaryBlue,
                                    child: const Text(
                                      '다음 캐릭터',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. 이름 입력 영역 (양옆 대각선 반짝이 포함 시안 6번 스타일)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PixelBox(
                      height: 52,
                      step: 4.5,
                      shadowOffset: 3.0,
                      lipHeight: 2.5,
                      backgroundColor: Colors.white,
                      lipColor: const Color(0xFFD5E6FA),
                      borderColor: PixelColors.borderDark,
                      borderWidth: 2.5,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const PixelIcon(PixelIconType.pencil, size: 20),
                          const SizedBox(width: 10),
                          Container(
                            width: 1.5,
                            height: 20,
                            color: PixelColors.borderLight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: PixelColors.textDark,
                              ),
                              decoration: const InputDecoration(
                                hintText: '이름 입력',
                                hintStyle: TextStyle(
                                  color: PixelColors.textMuted,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const PixelIcon(
                            PixelIconType.paw,
                            size: 18,
                            primaryColor: PixelColors.primaryBlueLight,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -6,
                      top: -12,
                      child: Transform.rotate(
                        angle: -0.45,
                        child: const PixelSparkle(
                          color: PixelColors.primaryBlueLight,
                          pixelSize: 2.3,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -12,
                      child: Transform.rotate(
                        angle: 0.45,
                        child: const PixelSparkle(
                          color: PixelColors.primaryBlueLight,
                          pixelSize: 2.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 4. 하단 액션 버튼: [ 선택하기 ]
                PixelButton(
                  text: '선택하기',
                  onPressed: _handleSelect,
                  withSparkle: false,
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelZigzagUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PixelColors.primaryBlueLight
      ..style = PaintingStyle.fill;
    const block = 3.0;
    for (double x = 0; x < size.width - block; x += block * 2) {
      final isUp = ((x ~/ (block * 2)) % 2 == 0);
      canvas.drawRect(
        Rect.fromLTWH(x, isUp ? 0 : block, block, block),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + block, block * 0.5, block, block),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
