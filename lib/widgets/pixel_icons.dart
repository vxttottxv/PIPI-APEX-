import 'package:flutter/material.dart';

/// 시안 이미지에 맞춘 16-bit 레트로 픽셀 아트 도트 매트릭스 아이콘 세트
enum PixelIconType {
  arrowLeft,
  chevronLeft,
  chevronRight,
  triangleLeft,
  triangleRight,
  triangleUp,
  triangleDown,
  paw,
  calendar,
  calendarPlus,
  timeline,
  pencil,
  clock,
  camera,
  gallery,
  info,
  check,
  checkCircle,
  dumbbell,
  book,
  droplet,
  cookie,
  heart,
  foodBowl,
  plus,
  close,
  sparkle,
}

class PixelIcon extends StatelessWidget {
  final PixelIconType type;
  final double size;
  final Color? primaryColor;
  final Color? accentColor;

  const PixelIcon(
    this.type, {
    super.key,
    this.size = 20,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelMatrixPainter(
          type: type,
          primaryColor: primaryColor,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _PixelMatrixPainter extends CustomPainter {
  final PixelIconType type;
  final Color? primaryColor;
  final Color? accentColor;

  _PixelMatrixPainter({
    required this.type,
    this.primaryColor,
    this.accentColor,
  });

  // 기본 시안 팔레트
  static const Color _outline = Color(0xFF1E375C); // 짙은 네이비 도트 아웃라인
  static const Color _blue = Color(0xFF5388D4);
  static const Color _blueLight = Color(0xFF8EC0FC);
  static const Color _bluePale = Color(0xFFD6E9FF);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _gold = Color(0xFFFFD44D);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _pink = Color(0xFFFF7B98);
  static const Color _pinkLight = Color(0xFFFFB5C5);
  static const Color _brown = Color(0xFFD99455);
  static const Color _brownDark = Color(0xFF6B3E21);
  static const Color _red = Color(0xFFE55353);
  static const Color _silver = Color(0xFF9FB8D6);

  List<String> _grid() {
    switch (type) {
      case PixelIconType.arrowLeft:
        return [
          '............',
          '.....##.....',
          '....##......',
          '...##.......',
          '..#########.',
          '.##########.',
          '..#########.',
          '...##.......',
          '....##......',
          '.....##.....',
          '............',
          '............',
        ];
      case PixelIconType.chevronLeft:
        return [
          '..........',
          '......##..',
          '.....##...',
          '....##....',
          '...##.....',
          '...##.....',
          '....##....',
          '.....##...',
          '......##..',
          '..........',
        ];
      case PixelIconType.chevronRight:
        return [
          '..........',
          '..##......',
          '...##.....',
          '....##....',
          '.....##...',
          '.....##...',
          '....##....',
          '...##.....',
          '..##......',
          '..........',
        ];
      case PixelIconType.triangleLeft:
        return [
          '..........',
          '......#...',
          '.....##...',
          '....#L#...',
          '...#LL#...',
          '...#LL#...',
          '....#L#...',
          '.....##...',
          '......#...',
          '..........',
        ];
      case PixelIconType.triangleRight:
        return [
          '..........',
          '...#......',
          '...##.....',
          '...#L#....',
          '...#LL#...',
          '...#LL#...',
          '...#L#....',
          '...##.....',
          '...#......',
          '..........',
        ];
      case PixelIconType.triangleUp:
        return [
          '..........',
          '..........',
          '....##....',
          '...####...',
          '..######..',
          '.########.',
          '..........',
          '..........',
          '..........',
          '..........',
        ];
      case PixelIconType.triangleDown:
        return [
          '..........',
          '..........',
          '..........',
          '.########.',
          '..######..',
          '...####...',
          '....##....',
          '..........',
          '..........',
          '..........',
        ];
      case PixelIconType.paw:
        return [
          '..............',
          '...##....##...',
          '..#WW#..#WW#..',
          '..#WW#..#WW#..',
          '.#.##....##.#.',
          '#W#........#W#',
          '#W#..####..#W#',
          '.#..#WWWW#..#.',
          '...#WWWWWW#...',
          '..#WWWWWWWW#..',
          '..#WWWWWWWW#..',
          '...########...',
          '..............',
          '..............',
        ];
      case PixelIconType.calendar:
        return [
          '..............',
          '...##....##...',
          '..####..####..',
          '.############.',
          '.#RRRRRRRRRR#.',
          '.#RRRRRRRRRR#.',
          '.############.',
          '.#WWWWWWWWWW#.',
          '.#W##W##W##W#.',
          '.#WWWWWWWWWW#.',
          '.#W##W##W##W#.',
          '.#WWWWWWWWWW#.',
          '.############.',
          '..............',
        ];
      case PixelIconType.calendarPlus:
        return [
          '..............',
          '...##....##...',
          '..#BBBBBBBB#..',
          '.#BBBBBBBBBB#.',
          '.############.',
          '.#WWWWWWWWWW#.',
          '.#W##W##WWWW#.',
          '.#WWWWWWGGGG#.',
          '.#W##WWGGWWGG.',
          '.#WWWWWGWWWWG.',
          '.#WWWWWGGWWGG.',
          '.#######GGGG#.',
          '..............',
          '..............',
        ];
      case PixelIconType.timeline:
        return [
          '..............',
          '..###.........',
          '.#LLL#.######.',
          '.#LLL#.######.',
          '..###.........',
          '...#..........',
          '..###.........',
          '.#LLL#.######.',
          '.#LLL#.######.',
          '..###.........',
          '...#..........',
          '..###.........',
          '.#LLL#.######.',
          '..###.........',
        ];
      case PixelIconType.pencil:
        return [
          '..............',
          '.........###..',
          '........#PPP#.',
          '.......#PPPY#.',
          '......#PYYYO#.',
          '.....#YYYYO#..',
          '....#YYYYO#...',
          '...#YYYYO#....',
          '..#WWYYO#.....',
          '.#WWWW##......',
          '.#WW##........',
          '.###..........',
          '..............',
          '..............',
        ];
      case PixelIconType.clock:
        return [
          '..............',
          '....######....',
          '..##WWWWWW##..',
          '.#WWWW##WWWW#.',
          '.#WWWW##WWWW#.',
          '#WWWWW##WWWWW#',
          '#WWWWW##WWWWW#',
          '#WWWWW#####WW#',
          '#WWWWWWWWWWWW#',
          '.#WWWWWWWWWW#.',
          '.#WWWWWWWWWW#.',
          '..##WWWWWW##..',
          '....######....',
          '..............',
        ];
      case PixelIconType.camera:
        return [
          '................',
          '.....######.....',
          '....#LLLLLL#....',
          '.##############.',
          '#LLLLLLLLLLLLGG#',
          '#LLBBB####BBBLL#',
          '#LLB#WWWWWW#BLL#',
          '#LLB#WLLLLW#BLL#',
          '#LLB#WLWWLW#BLL#',
          '#LLB#WLLLLW#BLL#',
          '#LLB#WWWWWW#BLL#',
          '#BBBBB####BBBBB#',
          '.##############.',
          '................',
        ];
      case PixelIconType.gallery:
        return [
          '..............',
          '.############.',
          '.#LLLLLLLLLL#.',
          '.#LLYYLLLLLL#.',
          '.#LLYYLLLLLL#.',
          '.#LLLLLL##LL#.',
          '.#LLLLL#BB#L#.',
          '.#LL###BBBB##.',
          '.#L#BBBBBBBB#.',
          '.##BBBBBBBBBB#',
          '.#BBBBBBBBBB#.',
          '.############.',
          '..............',
          '..............',
        ];
      case PixelIconType.info:
        return [
          '............',
          '...######...',
          '..#BBBBBB#..',
          '.#BBBWWBBB#.',
          '.#BBBWWBBB#.',
          '.#BBBBBBBB#.',
          '.#BBBWWBBB#.',
          '.#BBBWWBBB#.',
          '.#BBBWWBBB#.',
          '.#BBBWWBBB#.',
          '..#BBBBBB#..',
          '...######...',
        ];
      case PixelIconType.check:
        return [
          '............',
          '............',
          '.........##.',
          '........###.',
          '.......###..',
          '.##...###...',
          '.###.###....',
          '..#####.....',
          '...###......',
          '....#.......',
          '............',
          '............',
        ];
      case PixelIconType.checkCircle:
        return [
          '..............',
          '....######....',
          '..##WWWWWW##..',
          '.#WWWWWWWWWW#.',
          '.#WWWWWWWW##W#',
          '#WWWWWWWW##WW#',
          '#W##WWWW##WWW#',
          '#W###WW##WWWW#',
          '#WW#####WWWWW#',
          '.#WW###WWWWW#.',
          '.#WWWWWWWWWW#.',
          '..##WWWWWW##..',
          '....######....',
          '..............',
        ];
      case PixelIconType.dumbbell:
        return [
          '................',
          '................',
          '..##........##..',
          '.#SS#......#SS#.',
          '.#SS##....##SS#.',
          '#SSB########BSS#',
          '#SSB#LLLLLL#BSS#',
          '#SSB########BSS#',
          '.#SS##....##SS#.',
          '.#SS#......#SS#.',
          '..##........##..',
          '................',
        ];
      case PixelIconType.book:
        return [
          '................',
          '................',
          '..#####..#####..',
          '.#YYYYY##YYYYY#.',
          '.#YWWYY##YYWWY#.',
          '.#YYYYY##YYYYY#.',
          '.#YWWYY##YYWWY#.',
          '.#YYYYY##YYYYY#.',
          '.#BBBBB##BBBBB#.',
          '..#####..#####..',
          '................',
          '................',
        ];
      case PixelIconType.droplet:
        return [
          '..............',
          '......##......',
          '.....#LL#.....',
          '....#LLLL#....',
          '...#LWLLLL#...',
          '..#LWWLLLLB#..',
          '..#LWLLLLBB#..',
          '..#LLLLBBBB#..',
          '..#LLLBBBBB#..',
          '...#BBBBBB#...',
          '....######....',
          '..............',
        ];
      case PixelIconType.cookie:
        return [
          '..............',
          '....######....',
          '..##NNNNNN##..',
          '.#NNDDNNNNNN#.',
          '.#NNDDNNNDDN#.',
          '#NNNNNNNNDDNN#',
          '#NNNDDNNNNNNN#',
          '#NNNDDNNNNDDN#',
          '#NNNNNNNNNDDN#',
          '.#NNNNDDNNNN#.',
          '.#NNNNDDNNNN#.',
          '..##NNNNNN##..',
          '....######....',
          '..............',
        ];
      case PixelIconType.heart:
        return [
          '..............',
          '..####..####..',
          '.#PPPP##PPPP#.',
          '#PWWPPPPPPPPP#',
          '#PWPPPPPPPPPP#',
          '#PPPPPPPPPPPP#',
          '.#PPPPPPPPPP#.',
          '..#PPPPPPPP#..',
          '...#PPPPPP#...',
          '....#PPPP#....',
          '.....#PP#.....',
          '......##......',
          '..............',
          '..............',
        ];
      case PixelIconType.foodBowl:
        return [
          '................',
          '.....######.....',
          '....#NNNNNN#....',
          '...#NNDDNNNN#...',
          '..############..',
          '.#BBBBBBBBBBBB#.',
          '.#BBBWWBBWWBBB#.',
          '#BBBBBBWWBBBBBB#',
          '#BBBBBBBBBBBBBB#',
          '.##############.',
          '................',
          '................',
        ];
      case PixelIconType.plus:
        return [
          '............',
          '.....##.....',
          '.....##.....',
          '.....##.....',
          '.##########.',
          '.##########.',
          '.....##.....',
          '.....##.....',
          '.....##.....',
          '............',
        ];
      case PixelIconType.close:
        return [
          '............',
          '..##....##..',
          '..###..###..',
          '...######...',
          '....####....',
          '....####....',
          '...######...',
          '..###..###..',
          '..##....##..',
          '............',
        ];
      case PixelIconType.sparkle:
        return [
          '...........',
          '..#..#..#..',
          '...#.#.#...',
          '...........',
          '.##.....##.',
          '...........',
          '...........',
          '...........',
        ];
    }
  }

  Color? _colorForChar(String ch) {
    switch (ch) {
      case '.':
        return null;
      case '#':
        return primaryColor ?? _outline;
      case 'W':
        return _white;
      case 'B':
        return accentColor ?? _blue;
      case 'L':
        return _blueLight;
      case 'S':
        return _silver;
      case 'P':
        return _pink;
      case 'Y':
        return _gold;
      case 'O':
      case 'G':
        return _amber;
      case 'R':
        return _red;
      case 'N':
        return _brown;
      case 'D':
        return _brownDark;
      case 'C':
        return _bluePale;
      case 'I':
        return _pinkLight;
      default:
        return primaryColor ?? _outline;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = _grid();
    final rowCount = rows.length;
    final colCount = rows[0].length;
    final cellW = size.width / colCount;
    final cellH = size.height / rowCount;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < rowCount; r++) {
      final line = rows[r];
      for (int c = 0; c < colCount; c++) {
        final color = _colorForChar(line[c]);
        if (color == null) continue;
        paint.color = color;
        // 0.2px 오버랩으로 웹/고해상도 스케일링 시 픽셀 사이 미세 실선 방지
        canvas.drawRect(
          Rect.fromLTWH(
            c * cellW,
            r * cellH,
            cellW + 0.25,
            cellH + 0.25,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelMatrixPainter old) =>
      old.type != type ||
      old.primaryColor != primaryColor ||
      old.accentColor != accentColor;
}

/// 시안 스타일 3갈래 픽셀 반짝이 광선 (＼ | ／)
class PixelSparkle extends StatelessWidget {
  final Color color;
  final double pixelSize;
  final bool flipVertical;

  const PixelSparkle({
    super.key,
    this.color = const Color(0xFFFFC107),
    this.pixelSize = 3.0,
    this.flipVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = pixelSize;
    Widget widget = SizedBox(
      width: s * 8,
      height: s * 5,
      child: CustomPaint(
        painter: _PixelSparklePainter(color: color, pixelSize: s),
      ),
    );
    if (flipVertical) {
      widget = Transform.scale(scaleY: -1, child: widget);
    }
    return widget;
  }
}

class _PixelSparklePainter extends CustomPainter {
  final Color color;
  final double pixelSize;

  _PixelSparklePainter({required this.color, required this.pixelSize});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final s = pixelSize;

    // 좌측 사선 (＼)
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), p);
    canvas.drawRect(Rect.fromLTWH(s, s, s, s), p);

    // 중앙 수직선 (|)
    canvas.drawRect(Rect.fromLTWH(3.5 * s, 0, s, s), p);
    canvas.drawRect(Rect.fromLTWH(3.5 * s, s, s, s), p);
    canvas.drawRect(Rect.fromLTWH(3.5 * s, 2 * s, s, s), p);

    // 우측 사선 (／)
    canvas.drawRect(Rect.fromLTWH(7 * s, 0, s, s), p);
    canvas.drawRect(Rect.fromLTWH(6 * s, s, s, s), p);
  }

  @override
  bool shouldRepaint(covariant _PixelSparklePainter old) =>
      old.color != color || old.pixelSize != pixelSize;
}

/// 이름 설정 안내 모달 상단에 두 앞발로 매달려 빼꼼 내다보는 순수 픽셀 고양이
class PixelPeekingCat extends StatelessWidget {
  final double width;

  const PixelPeekingCat({
    super.key,
    this.width = 128,
  });

  @override
  Widget build(BuildContext context) {
    // 28x17 비율
    final height = width * (17 / 28);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _PixelPeekingCatPainter(),
          ),
        ),
        // 좌측 파스텔 블루 픽셀 별
        Positioned(
          left: -18,
          bottom: 12,
          child: SizedBox(
            width: 12,
            height: 12,
            child: CustomPaint(
              painter: _PixelMiniDiamondPainter(
                color: const Color(0xFFB3D5FC),
                borderColor: const Color(0xFF466FA7),
              ),
            ),
          ),
        ),
        // 우측 상단 노란 3갈래 픽셀 반짝이
        Positioned(
          right: -18,
          top: -6,
          child: Transform.rotate(
            angle: 0.45,
            child: const PixelSparkle(
              color: Color(0xFFFFC107),
              pixelSize: 2.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _PixelPeekingCatPainter extends CustomPainter {
  static const _rows = [
    '............................',
    '.....####..........####.....',
    '....#WWWW#........#WWWW#....',
    '...#WWIIWW#......#WWIIWW#...',
    '...#WWIIIW########WIIIWW#...',
    '..#WWWIIWWWWWWWWWWWWIIWWW#..',
    '..#WWWWWWWWWWWWWWWWWWWWWW#..',
    '..#WWWWWWWWWWWWWWWWWWWWWW#..',
    '..#WWWWW##WWWWWWWW##WWWWW#..',
    '###WWWWW##WWWWWWWW##WWWWW###',
    '..#WWWWWWWWWW##WWWWWWWWWW#..',
    '###WWPPWWWW#W##W#WWWWPPWW###',
    '..#WWPPWWWWW#WW#WWWWWPPWW#..',
    '..###WWWWWWWWWWWWWWWWWW###..',
    '.#WWWW#..##########..#WWWW#.',
    '#WW#W#W#............#W#W#WW#',
    '.######..............######.',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rowCount = _rows.length;
    final colCount = _rows[0].length;
    final cellW = size.width / colCount;
    final cellH = size.height / rowCount;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < rowCount; r++) {
      final line = _rows[r];
      for (int c = 0; c < colCount; c++) {
        Color? color;
        switch (line[c]) {
          case '#':
            color = const Color(0xFF284673);
            break;
          case 'W':
            color = Colors.white;
            break;
          case 'I':
            color = const Color(0xFFF6D9E4);
            break;
          case 'P':
            color = const Color(0xFFFFA9BE);
            break;
          default:
            color = null;
        }
        if (color == null) continue;
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, r * cellH, cellW + 0.25, cellH + 0.25),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PixelMiniDiamondPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _PixelMiniDiamondPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final p = size.width / 5;
    final bp = Paint()..color = borderColor;
    final fp = Paint()..color = color;

    // 5x5 픽셀 별 외곽선
    canvas.drawRect(Rect.fromLTWH(2 * p, 0, p, p * 5), bp);
    canvas.drawRect(Rect.fromLTWH(0, 2 * p, p * 5, p), bp);
    canvas.drawRect(Rect.fromLTWH(p, p, p * 3, p * 3), bp);
    // 내부 밝은 채우기
    canvas.drawRect(Rect.fromLTWH(2 * p, p, p, p * 3), fp);
    canvas.drawRect(Rect.fromLTWH(p, 2 * p, p * 3, p), fp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

