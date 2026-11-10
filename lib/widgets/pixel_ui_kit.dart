import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pixel_icons.dart';

/// 레트로 픽셀 아트 테마 색상 팔레트 (시안 이미지 기준 정밀 추출)
class PixelColors {
  static const Color bgSky = Color(0xFFD6E8FC);
  static const Color cardBg = Color(0xFFEBF4FE);
  static const Color cardBgWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFF466FA7);
  static const Color borderDark = Color(0xFF213E6D);
  static const Color borderLight = Color(0xFF7FAAE0);
  static const Color primaryBlue = Color(0xFF538CE0);
  static const Color primaryBlueDark = Color(0xFF3362AA);
  static const Color primaryBlueLight = Color(0xFF8EC0FC);
  static const Color whiteButtonBg = Color(0xFFF3F8FF);
  static const Color whiteButtonLip = Color(0xFFC2DCFA);
  static const Color textDark = Color(0xFF1E375C);
  static const Color textMuted = Color(0xFF5676A3);
  static const Color heartPink = Color(0xFFFF7B98);
  static const Color cookieGold = Color(0xFFFFA000);
}

/// ── [픽셀 형상 엔진] 8비트/16비트 레트로 계단식(Stepped) 픽셀 코너 패스 생성기 ──
Path buildPixelPath(Size size, double step) {
  final w = size.width;
  final h = size.height;
  if (w <= 0 || h <= 0) return Path();

  final maxStep = (w < h ? w : h) / 4;
  final s = step.clamp(1.0, maxStep > 1.0 ? maxStep : 1.0);

  final path = Path();
  path.moveTo(2 * s, 0);
  path.lineTo(w - 2 * s, 0);
  // 상단 우측 2단 픽셀 계단
  path.lineTo(w - s, 0);
  path.lineTo(w - s, s);
  path.lineTo(w, s);
  path.lineTo(w, 2 * s);
  // 우측 수직선
  path.lineTo(w, h - 2 * s);
  // 하단 우측 2단 픽셀 계단
  path.lineTo(w, h - s);
  path.lineTo(w - s, h - s);
  path.lineTo(w - s, h);
  path.lineTo(w - 2 * s, h);
  // 하단 수평선
  path.lineTo(2 * s, h);
  // 하단 좌측 2단 픽셀 계단
  path.lineTo(s, h);
  path.lineTo(s, h - s);
  path.lineTo(0, h - s);
  path.lineTo(0, h - 2 * s);
  // 좌측 수직선
  path.lineTo(0, 2 * s);
  // 상단 좌측 2단 픽셀 계단
  path.lineTo(0, s);
  path.lineTo(s, s);
  path.lineTo(s, 0);
  path.close();

  return path;
}

/// 픽셀 박스 내부 위젯 클리퍼
class PixelClipper extends CustomClipper<Path> {
  final double step;

  const PixelClipper({this.step = 4.0});

  @override
  Path getClip(Size size) => buildPixelPath(size, step);

  @override
  bool shouldReclip(covariant PixelClipper oldClipper) =>
      oldClipper.step != step;
}

/// ── [PixelBox] 레트로 픽셀 아트 3D 베벨 + 물리적 눌림(Press) 애니메이션 전용 박스 ──
class PixelBox extends StatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double step;
  final double shadowOffset;
  final Color? shadowColor;
  final Color? highlightColor;
  final Color? lipColor;
  final double lipHeight;
  final bool doubleBorder;
  final Color innerBorderColor;
  final bool enableBevel;
  final VoidCallback? onTap;

  const PixelBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor = Colors.white,
    this.borderColor = PixelColors.borderDark,
    this.borderWidth = 2.5,
    this.step = 4.0,
    this.shadowOffset = 3.0,
    this.shadowColor = const Color(0x332B4E80),
    this.highlightColor,
    this.lipColor,
    this.lipHeight = 3.0,
    this.doubleBorder = false,
    this.innerBorderColor = PixelColors.primaryBlue,
    this.enableBevel = true,
    this.onTap,
  });

  @override
  State<PixelBox> createState() => _PixelBoxState();
}

