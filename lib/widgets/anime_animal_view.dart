import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/character.dart';

/// 스튜디오 지브리(Studio Ghibli) 애니메이션 감성의 2D 캐릭터 뷰
///
/// 지브리 감성 요소:
/// 1. 따뜻한 수채화풍 자연광 파스텔 색채 & 부드러운 핸드드로운(손그림) 외곽선
/// 2. 지브리 특유의 깊고 맑은 눈망울 (영롱한 수채화 하이라이트)
/// 3. 고양이: 키키의 지지 / 고양이의 보은 감성 (귀 뒤에서 볼까지 쓱싹 닦는 포근한 세수 모션)
/// 4. 강아지: 하울의 힌 / 토토로 감성의 몽실몽실 털뭉치 강아지 (달려와서 혀 빼꼼 꼬리 붕붕)
/// 5. 오리: 센과 치히로의 '오오토리사마(온천 병아리신)' 감성
/// 6. 우파루파: '벼랑 위의 포뇨' 감성 (물방울 퐁퐁 신비로운 유영)
/// 7. 드래곤: 센과 치히로의 '하쿠(白龍)' 감성의 청록빛 신비로운 아기 용
/// 8. 공중에 은은하게 부유하는 지브리 먼지/반딧불이 파티클
class AnimeAnimalView extends StatefulWidget {
  final CharacterType characterType;
  final double size;
  final bool animated;

  const AnimeAnimalView({
    super.key,
    required this.characterType,
    this.size = 200,
    this.animated = true,
  });

  @override
  State<AnimeAnimalView> createState() => _AnimeAnimalViewState();
}

class _AnimeAnimalViewState extends State<AnimeAnimalView>
    with TickerProviderStateMixin {
  // 1. 메인 감성 동작 사이클 (세수, 달리기, 춤추기)
  late AnimationController _mainActionController;

  // 2. 빠른 보조 모션 (꼬리 살랑, 혓바닥 헥헥, 귀 쫑긋)
  late AnimationController _wiggleController;

  // 3. 지브리 부유 파티클 (Ambient Floating Dust)
  late AnimationController _particleController;

  // 4. 지브리 특유의 감성 눈 깜빡임 (Slow Blink)
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _mainActionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    if (widget.animated) {
      _mainActionController.repeat();
      _wiggleController.repeat(reverse: true);
      _particleController.repeat();
      _blinkController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimeAnimalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.characterType != oldWidget.characterType) {
      _mainActionController.dispose();
      _wiggleController.dispose();
      _particleController.dispose();
      _blinkController.dispose();
      _initAnimations();
    }
  }

  @override
  void dispose() {
    _mainActionController.dispose();
    _wiggleController.dispose();
    _particleController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainActionController,
        _wiggleController,
        _particleController,
        _blinkController,
      ]),
      builder: (context, child) {
        final actionT = _mainActionController.value;
        final fastVal = math.sin(_wiggleController.value * math.pi * 2);
        final particleT = _particleController.value;

        // 눈 깜빡임: 주기의 끝 6%에서 부드럽게 감겼다 뜸
        final blinkVal = _blinkController.value;
        final isBlink = blinkVal > 0.94;
        final blinkAmount = isBlink
            ? math.sin((blinkVal - 0.94) / 0.06 * math.pi)
            : 0.0;

        return SizedBox(
          width: size,
          height: size + 24,
          child: CustomPaint(
            size: Size(size, size + 24),
            painter: _GhibliArtPainter(
              type: widget.characterType,
              actionT: actionT,
              fastVal: fastVal,
              particleT: particleT,
              blinkAmount: blinkAmount,
            ),
          ),
        );
      },
    );
  }
}

/// 스튜디오 지브리 감성 페인터
class _GhibliArtPainter extends CustomPainter {
  final CharacterType type;
  final double actionT;
  final double fastVal;
  final double particleT;
  final double blinkAmount;

