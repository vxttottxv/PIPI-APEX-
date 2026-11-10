import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/character.dart';

/// 3D 클레이 쉐이딩 및 손가락/마우스 실시간 3D 회전 제스처를 지원하는 3D 캐릭터 뷰
class AnimatedAnimalView extends StatefulWidget {
  final CharacterType characterType;
  final double size;
  final bool animated;

  const AnimatedAnimalView({
    super.key,
    required this.characterType,
    this.size = 200,
    this.animated = true,
  });

  @override
  State<AnimatedAnimalView> createState() => _AnimatedAnimalViewState();
}

class _AnimatedAnimalViewState extends State<AnimatedAnimalView>
    with TickerProviderStateMixin {
  // 1. 기본 3D 턴테이블 회전 및 호흡 루프
  late AnimationController _idle3DController;

  // 2. 신체 동작 (꼬리 흔들기 / 날개 파닥이기)
  late AnimationController _actionController;

  // 3. 눈 깜빡임 (Eye Blink)
  late AnimationController _blinkController;

  // 4. 드래그 해제 시 정면 복귀 스프링 애니메이션
  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  // 실시간 사용자 3D 드래그 회전각 (라디안)
  Offset _dragRotation = Offset.zero;
  Offset _dragStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // 부드러운 3D 턴테이블 호흡 루프 (3초)
    _idle3DController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 꼬리/날개 빠른 모션
    final fastDuration = widget.characterType == CharacterType.dog ||
            widget.characterType == CharacterType.duck
        ? const Duration(milliseconds: 380)
        : const Duration(milliseconds: 650);

    _actionController = AnimationController(
      vsync: this,
      duration: fastDuration,
    );

    // 눈 깜빡임 (3.4초 주기)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    // 복귀 스프링
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (widget.animated) {
      _idle3DController.repeat(reverse: true);
      _actionController.repeat(reverse: true);
      _blinkController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedAnimalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.characterType != oldWidget.characterType) {
      _idle3DController.dispose();
      _actionController.dispose();
      _blinkController.dispose();
      _springController.dispose();
      _dragRotation = Offset.zero;
      _initAnimations();
    }
  }

  @override
  void dispose() {
    _idle3DController.dispose();
    _actionController.dispose();
    _blinkController.dispose();
    _springController.dispose();
    super.dispose();
  }

  // 3D 드래그 인터랙션 처리 (손가락/마우스로 돌려보기)
  void _onPanStart(DragStartDetails details) {
    _springController.stop();
    _dragStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // 좌우 드래그 -> Y축 회전 (최대 +-0.75 라디안, 약 +-43도)
      // 상하 드래그 -> X축 회전 (최대 +-0.35 라디안, 약 +-20도)
      final delta = details.localPosition - _dragStart;
      _dragRotation = Offset(
        (delta.dx * 0.008).clamp(-0.75, 0.75),
        (-delta.dy * 0.005).clamp(-0.35, 0.35),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _springAnimation = Tween<Offset>(
      begin: _dragRotation,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    ));

    _springController.reset();
    _springController.forward();
    _springController.addListener(() {
      setState(() {
        _dragRotation = _springAnimation.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idle3DController,
          _actionController,
          _blinkController,
        ]),
        builder: (context, child) {
          // 기본 3D 오토 턴테이블 (살짝 좌우로 몸을 돌리며 3D 입체감 과시)
          final autoTurnY = math.sin(_idle3DController.value * math.pi * 2) * 0.12;
          final autoTiltX = math.cos(_idle3DController.value * math.pi * 2) * 0.04;
          final breathY = -math.sin(_idle3DController.value * math.pi * 2).abs() * 6.0;

          // 드래그 회전과 오토 턴테이블 합성
          final totalRotY = (autoTurnY + _dragRotation.dx).clamp(-0.85, 0.85);
          final totalRotX = (autoTiltX + _dragRotation.dy).clamp(-0.45, 0.45);

          // 꼬리/날개 빠른 모션 값 (-1.0 ~ 1.0)
          final actionPhase = math.sin(_actionController.value * math.pi * 2);

          // 눈 깜빡임
          final blinkVal = _blinkController.value;
          final isBlink = blinkVal > 0.94;
          final blinkProgress = isBlink
              ? math.sin((blinkVal - 0.94) / 0.06 * math.pi)
              : 0.0;

          // 3D Perspective Matrix4 적용
          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.0018) // 3D 원근감 (Perspective depth)
            ..multiply(Matrix4.translationValues(0.0, breathY, 0.0))
            ..rotateX(totalRotX)
            ..rotateY(totalRotY);

          return Transform(
            alignment: Alignment.bottomCenter,
            transform: matrix,
            child: SizedBox(
              width: size,
              height: size + 24,
              child: CustomPaint(
                size: Size(size, size + 24),
                painter: _Clay3DAnimalPainter(
                  type: widget.characterType,
                  rotY: totalRotY,
                  rotX: totalRotX,
                  actionPhase: actionPhase,
                  blinkAmount: blinkProgress,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 3D 구체 볼륨, 광택 스페큘러, 앰비언트 쉐도우를 렌더링하는 3D 클레이 페인터
class _Clay3DAnimalPainter extends CustomPainter {
  final CharacterType type;
  final double rotY; // Y축 3D 회전각
  final double rotX; // X축 3D 회전각
  final double actionPhase; // 꼬리/날개 모션
  final double blinkAmount; // 눈 깜빡임

  _Clay3DAnimalPainter({
    required this.type,
    required this.rotY,
    required this.rotX,
    required this.actionPhase,
    required this.blinkAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final s = size.width / 200.0;

    canvas.save();
    canvas.translate(cx, cy);

    // 3D 바닥 접촉 그림자 (회전 각도에 따라 그림자가 연동되어 이동)
    _draw3DGroundShadow(canvas, s);

    switch (type) {
      case CharacterType.dog:
        _draw3DDog(canvas, s);
        break;
      case CharacterType.cat:
        _draw3DCat(canvas, s);
        break;
      case CharacterType.duck:
        _draw3DDuck(canvas, s);
        break;
      case CharacterType.capybara:
        _draw3DCapybara(canvas, s);
        break;
      case CharacterType.axolotl:
        _draw3DAxolotl(canvas, s);
        break;
      case CharacterType.dragon:
        _draw3DDragon(canvas, s);
        break;
    }

    canvas.restore();
  }

  /// 3D 공간 바닥 그림자 (조명 방향에 맞춘 입체 앰비언트 쉐도우)
  void _draw3DGroundShadow(Canvas canvas, double s) {
    final shadowX = rotY * 18 * s;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shadowX, 66 * s),
        width: 104 * s,
        height: 24 * s,
      ),
      shadowPaint,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🐶 3D 강아지 (Shiba/Goldie 3D Clay Style)
  // ─────────────────────────────────────────────────────────────
  void _draw3DDog(Canvas canvas, double s) {
    final baseColor = const Color(0xFFF39C12);
    final darkShade = const Color(0xFFB9770E);
    final lightColor = const Color(0xFFFDEBD0);

    // 1. 3D 꼬리 (엉덩이 뒤에서 좌우로 힘차게 흔들림)
    final tailWag = actionPhase * 0.55;
    canvas.save();
    canvas.translate((32 - rotY * 15) * s, 18 * s);
    canvas.rotate(tailWag + rotY * 0.4);
    _draw3DSphere(
      canvas,
      Offset(16 * s, -14 * s),
      14 * s,
      baseColor,
      darkShade,
      lightColor,
      specular: 0.4,
    );
    _draw3DSphere(
      canvas,
      Offset(26 * s, -24 * s),
      10 * s,
      lightColor,
      baseColor,
      Colors.white,
      specular: 0.5,
    );
    canvas.restore();

    // 2. 3D 통통한 몸통 구체
    _draw3DSphere(
      canvas,
      Offset(0, 26 * s),
      44 * s,
      baseColor,
      darkShade,
      lightColor,
    );

    // 배 하얀 털 3D 볼륨
    _draw3DSphere(
      canvas,
      Offset(rotY * 8 * s, 34 * s),
      26 * s,
      lightColor,
      const Color(0xFFF5CBA7),
      Colors.white,
      specular: 0.35,
    );

    // 3. 3D 앞발 2개 (바닥을 딛고 콩콩)
    _draw3DSphere(canvas, Offset(-20 * s + rotY * 4 * s, 60 * s), 13 * s, lightColor, const Color(0xFFF5CBA7), Colors.white);
    _draw3DSphere(canvas, Offset(20 * s + rotY * 4 * s, 60 * s), 13 * s, lightColor, const Color(0xFFF5CBA7), Colors.white);

    // 4. 3D 머리 (고개 회전 반영)
    final headCenter = Offset(rotY * 14 * s, -12 * s + rotX * 10 * s);

    // 귀 2개 (3D 볼륨 귀)
    final leftEarX = headCenter.dx - 32 * s;
    final rightEarX = headCenter.dx + 32 * s;
    final earY = headCenter.dy - 18 * s;
    _draw3DSphere(canvas, Offset(leftEarX, earY + actionPhase * 2 * s), 14 * s, darkShade, const Color(0xFF784212), baseColor);
    _draw3DSphere(canvas, Offset(rightEarX, earY - actionPhase * 2 * s), 14 * s, darkShade, const Color(0xFF784212), baseColor);

    // 머리 3D 구체 (하이라이트 포함)
    _draw3DSphere(canvas, headCenter, 46 * s, baseColor, darkShade, lightColor);

    // 3D 튀어나온 주둥이 (Snout 3D sphere)
    final snoutCenter = Offset(headCenter.dx + rotY * 10 * s, headCenter.dy + 14 * s);
    _draw3DSphere(canvas, snoutCenter, 22 * s, lightColor, const Color(0xFFF5CBA7), Colors.white, specular: 0.6);

    // 3D 검은 코 (Black glossy nose)
    _draw3DSphere(canvas, Offset(snoutCenter.dx, snoutCenter.dy - 6 * s), 6 * s, const Color(0xFF1B2631), Colors.black, const Color(0xFF5D6D7E), specular: 0.9);

    // 분홍 혓바닥 헥헥 (Glossy Tongue)
    final tongueY = snoutCenter.dy + 14 * s + (actionPhase.abs() * 3 * s);
    _draw3DSphere(canvas, Offset(snoutCenter.dx, tongueY), 7 * s, const Color(0xFFFF6B81), const Color(0xFFD63031), Colors.white, specular: 0.7);

    // 3D 초롱초롱 눈 (깜빡임 반영)
    _draw3DEyes(
      canvas,
      Offset(headCenter.dx - 18 * s, headCenter.dy - 4 * s),
      Offset(headCenter.dx + 18 * s, headCenter.dy - 4 * s),
      7 * s,
      s,
    );

    // 볼터치 3D 블러셔
    _drawBlush(canvas, Offset(headCenter.dx - 26 * s, headCenter.dy + 10 * s), 7 * s);
    _drawBlush(canvas, Offset(headCenter.dx + 26 * s, headCenter.dy + 10 * s), 7 * s);
  }

  // ─────────────────────────────────────────────────────────────
  // 🐱 3D 고양이 (Chubby Cat 3D Clay Style)
  // ─────────────────────────────────────────────────────────────
  void _draw3DCat(Canvas canvas, double s) {
    final catWhite = const Color(0xFFF8F9FA);
    final catShade = const Color(0xFFBDC3C7);
    final orangeStripe = const Color(0xFFE67E22);

    // 1. S자 물결치는 3D 꼬리
    final tailWave = actionPhase * 16 * s;
    for (int i = 0; i < 4; i++) {
      final tx = (30 + i * 8) * s + tailWave * (i / 4.0) - rotY * 12 * s;
      final ty = (24 - i * 14) * s;
      _draw3DSphere(canvas, Offset(tx, ty), (12 - i * 1.5) * s, orangeStripe, const Color(0xFFB9770E), const Color(0xFFF5B041), specular: 0.4);
    }

    // 2. 찹쌀떡 같은 3D 몸통
    _draw3DSphere(canvas, Offset(0, 26 * s), 45 * s, catWhite, catShade, Colors.white);

    // 3. 찹쌀떡 앞발 2개
    _draw3DSphere(canvas, Offset(-18 * s, 60 * s), 13 * s, catWhite, catShade, Colors.white);
    _draw3DSphere(canvas, Offset(18 * s, 60 * s), 13 * s, catWhite, catShade, Colors.white);

    // 4. 3D 머리
    final headCenter = Offset(rotY * 14 * s, -12 * s + rotX * 10 * s);

    // 3D 뾰족 삼각 귀 (클레이 콘)
    _draw3DConeEar(canvas, Offset(headCenter.dx - 28 * s, headCenter.dy - 32 * s), 18 * s, orangeStripe);
    _draw3DConeEar(canvas, Offset(headCenter.dx + 28 * s, headCenter.dy - 32 * s), 18 * s, catWhite);

    // 3D 둥근 얼굴
    _draw3DSphere(canvas, headCenter, 46 * s, catWhite, catShade, Colors.white);

    // 치즈 얼룩
    _draw3DSphere(canvas, Offset(headCenter.dx - 24 * s, headCenter.dy - 16 * s), 16 * s, orangeStripe, const Color(0xFFB9770E), const Color(0xFFF5B041), specular: 0.3);

    // 분홍 코 (Pink Nose)
    _draw3DSphere(canvas, Offset(headCenter.dx, headCenter.dy + 8 * s), 5 * s, const Color(0xFFFFB6C1), const Color(0xFFFF69B4), Colors.white, specular: 0.8);

    // 눈 (깜빡임 반영)
    _draw3DEyes(
      canvas,
      Offset(headCenter.dx - 18 * s, headCenter.dy - 2 * s),
      Offset(headCenter.dx + 18 * s, headCenter.dy - 2 * s),
      6.5 * s,
      s,
    );

    // 볼터치
    _drawBlush(canvas, Offset(headCenter.dx - 26 * s, headCenter.dy + 12 * s), 7 * s);
    _drawBlush(canvas, Offset(headCenter.dx + 26 * s, headCenter.dy + 12 * s), 7 * s);
  }

  // ─────────────────────────────────────────────────────────────
  // 🦆 3D 오리 (Duck 3D Clay Style)
  // ─────────────────────────────────────────────────────────────
  void _draw3DDuck(Canvas canvas, double s) {
    final duckYellow = const Color(0xFFF7DC6F);
    final duckShade = const Color(0xFFD4AC0D);
    final beakOrange = const Color(0xFFE67E22);

    // 1. 3D 엉덩이 꼬리 씰룩
    _draw3DSphere(canvas, Offset((28 - rotY * 12) * s, (24 + actionPhase * 6) * s), 14 * s, duckYellow, duckShade, Colors.white);

    // 2. 3D 날개 2개 (파닥파닥 퍼덕임)
    final wingAngle = actionPhase * 14 * s;
    _draw3DSphere(canvas, Offset(-36 * s, 18 * s - wingAngle), 18 * s, duckYellow, duckShade, Colors.white);
    _draw3DSphere(canvas, Offset(36 * s, 18 * s + wingAngle), 18 * s, duckYellow, duckShade, Colors.white);

    // 3. 통통한 3D 몸통
    _draw3DSphere(canvas, Offset(0, 24 * s), 44 * s, duckYellow, duckShade, Colors.white);

    // 4. 주황색 3D 물갈퀴 발
    _draw3DSphere(canvas, Offset(-18 * s, 60 * s), 13 * s, beakOrange, const Color(0xFFBA4A00), Colors.white);
    _draw3DSphere(canvas, Offset(18 * s, 60 * s), 13 * s, beakOrange, const Color(0xFFBA4A00), Colors.white);

    // 5. 3D 머리
    final headCenter = Offset(rotY * 14 * s, -12 * s + rotX * 10 * s);
    _draw3DSphere(canvas, headCenter, 44 * s, duckYellow, duckShade, Colors.white);

    // 3D 볼록한 오리 부리 (3D Beak)
    _draw3DSphere(canvas, Offset(headCenter.dx, headCenter.dy + 14 * s), 16 * s, beakOrange, const Color(0xFFBA4A00), const Color(0xFFFAD7A0), specular: 0.7);

    // 눈 (깜빡임 반영)
    _draw3DEyes(
      canvas,
      Offset(headCenter.dx - 16 * s, headCenter.dy - 2 * s),
      Offset(headCenter.dx + 16 * s, headCenter.dy - 2 * s),
      6.5 * s,
      s,
    );

    // 볼터치
    _drawBlush(canvas, Offset(headCenter.dx - 24 * s, headCenter.dy + 10 * s), 7 * s);
    _drawBlush(canvas, Offset(headCenter.dx + 24 * s, headCenter.dy + 10 * s), 7 * s);
  }

  // ─────────────────────────────────────────────────────────────
  // 🦫 3D 카피바라 (Capybara 3D Clay Style)
  // ─────────────────────────────────────────────────────────────
  void _draw3DCapybara(Canvas canvas, double s) {
    final capyBrown = const Color(0xFFBA8A5D);
    final darkBrown = const Color(0xFF6E4A28);

    // 1. 듬직한 3D 둥근 몸통
    _draw3DSphere(canvas, Offset(0, 24 * s), 48 * s, capyBrown, darkBrown, const Color(0xFFD7BDE2), specular: 0.25);

    // 2. 발 4개
    for (final x in [-24.0, -8.0, 8.0, 24.0]) {
      _draw3DSphere(canvas, Offset(x * s, 60 * s), 10 * s, darkBrown, const Color(0xFF3E2713), Colors.white, specular: 0.3);
    }

    // 3. 3D 머리
    final headCenter = Offset(rotY * 14 * s, -12 * s + rotX * 10 * s);

    // 머리 위 통통 튀는 3D 유자 (감귤 3D sphere)
    final yuzuBounce = (actionPhase.abs() * 4 * s);
    _draw3DSphere(
      canvas,
      Offset(headCenter.dx, headCenter.dy - 44 * s - yuzuBounce),
      12 * s,
      const Color(0xFFFFA502),
      const Color(0xFFD35400),
      const Color(0xFFFFFA65),
      specular: 0.8,
    );
    // 귤 잎사귀
    _draw3DSphere(canvas, Offset(headCenter.dx + 6 * s, headCenter.dy - 54 * s - yuzuBounce), 4 * s, const Color(0xFF2ED573), const Color(0xFF20BF6B), Colors.white);

    // 3D 작은 귀 2개
    _draw3DSphere(canvas, Offset(headCenter.dx - 36 * s, headCenter.dy - 20 * s), 10 * s, darkBrown, const Color(0xFF3E2713), Colors.white, specular: 0.3);
    _draw3DSphere(canvas, Offset(headCenter.dx + 36 * s, headCenter.dy - 20 * s), 10 * s, darkBrown, const Color(0xFF3E2713), Colors.white, specular: 0.3);

    // 넙적한 3D 머리
    _draw3DSphere(canvas, headCenter, 46 * s, capyBrown, darkBrown, const Color(0xFFEDBB99), specular: 0.3);

    // 3D 넙적한 코 (Snout 3D block)
    final snoutCenter = Offset(headCenter.dx, headCenter.dy + 12 * s);
    _draw3DSphere(canvas, snoutCenter, 24 * s, darkBrown, const Color(0xFF3E2713), const Color(0xFF873600), specular: 0.4);

    // 콧구멍 2개
    _draw3DSphere(canvas, Offset(snoutCenter.dx - 6 * s, snoutCenter.dy), 3 * s, Colors.black, Colors.black, Colors.grey);
    _draw3DSphere(canvas, Offset(snoutCenter.dx + 6 * s, snoutCenter.dy), 3 * s, Colors.black, Colors.black, Colors.grey);

    // 평온한 3D 실눈 (지그시 감은 힐링 표정)
    _draw3DEyes(
      canvas,
      Offset(headCenter.dx - 20 * s, headCenter.dy - 10 * s),
      Offset(headCenter.dx + 20 * s, headCenter.dy - 10 * s),
      5.5 * s,
      s,
    );

    // 볼터치
    _drawBlush(canvas, Offset(headCenter.dx - 26 * s, headCenter.dy + 8 * s), 7 * s);
    _drawBlush(canvas, Offset(headCenter.dx + 26 * s, headCenter.dy + 8 * s), 7 * s);
  }

  // ─────────────────────────────────────────────────────────────
  // 🦎 3D 우파루파 (Axolotl 3D Clay Style)
  // ─────────────────────────────────────────────────────────────
  void _draw3DAxolotl(Canvas canvas, double s) {
    final pinkBody = const Color(0xFFFFC0CB);
    final pinkShade = const Color(0xFFFF69B4);
    final frillPink = const Color(0xFFFF1493);

    // 1. 3D 꼬리지느러미 (물결침)
    final tailWave = actionPhase * 16 * s;
    for (int i = 0; i < 3; i++) {
      _draw3DSphere(canvas, Offset((24 + i * 10) * s + tailWave, (28 + i * 4) * s), (14 - i * 3) * s, frillPink, const Color(0xFFC71585), Colors.white, specular: 0.5);
    }

    // 2. 3D 찹쌀떡 몸통
    _draw3DSphere(canvas, Offset(0, 24 * s), 44 * s, pinkBody, pinkShade, Colors.white);

    // 3. 작은 손발 2개
    _draw3DSphere(canvas, Offset(-22 * s, 58 * s), 11 * s, pinkBody, pinkShade, Colors.white);
    _draw3DSphere(canvas, Offset(22 * s, 58 * s), 11 * s, pinkBody, pinkShade, Colors.white);

    // 4. 3D 머리
    final headCenter = Offset(rotY * 14 * s, -12 * s + rotX * 10 * s);

    // 양옆 6개 3D 깃털 아가미 (Frills)
    for (int i = 0; i < 3; i++) {
      final fy = headCenter.dy - 16 * s + i * 14 * s;
      final wave = math.sin(actionPhase * math.pi + i * 0.9) * 6 * s;
      _draw3DSphere(canvas, Offset(headCenter.dx - 44 * s, fy + wave), 10 * s, frillPink, const Color(0xFFC71585), Colors.white, specular: 0.6);
      _draw3DSphere(canvas, Offset(headCenter.dx + 44 * s, fy - wave), 10 * s, frillPink, const Color(0xFFC71585), Colors.white, specular: 0.6);
    }

    // 3D 둥근 얼굴
    _draw3DSphere(canvas, headCenter, 46 * s, pinkBody, pinkShade, Colors.white);

    // 방긋 웃는 입 (Pink smile)
    _draw3DSphere(canvas, Offset(headCenter.dx, headCenter.dy + 12 * s), 5 * s, const Color(0xFFD81B60), Colors.black, Colors.white, specular: 0.5);

    // 반짝이는 눈
    _draw3DEyes(
      canvas,
      Offset(headCenter.dx - 18 * s, headCenter.dy - 2 * s),
      Offset(headCenter.dx + 18 * s, headCenter.dy - 2 * s),
      6.5 * s,
      s,
    );

    // 진분홍 볼터치
    _drawBlush(canvas, Offset(headCenter.dx - 24 * s, headCenter.dy + 12 * s), 8 * s);
    _drawBlush(canvas, Offset(headCenter.dx + 24 * s, headCenter.dy + 12 * s), 8 * s);
  }

  // ─────────────────────────────────────────────────────────────
  // 🐉 3D 드래곤 (Dragon 3D Clay Style)
  // ─────────────────────────────────────────────────────────────
  void _draw3DDragon(Canvas canvas, double s) {
    final dragonGreen = const Color(0xFF2ECC71);
    final darkGreen = const Color(0xFF1E8449);
    final wingPurple = const Color(0xFF9B59B6);
    final hornYellow = const Color(0xFFF1C40F);

    // 1. 3D 꼬리 (끝에 하트/삼각 구체)
    final tailWag = actionPhase * 16 * s;
    _draw3DSphere(canvas, Offset((32 - rotY * 12) * s, 26 * s), 14 * s, dragonGreen, darkGreen, Colors.white);
    _draw3DSphere(canvas, Offset((46 - rotY * 12) * s + tailWag, 18 * s), 12 * s, hornYellow, const Color(0xFFB7950B), Colors.white, specular: 0.7);

    // 2. 3D 날개 2개 (파닥파닥)
    final wingFlap = actionPhase * 12 * s;
    _draw3DSphere(canvas, Offset(-36 * s, 14 * s - wingFlap), 18 * s, wingPurple, const Color(0xFF6C3483), Colors.white, specular: 0.6);
    _draw3DSphere(canvas, Offset(36 * s, 14 * s + wingFlap), 18 * s, wingPurple, const Color(0xFF6C3483), Colors.white, specular: 0.6);

    // 3. 3D 몸통
    _draw3DSphere(canvas, Offset(0, 24 * s), 44 * s, dragonGreen, darkGreen, Colors.white);

    // 배 노란 볼륨
    _draw3DSphere(canvas, Offset(rotY * 8 * s, 32 * s), 24 * s, hornYellow, const Color(0xFFB7950B), Colors.white, specular: 0.5);

    // 발 2개
    _draw3DSphere(canvas, Offset(-18 * s, 60 * s), 13 * s, dragonGreen, darkGreen, Colors.white);
    _draw3DSphere(canvas, Offset(18 * s, 60 * s), 13 * s, dragonGreen, darkGreen, Colors.white);

    // 4. 3D 머리
    final headCenter = Offset(rotY * 14 * s, -12 * s + rotX * 10 * s);

    // 귀여운 작은 3D 뿔 2개
    _draw3DSphere(canvas, Offset(headCenter.dx - 22 * s, headCenter.dy - 34 * s), 10 * s, hornYellow, const Color(0xFFB7950B), Colors.white, specular: 0.8);
    _draw3DSphere(canvas, Offset(headCenter.dx + 22 * s, headCenter.dy - 34 * s), 10 * s, hornYellow, const Color(0xFFB7950B), Colors.white, specular: 0.8);

    // 3D 머리 구체
    _draw3DSphere(canvas, headCenter, 46 * s, dragonGreen, darkGreen, Colors.white);

    // 3D 주둥이
    _draw3DSphere(canvas, Offset(headCenter.dx, headCenter.dy + 12 * s), 20 * s, hornYellow, const Color(0xFFB7950B), Colors.white, specular: 0.6);

    // 눈 (깜빡임 반영)
    _draw3DEyes(
      canvas,
      Offset(headCenter.dx - 18 * s, headCenter.dy - 4 * s),
      Offset(headCenter.dx + 18 * s, headCenter.dy - 4 * s),
      7 * s,
      s,
    );

    // 볼터치
    _drawBlush(canvas, Offset(headCenter.dx - 24 * s, headCenter.dy + 12 * s), 7 * s);
    _drawBlush(canvas, Offset(headCenter.dx + 24 * s, headCenter.dy + 12 * s), 7 * s);
  }

  // ─────────────────────────────────────────────────────────────
  // 🔮 3D 구체(Sphere) 클레이 렌더링 헬퍼 (빛, 음영, 스페큘러)
  // ─────────────────────────────────────────────────────────────
  void _draw3DSphere(
    Canvas canvas,
    Offset center,
    double radius,
    Color baseColor,
    Color shadeColor,
    Color highlightColor, {
    double specular = 0.5,
  }) {
    // 1. 기본 구체 바디 (방사형 3D 조명 그라데이션)
    // 광원은 왼쪽 상단(Offset(-0.35, -0.35))에 위치
    final lightOffset = Offset(
      center.dx - radius * 0.32,
      center.dy - radius * 0.32,
    );

    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [
          highlightColor,
          baseColor,
          shadeColor,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // 2. 스페큘러 광택 하이라이트 (빛 반사 점)
    if (specular > 0.1) {
      final glintPaint = Paint()
        ..color = Colors.white.withValues(alpha: specular.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.2);

      canvas.drawCircle(
        lightOffset,
        radius * 0.24,
        glintPaint,
      );
    }
  }

  void _draw3DConeEar(Canvas canvas, Offset top, double height, Color color) {
    final earPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.7)],
      ).createShader(Rect.fromLTWH(top.dx - height / 2, top.dy, height, height));

    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx - height * 0.5, top.dy + height)
      ..lineTo(top.dx + height * 0.5, top.dy + height)
      ..close();
    canvas.drawPath(path, earPaint);
  }

  void _drawBlush(Canvas canvas, Offset center, double radius) {
    final blushPaint = Paint()
      ..color = const Color(0xFFFF4757).withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6);
    canvas.drawCircle(center, radius, blushPaint);
  }

  void _draw3DEyes(Canvas canvas, Offset left, Offset right, double radius, double s) {
    if (blinkAmount > 0.3) {
      // 감은 눈 (스마일 곡선 ^ ^)
      final eyeLine = Paint()
        ..color = const Color(0xFF1B2631)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * s
        ..strokeCap = StrokeCap.round;

      final leftPath = Path()
        ..moveTo(left.dx - radius, left.dy)
        ..quadraticBezierTo(left.dx, left.dy - radius * 0.8, left.dx + radius, left.dy);
      canvas.drawPath(leftPath, eyeLine);

      final rightPath = Path()
        ..moveTo(right.dx - radius, right.dy)
        ..quadraticBezierTo(right.dx, right.dy - radius * 0.8, right.dx + radius, right.dy);
      canvas.drawPath(rightPath, eyeLine);
    } else {
      // 3D 글래스 아이 (초롱초롱 보석 같은 눈)
      _draw3DSphere(canvas, left, radius, const Color(0xFF1B2631), Colors.black, const Color(0xFF34495E), specular: 0.85);
      _draw3DSphere(canvas, right, radius, const Color(0xFF1B2631), Colors.black, const Color(0xFF34495E), specular: 0.85);
    }
  }

  @override
  bool shouldRepaint(covariant _Clay3DAnimalPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.rotY != rotY ||
        oldDelegate.rotX != rotX ||
        oldDelegate.actionPhase != actionPhase ||
        oldDelegate.blinkAmount != blinkAmount;
  }
}
