import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/character_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_ui_kit.dart';

/// 레퍼런스 1 디자인: 픽셀 인증 업로드 화면
class TaskProofDialog extends StatefulWidget {
  final Task task;

  const TaskProofDialog({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskProofDialog(task: task)),
    );
  }

  @override
  State<TaskProofDialog> createState() => _TaskProofDialogState();
}

class _TaskProofDialogState extends State<TaskProofDialog> {
  bool _isCaptured = false;
  String? _capturedImageMock;
  bool _isSubmitting = false;

  void _takePhoto() {
    setState(() {
      _isCaptured = true;
      _capturedImageMock =
          'proof_${widget.task.id}_${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  Future<void> _submitProof() async {
    if (!_isCaptured || _capturedImageMock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('완료 인증 사진을 먼저 첨부해주세요!')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final characterProvider = context.read<CharacterProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    setState(() => _isSubmitting = true);

    final success = await taskProvider.completeTask(
      userId: userId,
      taskId: widget.task.id,
      proofImagePath: _capturedImageMock!,
    );

    if (!mounted) return;

    if (success) {
      final exp = widget.task.expReward;
      final coins = widget.task.coinReward;
      final snacks = widget.task.snackReward;

      final leveledUp = await characterProvider.addRewards(
        userId: userId,
        exp: exp,
        coins: coins,
        snacks: snacks,
      );

      if (!mounted) return;

      Navigator.pop(context); // 인증 화면 닫기

      // 성공 및 보상 획득 다이얼로그
      _showSuccessRewardDialog(
        context,
        exp: exp,
        coins: coins,
        snacks: snacks,
        leveledUp: leveledUp,
      );
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 제출에 실패했습니다.')),
      );
    }
  }

  void _showSuccessRewardDialog(
    BuildContext context, {
    required int exp,
    required int coins,
    required int snacks,
    required bool leveledUp,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF5FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded,
                  size: 44, color: PixelColors.primaryBlue),
            ),
            const SizedBox(height: 14),
            Text(
              leveledUp ? '🎉 LEVEL UP & 목표 달성! 🎉' : '🎯 목표 실천 완료!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PixelColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '약속을 멋지게 지켜냈어요! 파트너가 쑥쑥 성장합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: PixelColors.textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRewardPill(
                      'EXP', '+$exp', Icons.auto_awesome, Colors.amber),
                  _buildRewardPill(
                      '코인', '+$coins', Icons.monetization_on, Colors.orange),
                  _buildRewardPill(
                      '간식', '+$snacks', Icons.cookie_rounded, Colors.brown),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PixelColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                '보상 받기 🎁',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardPill(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      backgroundColor: PixelColors.bgSky,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── 1. 상단 스카이 시티 헤더 & 픽셀 배너: "🐾 인증 업로드 🐾" ──
            PixelSkyHeader(
              title: '인증 업로드',
              onBack: () => Navigator.pop(context),
            ),

            // ── 2. 메인 콘텐츠 ──
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // 오늘의 일정 알약 픽셀 카드
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PixelBox(
                          width: double.infinity,
                          step: 5.0,
                          shadowOffset: 3.0,
                          lipHeight: 2.5,
                          backgroundColor: Colors.white,
                          lipColor: const Color(0xFFD6E7FB),
                          borderColor: PixelColors.borderLight,
                          borderWidth: 2.2,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const PixelIcon(PixelIconType.calendar, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                '오늘의 일정',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: PixelColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1.5,
                                height: 18,
                                color: PixelColors.borderLight,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: PixelBox(
                                  step: 3.5,
                                  shadowOffset: 0.0,
                                  enableBevel: false,
                                  backgroundColor: const Color(0xFFEFF6FE),
                                  borderColor: PixelColors.border,
                                  borderWidth: 1.8,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const PixelIcon(
                                        PixelIconType.paw,
                                        size: 16,
                                        primaryColor: PixelColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${task.title} 완료',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w900,
                                            color: PixelColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 시안처럼 일정 알약 우상단 노란 반짝이
                        Positioned(
                          right: 6,
                          top: -8,
                          child: Transform.rotate(
                            angle: 0.4,
                            child: const PixelSparkle(
                              color: PixelColors.cookieGold,
                              pixelSize: 2.3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 점선 사진 업로드 영역
                    PixelDashedCard(
                      onTap: _takePhoto,
                      child: Center(
                        child: _isCaptured
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const PixelIcon(
                                    PixelIconType.checkCircle,
                                    size: 56,
                                    primaryColor: PixelColors.borderDark,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '인증 사진 첨부 완료!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day} 실시간 인증 기록됨',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: PixelColors.textMuted),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 큰 픽셀 카메라 아이콘 + 우상단 노란 반짝이
                                  Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      const PixelIcon(
                                        PixelIconType.camera,
                                        size: 62,
                                      ),
                                      Positioned(
                                        top: -10,
                                        right: -18,
                                        child: Transform.rotate(
                                          angle: 0.45,
                                          child: const PixelSparkle(
                                            color: PixelColors.cookieGold,
                                            pixelSize: 2.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    '완료 인증 사진을\n업로드 해주세요',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.textDark,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 사진 찍기 & 갤러리 선택 픽셀 버튼 Row (눌림 효과 포함)
                    Row(
                      children: [
                        Expanded(
                          child: PixelBox(
                            height: 48,
                            step: 4.0,
                            shadowOffset: 3.0,
                            lipHeight: 3.0,
                            backgroundColor: const Color(0xFFD7E9FE),
                            highlightColor: Colors.white,
                            lipColor: const Color(0xFFABCBF7),
                            borderColor: PixelColors.borderDark,
                            borderWidth: 2.2,
                            onTap: _takePhoto,
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PixelIcon(PixelIconType.camera, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '사진 찍기',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PixelBox(
                            height: 48,
                            step: 4.0,
                            shadowOffset: 3.0,
                            lipHeight: 3.0,
                            backgroundColor: const Color(0xFFD7E9FE),
                            highlightColor: Colors.white,
                            lipColor: const Color(0xFFABCBF7),
                            borderColor: PixelColors.borderDark,
                            borderWidth: 2.2,
                            onTap: _takePhoto,
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PixelIcon(PixelIconType.gallery, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '갤러리 선택',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 안내 문구 바: (i) 일정을 완료한 사진을 첨부하면 인증이 완료돼요!
                    const PixelInfoBar(
                      text: '일정을 완료한 사진을 첨부하면 인증이 완료돼요!',
                    ),

                    const SizedBox(height: 24),

                    // 하단 버튼 Row: [ 나중에 ] & [ ✔️ 인증 완료 ]
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: PixelButton(
                            text: '나중에',
                            isWhite: true,
                            withSparkle: false,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: PixelButton(
                            text: '인증 완료',
                            pixelIcon: const PixelIcon(
                              PixelIconType.checkCircle,
                              size: 22,
                            ),
                            onPressed: _isSubmitting ? null : _submitProof,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
