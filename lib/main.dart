import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/character_provider.dart';
import 'providers/task_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/character_repository.dart';
import 'repositories/task_repository.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// PIPI 앱 진입점
Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 실제 휴대폰 알람 서비스 & 한국 시간대 초기화
  await NotificationService.instance.initialize();

  // 요청에 따라 기존 테스트용 가입 계정·인트로 기록을 1회 전체 초기화(탈퇴)
  const int resetGeneration = 1;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getInt('pipi_reset_gen') != resetGeneration) {
    await prefs.clear();
    await prefs.setInt('pipi_reset_gen', resetGeneration);
  }

  runApp(const PipiApp());
}

/// PIPI 애플리케이션 루트 위젯
/// 
/// Provider 상태 관리 설정 및 전역 테마, 초기 화면(스플래시)을 지정합니다.
class PipiApp extends StatelessWidget {
  const PipiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. 인증 데이터 처리 리포지토리 등록
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        // 2. 인증 상태 관리 Provider 등록
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (ctx) => AuthProvider(
            authRepository: ctx.read<AuthRepository>(),
          ),
          update: (_, authRepo, previousAuthProvider) =>
              previousAuthProvider ?? AuthProvider(authRepository: authRepo),
        ),
        // 3. 캐릭터 데이터 처리 리포지토리 등록 (명세서 4-2)
        Provider<CharacterRepository>(
          create: (_) => CharacterRepository(),
        ),
        // 4. 캐릭터 상태 관리 Provider 등록 (명세서 4-2)
        ChangeNotifierProxyProvider<CharacterRepository, CharacterProvider>(
          create: (ctx) => CharacterProvider(
            characterRepository: ctx.read<CharacterRepository>(),
          ),
          update: (_, charRepo, previousCharProvider) =>
              previousCharProvider ??
              CharacterProvider(characterRepository: charRepo),
        ),
        // 5. 일정(Task) 데이터 처리 리포지토리 등록 (명세서 4-3, 4-4)
        Provider<TaskRepository>(
          create: (_) => TaskRepository(),
        ),
        // 6. 일정(Task) 상태 관리 Provider 등록
        ChangeNotifierProxyProvider<TaskRepository, TaskProvider>(
          create: (ctx) => TaskProvider(
            repository: ctx.read<TaskRepository>(),
          ),
          update: (_, taskRepo, previousTaskProvider) =>
              previousTaskProvider ?? TaskProvider(repository: taskRepo),
        ),
      ],
      child: MaterialApp(
        title: 'PIPI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // 명세서 화면 흐름 1단계: 스플래시 화면(1.5초)으로 시작
        home: const SplashScreen(),
      ),
    );
  }
}