  _GhibliArtPainter({
    required this.type,
    required this.actionT,
    required this.fastVal,
    required this.particleT,
    required this.blinkAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final s = size.width / 200.0;

    canvas.save();
    canvas.translate(cx, cy);

    // 1. 지브리 수채화 수묵 바닥 그림자 (부드러운 워시 질감)
    _drawGhibliGroundShadow(canvas, s);

    // 2. 캐릭터 본체 렌더링
    switch (type) {
      case CharacterType.cat:
        _drawGhibliCat(canvas, s);
        break;
      case CharacterType.dog:
        _drawGhibliDog(canvas, s);
        break;
      case CharacterType.duck:
        _drawGhibliDuck(canvas, s);
        break;
      case CharacterType.capybara:
        _drawGhibliCapybara(canvas, s);
        break;
      case CharacterType.axolotl:
        _drawGhibliAxolotl(canvas, s);
        break;
      case CharacterType.dragon:
        _drawGhibliDragon(canvas, s);
        break;
    }

    // 3. 지브리 특유의 감성 부유 입자 (햇살 먼지 / 민들레 홀씨 / 반딧불이)
    _drawGhibliAtmosphereParticles(canvas, s);

    canvas.restore();
  }

  void _drawGhibliGroundShadow(Canvas canvas, double s) {
    final shadowPaint = Paint()
      ..color = const Color(0x3834495E)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * s);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 66 * s), width: 108 * s, height: 20 * s),
      shadowPaint,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🐱 1. 지브리 고양이 ('키키의 지지' & '고양이의 보은' 감성의 세수 모션)
  // ─────────────────────────────────────────────────────────────
  void _drawGhibliCat(Canvas canvas, double s) {
    // 지브리 따뜻한 크림 수채화톤
    final furCream = const Color(0xFFFFF9EE);
    final furWarmShade = const Color(0xFFF3E5D0);
    final gingerOrange = const Color(0xFFF39C12);
    final softPink = const Color(0xFFFFB6C1);
    final ghibliLine = Paint()
      ..color = const Color(0xFF3E2F28) // 지브리 특유의 흑갈색 연필선
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 세수 사이클 (0.2 ~ 0.8 구간에서 얼굴을 쓱싹쓱싹 문지름!)
    final isGrooming = actionT >= 0.20 && actionT <= 0.80;
    double pawY = 56 * s;
    double pawX = 14 * s;
    double pawRot = 0.0;

    if (actionT >= 0.20 && actionT < 0.32) {
      final prog = (actionT - 0.20) / 0.12;
      pawY = (56 - prog * 60) * s;
      pawX = (14 - prog * 8) * s;
      pawRot = prog * 0.4;
    } else if (actionT >= 0.32 && actionT < 0.72) {
      // 쓱싹쓱싹 부드러운 손동작 3회 반복!
      final washCycle = math.sin((actionT - 0.32) / 0.40 * math.pi * 6);
      pawY = (-4 + washCycle * 5) * s;
      pawX = (6 + washCycle * 14) * s;
      pawRot = 0.4 + washCycle * 0.25;
    } else if (actionT >= 0.72 && actionT <= 0.80) {
      final prog = (actionT - 0.72) / 0.08;
      pawY = (-4 + prog * 60) * s;
      pawX = (6 + prog * 8) * s;
      pawRot = (1.0 - prog) * 0.4;
    }

    // 1. 우아하게 흔들리는 지브리 고양이 꼬리 (살랑살랑)
    final tailWave = fastVal * 14 * s;
    final tailPath = Path()
      ..moveTo(26 * s, 36 * s)
      ..cubicTo(56 * s + tailWave, 28 * s, 48 * s - tailWave, -8 * s, 64 * s + tailWave, -26 * s)
      ..cubicTo(50 * s - tailWave, -12 * s, 44 * s + tailWave, 26 * s, 20 * s, 44 * s)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = gingerOrange);
    canvas.drawPath(tailPath, ghibliLine);

    // 2. 얌전하고 보송보송한 식빵 몸통
    final bodyPath = Path()
      ..moveTo(-34 * s, 60 * s)
      ..cubicTo(-44 * s, 12 * s, -30 * s, -2 * s, 0, -2 * s)
      ..cubicTo(30 * s, -2 * s, 44 * s, 12 * s, 34 * s, 60 * s)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = furCream);
    // 몸통 수채화 음영
    canvas.drawPath(bodyPath, Paint()..color = furWarmShade.withValues(alpha: 0.45));
    canvas.drawPath(bodyPath, ghibliLine);

    // 왼쪽 앞발 (바닥에 얌전히 딛음)
    canvas.drawOval(Rect.fromCenter(center: Offset(-14 * s, 58 * s), width: 18 * s, height: 16 * s), Paint()..color = furCream);
    canvas.drawOval(Rect.fromCenter(center: Offset(-14 * s, 58 * s), width: 18 * s, height: 16 * s), ghibliLine);

    // 3. 지브리 감성 머리 (뺨에 보송보송 털이 삐져나온 손그림)
    final headCenter = Offset(0, -16 * s);

    // 귀 2개 (속털이 보송보송한 지브리 귀)
    final leftEarTilt = isGrooming ? -0.15 : 0.0;
    canvas.save();
    canvas.translate(headCenter.dx - 22 * s, headCenter.dy - 16 * s);
    canvas.rotate(leftEarTilt);
    final leftEar = Path()
      ..moveTo(-14 * s, -4 * s)
      ..lineTo(-8 * s, -36 * s)
      ..lineTo(14 * s, -14 * s)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = gingerOrange);
    canvas.drawPath(leftEar, ghibliLine);
    final leftInner = Path()
      ..moveTo(-10 * s, -6 * s)
      ..lineTo(-6 * s, -30 * s)
      ..lineTo(10 * s, -14 * s)
      ..close();
    canvas.drawPath(leftInner, Paint()..color = softPink);
    canvas.restore();

    final rightEarTilt = isGrooming ? 0.25 : 0.0;
    canvas.save();
    canvas.translate(headCenter.dx + 22 * s, headCenter.dy - 16 * s);
    canvas.rotate(rightEarTilt);
    final rightEar = Path()
      ..moveTo(-14 * s, -14 * s)
      ..lineTo(8 * s, -36 * s)
      ..lineTo(14 * s, -4 * s)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = furCream);
    canvas.drawPath(rightEar, ghibliLine);
    final rightInner = Path()
      ..moveTo(-10 * s, -14 * s)
      ..lineTo(6 * s, -30 * s)
      ..lineTo(10 * s, -6 * s)
      ..close();
    canvas.drawPath(rightInner, Paint()..color = softPink);
    canvas.restore();

    // 뺨 털이 몽실몽실한 얼굴 윤곽
    final headPath = Path()
      ..moveTo(-34 * s, -20 * s)
      ..cubicTo(-46 * s, -6 * s, -44 * s, 14 * s, -32 * s, 22 * s) // 뺨 털
      ..cubicTo(-18 * s, 28 * s, 18 * s, 28 * s, 32 * s, 22 * s)
      ..cubicTo(44 * s, 14 * s, 46 * s, -6 * s, 34 * s, -20 * s) // 뺨 털
      ..cubicTo(20 * s, -30 * s, -20 * s, -30 * s, -34 * s, -20 * s)
      ..close();
    canvas.drawPath(headPath, Paint()..color = furCream);
    canvas.drawPath(headPath, ghibliLine);

    // 치즈 얼룩 무늬 (이마)
    final foreheadPattern = Path()
      ..moveTo(-26 * s, -24 * s)
      ..quadraticBezierTo(-8 * s, -16 * s, -18 * s, 4 * s)
      ..close();
    canvas.drawPath(foreheadPattern, Paint()..color = gingerOrange);

    // 앙증맞은 분홍 삼각 코
    final nose = Path()
      ..moveTo(-4 * s, -6 * s)
      ..lineTo(4 * s, -6 * s)
      ..lineTo(0, -1 * s)
      ..close();
    canvas.drawPath(nose, Paint()..color = softPink);

    // 오메가(ω) 고양이 입
    final mouth = Path()
      ..moveTo(-7 * s, 3 * s)
      ..quadraticBezierTo(-3.5 * s, 7 * s, 0, 1 * s)
      ..quadraticBezierTo(3.5 * s, 7 * s, 7 * s, 3 * s);
    canvas.drawPath(mouth, ghibliLine..strokeWidth = 2.4 * s);

    // 보송보송 수염 4줄기
    canvas.drawLine(Offset(-22 * s, -2 * s), Offset(-42 * s, -6 * s), ghibliLine..strokeWidth = 1.6 * s);
    canvas.drawLine(Offset(-22 * s, 3 * s), Offset(-40 * s, 8 * s), ghibliLine);
    canvas.drawLine(Offset(22 * s, -2 * s), Offset(42 * s, -6 * s), ghibliLine);
    canvas.drawLine(Offset(22 * s, 3 * s), Offset(40 * s, 8 * s), ghibliLine);

    // 맑고 영롱한 지브리 호박색 눈 (지지/바론 감성)
    if (isGrooming || blinkAmount > 0.4) {
      // 냥~ 세수하며 지그시 감은 행복한 눈 (^ ^)
      _drawGhibliHappyEyes(canvas, headCenter.dx - 18 * s, headCenter.dy - 6 * s, headCenter.dx + 18 * s, headCenter.dy - 6 * s, 8 * s, s, ghibliLine);
    } else {
      _drawGhibliGlassEyes(
        canvas,
        headCenter.dx - 18 * s,
        headCenter.dy - 6 * s,
        headCenter.dx + 18 * s,
        headCenter.dy - 6 * s,
        8.5 * s,
        s,
        const Color(0xFFF39C12), // 영롱한 호박색 눈동자
      );
    }

    // 수채화 볼터치
    _drawGhibliBlush(canvas, Offset(headCenter.dx - 26 * s, headCenter.dy + 6 * s), 8 * s);
    _drawGhibliBlush(canvas, Offset(headCenter.dx + 26 * s, headCenter.dy + 6 * s), 8 * s);

    // 4. 고양이 세수하는 찹쌀떡 앞발 (얼굴을 쓱싹 문지름)
    canvas.save();
    canvas.translate(pawX, pawY);
    canvas.rotate(pawRot);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 22 * s, height: 20 * s), Paint()..color = furCream);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 22 * s, height: 20 * s), ghibliLine);
    // 분홍 젤리 발바닥
    canvas.drawCircle(Offset(0, 2 * s), 4 * s, Paint()..color = softPink);
    canvas.drawCircle(Offset(-5 * s, -3 * s), 2.2 * s, Paint()..color = softPink);
    canvas.drawCircle(Offset(0, -5 * s), 2.2 * s, Paint()..color = softPink);
    canvas.drawCircle(Offset(5 * s, -3 * s), 2.2 * s, Paint()..color = softPink);
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────
  // 🐶 2. 지브리 강아지 (하울의 '힌' 감성 몽실몽실 털복숭이 + 혀 빼꼼 꼬리 붕붕)
  // ─────────────────────────────────────────────────────────────
  void _drawGhibliDog(Canvas canvas, double s) {
    final goldieColor = const Color(0xFFFFD572);
    final earColor = const Color(0xFFE5A638);
    final warmWhite = const Color(0xFFFFF9ED);
    final tonguePink = const Color(0xFFFF768E);
    final ghibliLine = Paint()
      ..color = const Color(0xFF3A2A1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bounceY = -fastVal.abs() * 7 * s;

    canvas.save();
    canvas.translate(0, bounceY);

    // 1. 꼬리 붕붕 (Wagging tail)
    final tailAngle = fastVal * 0.75;
    canvas.save();
    canvas.translate(32 * s, 24 * s);
    canvas.rotate(tailAngle);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(28 * s, -14 * s, 36 * s, -32 * s)
      ..quadraticBezierTo(18 * s, -22 * s, 0, 10 * s)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = earColor);
    canvas.drawPath(tailPath, ghibliLine);
    canvas.restore();

    // 2. 몽실몽실 털결이 살아있는 둥근 몸통
    final bodyRect = Rect.fromCenter(center: Offset(0, 24 * s), width: 84 * s, height: 70 * s);
    canvas.drawOval(bodyRect, Paint()..color = goldieColor);
    canvas.drawOval(bodyRect, ghibliLine);

    // 포근한 가슴 흰 털
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 32 * s), width: 46 * s, height: 42 * s), Paint()..color = warmWhite);

    // 3. 총총 뛰어오는 앙증맞은 앞발 (콩콩)
    final leftPawY = 56 * s + (fastVal > 0 ? -6 * s : 0);
    final rightPawY = 56 * s + (fastVal < 0 ? -6 * s : 0);
    canvas.drawOval(Rect.fromCenter(center: Offset(-18 * s, leftPawY), width: 22 * s, height: 18 * s), Paint()..color = warmWhite);
    canvas.drawOval(Rect.fromCenter(center: Offset(-18 * s, leftPawY), width: 22 * s, height: 18 * s), ghibliLine);
    canvas.drawOval(Rect.fromCenter(center: Offset(18 * s, rightPawY), width: 22 * s, height: 18 * s), Paint()..color = warmWhite);
    canvas.drawOval(Rect.fromCenter(center: Offset(18 * s, rightPawY), width: 22 * s, height: 18 * s), ghibliLine);

    // 4. 귀가 펄럭펄럭 춤추는 머리
    final headCenter = Offset(0, -14 * s);

    // 펄럭이는 댕댕이 귀 2개 (Flopping ears)
    final leftEarAngle = -0.22 + fastVal * 0.28;
    canvas.save();
    canvas.translate(headCenter.dx - 32 * s, headCenter.dy - 18 * s);
    canvas.rotate(leftEarAngle);
    final leftEar = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-24 * s, 8 * s, -18 * s, 38 * s)
      ..quadraticBezierTo(-2 * s, 28 * s, 6 * s, 8 * s)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = earColor);
    canvas.drawPath(leftEar, ghibliLine);
    canvas.restore();

    final rightEarAngle = 0.22 - fastVal * 0.28;
    canvas.save();
    canvas.translate(headCenter.dx + 32 * s, headCenter.dy - 18 * s);
    canvas.rotate(rightEarAngle);
    final rightEar = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(24 * s, 8 * s, 18 * s, 38 * s)
      ..quadraticBezierTo(2 * s, 28 * s, -6 * s, 8 * s)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = earColor);
    canvas.drawPath(rightEar, ghibliLine);
    canvas.restore();

    // 몽실몽실 얼굴
    final headRect = Rect.fromCenter(center: headCenter, width: 86 * s, height: 74 * s);
    canvas.drawOval(headRect, Paint()..color = goldieColor);
    canvas.drawOval(headRect, ghibliLine);

    // 둥근 주둥이
    canvas.drawOval(Rect.fromCenter(center: Offset(0, headCenter.dy + 14 * s), width: 46 * s, height: 34 * s), Paint()..color = warmWhite);

    // 까망 밤톨 코
    canvas.drawOval(Rect.fromCenter(center: Offset(0, headCenter.dy + 6 * s), width: 14 * s, height: 10 * s), Paint()..color = const Color(0xFF2C1B10));

    // '헤~' 길게 내민 혓바닥 헥헥 (Panting Tongue)
    final tongueY = headCenter.dy + 20 * s + fastVal.abs() * 5 * s;
    final tongue = Path()
      ..moveTo(-7 * s, headCenter.dy + 16 * s)
      ..quadraticBezierTo(0, tongueY + 9 * s, 7 * s, headCenter.dy + 16 * s)
      ..close();
    canvas.drawPath(tongue, Paint()..color = tonguePink);
    canvas.drawPath(tongue, ghibliLine..strokeWidth = 2.4 * s);

    // 영롱한 지브리 눈망울
    _drawGhibliGlassEyes(
      canvas,
      headCenter.dx - 18 * s,
      headCenter.dy - 6 * s,
      headCenter.dx + 18 * s,
      headCenter.dy - 6 * s,
      8.5 * s,
      s,
      const Color(0xFF4A2810),
    );

    // 수채화 볼터치
    _drawGhibliBlush(canvas, Offset(headCenter.dx - 26 * s, headCenter.dy + 8 * s), 7.5 * s);
    _drawGhibliBlush(canvas, Offset(headCenter.dx + 26 * s, headCenter.dy + 8 * s), 7.5 * s);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────
  // 🦆 3. 지브리 오리 (센과 치히로의 온천 병아리신 '오오토리사마' 감성!)
  // ─────────────────────────────────────────────────────────────
  void _drawGhibliDuck(Canvas canvas, double s) {
    final duckYellow = const Color(0xFFFFF2B2);
    final beakOrange = const Color(0xFFFF9F43);
    final leafGreen = const Color(0xFF2ED573);
    final ghibliLine = Paint()
      ..color = const Color(0xFF3D2E24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bounceY = -fastVal.abs() * 5 * s;
    canvas.save();
    canvas.translate(0, bounceY);

    // 엉덩이 씰룩
    final buttWave = fastVal * 10 * s;
    final tailPath = Path()
      ..moveTo(26 * s, 28 * s)
      ..lineTo(44 * s + buttWave, 20 * s)
      ..lineTo(32 * s, 38 * s)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = const Color(0xFFFFE082));
    canvas.drawPath(tailPath, ghibliLine);

    // 듬직하고 푸근한 온천 오리신 몸통
    final bodyRect = Rect.fromCenter(center: Offset(0, 26 * s), width: 84 * s, height: 72 * s);
    canvas.drawOval(bodyRect, Paint()..color = duckYellow);
    canvas.drawOval(bodyRect, ghibliLine);

    // 날개 파닥파닥
    final wingAngle = fastVal * 0.65;
    canvas.save();
    canvas.translate(-34 * s, 18 * s);
    canvas.rotate(-wingAngle - 0.2);
    final leftWing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-28 * s, -6 * s, -30 * s, 18 * s)
      ..quadraticBezierTo(-14 * s, 22 * s, 0, 14 * s)
      ..close();
    canvas.drawPath(leftWing, Paint()..color = const Color(0xFFFFE082));
    canvas.drawPath(leftWing, ghibliLine);
    canvas.restore();

    canvas.save();
    canvas.translate(34 * s, 18 * s);
    canvas.rotate(wingAngle + 0.2);
    final rightWing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(28 * s, -6 * s, 30 * s, 18 * s)
      ..quadraticBezierTo(14 * s, 22 * s, 0, 14 * s)
      ..close();
    canvas.drawPath(rightWing, Paint()..color = const Color(0xFFFFE082));
    canvas.drawPath(rightWing, ghibliLine);
    canvas.restore();

    // 주황 물갈퀴 발
    canvas.drawOval(Rect.fromCenter(center: Offset(-18 * s, 60 * s), width: 22 * s, height: 12 * s), Paint()..color = beakOrange);
    canvas.drawOval(Rect.fromCenter(center: Offset(-18 * s, 60 * s), width: 22 * s, height: 12 * s), ghibliLine);
    canvas.drawOval(Rect.fromCenter(center: Offset(18 * s, 60 * s), width: 22 * s, height: 12 * s), Paint()..color = beakOrange);
    canvas.drawOval(Rect.fromCenter(center: Offset(18 * s, 60 * s), width: 22 * s, height: 12 * s), ghibliLine);

    // 머리
    final headCenter = Offset(0, -14 * s);

    // 센과 치히로 온천신 시그니처: 머리 위에 얹은 작은 나뭇잎!
    final leaf = Path()
      ..moveTo(headCenter.dx, headCenter.dy - 40 * s)
      ..quadraticBezierTo(headCenter.dx + 12 * s, headCenter.dy - 48 * s, headCenter.dx + 10 * s, headCenter.dy - 36 * s)
      ..close();
    canvas.drawPath(leaf, Paint()..color = leafGreen);
    canvas.drawPath(leaf, ghibliLine..strokeWidth = 2 * s);

    // 푸근한 둥근 얼굴
    final headRect = Rect.fromCenter(center: headCenter, width: 84 * s, height: 72 * s);
    canvas.drawOval(headRect, Paint()..color = duckYellow);
    canvas.drawOval(headRect, ghibliLine);

    // 둥글넙적 귀여운 오리 부리
    final beakRect = Rect.fromCenter(center: Offset(0, headCenter.dy + 12 * s), width: 36 * s, height: 22 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(beakRect, Radius.circular(11 * s)), Paint()..color = beakOrange);
    canvas.drawRRect(RRect.fromRectAndRadius(beakRect, Radius.circular(11 * s)), ghibliLine);

    // 영롱한 눈 & 볼터치
    _drawGhibliGlassEyes(canvas, headCenter.dx - 16 * s, headCenter.dy - 2 * s, headCenter.dx + 16 * s, headCenter.dy - 2 * s, 8 * s, s, const Color(0xFF2C3E50));
    _drawGhibliBlush(canvas, Offset(headCenter.dx - 26 * s, headCenter.dy + 8 * s), 7.5 * s);
    _drawGhibliBlush(canvas, Offset(headCenter.dx + 26 * s, headCenter.dy + 8 * s), 7.5 * s);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────
  // 🦫 4. 지브리 카피바라 (온천 숲 신령 감성 + 모락모락 온천 수증기)
  // ─────────────────────────────────────────────────────────────
  void _drawGhibliCapybara(Canvas canvas, double s) {
    final capyWarmBrown = const Color(0xFFD4A373);
    final darkBrown = const Color(0xFF7F4F24);
    final ghibliLine = Paint()
      ..color = const Color(0xFF3A2414)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final breathY = -fastVal.abs() * 3 * s;

    // 푸근한 사각둥글 몸통
    final bodyRect = Rect.fromCenter(center: Offset(0, 24 * s + breathY), width: 88 * s, height: 74 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(28 * s)), Paint()..color = capyWarmBrown);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(28 * s)), ghibliLine);

    // 발 4개
    for (final x in [-24.0, -8.0, 8.0, 24.0]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x * s, 60 * s), width: 14 * s, height: 16 * s), Radius.circular(6 * s)), Paint()..color = darkBrown);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x * s, 60 * s), width: 14 * s, height: 16 * s), Radius.circular(6 * s)), ghibliLine);
    }

    // 머리
    final headCenter = Offset(0, -12 * s + breathY);

    // 머리 위 통통 튀는 황금 유자
    final yuzuBounce = fastVal.abs() * 4 * s;
    canvas.drawCircle(Offset(0, headCenter.dy - 38 * s - yuzuBounce), 12 * s, Paint()..color = const Color(0xFFFFA502));
    canvas.drawCircle(Offset(0, headCenter.dy - 38 * s - yuzuBounce), 12 * s, ghibliLine);

    // 귀 2개
    canvas.drawCircle(Offset(headCenter.dx - 36 * s, headCenter.dy - 20 * s), 8 * s, Paint()..color = darkBrown);
    canvas.drawCircle(Offset(headCenter.dx - 36 * s, headCenter.dy - 20 * s), 8 * s, ghibliLine);
    canvas.drawCircle(Offset(headCenter.dx + 36 * s, headCenter.dy - 20 * s), 8 * s, Paint()..color = darkBrown);
    canvas.drawCircle(Offset(headCenter.dx + 36 * s, headCenter.dy - 20 * s), 8 * s, ghibliLine);

    // 넙적한 머리
    final headRect = Rect.fromCenter(center: headCenter, width: 84 * s, height: 70 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, Radius.circular(26 * s)), Paint()..color = capyWarmBrown);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, Radius.circular(26 * s)), ghibliLine);

    // 넙적한 코
    final snoutRect = Rect.fromCenter(center: Offset(headCenter.dx, headCenter.dy + 14 * s), width: 40 * s, height: 28 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(snoutRect, Radius.circular(13 * s)), Paint()..color = darkBrown);
    canvas.drawRRect(RRect.fromRectAndRadius(snoutRect, Radius.circular(13 * s)), ghibliLine);

    // 콧구멍
    canvas.drawCircle(Offset(headCenter.dx - 6 * s, headCenter.dy + 14 * s), 2.5 * s, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(headCenter.dx + 6 * s, headCenter.dy + 14 * s), 2.5 * s, Paint()..color = Colors.black);

    // 평온한 온천 실눈 (^ ^)
    _drawGhibliHappyEyes(canvas, headCenter.dx - 18 * s, headCenter.dy - 6 * s, headCenter.dx + 18 * s, headCenter.dy - 6 * s, 7 * s, s, ghibliLine);

    // 볼터치
    _drawGhibliBlush(canvas, Offset(headCenter.dx - 26 * s, headCenter.dy + 8 * s), 7.5 * s);
    _drawGhibliBlush(canvas, Offset(headCenter.dx + 26 * s, headCenter.dy + 8 * s), 7.5 * s);

    // 모락모락 피어오르는 온천 수증기 (Steam)
    _drawSteamPuff(canvas, Offset(headCenter.dx - 24 * s, headCenter.dy - 44 * s), s);
    _drawSteamPuff(canvas, Offset(headCenter.dx + 24 * s, headCenter.dy - 48 * s), s);
  }

  // ─────────────────────────────────────────────────────────────
  // 🦎 5. 지브리 우파루파 ('벼랑 위의 포뇨' 수중 요정 감성 + 무지개 물방울)
  // ─────────────────────────────────────────────────────────────
  void _drawGhibliAxolotl(Canvas canvas, double s) {
    final pinkBody = const Color(0xFFFFD1DC);
    final frillCoral = const Color(0xFFFF6B81);
    final ghibliLine = Paint()
      ..color = const Color(0xFF4A1525)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final floatY = math.sin(actionT * math.pi * 2) * 6 * s;
    canvas.save();
    canvas.translate(0, floatY);

    // 꼬리지느러미 살랑
    final tailWave = fastVal * 14 * s;
    final tailPath = Path()
      ..moveTo(22 * s, 34 * s)
      ..cubicTo(44 * s + tailWave, 26 * s, 48 * s - tailWave, 48 * s, 58 * s + tailWave, 40 * s)
      ..cubicTo(40 * s - tailWave, 56 * s, 30 * s + tailWave, 42 * s, 14 * s, 42 * s)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = frillCoral);
    canvas.drawPath(tailPath, ghibliLine);

    // 포뇨 같은 물방울 몸통
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 26 * s), width: 74 * s, height: 66 * s), Paint()..color = pinkBody);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 26 * s), width: 74 * s, height: 66 * s), ghibliLine);

    // 손 흔들며 인사 (안녕안녕~)
    final handWave = fastVal * 6 * s;
    canvas.drawCircle(Offset(-28 * s, 36 * s), 8 * s, Paint()..color = pinkBody);
    canvas.drawCircle(Offset(-28 * s, 36 * s), 8 * s, ghibliLine);
    canvas.drawCircle(Offset(28 * s, 26 * s + handWave), 8 * s, Paint()..color = pinkBody);
    canvas.drawCircle(Offset(28 * s, 26 * s + handWave), 8 * s, ghibliLine);

    // 머리
    final headCenter = Offset(0, -12 * s);

    // 양옆 6개 깃털 아가미 (물결에 춤추듯 살랑살랑)
    for (int i = 0; i < 3; i++) {
      final fy = headCenter.dy - 16 * s + i * 16 * s;
      final wave = math.sin(actionT * math.pi * 4 + i) * 6 * s;
      canvas.drawCircle(Offset(-44 * s, fy + wave), 8.5 * s, Paint()..color = frillCoral);
      canvas.drawCircle(Offset(-44 * s, fy + wave), 8.5 * s, ghibliLine);
      canvas.drawCircle(Offset(44 * s, fy - wave), 8.5 * s, Paint()..color = frillCoral);
      canvas.drawCircle(Offset(44 * s, fy - wave), 8.5 * s, ghibliLine);
    }

    // 포뇨 뺨 얼굴
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: 84 * s, height: 70 * s), Paint()..color = pinkBody);
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: 84 * s, height: 70 * s), ghibliLine);

    // 방긋 미소
    final smile = Path()
      ..moveTo(-10 * s, headCenter.dy + 10 * s)
      ..quadraticBezierTo(0, headCenter.dy + 18 * s, 10 * s, headCenter.dy + 10 * s);
    canvas.drawPath(smile, ghibliLine..strokeWidth = 2.6 * s);

    // 포뇨 감성의 초롱초롱 맑은 눈
    _drawGhibliGlassEyes(canvas, headCenter.dx - 18 * s, headCenter.dy - 4 * s, headCenter.dx + 18 * s, headCenter.dy - 4 * s, 8.5 * s, s, const Color(0xFF2C3E50));
    _drawGhibliBlush(canvas, Offset(headCenter.dx - 24 * s, headCenter.dy + 8 * s), 7.5 * s);
    _drawGhibliBlush(canvas, Offset(headCenter.dx + 24 * s, headCenter.dy + 8 * s), 7.5 * s);

    // 주변 무지개 물방울 퐁퐁 (Ponyo bubbles)
    _drawPonyoBubble(canvas, Offset(-36 * s, -38 * s), 7 * s);
    _drawPonyoBubble(canvas, Offset(38 * s, -42 * s), 9 * s);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────
  // 🐉 6. 지브리 드래곤 (센과 치히로의 백룡 '하쿠' 감성 + 청록빛 갈기)
  // ─────────────────────────────────────────────────────────────
  void _drawGhibliDragon(Canvas canvas, double s) {
    final dragonEmerald = const Color(0xFF64DFDF);
    final maneWhite = const Color(0xFFFFFFFF);
    final hornGold = const Color(0xFFFFD166);
    final ghibliLine = Paint()
      ..color = const Color(0xFF1B3B36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bounceY = -fastVal.abs() * 4 * s;
    canvas.save();
    canvas.translate(0, bounceY);

    // 하쿠 스타일 청록/백색 꼬리 (바람에 흩날림)
    final tailWag = fastVal * 12 * s;
    canvas.drawCircle(Offset(38 * s + tailWag, 26 * s), 13 * s, Paint()..color = dragonEmerald);
    canvas.drawCircle(Offset(38 * s + tailWag, 26 * s), 13 * s, ghibliLine);
    canvas.drawCircle(Offset(50 * s + tailWag, 18 * s), 9 * s, Paint()..color = maneWhite);
    canvas.drawCircle(Offset(50 * s + tailWag, 18 * s), 9 * s, ghibliLine);

    // 날개 파닥파닥
    final wingAngle = fastVal * 0.55;
    canvas.save();
    canvas.translate(-32 * s, 14 * s);
    canvas.rotate(-wingAngle - 0.2);
    final leftWing = Path()
      ..moveTo(0, 0)
      ..lineTo(-30 * s, -18 * s)
      ..lineTo(-24 * s, 8 * s)
      ..close();
    canvas.drawPath(leftWing, Paint()..color = const Color(0xFF72EFDD));
    canvas.drawPath(leftWing, ghibliLine);
    canvas.restore();

    canvas.save();
    canvas.translate(32 * s, 14 * s);
    canvas.rotate(wingAngle + 0.2);
    final rightWing = Path()
      ..moveTo(0, 0)
      ..lineTo(30 * s, -18 * s)
      ..lineTo(24 * s, 8 * s)
      ..close();
    canvas.drawPath(rightWing, Paint()..color = const Color(0xFF72EFDD));
    canvas.drawPath(rightWing, ghibliLine);
    canvas.restore();

    // 몸통
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 24 * s), width: 78 * s, height: 68 * s), Paint()..color = dragonEmerald);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 24 * s), width: 78 * s, height: 68 * s), ghibliLine);
    // 하쿠 백색 배
    canvas.drawOval(Rect.fromCenter(center: Offset(0, 30 * s), width: 42 * s, height: 38 * s), Paint()..color = maneWhite);

    // 발 2개
    canvas.drawOval(Rect.fromCenter(center: Offset(-18 * s, 56 * s), width: 22 * s, height: 16 * s), Paint()..color = dragonEmerald);
    canvas.drawOval(Rect.fromCenter(center: Offset(-18 * s, 56 * s), width: 22 * s, height: 16 * s), ghibliLine);
    canvas.drawOval(Rect.fromCenter(center: Offset(18 * s, 56 * s), width: 22 * s, height: 16 * s), Paint()..color = dragonEmerald);
    canvas.drawOval(Rect.fromCenter(center: Offset(18 * s, 56 * s), width: 22 * s, height: 16 * s), ghibliLine);

    // 머리
    final headCenter = Offset(0, -14 * s);

    // 신비로운 황금빛 사슴 뿔 (하쿠 뿔)
    final leftHorn = Path()
      ..moveTo(-18 * s, -24 * s)
      ..lineTo(-26 * s, -42 * s)
      ..lineTo(-10 * s, -28 * s)
      ..close();
    canvas.drawPath(leftHorn, Paint()..color = hornGold);
    canvas.drawPath(leftHorn, ghibliLine);

    final rightHorn = Path()
      ..moveTo(18 * s, -24 * s)
      ..lineTo(26 * s, -42 * s)
      ..lineTo(10 * s, -28 * s)
      ..close();
    canvas.drawPath(rightHorn, Paint()..color = hornGold);
    canvas.drawPath(rightHorn, ghibliLine);

    // 머리 윤곽
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: 84 * s, height: 70 * s), Paint()..color = dragonEmerald);
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: 84 * s, height: 70 * s), ghibliLine);

    // 백색 주둥이
    canvas.drawOval(Rect.fromCenter(center: Offset(0, headCenter.dy + 12 * s), width: 44 * s, height: 26 * s), Paint()..color = maneWhite);
    canvas.drawCircle(Offset(-6 * s, headCenter.dy + 10 * s), 2.2 * s, Paint()..color = const Color(0xFF1B3B36));
    canvas.drawCircle(Offset(6 * s, headCenter.dy + 10 * s), 2.2 * s, Paint()..color = const Color(0xFF1B3B36));

    // 하쿠 특유의 깊은 청록빛 지브리 눈
    _drawGhibliGlassEyes(canvas, headCenter.dx - 18 * s, headCenter.dy - 6 * s, headCenter.dx + 18 * s, headCenter.dy - 6 * s, 8 * s, s, const Color(0xFF00B4D8));
    _drawGhibliBlush(canvas, Offset(headCenter.dx - 24 * s, headCenter.dy + 10 * s), 7 * s);
    _drawGhibliBlush(canvas, Offset(headCenter.dx + 24 * s, headCenter.dy + 10 * s), 7 * s);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────
  // 🌟 지브리 특유의 영롱한 수채화 눈망울 (Ghibli Glass Eyes)
  // ─────────────────────────────────────────────────────────────
  void _drawGhibliGlassEyes(
    Canvas canvas,
    double lx,
    double ly,
    double rx,
    double ry,
    double r,
    double s,
    Color irisColor,
  ) {
    if (blinkAmount > 0.4) {
      final linePaint = Paint()
        ..color = const Color(0xFF2C3E50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * s
        ..strokeCap = StrokeCap.round;
      _drawGhibliHappyEyes(canvas, lx, ly, rx, ry, r, s, linePaint);
      return;
    }

    final eyeWhite = Paint()..color = Colors.white;
    final pupilBlack = Paint()..color = const Color(0xFF1A1A1A);
    final irisPaint = Paint()..color = irisColor;

    for (final x in [lx, rx]) {
      // 1. 흰자위
      canvas.drawCircle(Offset(x, ly), r, eyeWhite);
      // 2. 수채화 홍채 (영롱한 수채화 그라데이션)
      canvas.drawCircle(Offset(x, ly), r * 0.88, irisPaint);
      // 3. 깊은 동공
      canvas.drawCircle(Offset(x, ly + r * 0.1), r * 0.55, pupilBlack);
      // 4. 지브리 특유의 3단 반짝이 하이라이트 (빛나는 생명감!)
      canvas.drawCircle(Offset(x - r * 0.35, ly - r * 0.35), r * 0.36, eyeWhite);
      canvas.drawCircle(Offset(x + r * 0.32, ly + r * 0.3), r * 0.18, eyeWhite);
      canvas.drawCircle(Offset(x - r * 0.1, ly + r * 0.42), r * 0.12, eyeWhite);
      // 5. 부드러운 눈꺼풀 선
      final lash = Path()
        ..moveTo(x - r * 1.1, ly - r * 0.3)
        ..quadraticBezierTo(x, ly - r * 1.15, x + r * 1.1, ly - r * 0.3);
      canvas.drawPath(
        lash,
        Paint()
          ..color = const Color(0xFF2C1E18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * s
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // 지브리 감은 미소 눈 (^ ^)
  void _drawGhibliHappyEyes(Canvas canvas, double lx, double ly, double rx, double ry, double r, double s, Paint linePaint) {
    for (final x in [lx, rx]) {
      final path = Path()
        ..moveTo(x - r, ly + r * 0.2)
        ..quadraticBezierTo(x, ly - r * 0.7, x + r, ly + r * 0.2);
      canvas.drawPath(path, linePaint);
    }
  }

  // 지브리 수채화 홍조 볼터치
  void _drawGhibliBlush(Canvas canvas, Offset center, double radius) {
    final blush = Paint()
      ..color = const Color(0x66FF6B81)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6);
    canvas.drawCircle(center, radius, blush);
  }

  // 포뇨 무지개 물방울 (Ponyo Rainbow Bubble)
  void _drawPonyoBubble(Canvas canvas, Offset center, double radius) {
    final bubblePaint = Paint()
      ..color = const Color(0x4448CAE4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bubblePaint);
    final borderPaint = Paint()
      ..color = const Color(0x9990E0EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, borderPaint);
    // 물방울 반사광
    canvas.drawCircle(Offset(center.dx - radius * 0.35, center.dy - radius * 0.35), radius * 0.28, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  // 온천 수증기 (Steam puff)
  void _drawSteamPuff(Canvas canvas, Offset center, double s) {
    final steamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * s);
    canvas.drawCircle(center, 5 * s, steamPaint);
  }

  // 🌿 지브리 분위기 부유 파티클 (Ambient Floating Sunlight Dust / Pollen)
  void _drawGhibliAtmosphereParticles(Canvas canvas, double s) {
    final offsets = [
      Offset(-50 * s, -40 * s),
      Offset(48 * s, -35 * s),
      Offset(-38 * s, 10 * s),
      Offset(42 * s, 15 * s),
      Offset(-10 * s, -60 * s),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final base = offsets[i];
      final driftY = math.sin((particleT + i * 0.2) * math.pi * 2) * 6 * s;
      final driftX = math.cos((particleT + i * 0.3) * math.pi * 2) * 4 * s;
      final pColor = (i % 2 == 0)
          ? const Color(0x66FFF176) // 따뜻한 햇살 먼지
          : const Color(0x6681C784); // 작은 숲속 요정 빛

      canvas.drawCircle(
        Offset(base.dx + driftX, base.dy + driftY),
        (2.5 + (i % 2) * 1.5) * s,
        Paint()..color = pColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GhibliArtPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.actionT != actionT ||
        oldDelegate.fastVal != fastVal ||
        oldDelegate.particleT != particleT ||
        oldDelegate.blinkAmount != blinkAmount;
  }
}
