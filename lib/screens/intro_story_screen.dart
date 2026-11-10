import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_ui_kit.dart';
import 'character_selection_screen.dart';

/// 1회성(최초 회원가입 시) 픽셀 RPG 인트로 컷신 화면
///
/// 어떤 기종(작은 폰, 대화면 스마트폰, 태블릿, 와이드 웹)에서도
/// 화면 크기와 비율에 맞추어 배경과 대화창을 자동으로 조절합니다.
class IntroStoryScreen extends StatefulWidget {
  final String userId;

  const IntroStoryScreen({
    super.key,
    required this.userId,
  });

  static String _seenKey(String userId) => 'pipi_intro_seen_$userId';

  static Future<bool> hasSeenIntro(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final localSeen = prefs.getBool(_seenKey(userId)) ?? false;
    if (localSeen) return true;

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final res = await ApiClient.instance.request('GET', '/api/intro/status');
        if (res != null && res['introSeen'] == true) {
          await prefs.setBool(_seenKey(userId), true);
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  static Future<void> markIntroSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey(userId), true);

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.instance.request('POST', '/api/intro/seen', body: {});
      } catch (_) {}
    }
  }

  @override
  State<IntroStoryScreen> createState() => _IntroStoryScreenState();
}

class _IntroStoryScene {
  final String backgroundAsset;
  final String text;
  final bool hasRain;
  final bool hasDiscoverySparkle;
  final bool hasSilhouetteHint;

  const _IntroStoryScene({
    required this.backgroundAsset,
    required this.text,
    this.hasRain = false,
    this.hasDiscoverySparkle = false,
    this.hasSilhouetteHint = false,
  });
}

