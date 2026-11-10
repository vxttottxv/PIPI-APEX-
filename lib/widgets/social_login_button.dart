import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 소셜 로그인 플랫폼 종류
enum SocialLoginType {
  /// 카카오 계정 로그인
  kakao,

  /// 구글 계정 로그인
  google,
}

/// 카카오 및 구글 연동 로그인 전용 버튼 위젯
/// 
/// 명세서 디자인 사양:
/// - 둥근 모서리: 12
/// - 부드러운 그림자 및 테두리 효과
/// - 고해상도 벡터 기반 공식 브랜드 로고(CustomPainter) 내장
/// - 로딩 상태(스피너 표시) 내장
class SocialLoginButton extends StatelessWidget {
  /// 연동할 소셜 플랫폼 종류 (카카오 또는 구글)
  final SocialLoginType type;

  /// 버튼 클릭 시 호출되는 콜백 (null이거나 [isLoading]이 true이면 비활성화)
  final VoidCallback? onPressed;

  /// 로딩 상태 여부
  final bool isLoading;

  /// 버튼에 표시할 커스텀 텍스트 (생략 시 기본 "카카오 로그인" 또는 "Google로 로그인")
  final String? text;

  /// 버튼 높이 (기본값: 50.0)
  final double height;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
    this.text,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    final isKakao = type == SocialLoginType.kakao;

    // 카카오 / 구글 플랫폼별 색상 및 기본 텍스트 지정
    final backgroundColor = isKakao ? const Color(0xFFFEE500) : Colors.white;
    final textColor = isKakao ? const Color(0xFF191919) : const Color(0xFF1F1F1F);
    final buttonText = text ?? (isKakao ? '카카오 로그인' : 'Google로 로그인');
    final borderColor = isKakao ? null : AppColors.border;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
        boxShadow: onPressed != null && !isLoading
            ? [
                BoxShadow(
                  color: isKakao
                      ? const Color(0xFFFEE500).withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 공식 브랜드 로고 벡터 렌더링
                      _buildLogo(),
                      const SizedBox(width: 10),
                      // 버튼 라벨
                      Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// 브랜드별 공식 로고 위젯 생성
  Widget _buildLogo() {
    switch (type) {
      case SocialLoginType.kakao:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CustomPaint(
            painter: KakaoLogoPainter(),
          ),
        );
      case SocialLoginType.google:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CustomPaint(
            painter: GoogleLogoPainter(),
          ),
        );
    }
  }
}

/// 카카오 공식 말풍선 심볼 벡터 페인터
class KakaoLogoPainter extends CustomPainter {
  final Color color;
  const KakaoLogoPainter({this.color = const Color(0xFF191919)});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 카카오 심볼 말풍선 패스
    final path = Path()
      ..moveTo(12.0, 3.5)
      ..cubicTo(6.48, 3.5, 2.0, 7.08, 2.0, 11.5)
      ..cubicTo(2.0, 14.37, 3.9, 16.88, 6.77, 18.23)
      ..lineTo(5.56, 22.68)
      ..cubicTo(5.45, 23.07, 5.9, 23.38, 6.23, 23.15)
      ..lineTo(11.5, 19.64)
      ..cubicTo(11.67, 19.65, 11.83, 19.66, 12.0, 19.66)
      ..cubicTo(17.52, 19.66, 22.0, 16.08, 22.0, 11.5)
      ..cubicTo(22.0, 7.08, 17.52, 3.5, 12.0, 3.5)
      ..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 구글 4색 'G' 로고 벡터 페인터
class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 파랑 (#4285F4)
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.49, 12.28)
      ..cubicTo(23.49, 11.43, 23.42, 10.61, 23.28, 9.83)
      ..lineTo(12.0, 9.83)
      ..lineTo(12.0, 14.46)
      ..lineTo(18.44, 14.46)
      ..cubicTo(18.16, 15.94, 17.33, 17.19, 16.07, 18.04)
      ..lineTo(16.07, 21.01)
      ..lineTo(19.91, 21.01)
      ..cubicTo(22.16, 18.94, 23.49, 15.89, 23.49, 12.28)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 녹색 (#34A853)
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.95, 22.92, 19.91, 21.09)
      ..lineTo(16.07, 18.12)
      ..cubicTo(15.0, 18.84, 13.63, 19.27, 12.0, 19.27)
      ..cubicTo(8.85, 19.27, 6.18, 17.14, 5.23, 14.27)
      ..lineTo(1.25, 14.27)
      ..lineTo(1.25, 17.34)
      ..cubicTo(3.24, 21.29, 7.34, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 노랑 (#FBBC05)
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.23, 14.27)
      ..cubicTo(4.99, 13.55, 4.85, 12.78, 4.85, 12.0)
      ..cubicTo(4.85, 11.22, 4.99, 10.45, 5.23, 9.73)
      ..lineTo(5.23, 6.66)
      ..lineTo(1.25, 6.66)
      ..cubicTo(0.45, 8.24, 0.0, 10.06, 0.0, 12.0)
      ..cubicTo(0.0, 13.94, 0.45, 15.76, 1.25, 17.34)
      ..lineTo(5.23, 14.27)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 빨강 (#EA4335)
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0, 4.73)
      ..cubicTo(13.77, 4.73, 15.35, 5.34, 16.6, 6.53)
      ..lineTo(20.02, 3.11)
      ..cubicTo(17.95, 1.19, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.34, 0.0, 3.24, 2.71, 1.25, 6.66)
      ..lineTo(5.23, 9.73)
      ..cubicTo(6.18, 6.86, 8.85, 4.73, 12.0, 4.73)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