class _PixelBoxState extends State<PixelBox> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;
    final maxPressShift =
        widget.shadowOffset > 0 ? widget.shadowOffset : 2.5;
    final pressShift = (isInteractive && _isPressed) ? maxPressShift : 0.0;
    final currentShadow = (isInteractive && _isPressed)
        ? (widget.shadowOffset > 0 ? 0.5 : 0.0)
        : widget.shadowOffset;

    // 눌림/호버 시 배경색 톤 조절
    Color bg = widget.backgroundColor;
    if (isInteractive && _isPressed) {
      bg = Color.lerp(bg, widget.borderColor, 0.08) ?? bg;
    } else if (isInteractive && _isHovered) {
      bg = Color.lerp(bg, Colors.white, 0.14) ?? bg;
    }

    // 베벨 기본 색상 자동 추론 (어두운 배경이면 밝은 블루 하이라이트 + 진한 블루 립, 밝은 배경이면 화이트 하이라이트 + 연블루 립)
    final luminance = widget.backgroundColor.computeLuminance();
    final isDarkBg = luminance < 0.45;
    final resolvedHighlight = widget.enableBevel
        ? (widget.highlightColor ??
            (isDarkBg
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.9)))
        : null;
    final resolvedLip = widget.enableBevel
        ? (widget.lipColor ??
            (isDarkBg
                ? Colors.black.withValues(alpha: 0.22)
                : const Color(0xFFC8DFF8).withValues(alpha: 0.85)))
        : null;

    Widget box = AnimatedContainer(
      duration: const Duration(milliseconds: 55),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, pressShift, 0),
      child: CustomPaint(
        painter: _PixelBoxPainter(
          backgroundColor: bg,
          borderColor: widget.borderColor,
          borderWidth: widget.borderWidth,
          step: widget.step,
          shadowOffset: currentShadow,
          shadowColor: widget.shadowColor,
          highlightColor: resolvedHighlight,
          lipColor: resolvedLip,
          lipHeight: widget.lipHeight,
          doubleBorder: widget.doubleBorder,
          innerBorderColor: widget.innerBorderColor,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          child: widget.child == null
              ? null
              : ClipPath(
                  clipper: PixelClipper(step: widget.step),
                  child: widget.child,
                ),
        ),
      ),
    );

    if (isInteractive) {
      box = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            HapticFeedback.lightImpact();
            _setPressed(true);
          },
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: box,
          ),
        ),
      );
    }

    if (widget.margin != null || widget.shadowOffset > 0) {
      final extraBottom = widget.shadowOffset > 0 ? widget.shadowOffset : 0.0;
      final m = (widget.margin ?? EdgeInsets.zero)
          .add(EdgeInsets.only(bottom: extraBottom));
      box = Padding(padding: m, child: box);
    }

    return box;
  }
}

class _PixelBoxPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double step;
  final double shadowOffset;
  final Color? shadowColor;
  final Color? highlightColor;
  final Color? lipColor;
  final double lipHeight;
  final bool doubleBorder;
  final Color innerBorderColor;

  _PixelBoxPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.step,
    required this.shadowOffset,
    required this.shadowColor,
    this.highlightColor,
    this.lipColor,
    this.lipHeight = 3.0,
    this.doubleBorder = false,
    this.innerBorderColor = PixelColors.primaryBlue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final mainPath = buildPixelPath(size, step);

    // 1. 하단 3D 픽셀 그림자 (블러 없이 칼같이 떨어지는 도트 그림자)
    if (shadowOffset > 0 && shadowColor != null) {
      canvas.save();
      canvas.translate(0, shadowOffset);
      final shadowPaint = Paint()
        ..color = shadowColor!
        ..style = PaintingStyle.fill;
      canvas.drawPath(mainPath, shadowPaint);
      canvas.restore();
    }

    // 2. 픽셀 본체 채우기 + 내부 3D 베벨(상단 하이라이트 & 하단 입체 립)
    canvas.save();
    canvas.clipPath(mainPath);

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);

    // 상단 밝은 하이라이트 띠
    if (highlightColor != null && size.height > 12) {
      final hlPaint = Paint()
        ..color = highlightColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(0, borderWidth * 0.5, size.width, 3.0),
        hlPaint,
      );
    }

    // 하단 3D 입체 립 (시안 버튼의 아래쪽 굵은 입체 음영)
    if (lipColor != null && lipHeight > 0 && size.height > 16) {
      final lipPaint = Paint()
        ..color = lipColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          size.height - lipHeight - borderWidth * 0.4,
          size.width,
          lipHeight + borderWidth * 0.4,
        ),
        lipPaint,
      );
    }

    // 이중 테두리(Double Frame): 배너나 주요 카드에 시안처럼 안쪽 하늘색 라인 추가
    if (doubleBorder && size.width > 24 && size.height > 20) {
      const inset = 4.0;
      final innerRect = Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      );
      final innerPath = buildPixelPath(
        innerRect.size,
        (step - 1.5).clamp(2.0, step),
      );
      canvas.save();
      canvas.translate(inset, inset);
      final innerPaint = Paint()
        ..color = innerBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter;
      canvas.drawPath(innerPath, innerPaint);
      canvas.restore();
    }

    canvas.restore();

    // 3. 짙은 픽셀 테두리 선
    if (borderWidth > 0) {
      final strokePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter;
      canvas.drawPath(mainPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelBoxPainter old) =>
      old.backgroundColor != backgroundColor ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.step != step ||
      old.shadowOffset != shadowOffset ||
      old.shadowColor != shadowColor ||
      old.highlightColor != highlightColor ||
      old.lipColor != lipColor ||
      old.lipHeight != lipHeight ||
      old.doubleBorder != doubleBorder ||
      old.innerBorderColor != innerBorderColor;
}