class _IntroStoryScreenState extends State<IntroStoryScreen>
    with SingleTickerProviderStateMixin {
  static const List<_IntroStoryScene> _scenes = [
    _IntroStoryScene(
      backgroundAsset: 'assets/pixel_ui/intro_rain_street.png',
      text: '오늘도 바쁘고 지친 하루가 지나가고...',
      hasRain: true,
    ),
    _IntroStoryScene(
      backgroundAsset: 'assets/pixel_ui/intro_rain_street.png',
      text: '가로등 불빛만 비추는 조용한 밤길을 걷고 있었다.',
      hasRain: true,
    ),
    _IntroStoryScene(
      backgroundAsset: 'assets/pixel_ui/intro_warm_alley.png',
      text: '어... 저기 골목 안쪽에서 무언가 작게 반짝이고 있다?',
      hasDiscoverySparkle: true,
    ),
    _IntroStoryScene(
      backgroundAsset: 'assets/pixel_ui/intro_warm_alley.png',
      text: '길가다가 작고 소중한 무언가를 발견했다!',
      hasDiscoverySparkle: true,
      hasSilhouetteHint: true,
    ),
    _IntroStoryScene(
      backgroundAsset: 'assets/pixel_ui/intro_warm_alley.png',
      text: '오늘부터 내 하루를 함께 걸어갈 작은 친구를 만나러 가볼까?',
      hasDiscoverySparkle: true,
      hasSilhouetteHint: true,
    ),
  ];

  int _sceneIndex = 0;
  int _charIndex = 0;
  bool _cursorVisible = true;
  bool _isNavigating = false;

  Timer? _typewriterTimer;
  Timer? _cursorTimer;
  late AnimationController _ambientController;

  _IntroStoryScene get _currentScene => _scenes[_sceneIndex];
  bool get _isLineComplete => _charIndex >= _currentScene.text.length;
  bool get _isLastScene => _sceneIndex >= _scenes.length - 1;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _cursorVisible = !_cursorVisible);
    });

    _startTypewriter();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _cursorTimer?.cancel();
    _ambientController.dispose();
    super.dispose();
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    setState(() {
      _charIndex = 0;
    });

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 42), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charIndex < _currentScene.text.length) {
        setState(() {
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _finishIntro() async {
    if (_isNavigating) return;
    _isNavigating = true;
    _typewriterTimer?.cancel();
    _cursorTimer?.cancel();

    await IntroStoryScreen.markIntroSeen(widget.userId);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const CharacterSelectionScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  void _handleTapDialogue() {
    if (_isNavigating) return;
    if (!_isLineComplete) {
      _typewriterTimer?.cancel();
      setState(() {
        _charIndex = _currentScene.text.length;
      });
      return;
    }

    if (!_isLastScene) {
      setState(() {
        _sceneIndex++;
      });
      _startTypewriter();
    } else {
      _finishIntro();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = _currentScene.text.substring(
      0,
      _charIndex.clamp(0, _currentScene.text.length),
    );
    final mediaPadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTapDialogue,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;
            final aspect = screenH > 0 ? screenW / screenH : 0.56;
            final isWideScreen = aspect > 0.72;

            // 기종/창 크기에 맞춘 반응형 컷신 스테이지 크기 계산
            // 세로 모바일: 전체 폭 100% 꽉 채움
            // 가로 웹/태블릿: 이미지가 과도하게 확대되어 깨지지 않도록 9:16 기반 스테이지 폭 자동 산출
            final maxStageW = math.min(screenW, 560.0).toDouble();
            final minStageW = math.min(380.0, maxStageW).toDouble();
            final double stageWidth = isWideScreen
                ? (screenH * 0.60).clamp(minStageW, maxStageW).toDouble()
                : screenW;
            final dialogMinHeight = (screenH * 0.155).clamp(108.0, 142.0);
            final fontSize = (stageWidth * 0.041).clamp(14.5, 17.5);
            final dialogBottom = mediaPadding.bottom + 20.0;

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── 0. 와이드 화면용 은은한 다크 앰비언트 배경 (세로 화면에서는 투명) ──
                if (isWideScreen) ...[
                  Opacity(
                    opacity: 0.25,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 650),
                      child: SizedBox.expand(
                        key: ValueKey('ambient_${_currentScene.backgroundAsset}'),
                        child: Image.asset(
                          _currentScene.backgroundAsset,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Color(0x330B101D),
                          Color(0xEE0B101D),
                        ],
                      ),
                    ),
                  ),
                ],

                // ── 1. 중앙 반응형 픽셀 컷신 스테이지 ──
                Center(
                  child: SizedBox(
                    width: stageWidth,
                    height: screenH,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 고해상도 컷신 배경 이미지 (기종 크기에 맞게 깨짐 없이 자동 맞춤)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 650),
                          child: SizedBox.expand(
                            key: ValueKey(_currentScene.backgroundAsset),
                            child: Image.asset(
                              _currentScene.backgroundAsset,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),

                        // 와이드 화면일 때 좌우 경계를 부드럽게 감싸는 비네팅
                        if (isWideScreen)
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: [0.0, 0.08, 0.92, 1.0],
                                colors: [
                                  Color(0xFF0B101D),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Color(0xFF0B101D),
                                ],
                              ),
                            ),
                          ),

                        // 실시간 빗줄기 / 골목길 발견 반짝임 오버레이
                        AnimatedBuilder(
                          animation: _ambientController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _IntroAtmospherePainter(
                                t: _ambientController.value,
                                hasRain: _currentScene.hasRain,
                                hasDiscoverySparkle:
                                    _currentScene.hasDiscoverySparkle,
                                hasSilhouetteHint:
                                    _currentScene.hasSilhouetteHint,
                              ),
                            );
                          },
                        ),

                        // 발견 실루엣 (4~5번째 컷: 대화창 바로 위 골목 바닥에서 반짝임)
                        if (_currentScene.hasSilhouetteHint)
                          Positioned(
                            bottom: dialogBottom + dialogMinHeight + 28,
                            left: 0,
                            right: 0,
                            child: AnimatedBuilder(
                              animation: _ambientController,
                              builder: (context, _) {
                                final bob = math.sin(
                                    _ambientController.value * math.pi * 2);
                                return Center(
                                  child: Transform.translate(
                                    offset: Offset(0, bob * 4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PixelBox(
                                          step: 3.0,
                                          shadowOffset: 2.0,
                                          enableBevel: false,
                                          backgroundColor: Colors.white,
                                          borderColor:
                                              const Color(0xFF1E375C),
                                          borderWidth: 2.2,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 3),
                                          child: const Text(
                                            '!',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFE55353),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0x66FFD44D),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          child: const PixelIcon(
                                            PixelIconType.paw,
                                            size: 30,
                                            primaryColor: Color(0xFF284673),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // 상단 우측 SKIP 버튼
                        Positioned(
                          top: mediaPadding.top + 14,
                          right: 16,
                          child: PixelBox(
                            step: 3.5,
                            shadowOffset: 2.5,
                            borderWidth: 2.0,
                            lipHeight: 2.0,
                            backgroundColor: const Color(0xDD17223B),
                            lipColor: const Color(0xDD0D1426),
                            borderColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            onTap: _finishIntro,
                            child: const Text(
                              'SKIP >>',
                              style: TextStyle(
                                fontFamily: 'Galmuri11',
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        // 하단 레트로 RPG 픽셀 대화창 (계단식 도트 프레임 + 픽셀 글씨체)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: dialogBottom,
                          child: CustomPaint(
                            painter: _RetroRpgDialogPainter(),
                            child: Container(
                              width: double.infinity,
                              constraints:
                                  BoxConstraints(minHeight: dialogMinHeight),
                              padding:
                                  const EdgeInsets.fromLTRB(22, 20, 22, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontFamily: 'Galmuri11',
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                        height: 1.65,
                                        letterSpacing: 0.3,
                                      ),
                                      children: [
                                        TextSpan(text: visibleText),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                                milliseconds: 80),
                                            opacity:
                                                _cursorVisible ? 1.0 : 0.0,
                                            child: Container(
                                              width: 8,
                                              height: fontSize,
                                              margin: const EdgeInsets.only(
                                                  left: 4),
                                              color: const Color(0xFFFFD44D),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_sceneIndex + 1} / ${_scenes.length}',
                                        style: TextStyle(
                                          fontFamily: 'Galmuri11',
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      if (_isLineComplete)
                                        AnimatedBuilder(
                                          animation: _ambientController,
                                          builder: (context, _) {
                                            final bob =
                                                (_ambientController.value * 2)
                                                            .floor() %
                                                        2 ==
                                                    0;
                                            return Transform.translate(
                                              offset:
                                                  Offset(0, bob ? 0 : 3.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _isLastScene
                                                        ? '터치해서 만나기'
                                                        : '터치하여 계속',
                                                    style: const TextStyle(
                                                      fontFamily: 'Galmuri11',
                                                      fontSize: 12.0,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFFFFD44D),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  PixelIcon(
                                                    _isLastScene
                                                        ? PixelIconType
                                                            .triangleRight
                                                        : PixelIconType
                                                            .triangleDown,
                                                    size: 12,
                                                    primaryColor:
                                                        const Color(0xFFFFD44D),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      else
                                        Text(
                                          '터치 시 즉시 표시',
                                          style: TextStyle(
                                            fontFamily: 'Galmuri11',
                                            fontSize: 10.5,
                                            color: Colors.white
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                    ],
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
            );
          },
        ),
      ),
    );
  }
}

/// 시안 이미지와 동일한 이중 흰 테두리 + 코너 도트 장식 레트로 RPG 대화창 페인터
class _RetroRpgDialogPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 0. 하단 4px 도트 그림자
    final shadowPath = buildPixelPath(size, 4.0);
    canvas.save();
    canvas.translate(0, 4.0);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = const Color(0x99040712)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    final bgPath = buildPixelPath(size, 4.0);
    final bgPaint = Paint()
      ..color = const Color(0xF00D1322)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bgPath, bgPaint);

    final outerStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(bgPath, outerStroke);

    const inset = 6.0;
    final innerPath = buildPixelPath(
      Size(w - inset * 2, h - inset * 2),
      3.0,
    );
    canvas.save();
    canvas.translate(inset, inset);
    final innerStroke = Paint()
      ..color = const Color(0xFF7FAAE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(innerPath, innerStroke);
    canvas.restore();

    final dotPaint = Paint()..color = const Color(0xFFFFD44D);
    const d = 4.0;
    canvas.drawRect(const Rect.fromLTWH(9, 9, d, d), dotPaint);
    canvas.drawRect(Rect.fromLTWH(w - 13, 9, d, d), dotPaint);
    canvas.drawRect(Rect.fromLTWH(9, h - 13, d, d), dotPaint);
    canvas.drawRect(Rect.fromLTWH(w - 13, h - 13, d, d), dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 인트로 밤길 실시간 빗줄기 & 골목길 발견 반짝임 픽셀 페인터
class _IntroAtmospherePainter extends CustomPainter {
  final double t;
  final bool hasRain;
  final bool hasDiscoverySparkle;
  final bool hasSilhouetteHint;

  _IntroAtmospherePainter({
    required this.t,
    required this.hasRain,
    required this.hasDiscoverySparkle,
    required this.hasSilhouetteHint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (hasRain) {
      final rainPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 24; i++) {
        final seedX = ((i * 73) % 100) / 100.0;
        final speed = 1.0 + (i % 3) * 0.35;
        final offset = ((i * 37) % 100) / 100.0;
        final progress = (t * speed + offset) % 1.0;

        final x = seedX * w;
        final y = progress * (h * 0.85);
        canvas.drawRect(Rect.fromLTWH(x, y, 2.0, 14.0), rainPaint);
      }
    }

    if (hasDiscoverySparkle) {
      final pulse = (0.4 + 0.6 * math.sin(t * math.pi * 4).abs());
      final sparklePaint = Paint()
        ..color = Color.fromRGBO(255, 218, 100, pulse)
        ..style = PaintingStyle.fill;

      final spots = [
        Offset(w * 0.5, h * 0.66),
        Offset(w * 0.44, h * 0.63),
        Offset(w * 0.57, h * 0.64),
      ];
      for (int i = 0; i < spots.length; i++) {
        final s = (i == 0 ? 4.0 : 2.5) * pulse;
        final cx = spots[i].dx;
        final cy = spots[i].dy;
        canvas.drawRect(
            Rect.fromLTWH(cx - s * 2, cy - s * 0.5, s * 4, s), sparklePaint);
        canvas.drawRect(
            Rect.fromLTWH(cx - s * 0.5, cy - s * 2, s, s * 4), sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IntroAtmospherePainter old) =>
      old.t != t ||
      old.hasRain != hasRain ||
      old.hasDiscoverySparkle != hasDiscoverySparkle ||
      old.hasSilhouetteHint != hasSilhouetteHint;
}
