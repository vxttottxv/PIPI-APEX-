import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/pipi_logo.dart';
import 'character_selection_screen.dart';
import 'intro_story_screen.dart';

/// 회원가입 화면
/// 
/// 명세서 4-1. 로그인 / 회원가입:
/// - 아이디, 비밀번호 입력 및 비밀번호 확인
/// - 평문 비밀번호가 아닌 SHA-256 해시로 안전하게 저장
/// - 회원가입 성공 시 사용자별 격리 저장 공간 생성 및 자동 로그인
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 회원가입 실행 처리 함수
  Future<void> _handleSignUp() async {
    // 키보드 내리기
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      id: _idController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final userId = authProvider.currentUser?.id ?? _idController.text.trim();
      final seenIntro = await IntroStoryScreen.hasSeenIntro(userId);
      if (!mounted) return;

      // 최초 회원가입 시 1회성 인트로 스토리 연출 후 캐릭터 선택 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => seenIntro
              ? const CharacterSelectionScreen()
              : IntroStoryScreen(userId: userId),
        ),
        (route) => false,
      );
    } else {
      // 실패 시 에러 안내
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? '회원가입에 실패했습니다.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.read<AuthProvider>().clearError();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 소형 공식 로고 심볼
                const PipiLogo(width: 150, showSubtitle: false),
                const SizedBox(height: 18),

                // 2. 회원가입 카드 폼
                _buildSignUpFormCard(authProvider),
                const SizedBox(height: 20),

                // 3. 기존 로그인 화면 복귀 링크
                _buildBackToLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 회원가입 입력 필드를 감싸는 카드 위젯
  Widget _buildSignUpFormCard(AuthProvider authProvider) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(22.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '새 계정 만들기',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.pointNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '아이디와 비밀번호로 간편하게 시작하세요.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // 아이디 입력 필드
            CustomTextField(
              controller: _idController,
              label: '아이디',
              hintText: '영문/숫자 3자 이상',
              prefixIcon: Icons.badge_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '아이디를 입력해주세요.';
                }
                if (value.trim().length < 3) {
                  return '아이디는 최소 3자 이상이어야 합니다.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // 비밀번호 입력 필드
            CustomTextField(
              controller: _passwordController,
              label: '비밀번호',
              hintText: '4자 이상의 비밀번호',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요.';
                }
                if (value.length < 4) {
                  return '비밀번호는 최소 4자 이상이어야 합니다.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // 비밀번호 확인 입력 필드
            CustomTextField(
              controller: _confirmPasswordController,
              label: '비밀번호 확인',
              hintText: '비밀번호를 한 번 더 입력해주세요',
              prefixIcon: Icons.lock_reset_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignUp(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호 확인을 입력해주세요.';
                }
                if (value != _passwordController.text) {
                  return '비밀번호가 일치하지 않습니다.';
                }
                return null;
              },
            ),

            // 에러 메시지 표시
            if (authProvider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      authProvider.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 22),

            // 회원가입 버튼
            CustomButton(
              text: '가입 완료하고 시작하기',
              isLoading: authProvider.isLoading,
              onPressed: _handleSignUp,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  /// 로그인 화면으로 돌아가기 링크 위젯
  Widget _buildBackToLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '이미 계정이 있으신가요?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            context.read<AuthProvider>().clearError();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '로그인하기',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.pointNavy,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