/// 1. 상단 서울 야경 도시 스카이라인 배경 + 뒤로가기 + 이중 프레임 픽셀 배너 헤더
class PixelSkyHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? customLeading;
  final Widget? customTrailing;
  final bool showPawDecorations;

  const PixelSkyHeader({
    super.key,
    required this.title,
    this.onBack,
    this.customLeading,
    this.customTrailing,
    this.showPawDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 150.0;

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 서울 야경 도시 스카이라인 픽셀 아트 이미지
          Image.asset(
            'assets/pixel_ui/sky_city_header.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.none,
          ),

          // 하단 배경(PixelColors.bgSky)과 자연스럽게 이어지는 페이드 오버레이
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PixelColors.bgSky.withValues(alpha: 0.0),
                    PixelColors.bgSky,
                  ],
                ),
              ),
            ),
          ),

          // 좌상단 뒤로가기 픽셀 버튼
          if (onBack != null)
            Positioned(
              top: topPadding + 10,
              left: 16,
              child: PixelBox(
                width: 42,
                height: 42,
                step: 4.0,
                shadowOffset: 3.0,
                backgroundColor: PixelColors.whiteButtonBg,
                lipColor: PixelColors.whiteButtonLip,
                borderColor: PixelColors.borderDark,
                borderWidth: 2.5,
                onTap: onBack,
                child: const Center(
                  child: PixelIcon(PixelIconType.arrowLeft, size: 20),
                ),
              ),
            ),

          // 중앙 하단 이중 테두리 픽셀 프레임 배너 (시안 스타일)
          Positioned(
            left: 24,
            right: 24,
            bottom: 6,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 235, maxWidth: 320),
                child: PixelBox(
                  height: 52,
                  step: 5.0,
                  shadowOffset: 4.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.97),
                  borderColor: PixelColors.borderDark,
                  borderWidth: 2.8,
                  doubleBorder: true,
                  innerBorderColor: PixelColors.primaryBlue,
                  lipHeight: 2.0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    widthFactor: 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 좌측 '+' 픽셀 별
                        _buildMiniPlusStar(),
                        const SizedBox(width: 10),

                        if (customLeading != null) ...[
                          customLeading!,
                          const SizedBox(width: 8),
                        ] else if (showPawDecorations) ...[
                          const PixelIcon(PixelIconType.paw, size: 22),
                          const SizedBox(width: 8),
                        ],

                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: PixelColors.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        if (customTrailing != null) ...[
                          const SizedBox(width: 8),
                          customTrailing!,
                        ],

                        const SizedBox(width: 10),
                        // 우측 '+' 픽셀 별
                        _buildMiniPlusStar(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlusStar() {
    return SizedBox(
      width: 8,
      height: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 8, height: 2.5, color: PixelColors.primaryBlueLight),
          Container(width: 2.5, height: 8, color: PixelColors.primaryBlueLight),
        ],
      ),
    );
  }
}

/// 2. 레퍼런스 5: 상단 픽셀 리본 배너 ("🐾 캐릭터 선택 🐾")
class PixelRibbonHeader extends StatelessWidget {
  final String title;

