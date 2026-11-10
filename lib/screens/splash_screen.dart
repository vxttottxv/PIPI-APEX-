import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/character_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/pipi_logo.dart';
import 'character_selection_screen.dart';
import 'home_screen.dart';
import 'intro_story_screen.dart';
import 'login_screen.dart';

/// 앱 최초 구동 시 표시되는 스플래시 화면
/// 
/// 명세서 화면 흐름:
/// 1. 앱 실행 → 로고 스플래시 (1.5초)
/// 2. 로그인 상태 확인 (자동 로그인):
///    - 로그인 세션 존재: 홈 화면으로 이동
///    - 미로그인: 로그인/회원가입 화면으로 이동
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 부드러운 스케일 & 페이드인 애니메이션
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();

    // 첫 프레임 렌더링 완료 후 세션 확인 및 1.5초 대기 진행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initAppAndNavigate();
      }
    });
  }

  Future<void> _initAppAndNavigate() async {
    final startTime = DateTime.now();

    // 자동 로그인 세션 확인
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = await authProvider.checkAutoLogin();

    // 최소 1.5초(1500ms) 동안 스플래시 화면 노출 보장 (명세서 규칙)
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    const minSplashDuration = 1500;
    if (elapsed < minSplashDuration) {
      await Future.delayed(
        Duration(milliseconds: minSplashDuration - elapsed),
      );
    }

    if (!mounted) return;

    // 로그인 여부에 따른 화면 전환
    if (isLoggedIn) {
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
          return;
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
          return;
        }
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PipiLogo(width: 230, showSubtitle: true),
                SizedBox(height: 28),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.pointNavy),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
