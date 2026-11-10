import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

/// 4-1 단계 완료 확인 및 다음 단계(4-2 캐릭터 선택) 진입을 위한 플레이스홀더 화면
/// 
/// 4-1 요구사항 검증 기능:
/// - 로그인된 사용자 ID 표시
/// - SHA-256 비밀번호 해시 암호화 적용 상태 안내
/// - 사용자 ID 기준 분리 저장(격리) 키 안내
/// - 로그아웃 기능 동작 확인
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final userId = user?.id ?? '사용자';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PIPI 홈 (4-1 완료)'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout_rounded, color: AppColors.pointNavy),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 환영 및 로그인 성공 카드
              _buildWelcomeCard(userId),
              const SizedBox(height: 16),

              // 2. 4-1 명세서 요구사항 달성 점검 카드
              _buildSpecCheckCard(userId),
              const SizedBox(height: 16),

              // 3. 다음 개발 단계(4-2) 안내 카드
              _buildNextStepCard(),
              const SizedBox(height: 24),

              // 4. 로그아웃 버튼 (명세서: 로그아웃 기능)
              CustomButton(
                text: '로그아웃',
                backgroundColor: Colors.white,
                textColor: AppColors.error,
                icon: Icons.logout_rounded,
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 환영 배너 카드
  Widget _buildWelcomeCard(String userId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.pointNavy.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_transparent.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '반가워요, $userId 님!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pointNavy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '로그인 및 세션 상태가 성공적으로 유지되고 있습니다.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.pointNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4-1 명세서 달성 내역 점검 카드
  Widget _buildSpecCheckCard(String userId) {
    final sampleStorageKey = AuthRepository.getUserStorageKey(userId, 'character');

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.pointMint, size: 22),
              SizedBox(width: 8),
              Text(
                '4-1 기능 명세 충족 현황',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pointNavy,
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.border),
          _buildCheckItem(
            title: '회원가입 & 로그인',
            desc: '아이디/비밀번호 검증 및 성공 시 세션 등록',
            isComplete: true,
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            title: '로그인 상태 유지 (자동 로그인)',
            desc: '앱 재실행 시 스플래시(1.5초)에서 세션을 읽어 자동 진입',
            isComplete: true,
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            title: '비밀번호 평문 저장 금지',
            desc: 'crypto 라이브러리의 SHA-256 해시로 안전하게 저장',
            isComplete: true,
          ),
          const SizedBox(height: 12),
          _buildCheckItem(
            title: '사용자 ID 기준 분리 저장',
            desc: '모든 데이터가 ID 기반 격리 키로 보관됨 (예: $sampleStorageKey)',
            isComplete: true,
          ),
        ],
      ),
    );
  }

  /// 점검 항목 한 줄
  Widget _buildCheckItem({
    required String title,
    required String desc,
    required bool isComplete,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isComplete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: isComplete ? AppColors.pointNavy : AppColors.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pointNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 다음 개발 단계 안내 카드
  Widget _buildNextStepCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pointMint.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pointMint, width: 1.2),
      ),
      padding: const EdgeInsets.all(18.0),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_forward_rounded, color: AppColors.pointNavy, size: 20),
              SizedBox(width: 8),
              Text(
                '다음 단계: 4-2. 캐릭터 선택',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pointNavy,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '고양이, 강아지, 카피바라, 오리, 우파루파, 드래곤 6종 동물 중 하나를 선택하고 이름을 지정하는 단계입니다.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 로그아웃 확인 다이얼로그 표시
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '로그아웃',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.pointNavy,
          ),
        ),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
