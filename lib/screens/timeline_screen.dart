import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_ui_kit.dart';
import 'task_edit_screen.dart';
import 'task_proof_dialog.dart';

/// 픽셀 아트 디자인 시스템이 적용된 실천 타임라인 화면
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<TaskProvider>().loadTasks(userId);
      }
    });
  }

  Widget _getCategoryPixelIcon(Task task) {
    if (task.title.contains('산책') || task.title.contains('반려동물')) {
      return const PixelIcon(PixelIconType.paw, size: 18);
    }
    if (task.title.contains('물') || task.title.contains('수분')) {
      return const PixelIcon(PixelIconType.droplet, size: 18);
    }
    if (task.category == TaskCategory.exercise ||
        task.title.contains('스트레칭') ||
        task.title.contains('운동')) {
      return const PixelIcon(PixelIconType.dumbbell, size: 18);
    }
    if (task.category == TaskCategory.study || task.title.contains('공부')) {
      return const PixelIcon(PixelIconType.book, size: 18);
    }
    return const PixelIcon(PixelIconType.calendar, size: 18);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final allTasks = taskProvider.allHistoryTasks;
    final completedCount = taskProvider.totalCompletedCount;
    final totalCount = allTasks.length;
    final rate = taskProvider.achievementRate;

    return Scaffold(
      backgroundColor: PixelColors.bgSky,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── 1. 서울 야경 픽셀 헤더: [←] [📊 타임라인 보기] ──
            PixelSkyHeader(
              title: '타임라인 보기',
              customLeading: const PixelIcon(
                PixelIconType.timeline,
                size: 22,
              ),
              showPawDecorations: false,
              onBack: () => Navigator.pop(context),
            ),

            // ── 2. 스크롤 콘텐츠 (요약 대시보드 + 연대기 리스트) ──
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 상단 실천 요약 픽셀 카드
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: PixelBox(
                        step: 6.0,
                        shadowOffset: 4.0,
                        borderWidth: 2.4,
                        lipHeight: 3.5,
                        backgroundColor: const Color(0xFFF3F8FF),
                        lipColor: const Color(0xFFD0E3FC),
                        borderColor: PixelColors.borderDark,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            // 카드 타이틀 바
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    PixelIcon(PixelIconType.paw, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      '나의 실천 기록',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w900,
                                        color: PixelColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                PixelBox(
                                  step: 3.0,
                                  shadowOffset: 0.0,
                                  enableBevel: false,
                                  backgroundColor: const Color(0xFFD5E7FC),
                                  borderColor: PixelColors.border,
                                  borderWidth: 1.6,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  child: Text(
                                    '달성률 ${rate.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.primaryBlueDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 3단 요약 스탯 픽셀 박스
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryStatBox(
                                    title: '총 달성 목표',
                                    value: '$completedCount개',
                                    icon: const PixelIcon(
                                      PixelIconType.checkCircle,
                                      size: 22,
                                    ),
                                    accentBg: const Color(0xFFE7F6EE),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSummaryStatBox(
                                    title: '전체 일정',
                                    value: '$totalCount개',
                                    icon: const PixelIcon(
                                      PixelIconType.calendar,
                                      size: 22,
                                    ),
                                    accentBg: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSummaryStatBox(
                                    title: '목표 달성률',
                                    value: '${rate.toStringAsFixed(0)}%',
                                    icon: const PixelIcon(
                                      PixelIconType.heart,
                                      size: 22,
                                    ),
                                    accentBg: const Color(0xFFFFEFF3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 픽셀 달성률 게이지 바
                            Container(
                              width: double.infinity,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: PixelColors.borderDark,
                                  width: 2.0,
                                ),
                              ),
                              child: LinearProgressIndicator(
                                value: (rate / 100).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFFE8F1FC),
                                valueColor: const AlwaysStoppedAnimation(
                                  PixelColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 빈 상태 vs 타임라인 목록
                  if (allTasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        child: Center(
                          child: PixelCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PixelIcon(
                                  PixelIconType.timeline,
                                  size: 46,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  '아직 등록된 실천 기록이 없습니다.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: PixelColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '일정을 생성하고 인증하여 기록을 남겨보세요!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: PixelColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                PixelButton(
                                  width: 190,
                                  height: 46,
                                  text: '일정 추가하기',
                                  pixelIcon: const PixelIcon(
                                    PixelIconType.calendarPlus,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const TaskEditScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = allTasks[index];
                            return _buildTimelineItem(
                              task,
                              isLast: index == allTasks.length - 1,
                            );
                          },
                          childCount: allTasks.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatBox({
    required String title,
    required String value,
    required Widget icon,
    required Color accentBg,
  }) {
    return PixelBox(
      step: 4.0,
      shadowOffset: 2.5,
      borderWidth: 2.0,
      lipHeight: 2.5,
      backgroundColor: accentBg,
      lipColor: const Color(0xFFCDE2FA),
      borderColor: PixelColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: PixelColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: PixelColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Task task, {required bool isLast}) {
    final isCompleted = task.status == TaskStatus.completed;
    final isExpired = task.isExpired;

    final Color nodeColor = isCompleted
        ? const Color(0xFF42B874)
        : (isExpired ? const Color(0xFFE55353) : PixelColors.primaryBlueLight);
    final Color nodeLip = isCompleted
        ? const Color(0xFF2B8C54)
        : (isExpired ? const Color(0xFFB53636) : PixelColors.primaryBlue);

    final String statusLabel =
        isCompleted ? '성공' : (isExpired ? '실패' : '진행 중');
    final Color statusBg = isCompleted
        ? const Color(0xFFE2F7EA)
        : (isExpired ? const Color(0xFFFDE8E8) : const Color(0xFFE5F0FE));
    final Color statusTextColor = isCompleted
        ? const Color(0xFF23864E)
        : (isExpired ? const Color(0xFFC93B3B) : PixelColors.primaryBlueDark);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 좌측 픽셀 타임라인 노드 + 픽셀 점선 연결선
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 8),
                PixelBox(
                  width: 28,
                  height: 28,
                  step: 2.5,
                  shadowOffset: 2.0,
                  borderWidth: 2.0,
                  lipHeight: 2.0,
                  backgroundColor: nodeColor,
                  lipColor: nodeLip,
                  borderColor: PixelColors.borderDark,
                  child: Center(
                    child: PixelIcon(
                      isCompleted
                          ? PixelIconType.check
                          : (isExpired
                              ? PixelIconType.close
                              : PixelIconType.clock),
                      size: 14,
                      primaryColor: Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: SizedBox(
                      width: 6,
                      child: CustomPaint(
                        painter: _PixelDottedLinePainter(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 우측 픽셀 일정 카드 (진행 중일 경우 탭하면 인증 업로드 가능 + 눌림 효과)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PixelBox(
                step: 5.0,
                shadowOffset: 3.5,
                borderWidth: 2.2,
                lipHeight: 3.0,
                backgroundColor: Colors.white,
                lipColor: isCompleted
                    ? const Color(0xFFCDEFD9)
                    : const Color(0xFFD2E4FA),
                borderColor: isCompleted
                    ? const Color(0xFF42B874)
                    : PixelColors.borderDark,
                padding: const EdgeInsets.all(14),
                onTap: !isCompleted && !isExpired
                    ? () {
                        showDialog(
                          context: context,
                          builder: (_) => TaskProofDialog(task: task),
                        );
                      }
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 카테고리 & 상태 픽셀 뱃지 Row
                          Row(
                            children: [
                              PixelBox(
                                step: 2.5,
                                shadowOffset: 0.0,
                                enableBevel: false,
                                backgroundColor:
                                    task.category.color.withValues(alpha: 0.14),
                                borderColor:
                                    task.category.color.withValues(alpha: 0.7),
                                borderWidth: 1.5,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                child: Text(
                                  task.category.koreanName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: task.category.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              PixelBox(
                                step: 2.5,
                                shadowOffset: 0.0,
                                enableBevel: false,
                                backgroundColor: statusBg,
                                borderColor:
                                    statusTextColor.withValues(alpha: 0.5),
                                borderWidth: 1.5,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: statusTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 아이콘 + 제목
                          Row(
                            children: [
                              _getCategoryPixelIcon(task),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    color: PixelColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          if (task.goal.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.goal,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: PixelColors.textMuted,
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // 시각/소요시간 픽셀 태그
                          Row(
                            children: [
                              const PixelIcon(PixelIconType.clock, size: 13),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  isCompleted && task.completedAt != null
                                      ? '완료: ${task.completedAt!.year}.${task.completedAt!.month}.${task.completedAt!.day} ${task.completedAt!.hour.toString().padLeft(2, '0')}:${task.completedAt!.minute.toString().padLeft(2, '0')}'
                                      : '소요 시간: ${task.durationString}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: PixelColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 인증 사진 썸네일 픽셀 카드 (인증완료 시) 또는 인증하기 유도 뱃지
                    if (isCompleted && task.proofImagePath != null)
                      PixelBox(
                        width: 62,
                        height: 62,
                        step: 3.5,
                        shadowOffset: 2.0,
                        borderWidth: 2.0,
                        lipHeight: 2.0,
                        backgroundColor: const Color(0xFFEBF4FE),
                        lipColor: const Color(0xFFC4DDFB),
                        borderColor: PixelColors.borderDark,
                        margin: const EdgeInsets.only(left: 10),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PixelIcon(PixelIconType.camera, size: 24),
                            SizedBox(height: 3),
                            Text(
                              '인증완료',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: PixelColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!isCompleted && !isExpired)
                      PixelBox(
                        step: 3.0,
                        shadowOffset: 2.0,
                        borderWidth: 1.8,
                        lipHeight: 2.0,
                        backgroundColor: PixelColors.primaryBlue,
                        lipColor: PixelColors.primaryBlueDark,
                        borderColor: PixelColors.borderDark,
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PixelIcon(PixelIconType.camera, size: 18),
                            SizedBox(height: 2),
                            Text(
                              '인증하기',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 타임라인 세로 픽셀 점선 페인터
class _PixelDottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PixelColors.borderLight
      ..style = PaintingStyle.fill;
    const dotSize = 4.0;
    const gap = 5.0;
    final x = (size.width - dotSize) / 2;
    for (double y = 4; y < size.height - 2; y += dotSize + gap) {
      canvas.drawRect(Rect.fromLTWH(x, y, dotSize, dotSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