  const PixelRibbonHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 상단 픽셀 반짝이 광선
        const PixelSparkle(
          color: PixelColors.primaryBlueLight,
          pixelSize: 3.0,
        ),
        const SizedBox(height: 6),

        // 메인 리본 배너
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 좌측 계단식 픽셀 리본 꼬리
            Positioned(
              left: -18,
              child: CustomPaint(
                size: const Size(30, 38),
                painter: _PixelRibbonTailPainter(isLeft: true),
              ),
            ),
            // 우측 계단식 픽셀 리본 꼬리
            Positioned(
              right: -18,
              child: CustomPaint(
                size: const Size(30, 38),
                painter: _PixelRibbonTailPainter(isLeft: false),
              ),
            ),

            // 리본 중앙 이중 프레임 픽셀 바
            PixelBox(
              step: 5.0,
              shadowOffset: 4.0,
              backgroundColor: Colors.white,
              borderColor: PixelColors.borderDark,
              borderWidth: 2.8,
              doubleBorder: true,
              innerBorderColor: PixelColors.primaryBlueLight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PixelIcon(
                    PixelIconType.paw,
                    size: 20,
                    primaryColor: PixelColors.primaryBlueLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: PixelColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const PixelIcon(
                    PixelIconType.paw,
                    size: 20,
                    primaryColor: PixelColors.primaryBlueLight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PixelRibbonTailPainter extends CustomPainter {
  final bool isLeft;

  _PixelRibbonTailPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // 계단식 픽셀 리본 노치
    if (isLeft) {
      path.moveTo(w, 0);
      path.lineTo(0, 0);
      path.lineTo(0, 6);
      path.lineTo(5, 6);
      path.lineTo(5, 13);
      path.lineTo(10, 13);
      path.lineTo(10, 25);
      path.lineTo(5, 25);
      path.lineTo(5, 32);
      path.lineTo(0, 32);
      path.lineTo(0, h);
      path.lineTo(w, h);
    } else {
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, 6);
      path.lineTo(w - 5, 6);
      path.lineTo(w - 5, 13);
      path.lineTo(w - 10, 13);
      path.lineTo(w - 10, 25);
      path.lineTo(w - 5, 25);
      path.lineTo(w - 5, 32);
      path.lineTo(w, 32);
      path.lineTo(w, h);
      path.lineTo(0, h);
    }
    path.close();

    final fillPaint = Paint()
      ..color = PixelColors.primaryBlueLight
      ..style = PaintingStyle.fill;
    final lipPaint = Paint()
      ..color = PixelColors.primaryBlue
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = PixelColors.borderDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(path, fillPaint);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(Rect.fromLTWH(0, h - 7, w, 7), lipPaint);
    canvas.restore();
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. 3D 베벨 + 물리적 눌림 효과 + 픽셀 반짝이가 포함된 픽셀 메인 액션 버튼
class PixelButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? pixelIcon;
  final bool isWhite;
  final double height;
  final double? width;
  final bool withSparkle;

  const PixelButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.pixelIcon,
    this.isWhite = false,
    this.height = 54,
    this.width,
    this.withSparkle = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidget = PixelBox(
      width: width,
      height: height,
      step: 5.0,
      shadowOffset: 4.0,
      borderWidth: 2.8,
      lipHeight: 4.0,
      backgroundColor:
          isWhite ? PixelColors.whiteButtonBg : PixelColors.primaryBlue,
      highlightColor:
          isWhite ? Colors.white : const Color(0xFF9AC9FF),
      lipColor:
          isWhite ? PixelColors.whiteButtonLip : PixelColors.primaryBlueDark,
      borderColor:
          isWhite ? PixelColors.border : PixelColors.borderDark,
      shadowColor:
          isWhite ? const Color(0x2A2B4E80) : const Color(0x551E375C),
      onTap: onPressed,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: width == null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (pixelIcon != null) ...[
              pixelIcon!,
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(
                icon,
                color: isWhite ? PixelColors.textDark : Colors.white,
                size: 21,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: isWhite ? PixelColors.textDark : Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );

    if (!withSparkle || isWhite) {
      return buttonWidget;
    }

    // 시안처럼 파란 버튼 우상단 모서리 위에 작은 3갈래 픽셀 반짝이 광선 배치
    return Stack(
      clipBehavior: Clip.none,
      children: [
        buttonWidget,
        const Positioned(
          right: -6,
          top: -12,
          child: IgnorePointer(
            child: PixelSparkle(
              color: PixelColors.primaryBlue,
              pixelSize: 2.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// 4. 픽셀 카드 컨테이너 (시안 "목표이름", "기간", "알림시간" 섹션 카드)
class PixelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  const PixelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = PixelColors.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      width: double.infinity,
      step: 5.5,
      shadowOffset: 3.0,
      borderWidth: 2.2,
      lipHeight: 2.5,
      backgroundColor: backgroundColor,
      borderColor: PixelColors.borderLight,
      highlightColor: Colors.white.withValues(alpha: 0.7),
      lipColor: const Color(0xFFD0E4FC),
      padding: padding,
      child: child,
    );
  }
}

/// 5. 픽셀 점선 카드 + 하단 파스텔 픽셀 구름 실루엣 (시안 1 "완료 인증 사진을 업로드 해주세요")
class PixelDashedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double height;
  final VoidCallback? onTap;

  const PixelDashedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.height = 240,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = CustomPaint(
      painter: _PixelDashedBorderPainter(
        color: PixelColors.primaryBlueLight,
        backgroundColor: PixelColors.cardBg,
        step: 5.0,
        dashLength: 7.0,
        gapLength: 5.0,
        strokeWidth: 2.5,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipPath(
          clipper: const PixelClipper(step: 5.0),
          child: Stack(
            children: [
              // 하단 연한 픽셀 구름 실루엣 (시안 디테일)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 44,
                child: CustomPaint(
                  painter: _PixelCloudSilhouettePainter(),
                ),
              ),
              Padding(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}

class _PixelCloudSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFD5E8FE)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // 좌측 픽셀 구름 언덕
    canvas.drawRect(Rect.fromLTWH(0, h - 14, w, 14), p);
    canvas.drawRect(Rect.fromLTWH(16, h - 24, 56, 10), p);
    canvas.drawRect(Rect.fromLTWH(28, h - 32, 32, 8), p);
    canvas.drawRect(Rect.fromLTWH(84, h - 20, 40, 6), p);

    // 우측 픽셀 구름 언덕
    canvas.drawRect(Rect.fromLTWH(w - 86, h - 26, 64, 12), p);
    canvas.drawRect(Rect.fromLTWH(w - 68, h - 34, 34, 8), p);
    canvas.drawRect(Rect.fromLTWH(w - 130, h - 20, 44, 6), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PixelDashedBorderPainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;
  final double step;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  _PixelDashedBorderPainter({
    required this.color,
    required this.backgroundColor,
    required this.step,
    required this.dashLength,
    required this.gapLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPixelPath(size, step);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, next);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. 화면 전체 외곽 픽셀 프레임 (레퍼런스 5 전용 아케이드 도트 프레임)
class PixelScreenBorder extends StatelessWidget {
  final Widget child;

  const PixelScreenBorder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelScreenFramePainter(),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }
}

class _PixelScreenFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const frameColor = PixelColors.primaryBlueLight;
    final w = size.width;
    final h = size.height;

    final borderPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.square;

    canvas.drawRect(Rect.fromLTWH(3, 3, w - 6, h - 6), borderPaint);

    final dotPaint = Paint()
      ..color = PixelColors.primaryBlueDark
      ..style = PaintingStyle.fill;

    const dotSize = 5.0;
    // Top-Left
    canvas.drawRect(const Rect.fromLTWH(8, 8, dotSize, dotSize), dotPaint);
    canvas.drawRect(const Rect.fromLTWH(14, 8, dotSize, dotSize), dotPaint);
    canvas.drawRect(const Rect.fromLTWH(8, 14, dotSize, dotSize), dotPaint);

    // Top-Right
    canvas.drawRect(Rect.fromLTWH(w - 13, 8, dotSize, dotSize), dotPaint);
    canvas.drawRect(Rect.fromLTWH(w - 19, 8, dotSize, dotSize), dotPaint);
    canvas.drawRect(Rect.fromLTWH(w - 13, 14, dotSize, dotSize), dotPaint);

    // Bottom-Left
    canvas.drawRect(Rect.fromLTWH(8, h - 13, dotSize, dotSize), dotPaint);
    canvas.drawRect(Rect.fromLTWH(14, h - 13, dotSize, dotSize), dotPaint);
    canvas.drawRect(Rect.fromLTWH(8, h - 19, dotSize, dotSize), dotPaint);

    // Bottom-Right
    canvas.drawRect(Rect.fromLTWH(w - 13, h - 13, dotSize, dotSize), dotPaint);
    canvas.drawRect(Rect.fromLTWH(w - 19, h - 13, dotSize, dotSize), dotPaint);
    canvas.drawRect(Rect.fromLTWH(w - 13, h - 19, dotSize, dotSize), dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7. 픽셀 인포 알림 바 (레퍼런스 1 "(i) 일정을 완료한 사진을 첨부하면 인증이 완료돼요!")
class PixelInfoBar extends StatelessWidget {
  final String text;

  const PixelInfoBar({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      width: double.infinity,
      step: 4.0,
      shadowOffset: 2.0,
      borderWidth: 2.0,
      backgroundColor: PixelColors.cardBg,
      borderColor: PixelColors.borderLight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const PixelIcon(PixelIconType.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: PixelColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 8. 레퍼런스 신규: 하단 + 버튼용 픽셀 말풍선 팝업 (일정 추가 / 캘린더 보기 / 타임라인 보기)
class PixelSpeechBubbleMenu extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenTimeline;

  const PixelSpeechBubbleMenu({
    super.key,
    required this.onAddTask,
    required this.onOpenCalendar,
    required this.onOpenTimeline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topLeft,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 말풍선 본체 픽셀 카드
            PixelBox(
              width: 222,
              step: 5.0,
              shadowOffset: 4.0,
              borderWidth: 2.8,
              lipHeight: 3.5,
              backgroundColor: const Color(0xFFE4F1FD),
              lipColor: const Color(0xFFC3DDF8),
              borderColor: PixelColors.borderDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 일정 추가하기
                  _buildMenuItem(
                    iconWidget: const PixelIcon(
                      PixelIconType.calendarPlus,
                      size: 22,
                    ),
                    label: '일정 추가하기',
                    onTap: onAddTask,
                  ),
                  const SizedBox(height: 10),

                  // 2. 캘린더 보기
                  _buildMenuItem(
                    iconWidget: const PixelIcon(
                      PixelIconType.calendar,
                      size: 22,
                    ),
                    label: '캘린더 보기',
                    onTap: onOpenCalendar,
                  ),
                  const SizedBox(height: 10),

                  // 3. 타임라인 보기
                  _buildMenuItem(
                    iconWidget: const PixelIcon(
                      PixelIconType.timeline,
                      size: 22,
                    ),
                    label: '타임라인 보기',
                    onTap: onOpenTimeline,
                  ),
                ],
              ),
            ),

            // 하단 말풍선 꼬리 (계단식 픽셀 피라미드)
            CustomPaint(
              size: const Size(20, 10),
              painter: _PixelSteppedTailPainter(
                fillColor: const Color(0xFFC3DDF8),
                borderColor: PixelColors.borderDark,
              ),
            ),
          ],
        ),
        // 말풍선 좌상단 모서리 흰색 픽셀 반짝이 광선 (시안 7번 그대로)
        Positioned(
          left: -12,
          top: -12,
          child: Transform.rotate(
            angle: -0.4,
            child: const PixelSparkle(
              color: Colors.white,
              pixelSize: 2.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return PixelBox(
      height: 44,
      step: 4.0,
      shadowOffset: 3.0,
      borderWidth: 2.0,
      lipHeight: 2.5,
      backgroundColor: Colors.white,
      lipColor: const Color(0xFFD2E5FB),
      borderColor: const Color(0xFF8AB4E8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: iconWidget)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: PixelColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 계단식 픽셀 말풍선 꼬리 페인터
class _PixelSteppedTailPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _PixelSteppedTailPainter({
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rows = [
      Rect.fromLTWH(1, 0, 18, 2),
      Rect.fromLTWH(3, 2, 14, 2),
      Rect.fromLTWH(5, 4, 10, 2),
      Rect.fromLTWH(7, 6, 6, 2),
      Rect.fromLTWH(9, 8, 2, 2),
    ];

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    for (final r in rows) {
      canvas.drawRect(r, borderPaint);
    }
    canvas.drawRect(const Rect.fromLTWH(3, 0, 14, 2), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(5, 2, 10, 2), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(7, 4, 6, 2), fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
