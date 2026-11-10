import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/character.dart';

/// 캐릭터의 자율 / 인터랙션 모션 상태
enum PetBehavior {
  idle,        // 기본 숨쉬기
  roamWalk,    // 방 안 좌우 아장아장 산책
  restSquish,  // 찌부러져 엎드려 쉬기 + Zzz/하트 (시안 1)
  curiousLook, // 두리번두리번 주변 살피기
  groomOrNap,  // 몸단장 / 귤 튕기기 / 날갯짓
  happyJump,   // 클릭 리액션 1: 기쁨 하이점프
  spinTwirl,   // 클릭 리액션 2: 빙그르르 한 바퀴 회전
  loveySquish, // 클릭 리액션 3: 폭신 찌부 애교 + 큰 하트
  dashZigzag,  // 클릭 리액션 4: 좌우 통통 대시
  eatSnack,    // 밥 주기 리액션: 냠냠 먹기
  playBurst,   // 놀아주기 리액션: 연속 대점프 파티
}

/// 방 안에서 마우스 클릭과 3초 이상 유휴(Idle) 상태에 따라
/// 다채로운 랜덤 모션과 픽셀 이펙트를 보여주는 생동감 있는 픽셀 펫 뷰
class PixelAnimalView extends StatefulWidget {
  final CharacterType characterType;
  final double size;
  final bool animated;
  final Color? customColor;
  final bool enableRoam;
  final PetBehavior? forcedBehavior;
  final int actionTrigger;
  final ValueChanged<PetBehavior>? onBehaviorChanged;

  const PixelAnimalView({
    super.key,
    required this.characterType,
    this.size = 200,
    this.animated = true,
    this.customColor,
    this.enableRoam = false,
    this.forcedBehavior,
    this.actionTrigger = 0,
    this.onBehaviorChanged,
  });

  @override
  State<PixelAnimalView> createState() => _PixelAnimalViewState();
}

