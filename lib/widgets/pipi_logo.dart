import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// PIPI 공식 브랜드 로고 위젯
/// 
/// 고양이 캐릭터와 PIPI (plan pet) 브랜드 그래픽을 표시합니다.
/// 투명 배경 에셋(`assets/images/logo_transparent.png`)을 기본으로 사용합니다.
class PipiLogo extends StatelessWidget {
  /// 로고의 가로 너비 (기본값: 190.0)
  final double width;

  /// 하단 슬로건 텍스트 표시 여부 ('계획으로 나만의 반려동물을 키워보세요!')
  final bool showSubtitle;

  const PipiLogo({
    super.key,
    this.width = 190.0,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 공식 PIPI 로고 이미지 에셋
        Image.asset(
          'assets/images/logo_transparent.png',
          width: width,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // 혹시 투명 버전 에셋 로드 실패 시 원본 로고로 폴백
            return Image.asset(
              'assets/images/logo.png',
              width: width,
              fit: BoxFit.contain,
            );
          },
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 10),
          const Text(
            '계획으로 나만의 반려동물을 키워보세요!',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.pointNavy,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
