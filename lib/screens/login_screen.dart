import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/character_provider.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/pipi_logo.dart';
import '../widgets/social_login_button.dart';
import '../widgets/social_oauth_dialog.dart';
import 'character_selection_screen.dart';
import 'home_screen.dart';
import 'intro_story_screen.dart';
import 'signup_screen.dart';

/// 로그인 화면
/// 
/// 명세서 4-1. 로그인 / 회원가입:
/// - 아이디, 비밀번호 입력으로 로그인
/// - 비밀번호 SHA-256 일치 검증
/// - 로그인 상태 유지 세션 생성
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  /// 현재 진행 중인 소셜 로그인 종류 (로딩 스피너 제어용)
  SocialLoginType? _socialLoadingType;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 로그인 또는 소셜 로그인 성공 후 공통 라우팅 처리
  Future<void> _navigateAfterAuth(AuthProvider authProvider) async {
    final user = authProvider.currentUser;
    if (user != null) {
      final characterProvider = context.read<CharacterProvider>();
      await characterProvider.loadCharacter(user.id);
      if (!mounted) return;

      if (characterProvider.hasCharacter) {
        // 이미 캐릭터가 선택되어 고정된 상태 -> 메인 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // 캐릭터 미선택 상태: 최초 1회 인트로 미시청 시 인트로로, 시청 완료 시 캐릭터 선택으로 이동
        final seenIntro = await IntroStoryScreen.hasSeenIntro(user.id);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => seenIntro
                ? const CharacterSelectionScreen()
                : IntroStoryScreen(userId: user.id),
          ),
        );
      }
    }
  }

  /// 일반 아이디/비밀번호 로그인 버튼 탭 처리 함수
  Future<void> _handleLogin() async {
    // 키보드 내리기
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      id: _idController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      await _navigateAfterAuth(authProvider);
    } else {
      // 실패 시 에러 메시지 스낵바 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? '로그인에 실패했습니다.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 카카오 / 구글 연동 로그인 탭 처리 함수
  Future<void> _handleSocialLogin(SocialLoginType type) async {
    // 키보드 내리기
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final provider = type == SocialLoginType.kakao
        ? SocialProvider.kakao
        : SocialProvider.google;

    final remembered = await authProvider.getRememberedSocialAccounts(provider);
    if (!mounted) return;

    final selectedAccount = await showSocialOAuthDialog(
      context: context,
      type: type,
      rememberedAccounts: remembered,
    );
    if (!mounted || selectedAccount == null || selectedAccount.trim().isEmpty) {
      return;
    }

    setState(() {
      _socialLoadingType = type;
    });

    final success = await authProvider.loginWithSocial(
      provider,
      accountIdentifier: selectedAccount.trim(),
    );

    if (!mounted) return;

    setState(() {
      _socialLoadingType = null;
    });

    if (success) {
      await _navigateAfterAuth(authProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? '${provider.displayName} 로그인에 실패했습니다.',
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 상단 공식 로고 영역
                const PipiLogo(width: 200, showSubtitle: true),
                const SizedBox(height: 24),

                // 2. 입력 폼 카드 영역
                _buildLoginFormCard(authProvider),
                const SizedBox(height: 24),

                // 3. 하단 회원가입 이동 링크
                _buildSignUpPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 로그인 폼을 감싸는 카드 위젯 (둥근 모서리 16, 부드러운 그림자)
  Widget _buildLoginFormCard(AuthProvider authProvider) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(22.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '로그인',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.pointNavy,
              ),
            ),
            const SizedBox(height: 18),

            // 아이디 입력 필드
            CustomTextField(
              controller: _idController,
              label: '아이디',
              hintText: '아이디를 입력해주세요',
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '아이디를 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 비밀번호 입력 필드
            CustomTextField(
              controller: _passwordController,
              label: '비밀번호',
              hintText: '비밀번호를 입력해주세요',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요.';
                }
                return null;
              },
            ),

            // 에러 메시지 안내 영역 (제공된 에러가 있을 때)
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

            // 로그인 실행 버튼
            CustomButton(
              text: '로그인하기',
              isLoading: authProvider.isLoading && _socialLoadingType == null,
              onPressed: authProvider.isLoading || _socialLoadingType != null ? null : _handleLogin,
              icon: Icons.login_rounded,
            ),
            const SizedBox(height: 20),

            // 간편 로그인 구분선
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    '또는 SNS 간편 로그인',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
              ],
            ),
            const SizedBox(height: 16),

            // 1. 카카오 연동 로그인 버튼
            SocialLoginButton(
              type: SocialLoginType.kakao,
              isLoading: _socialLoadingType == SocialLoginType.kakao,
              onPressed: authProvider.isLoading || _socialLoadingType != null
                  ? null
                  : () => _handleSocialLogin(SocialLoginType.kakao),
            ),
            const SizedBox(height: 10),

            // 2. 구글 연동 로그인 버튼
            SocialLoginButton(
              type: SocialLoginType.google,
              isLoading: _socialLoadingType == SocialLoginType.google,
              onPressed: authProvider.isLoading || _socialLoadingType != null
                  ? null
                  : () => _handleSocialLogin(SocialLoginType.google),
            ),
          ],
        ),
      ),
    );
  }

  /// 회원가입 유도 링크 위젯
  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '아직 계정이 없으신가요?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            // 에러 상태 리셋 후 회원가입 화면으로 이동
            context.read<AuthProvider>().clearError();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '회원가입',
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
