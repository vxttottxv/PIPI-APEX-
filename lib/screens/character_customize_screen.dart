import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../providers/auth_provider.dart';
import '../providers/character_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/character_view.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';

/// 2단계 커스터마이징 화면: 이름 설정 & 컬러팔레트(품종/색상) 정하기
class CharacterCustomizeScreen extends StatefulWidget {
  final CharacterType characterType;

  const CharacterCustomizeScreen({
    super.key,
    required this.characterType,
  });

  @override
  State<CharacterCustomizeScreen> createState() =>
      _CharacterCustomizeScreenState();
}

class _CharacterCustomizeScreenState extends State<CharacterCustomizeScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _nameController.text = _defaultNameFor(widget.characterType);
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

  List<String> get _recommendedNames {
    switch (widget.characterType) {
      case CharacterType.cat:
        return ['눈송이', '나비', '구름이', '미미', '치즈'];
      case CharacterType.dog:
        return ['뭉치', '보리', '해피', '누룽지', '콩이'];
      case CharacterType.capybara:
        return ['바라', '유자', '포근이', '카피', '탱귤'];
      case CharacterType.duck:
        return ['마린이', '도날드', '꽥꽥이', '선장님', '치치'];
      case CharacterType.axolotl:
        return ['루파', '로티', '분홍이', '아가미', '포롱이'];
      case CharacterType.dragon:
        return ['용용이', '다크', '카이저', '수호', '하쿠'];
    }
  }

  String _roomAssetFor(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return 'assets/rooms/room_cat.jpg';
      case CharacterType.dog:
        return 'assets/rooms/room_dog.jpg';
      case CharacterType.capybara:
        return 'assets/rooms/room_capybara.jpg';
      case CharacterType.duck:
        return 'assets/rooms/room_duck.jpg';
      case CharacterType.axolotl:
        return 'assets/rooms/room_axolotl.jpg';
      case CharacterType.dragon:
        return 'assets/rooms/room_dragon.jpg';
    }
  }

  Future<void> _handleConfirm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final characterName = _nameController.text.trim();
    final chosenPalette =
        widget.characterType.paletteOptions[_selectedColorIndex];

    // 확정 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.pets_rounded, color: AppColors.pointNavy, size: 24),
              SizedBox(width: 8),
              Text(
                '파트너 확정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pointNavy,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\'$characterName\' (${widget.characterType.koreanName} / ${chosenPalette.name})와(과) 함께 PIPI를 시작하시겠습니까?',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD6E4F8)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_rounded,
                        color: AppColors.pointNavy, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '선택한 캐릭터는 육성 특성상 지속해서 함께 성장하게 됩니다.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.pointNavy,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('다시 볼래요', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pointNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('결정하고 시작하기'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final characterProvider = context.read<CharacterProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 올바르지 않습니다.')),
      );
      return;
    }

    final success = await characterProvider.selectCharacter(
      userId: userId,
      type: widget.characterType,
      name: characterName,
      colorHex: chosenPalette.hex,
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
          content:
              Text(characterProvider.errorMessage ?? '캐릭터 생성에 실패했습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();
    final paletteOptions = widget.characterType.paletteOptions;
    final currentPalette = paletteOptions[_selectedColorIndex];
    final roomAsset = _roomAssetFor(widget.characterType);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false, // 상단 배경 일러스트가 상태표시줄까지 시원하게 확장
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── 1. 메인: 화면 상단을 크게 차지하는 방 배경 & 초대형 실시간 컬러 반응 픽셀 캐릭터 ──
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 방 배경 픽셀 일러스트 (화면 메인)
                    Image.asset(
                      roomAsset,
                      fit: BoxFit.cover,
                    ),

                    // 감성 비네팅 그라데이션
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),

                    // 상단 내비게이션 바 (뒤로가기 & 화면 타이틀)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.pointNavy, size: 18),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              '프로필 설정',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pointNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 44), // 좌우 균형용 여백
                        ],
                      ),
                    ),

                    // 초대형 픽셀 아트 캐릭터 (품종 선택 시 즉시 실시간 색상 반영!)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 현재 선택된 품종/색상 실시간 알림 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: currentPalette.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '${currentPalette.name} · 실시간 반영 중',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 초대형 캐릭터 뷰 (customColor 전달로 실시간 변환)
                          CharacterView(
                            characterType: widget.characterType,
                            size: 250, // 메인으로 시원하게 크게 배치!
                            animated: true,
                            customColor: currentPalette.color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. 하단: 불투명한 칸 안에서 누르는 선택 패널 (품종 선택, 이름 설정, 시작 버튼) ──
              Expanded(
                flex: 13,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white, // 100% 완전 불투명한 흰색 배경 칸!
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 상단 드래그 인디케이터 바
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // 스크롤 가능한 옵션 영역
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── 섹션 1: 품종 / 털색 선택 ──
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.palette_rounded,
                                          size: 18, color: AppColors.pointNavy),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '품종 / 털색 선택',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.pointNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF5FE),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFD0E1FD)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: currentPalette.color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.black26),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          currentPalette.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.pointNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 불투명한 칸 안에서 누를 수 있는 컬러/품종 선택 버튼들
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                    paletteOptions.length, (index) {
                                  final option = paletteOptions[index];
                                  final isSelected =
                                      index == _selectedColorIndex;

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedColorIndex = index;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 13, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFEFF5FE)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.pointNavy
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 2.2 : 1.0,
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: AppColors.pointNavy
                                                  .withValues(alpha: 0.12),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: option.color,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: option.color
                                                                .computeLuminance() >
                                                            0.5
                                                        ? Colors.black87
                                                        : Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            option.name,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? AppColors.pointNavy
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 18),

                              // ── 섹션 2: 이름 짓기 ──
                              Row(
                                children: [
                                  const Icon(Icons.edit_note_rounded,
                                      size: 19, color: AppColors.pointNavy),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '이름 짓기',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.pointNavy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _nameController,
                                label: '캐릭터 이름',
                                hintText: '이름을 입력해주세요 (최대 8자)',
                                prefixIcon: Icons.badge_outlined,
                                onChanged: (val) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return '이름을 입력해주세요.';
                                  }
                                  if (val.trim().length > 8) {
                                    return '이름은 최대 8자까지 가능합니다.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _recommendedNames.map((rec) {
                                  final isCurrent =
                                      _nameController.text == rec;
                                  return ActionChip(
                                    label: Text(rec),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isCurrent
                                          ? Colors.white
                                          : AppColors.pointNavy,
                                    ),
                                    backgroundColor: isCurrent
                                        ? AppColors.pointNavy
                                        : const Color(0xFFEFF5FE),
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _nameController.text = rec;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 하단 확정 버튼 ──
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: characterProvider.isLoading
                                ? null
                                : _handleConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pointNavy,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.pointNavy
                                  .withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: characterProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        '\'${_nameController.text.trim().isEmpty ? widget.characterType.koreanName : _nameController.text.trim()}\'(으)로 PIPI 시작하기',
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

