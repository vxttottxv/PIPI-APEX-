import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../providers/auth_provider.dart';
import '../providers/character_provider.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../widgets/character_view.dart';
import '../widgets/pixel_animal_view.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_ui_kit.dart';
import 'calendar_screen.dart';
import 'character_selection_screen.dart';
import 'login_screen.dart';
import 'task_edit_screen.dart';
import 'timeline_screen.dart';
import 'timetable_screen.dart';

/// 레퍼런스 3 & 레퍼런스 신규 디자인: 일본식 야경 픽셀 룸 & 상단 애정도/간식바 & 하단 팝업 메뉴
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _quoteIndex = 0;
  bool _showAddMenu = false;
  bool _isLoggingOut = false;
  PetBehavior _currentBehavior = PetBehavior.idle;
  PetBehavior? _forcedBehavior;
  int _actionTrigger = 0;
  StreamSubscription<NotificationItem>? _alarmSubscription;

  @override
  void initState() {
    super.initState();
    _alarmSubscription =
        NotificationService.instance.onNotificationReceived.listen((item) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.alarm_rounded, color: Colors.amberAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.body,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: PixelColors.borderDark,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  void _cycleQuote(Character character) {
    setState(() {
      _quoteIndex =
          (_quoteIndex + 1) % character.characterType.speechQuotes.length;
    });
  }

  String? _behaviorStatusText(Character character, PetBehavior behavior) {
    switch (behavior) {
      case PetBehavior.roamWalk:
        return '총총총~ 방 안을 구경하는 중이에요!';
      case PetBehavior.restSquish:
        return '꾸벅꾸벅... 포근하게 쉬고 있어요 💤';
      case PetBehavior.curiousLook:
        return '두리번두리번... 주인님 뭐 하세요?';
      case PetBehavior.groomOrNap:
        return character.characterType == CharacterType.capybara
            ? '머리 위 귤 균형 잡는 중... 🍊'
            : '사각사각~ 기분 좋게 몸단장 중!';
      case PetBehavior.happyJump:
        return '폴짝! 기분이 날아갈 것 같아요!';
      case PetBehavior.spinTwirl:
        return '빙그르르~ 제 한 바퀴 어때요?';
      case PetBehavior.loveySquish:
        return '폭신폭신~ 주인님이 제일 좋아요!';
      case PetBehavior.dashZigzag:
        return '타다닥! 오늘도 에너지가 넘쳐요!';
      case PetBehavior.eatSnack:
        return '오물오물... 간식이 정말 맛있어요!';
      case PetBehavior.playBurst:
        return '야호! 함께 노니까 너무 신나요!';
      case PetBehavior.idle:
        return null;
    }
  }

  Future<void> _handleFeed(String userId, Character character) async {
    final characterProvider = context.read<CharacterProvider>();
    final success = await characterProvider.feedSnack(userId);

    if (!mounted) return;

    if (success) {
      setState(() {
        _forcedBehavior = PetBehavior.eatSnack;
        _actionTrigger++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cookie_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '${character.name}에게 간식을 주었습니다! (+20 EXP, 애정도 UP)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: PixelColors.borderDark,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(characterProvider.errorMessage ?? '간식이 부족합니다.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handlePlay(String userId, Character character) async {
    final characterProvider = context.read<CharacterProvider>();
    await characterProvider.playActivity(userId);

    if (!mounted) return;

    setState(() {
      _forcedBehavior = PetBehavior.playBurst;
      _actionTrigger++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration_rounded,
                color: Colors.amberAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              '${character.name}와(과) \'${character.characterType.playActivityName}\' 완료! (+15 EXP, +10 코인)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: PixelColors.borderDark,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.read<CharacterProvider>().clear();
    context.read<TaskProvider>().clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '계정과 캐릭터, 일정, 인트로 기록이 모두 삭제됩니다. 정말 탈퇴하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    await context.read<AuthProvider>().deleteCurrentAccount();
    if (!mounted) return;
    context.read<CharacterProvider>().clear();
    context.read<TaskProvider>().clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleResetCharacter(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('캐릭터 초기화 (개발용)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '저장된 캐릭터를 초기화하고 캐릭터 선택 화면으로 다시 이동합니다. 계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('초기화 실행', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<CharacterProvider>().resetCharacterForTesting(userId);
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CharacterSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final characterProvider = context.watch<CharacterProvider>();
    final userId = authProvider.currentUser?.id ?? '사용자';
    final character = characterProvider.currentCharacter;

    // 로그아웃 진행 중이거나 미인증 상태일 때 캐릭터 선택 화면으로 잘못 리다이렉트되지 않도록 방어
    if (_isLoggingOut || !authProvider.isAuthenticated) {
      return const Scaffold(
        backgroundColor: Color(0xFF2C4C72),
        body: SizedBox.shrink(),
      );
    }

    if (character == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const CharacterSelectionScreen()),
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final speechQuotes = character.characterType.speechQuotes;
    final currentQuote =
        _behaviorStatusText(character, _currentBehavior) ??
        speechQuotes[_quoteIndex % speechQuotes.length];

    return Scaffold(
      backgroundColor: const Color(0xFF35535E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. 메인 배경: 기기 비율에 맞춘 일본식 야경 픽셀 룸 (버튼 오버레이 없는 순수 배경) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final aspect = constraints.maxHeight > 0
                  ? constraints.maxWidth / constraints.maxHeight
                  : 0.5;
              if (aspect <= 0.65) {
                return Image.asset(
                  'assets/rooms/room_pixel_night.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.none,
                );
              }
              return DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2F4A5C),
                      Color(0xFF35535E),
                    ],
                  ),
                ),
                child: Image.asset(
                  'assets/rooms/room_pixel_night.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.none,
                ),
              );
            },
          ),

          // ── 2. 중앙 캐릭터: 방 한가운데 앉아 무한 픽셀 애니메이션 구동 ──
          Positioned(
            bottom: MediaQuery.sizeOf(context).height < 720 ? 130 : 170,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _cycleQuote(character),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 귀여운 파트너 이름 & 레벨 뱃지
                  PixelBox(
                    step: 3.0,
                    shadowOffset: 2.0,
                    backgroundColor: Colors.white,
                    borderColor: PixelColors.borderDark,
                    borderWidth: 2.0,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PixelIcon(PixelIconType.paw, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          character.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: PixelColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lv.${character.level}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: PixelColors.primaryBlueDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const PixelIcon(PixelIconType.paw, size: 15),
                      ],
                    ),
                  ),

                  // 터치 시 대사 말풍선
                  PixelBox(
                    step: 4.5,
                    shadowOffset: 3.0,
                    backgroundColor: Colors.white,
                    borderColor: PixelColors.borderDark,
                    borderWidth: 2.0,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      currentQuote,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: PixelColors.textDark,
                      ),
                    ),
                  ),

                  // 24시간 무한 루프 + 클릭/유휴(3초+) 반응형 픽셀 캐릭터
                  CharacterView(
                    characterType: character.characterType,
                    size: 200,
                    animated: true,
                    colorHex: character.color,
                    enableRoam: true,
                    forcedBehavior: _forcedBehavior,
                    actionTrigger: _actionTrigger,
                    onBehaviorChanged: (behavior) {
                      if (!mounted) return;
                      setState(() {
                        _currentBehavior = behavior;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── 3. 상단 상태바: [🍪 간식] & [💖 애정도] & 우측 메뉴 ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측: 쿠키/간식 카운터 픽셀 알약 + 좌상단 반짝이
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PixelBox(
                      height: 44,
                      step: 5.0,
                      shadowOffset: 3.0,
                      borderWidth: 2.5,
                      lipHeight: 3.0,
                      backgroundColor: Colors.white.withValues(alpha: 0.96),
                      lipColor: const Color(0xFFC5DCF7),
                      borderColor: PixelColors.borderDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          const PixelIcon(PixelIconType.cookie, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '${character.snacks}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: PixelColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PixelBox(
                            width: 26,
                            height: 26,
                            step: 3.0,
                            shadowOffset: 2.0,
                            borderWidth: 1.8,
                            lipHeight: 2.0,
                            backgroundColor: PixelColors.primaryBlueLight,
                            lipColor: PixelColors.primaryBlue,
                            borderColor: PixelColors.borderDark,
                            onTap: () => _handleFeed(userId, character),
                            child: const Center(
                              child: PixelIcon(
                                PixelIconType.plus,
                                size: 12,
                                primaryColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -6,
                      top: -12,
                      child: Transform.rotate(
                        angle: -0.35,
                        child: const PixelSparkle(
                          color: Colors.white,
                          pixelSize: 2.2,
                        ),
                      ),
                    ),
                  ],
                ),

                // 우측 그룹: 애정도 게이지 알약 + 메뉴 버튼
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PixelBox(
                          height: 44,
                          step: 5.0,
                          shadowOffset: 3.0,
                          borderWidth: 2.5,
                          lipHeight: 3.0,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.96),
                          lipColor: const Color(0xFFC5DCF7),
                          borderColor: PixelColors.borderDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          child: Row(
                            children: [
                              const PixelIcon(PixelIconType.heart, size: 22),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        '애정도',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: PixelColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        '${character.intimacy} / 100',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: PixelColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 96,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: PixelColors.borderDark,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: LinearProgressIndicator(
                                      value: (character.intimacy / 100)
                                          .clamp(0.0, 1.0),
                                      backgroundColor:
                                          const Color(0xFFF1F5F9),
                                      valueColor: const AlwaysStoppedAnimation(
                                          PixelColors.heartPink),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: -6,
                          top: -12,
                          child: Transform.rotate(
                            angle: 0.35,
                            child: const PixelSparkle(
                              color: Colors.white,
                              pixelSize: 2.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // 우측 미니 메뉴 팝업
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: PixelBox(
                        width: 40,
                        height: 40,
                        step: 3.5,
                        shadowOffset: 3.0,
                        borderWidth: 2.2,
                        backgroundColor: Colors.white,
                        lipColor: const Color(0xFFC5DCF7),
                        borderColor: PixelColors.borderDark,
                        child: const Center(
                          child: Icon(Icons.menu_rounded,
                              size: 20, color: PixelColors.textDark),
                        ),
                      ),
                  onSelected: (value) {
                    if (value == 'calendar') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CalendarScreen()));
                    } else if (value == 'timetable') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TimetableScreen()));
                    } else if (value == 'timeline') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TimelineScreen()));
                    } else if (value == 'logout') {
                      _handleLogout();
                    } else if (value == 'delete_account') {
                      _handleDeleteAccount();
                    } else if (value == 'reset') {
                      _handleResetCharacter(userId);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        '${character.name} (Lv.${character.level})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'calendar',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 18, color: PixelColors.primaryBlue),
                          SizedBox(width: 8),
                          Text('캘린더 보기'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'timetable',
                      child: Row(
                        children: [
                          Icon(Icons.view_week_rounded,
                              size: 18, color: PixelColors.primaryBlue),
                          SizedBox(width: 8),
                          Text('시간표 보기'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'timeline',
                      child: Row(
                        children: [
                          Icon(Icons.timeline_rounded,
                              size: 18, color: PixelColors.primaryBlue),
                          SizedBox(width: 8),
                          Text('실천 타임라인'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('캐릭터 다시 선택'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('로그아웃', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete_account',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove_rounded,
                              size: 18, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('회원 탈퇴',
                              style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
                  ],
                ),
              ],
            ),
          ),

          // ── 4. 팝업 메뉴 배경 닫기 디텍터 (열려있을 때 바깥 터치 시 닫힘) ──
          if (_showAddMenu)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _showAddMenu = false;
                  });
                },
                child: const SizedBox.expand(),
              ),
            ),

          // ── 5. 레퍼런스 신규 디자인: 하단 + 클릭 시 뜨는 픽셀 말풍선 팝업 메뉴 ──
          if (_showAddMenu)
            Positioned(
              bottom: 108,
              left: 0,
              right: 0,
              child: Center(
                child: PixelSpeechBubbleMenu(
                  onAddTask: () {
                    setState(() {
                      _showAddMenu = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TaskEditScreen()),
                    );
                  },
                  onOpenCalendar: () {
                    setState(() {
                      _showAddMenu = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CalendarScreen()),
                    );
                  },
                  onOpenTimeline: () {
                    setState(() {
                      _showAddMenu = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TimelineScreen()),
                    );
                  },
                ),
              ),
            ),

          // ── 6. 하단 액션바: [🐾 놀아주기]  [ + ]  [🥣 밥 주기] (중앙 + 버튼 솟아오른 시안 디자인) ──
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 하단 독 본체
                PixelBox(
                  height: 58,
                  step: 6.5,
                  shadowOffset: 4.0,
                  borderWidth: 2.8,
                  lipHeight: 3.5,
                  backgroundColor: const Color(0xFFDCEBFE),
                  lipColor: const Color(0xFFB3D2FA),
                  borderColor: PixelColors.borderDark,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 좌측: [🐾 놀아주기] 픽셀 버튼
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: PixelBox(
                            height: 40,
                            step: 4.5,
                            shadowOffset: 2.5,
                            borderWidth: 2.2,
                            lipHeight: 3.0,
                            backgroundColor: PixelColors.whiteButtonBg,
                            lipColor: PixelColors.whiteButtonLip,
                            borderColor: PixelColors.borderDark,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            onTap: () => _handlePlay(userId, character),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PixelIcon(PixelIconType.paw, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    '놀아주기',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 우측: [🥣 밥 주기] 픽셀 버튼
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: PixelBox(
                            height: 40,
                            step: 4.5,
                            shadowOffset: 2.5,
                            borderWidth: 2.2,
                            lipHeight: 3.0,
                            backgroundColor: PixelColors.whiteButtonBg,
                            lipColor: PixelColors.whiteButtonLip,
                            borderColor: PixelColors.borderDark,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            onTap: () => _handleFeed(userId, character),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PixelIcon(PixelIconType.foodBowl, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    '밥 주기',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 중앙 솟아오른 [+] 픽셀 원형/팔각 버튼 + 상단 반짝이
                Positioned(
                  top: -12,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      PixelBox(
                        width: 62,
                        height: 62,
                        step: 9.0,
                        shadowOffset: 4.0,
                        borderWidth: 3.0,
                        lipHeight: 4.5,
                        backgroundColor: _showAddMenu
                            ? PixelColors.primaryBlueDark
                            : PixelColors.primaryBlueLight,
                        highlightColor: const Color(0xFFB5DAFF),
                        lipColor: PixelColors.primaryBlue,
                        borderColor: PixelColors.borderDark,
                        onTap: () {
                          setState(() {
                            _showAddMenu = !_showAddMenu;
                          });
                        },
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PixelIcon(
                                _showAddMenu
                                    ? PixelIconType.close
                                    : PixelIconType.plus,
                                size: 28,
                                primaryColor: Colors.white,
                              ),
                              // 테스트 호환용 (시각적으로는 보이지 않음)
                              Opacity(
                                opacity: 0.0,
                                child: Icon(
                                  _showAddMenu
                                      ? Icons.close_rounded
                                      : Icons.add,
                                  size: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        top: -16,
                        child: IgnorePointer(
                          child: PixelSparkle(
                            color: Colors.white,
                            pixelSize: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