class _PixelAnimalViewState extends State<PixelAnimalView>
    with TickerProviderStateMixin {
  late AnimationController _loopController;
  late AnimationController _actionController;

  final math.Random _rng = math.Random();

  PetBehavior _behavior = PetBehavior.idle;
  PetBehavior? _lastClickBehavior;
  PetBehavior? _lastIdleBehavior;

  // 방 안 좌우 이동 좌표 (-maxRoam ~ +maxRoam)
  double _posX = 0.0;
  double _startX = 0.0;
  double _targetX = 0.0;
  double _walkProgress = 1.0;
  bool _facingRight = true;

  Timer? _inactivityTimer;
  Timer? _autoBehaviorTimer;
  Timer? _actionResetTimer;

  double get _maxRoam => widget.enableRoam ? 58.0 : 0.0;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _actionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _loopController.addListener(_tickMovement);

    if (widget.animated) {
      _loopController.repeat();
      _scheduleInactivityTimeout();
    }
  }

  @override
  void didUpdateWidget(covariant PixelAnimalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _loopController.repeat();
        _scheduleInactivityTimeout();
      } else {
        _loopController.stop();
        _cancelAllTimers();
      }
    }
    if (widget.actionTrigger != oldWidget.actionTrigger &&
        widget.forcedBehavior != null) {
      final target = widget.forcedBehavior!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _playExternalBehavior(target);
        }
      });
    }
  }

  @override
  void dispose() {
    _cancelAllTimers();
    _loopController.removeListener(_tickMovement);
    _loopController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  void _cancelAllTimers() {
    _inactivityTimer?.cancel();
    _autoBehaviorTimer?.cancel();
    _actionResetTimer?.cancel();
  }

  /// 아무것도 클릭하지 않고 3초 이상 지나면 자율 랜덤 모션 시작
  void _scheduleInactivityTimeout() {
    if (!widget.animated) return;
    _inactivityTimer?.cancel();
    _autoBehaviorTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !widget.animated) return;
      _triggerRandomIdleBehavior();
    });
  }

  void _notifyBehaviorChanged(PetBehavior behavior) {
    if (widget.onBehaviorChanged == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onBehaviorChanged?.call(behavior);
      }
    });
  }

  /// 자율(방치 3초+) 랜덤 모션 선택 및 순환
  void _triggerRandomIdleBehavior() {
    if (!mounted || !widget.animated) return;

    final pool = <PetBehavior>[
      if (widget.enableRoam) PetBehavior.roamWalk,
      if (widget.enableRoam) PetBehavior.roamWalk, // 걷기 확률 가중치
      PetBehavior.restSquish,
      PetBehavior.curiousLook,
      PetBehavior.groomOrNap,
      PetBehavior.idle,
    ];

    final candidates =
        pool.where((b) => b != _lastIdleBehavior).toList(growable: false);
    final chosen = candidates[_rng.nextInt(candidates.length)];
    _lastIdleBehavior = chosen;

    setState(() {
      _behavior = chosen;
      if (chosen == PetBehavior.roamWalk && widget.enableRoam) {
        _startX = _posX;
        double nextX = (_rng.nextDouble() * 2 - 1) * _maxRoam;
        // 최소 26px 이상 이동하도록 보정
        if ((nextX - _posX).abs() < 26) {
          nextX = _posX > 0 ? -_maxRoam * 0.7 : _maxRoam * 0.7;
        }
        _targetX = nextX.clamp(-_maxRoam, _maxRoam);
        _facingRight = _targetX >= _posX;
        _walkProgress = 0.0;
      } else if (chosen == PetBehavior.curiousLook) {
        _facingRight = _rng.nextBool();
      }
    });
    _notifyBehaviorChanged(chosen);

    // 3.0 ~ 4.4초 후 또 다른 랜덤 자율 모션으로 전환
    _autoBehaviorTimer?.cancel();
    _autoBehaviorTimer = Timer(
      Duration(milliseconds: 3000 + _rng.nextInt(1400)),
      _triggerRandomIdleBehavior,
    );
  }

  /// 마우스 클릭/터치 시 매번 다른 랜덤 생동감 모션 실행!
  void _handleUserClick() {
    if (!widget.animated) return;

    final clickPool = <PetBehavior>[
      PetBehavior.happyJump,
      PetBehavior.spinTwirl,
      PetBehavior.loveySquish,
      PetBehavior.dashZigzag,
    ];
    final candidates =
        clickPool.where((b) => b != _lastClickBehavior).toList();
    final chosen = candidates[_rng.nextInt(candidates.length)];
    _lastClickBehavior = chosen;

    _runActionBehavior(chosen, durationMs: 900);
  }

  void _playExternalBehavior(PetBehavior behavior) {
    if (!widget.animated) return;
    _runActionBehavior(behavior, durationMs: 1100);
  }

  void _runActionBehavior(PetBehavior behavior, {required int durationMs}) {
    _inactivityTimer?.cancel();
    _autoBehaviorTimer?.cancel();
    _actionResetTimer?.cancel();

    setState(() {
      _behavior = behavior;
      _walkProgress = 1.0;
    });
    _notifyBehaviorChanged(behavior);

    _actionController.duration = Duration(milliseconds: durationMs);
    _actionController.forward(from: 0.0);

    _actionResetTimer = Timer(Duration(milliseconds: durationMs), () {
      if (!mounted) return;
      setState(() {
        _behavior = PetBehavior.idle;
      });
      _notifyBehaviorChanged(PetBehavior.idle);
      // 액션 종료 후 다시 3초 유휴 타이머 시작
      _scheduleInactivityTimeout();
    });
  }

  void _tickMovement() {
    if (_behavior == PetBehavior.roamWalk && _walkProgress < 1.0) {
      // 1.8초 루프당 한 번 목적지 도착
      _walkProgress = (_walkProgress + 0.012).clamp(0.0, 1.0);
      final ease = Curves.easeInOut.transform(_walkProgress);
      _posX = _startX + (_targetX - _startX) * ease;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final stageWidth = widget.enableRoam ? size + 120 : size;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleUserClick(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_loopController, _actionController]),
        builder: (context, child) {
          final t = widget.animated ? _loopController.value : 0.0;
          final actT = _actionController.value;
          final motion = _computeMotion(
            widget.characterType,
            _behavior,
            t,
            actT,
            _walkProgress,
            _facingRight,
          );

          return SizedBox(
            width: stageWidth,
            height: size + 28,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // 1. 바닥 픽셀 그림자 (캐릭터 x위치 및 점프/찌부 상태에 연동)
                Positioned(
                  bottom: 4,
                  child: Transform.translate(
                    offset: Offset(_posX + motion.dx, 0),
                    child: CustomPaint(
                      size: Size(size * 0.54 * motion.shadowScale, 14),
                      painter: _PixelGroundShadowPainter(),
                    ),
                  ),
                ),

                // 2. 살아 움직이는 픽셀 캐릭터 스프라이트
                Positioned(
                  bottom: 8,
                  child: Transform.translate(
                    offset: Offset(_posX + motion.dx, motion.dy),
                    child: Transform.rotate(
                      angle: motion.rotation,
                      alignment: Alignment.bottomCenter,
                      child: Transform.scale(
                        scaleX: motion.scaleX * motion.flipX,
                        scaleY: motion.scaleY,
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: size * 0.88,
                          height: size * 0.88,
                          child: Image.asset(
                            widget.characterType.getAssetPath(stage: 'baby'),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. 상황별/모션별 픽셀 파티클 이펙트 (하트, Zzz, 별, 먼지, 음표)
                Positioned(
                  bottom: 0,
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(_posX + motion.dx, 0),
                      child: CustomPaint(
                        painter: _PixelBehaviorEffectPainter(
                          type: widget.characterType,
                          behavior: _behavior,
                          t: t,
                          actT: actT,
                          facingRight: _facingRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _CharacterMotion _computeMotion(
    CharacterType type,
    PetBehavior behavior,
    double t,
    double actT,
    double walkProgress,
    bool facingRight,
  ) {
    final twoPi = math.pi * 2;
    double dx = 0;
    double dy = 0;
    double rotation = 0;
    double scaleX = 1.0;
    double scaleY = 1.0;
    double shadowScale = 1.0;
    // 기본 이미지는 오리/강아지/고양이/드래곤/카피바라 대부분 오른쪽(또는 정면우측) 응시
    double flipX = facingRight ? 1.0 : -1.0;

    switch (behavior) {
      case PetBehavior.idle:
        // 캐릭터별 기본 생동감 숨쉬기
        if (type == CharacterType.dragon) {
          dy = -7.0 + math.sin(t * twoPi) * 6.0;
          scaleX = 1.0 + math.sin(t * twoPi * 4) * 0.03;
          scaleY = 1.0 - math.sin(t * twoPi * 4) * 0.02;
          shadowScale = 0.85 + math.sin(t * twoPi) * 0.1;
        } else if (type == CharacterType.axolotl) {
          dx = math.sin(t * twoPi) * 4.0;
          dy = -4.0 + math.cos(t * twoPi * 2) * 3.5;
          rotation = math.sin(t * twoPi) * 0.04;
        } else {
          final b = math.sin(t * twoPi);
          scaleY = 1.0 + b * 0.035;
          scaleX = 1.0 - b * 0.025;
          rotation = math.sin(t * twoPi) * 0.025;
        }
        break;

      case PetBehavior.roamWalk:
        // 방 안 아장아장 걸어가기! (도착 전엔 톡톡 스텝, 도착 후엔 갸웃)
        if (walkProgress < 0.98) {
          final step = math.sin(t * twoPi * 4);
          final hop = step.abs();
          dy = -hop * 10.0;
          rotation = step * 0.085;
          scaleY = 1.0 + hop * 0.045 - (hop < 0.18 ? 0.04 : 0.0);
          scaleX = 1.0 - hop * 0.02 + (hop < 0.18 ? 0.04 : 0.0);
          shadowScale = 1.0 - hop * 0.16;
        } else {
          final b = math.sin(t * twoPi);
          scaleY = 1.0 + b * 0.03;
          scaleX = 1.0 - b * 0.02;
        }
        break;

      case PetBehavior.restSquish:
        // 시안 1번: 바닥에 납작 폭신하게 찌부러져 쉬기 + 꾸벅꾸벅
        final napBreath = math.sin(t * twoPi);
        scaleY = 0.78 + napBreath * 0.035;
        scaleX = 1.16 - napBreath * 0.025;
        rotation = math.sin(t * twoPi * 0.5) * 0.02;
        shadowScale = 1.15;
        break;

      case PetBehavior.curiousLook:
        // 두리번두리번 좌우 살펴보며 귀 쫑긋 홉
        final lookTick = (t * 2).floor() % 2 == 0;
        flipX = lookTick ? 1.0 : -1.0;
        final hop = math.max(0.0, math.sin(t * twoPi * 2));
        dy = -hop * 5.0;
        rotation = (lookTick ? 1 : -1) * 0.05;
        scaleY = 1.0 + hop * 0.04;
        break;

      case PetBehavior.groomOrNap:
        // 앞뒤 리드미컬 몸단장 / 귤 튕기기 / 날갯짓
        final sway = math.sin(t * twoPi * 2);
        dy = -sway.abs() * 5.0;
        rotation = sway * 0.075;
        scaleY = 1.0 - (sway > 0.4 ? 0.05 : 0.0);
        scaleX = 1.0 + (sway > 0.4 ? 0.04 : 0.0);
        break;

      case PetBehavior.happyJump:
        // 클릭 리액션 1: 높이 폴짝 점프 + 착지 스쿼시
        final p = actT;
        if (p < 0.15) {
          // 도약 준비 스쿼시
          final s = p / 0.15;
          scaleY = 1.0 - s * 0.22;
          scaleX = 1.0 + s * 0.18;
          shadowScale = 1.0 + s * 0.14;
        } else if (p < 0.78) {
          // 공중 포물선 점프
          final air = (p - 0.15) / 0.63;
          final arc = math.sin(air * math.pi);
          dy = -arc * 38.0;
          rotation = math.sin(air * math.pi * 2) * 0.13;
          scaleY = 1.0 + arc * 0.08;
          scaleX = 1.0 - arc * 0.05;
          shadowScale = 1.0 - arc * 0.35;
        } else {
          // 착지 폭신 스쿼시
          final land = (p - 0.78) / 0.22;
          final bounce = math.sin(land * math.pi);
          scaleY = 1.0 - bounce * 0.20;
          scaleX = 1.0 + bounce * 0.16;
          shadowScale = 1.0 + bounce * 0.12;
        }
        break;

      case PetBehavior.spinTwirl:
        // 클릭 리액션 2: 빙그르르 한 바퀴 회전! (가로 스케일 cos 회전 효과)
        final p = actT;
        final arc = math.sin(p * math.pi);
        dy = -arc * 24.0;
        final spinCos = math.cos(p * twoPi * 2); // 두 번 뒤집기 360 회전
        flipX = spinCos.abs().clamp(0.15, 1.0) * (spinCos >= 0 ? 1.0 : -1.0);
        scaleY = 1.0 + arc * 0.06;
        shadowScale = 1.0 - arc * 0.25;
        break;

      case PetBehavior.loveySquish:
        // 클릭 리액션 3: 시안 1처럼 말랑하게 찌부 애교 + 탱글 복귀
        final p = actT;
        if (p < 0.55) {
          final press = math.sin((p / 0.55) * math.pi);
          scaleY = 1.0 - press * 0.28;
          scaleX = 1.0 + press * 0.24;
          shadowScale = 1.0 + press * 0.2;
        } else {
          final pop = math.sin(((p - 0.55) / 0.45) * math.pi);
          dy = -pop * 14.0;
          scaleY = 1.0 + pop * 0.08;
          scaleX = 1.0 - pop * 0.04;
          shadowScale = 1.0 - pop * 0.18;
        }
        break;

      case PetBehavior.dashZigzag:
        // 클릭 리액션 4: 좌우로 통통통 신나게 대시!
        final p = actT;
        final wave = math.sin(p * twoPi * 2);
        dx = wave * 18.0;
        dy = -wave.abs() * 14.0;
        flipX = math.cos(p * twoPi * 2) >= 0 ? 1.0 : -1.0;
        rotation = wave * 0.10;
        shadowScale = 1.0 - wave.abs() * 0.2;
        break;

      case PetBehavior.eatSnack:
        // 밥 주기 리액션: 3번 끄덕끄덕 오물오물 냠냠!
        final chomp = math.sin(actT * twoPi * 3);
        scaleY = 1.0 - chomp.abs() * 0.14;
        scaleX = 1.0 + chomp.abs() * 0.10;
        rotation = chomp * 0.09;
        dy = -math.max(0.0, -chomp) * 4.0;
        break;

      case PetBehavior.playBurst:
        // 놀아주기 리액션: 신난 2단 하이점프 콤보!
        final jumpWave = math.sin(actT * twoPi).abs();
        dx = math.sin(actT * twoPi) * 14.0;
        dy = -jumpWave * 36.0;
        rotation = math.sin(actT * twoPi * 2) * 0.12;
        scaleY = 1.0 + jumpWave * 0.08;
        shadowScale = 1.0 - jumpWave * 0.35;
        break;
    }

    return _CharacterMotion(
      dx: dx,
      dy: dy,
      rotation: rotation,
      scaleX: scaleX,
      scaleY: scaleY,
      flipX: flipX,
      shadowScale: shadowScale.clamp(0.55, 1.25),
    );
  }
}

class _CharacterMotion {
  final double dx;
  final double dy;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final double flipX;
  final double shadowScale;

  const _CharacterMotion({
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.scaleX,
    required this.scaleY,
    required this.flipX,
    required this.shadowScale,
  });
}

/// 계단식 픽셀 바닥 그림자 페인터
class _PixelGroundShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x3D213E6D)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(w * 0.14, 0, w * 0.72, h * 0.3), p);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.28, w, h * 0.44), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.14, h * 0.70, w * 0.72, h * 0.3), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 모션 상태 및 캐릭터 성격별 픽셀 파티클 이펙트 페인터
class _PixelBehaviorEffectPainter extends CustomPainter {
  final CharacterType type;
  final PetBehavior behavior;
  final double t;
  final double actT;
  final bool facingRight;

  _PixelBehaviorEffectPainter({
    required this.type,
    required this.behavior,
    required this.t,
    required this.actT,
    required this.facingRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;
    final px = (h / 52).clamp(2.5, 4.2);

    switch (behavior) {
      case PetBehavior.restSquish:
        // 시안 1번처럼: 찌부러져 쉴 때 머리 위 분홍 하트 또는 Zzz!
        final rise = t % 1.0;
        final alpha = math.sin(rise * math.pi).clamp(0.0, 1.0);
        _drawPixelHeart(
          canvas,
          cx,
          h * (0.28 - rise * 0.16),
          px * 1.1,
          Color.fromRGBO(255, 130, 160, alpha),
        );
        _drawPixelZ(
          canvas,
          cx + 34,
          h * (0.34 - ((t + 0.4) % 1.0) * 0.16),
          px * 0.9,
          Color.fromRGBO(255, 255, 255, alpha * 0.9),
        );
        break;

      case PetBehavior.roamWalk:
        // 걸을 때 발 뒤로 작은 픽셀 발걸음 먼지 퐁퐁
        final dustPhase = (t * 4) % 1.0;
        final dir = facingRight ? -1.0 : 1.0;
        _drawPixelDust(
          canvas,
          cx + dir * (28 + dustPhase * 16),
          h - 14 - dustPhase * 8,
          px * 0.85,
          Color.fromRGBO(255, 255, 255, (1.0 - dustPhase).clamp(0.0, 0.8)),
        );
        break;

      case PetBehavior.groomOrNap:
        // 몸단장 / 온천 수증기 / 음표
        final rise = t % 1.0;
        final alpha = math.sin(rise * math.pi).clamp(0.0, 1.0);
        if (type == CharacterType.capybara) {
          _drawPixelSteam(
            canvas,
            cx,
            h * (0.22 - rise * 0.15),
            px,
            Color.fromRGBO(255, 255, 255, alpha),
          );
        } else {
          _drawPixelNote(
            canvas,
            cx + 36,
            h * (0.26 - rise * 0.16),
            px,
            Color.fromRGBO(255, 200, 60, alpha),
          );
        }
        break;

      case PetBehavior.curiousLook:
        // 갸웃 물음표/느낌표 느낌의 반짝이
        final blink = (t * 2) % 1.0;
        _drawPixelStar(
          canvas,
          cx + (facingRight ? 38 : -38),
          h * 0.25,
          px,
          Color.fromRGBO(142, 192, 252, blink < 0.6 ? 1.0 : 0.3),
        );
        break;

      case PetBehavior.happyJump:
      case PetBehavior.playBurst:
      case PetBehavior.spinTwirl:
      case PetBehavior.dashZigzag:
        // 클릭/놀아주기 리액션: 사방으로 하트와 별 폭발!
        final p = actT;
        final alpha = (1.0 - p).clamp(0.0, 1.0);
        final spread = p * 34.0;
        _drawPixelHeart(
          canvas,
          cx,
          h * 0.16 - spread * 0.7,
          px * 1.25,
          Color.fromRGBO(255, 123, 152, alpha),
        );
        _drawPixelStar(
          canvas,
          cx - 38 - spread * 0.6,
          h * 0.28 - spread * 0.5,
          px * 1.1,
          Color.fromRGBO(255, 212, 77, alpha),
        );
        _drawPixelStar(
          canvas,
          cx + 38 + spread * 0.6,
          h * 0.28 - spread * 0.5,
          px * 1.1,
          Color.fromRGBO(255, 212, 77, alpha),
        );
        _drawPixelNote(
          canvas,
          cx + 24,
          h * 0.18 - spread * 0.8,
          px,
          Color.fromRGBO(142, 192, 252, alpha),
        );
        break;

      case PetBehavior.loveySquish:
      case PetBehavior.eatSnack:
        // 찌부 애교 & 밥 먹기: 큰 분홍 하트 + 별!
        final p = actT;
        final alpha = (1.0 - p * 0.85).clamp(0.0, 1.0);
        final rise = p * 26.0;
        _drawPixelHeart(
          canvas,
          cx,
          h * 0.22 - rise,
          px * 1.4,
          Color.fromRGBO(255, 123, 152, alpha),
        );
        _drawPixelStar(
          canvas,
          cx - 32,
          h * 0.30 - rise * 0.7,
          px,
          Color.fromRGBO(255, 212, 77, alpha),
        );
        _drawPixelStar(
          canvas,
          cx + 32,
          h * 0.30 - rise * 0.7,
          px,
          Color.fromRGBO(255, 212, 77, alpha),
        );
        break;

      case PetBehavior.idle:
        // 기본 상태에서도 캐릭터별 은은한 시그니처 도트
        final rise = t % 1.0;
        final alpha = math.sin(rise * math.pi).clamp(0.0, 1.0);
        if (type == CharacterType.dragon) {
          _drawPixelStar(
            canvas,
            cx - 46,
            h * 0.30,
            px * (0.6 + alpha * 0.5),
            Color.fromRGBO(255, 212, 77, 0.4 + alpha * 0.6),
          );
          _drawPixelStar(
            canvas,
            cx + 46,
            h * 0.58,
            px * (1.1 - alpha * 0.4),
            Color.fromRGBO(255, 212, 77, 1.0 - alpha * 0.5),
          );
        } else if (type == CharacterType.axolotl) {
          _drawPixelDust(
            canvas,
            cx + 42,
            h * (0.50 - rise * 0.25),
            px,
            Color.fromRGBO(142, 192, 252, alpha * 0.9),
          );
        } else {
          _drawPixelHeart(
            canvas,
            cx + 40,
            h * (0.34 - rise * 0.14),
            px * 0.85,
            Color.fromRGBO(255, 123, 152, alpha * 0.85),
          );
        }
        break;
    }
  }

  void _drawPixelHeart(Canvas canvas, double cx, double cy, double p, Color c) {
    final paint = Paint()..color = c;
    const rows = [
      '.##.##.',
      '#######',
      '#######',
      '.#####.',
      '..###..',
      '...#...',
    ];
    for (int r = 0; r < rows.length; r++) {
      for (int col = 0; col < rows[r].length; col++) {
        if (rows[r][col] == '#') {
          canvas.drawRect(
            Rect.fromLTWH(cx + (col - 3.5) * p, cy + (r - 3) * p, p, p),
            paint,
          );
        }
      }
    }
  }

  void _drawPixelStar(Canvas canvas, double cx, double cy, double p, Color c) {
    final paint = Paint()..color = c;
    canvas.drawRect(Rect.fromLTWH(cx - p * 0.5, cy - p * 2.0, p, p * 4), paint);
    canvas.drawRect(Rect.fromLTWH(cx - p * 2.0, cy - p * 0.5, p * 4, p), paint);
    canvas.drawRect(
      Rect.fromLTWH(cx - p * 0.5, cy - p * 0.5, p, p),
      Paint()..color = Colors.white.withValues(alpha: c.a),
    );
  }

  void _drawPixelNote(Canvas canvas, double cx, double cy, double p, Color c) {
    final paint = Paint()..color = c;
    canvas.drawRect(Rect.fromLTWH(cx, cy - p * 3, p, p * 4), paint);
    canvas.drawRect(Rect.fromLTWH(cx, cy - p * 3, p * 2.5, p), paint);
    canvas.drawRect(Rect.fromLTWH(cx - p * 1.5, cy, p * 2, p * 1.5), paint);
  }

  void _drawPixelSteam(Canvas canvas, double cx, double cy, double p, Color c) {
    final paint = Paint()..color = c;
    canvas.drawRect(Rect.fromLTWH(cx, cy, p, p * 1.5), paint);
    canvas.drawRect(Rect.fromLTWH(cx - p, cy - p * 1.5, p, p * 1.5), paint);
    canvas.drawRect(Rect.fromLTWH(cx, cy - p * 3, p, p * 1.5), paint);
  }

  void _drawPixelDust(Canvas canvas, double cx, double cy, double p, Color c) {
    final paint = Paint()..color = c;
    canvas.drawRect(Rect.fromLTWH(cx - p, cy - p, p * 2, p * 2), paint);
  }

  void _drawPixelZ(Canvas canvas, double cx, double cy, double p, Color c) {
    final paint = Paint()..color = c;
    canvas.drawRect(Rect.fromLTWH(cx, cy, p * 3, p), paint);
    canvas.drawRect(Rect.fromLTWH(cx + p, cy + p, p, p), paint);
    canvas.drawRect(Rect.fromLTWH(cx, cy + p * 2, p * 3, p), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelBehaviorEffectPainter old) =>
      old.t != t ||
      old.actT != actT ||
      old.behavior != behavior ||
      old.type != type ||
      old.facingRight != facingRight;
}
