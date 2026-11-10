import 'package:flutter/material.dart';
import '../models/character.dart';
import 'pixel_animal_view.dart';

/// 레트로 픽셀 아트(도트 그래픽) 캐릭터를 전담하여 렌더링하는 공통 위젯
///
/// 기능:
/// - 포켓몬스터 / 스타듀밸리 / 다마고치 감성의 크리스피 도트 픽셀 그래픽
/// - 고양이: 도트 앞발로 뺨과 얼굴을 쓱싹 문지르는 "픽셀 고양이 세수" 모션!
/// - 강아지: 픽셀 꼬리를 붕붕 흔들고 픽셀 혓바닥을 빼꼼 내밀며 총총 뛰는 모션!
/// - 오리/카피바라/우파루파/드래곤: 날개 파닥이기, 귤 통통, 손 흔들기 도트 애니메이션!
class CharacterView extends StatelessWidget {
  final CharacterType characterType;
  final String stage;
  final double size;
  final bool animated;
  final Color? accentColor;
  final Color? customColor;
  final String? colorHex;
  final bool showCard;
  final bool enableRoam;
  final PetBehavior? forcedBehavior;
  final int actionTrigger;
  final ValueChanged<PetBehavior>? onBehaviorChanged;

  const CharacterView({
    super.key,
    required this.characterType,
    this.stage = 'baby',
    this.size = 180,
    this.animated = true,
    this.accentColor,
    this.customColor,
    this.colorHex,
    this.showCard = false,
    this.enableRoam = false,
    this.forcedBehavior,
    this.actionTrigger = 0,
    this.onBehaviorChanged,
  });

  Color? _resolveColor() {
    if (customColor != null) return customColor;
    if (colorHex != null && colorHex!.isNotEmpty) {
      final clean = colorHex!.replaceFirst('#', '');
      try {
        if (clean.length == 6) {
          return Color(int.parse('FF$clean', radix: 16));
        } else if (clean.length == 8) {
          return Color(int.parse(clean, radix: 16));
        }
      } catch (_) {}
    }
    return accentColor;
  }

  @override
  Widget build(BuildContext context) {
    return PixelAnimalView(
      characterType: characterType,
      size: size,
      animated: animated,
      customColor: _resolveColor(),
      enableRoam: enableRoam,
      forcedBehavior: forcedBehavior,
      actionTrigger: actionTrigger,
      onBehaviorChanged: onBehaviorChanged,
    );
  }
}
