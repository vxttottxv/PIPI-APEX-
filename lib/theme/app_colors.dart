import 'package:flutter/material.dart';

/// PIPI 앱 전체에서 일관되게 사용하는 색상 팔레트 정의 클래스
/// 
/// 명세서 기준 색상:
/// - Primary: #A9C9F5 (부드러운 하늘색)
/// - Background: #F3F7FD (밝은 파스텔 배경색)
/// - Point (Navy): #344B70 (차분한 네이비 포인트)
/// - Point (Mint): #B9DFC9 (화사한 민트 포인트)
class AppColors {
  // 인스턴스 생성을 방지하기 위한 private 생성자
  AppColors._();

  // === 명세서 지정 핵심 색상 ===
  /// 메인 브랜드 컬러 (하늘색)
  static const Color primary = Color(0xFFA9C9F5);

  /// 기본 배경색 (부드러운 연한 블루/그레이)
  static const Color background = Color(0xFFF3F7FD);

  /// 주요 텍스트 및 강조 포인트 컬러 (네이비)
  static const Color pointNavy = Color(0xFF344B70);

  /// 보조 포인트 및 배지 등에 사용하는 컬러 (민트)
  static const Color pointMint = Color(0xFFB9DFC9);

  // === 확장 UI 색상 ===
  /// 카드 및 모달 배경 흰색
  static const Color surface = Colors.white;

  /// 본문 기본 텍스트 (짙은 네이비 그레이)
  static const Color textPrimary = Color(0xFF24344D);

  /// 부가 설명 및 힌트 텍스트 (연한 그레이)
  static const Color textSecondary = Color(0xFF7E8EA6);

  /// 입력창 테두리 기본 색상
  static const Color border = Color(0xFFD8E2F0);

  /// 입력창 포커스 테두리 색상
  static const Color borderFocused = Color(0xFF7FA8DE);

  /// 에러 및 경고 텍스트/테두리 색상
  static const Color error = Color(0xFFE56A6A);

  /// 성공 안내 색상
  static const Color success = Color(0xFF48B685);

  /// 비활성화 버튼/요소 색상
  static const Color disabled = Color(0xFFCCD6E4);
}
