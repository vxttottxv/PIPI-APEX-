import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_colors.dart';
import 'task_edit_screen.dart';
import 'task_proof_dialog.dart';

/// 4-4. 소요 시간 기반 시간표 배치 화면 (PIPI 핵심 기능)
///
/// 명세서 4-4 요구사항:
/// - 06:00 ~ 24:00 세로 시간축, 30분 단위 칸, 세로 스크롤
/// - 소요 시간에 비례한 블록 크기
/// - 블록 보관함에서 드래그 앤 드롭으로 스티커 붙이듯 시간표에 배치
/// - 30분 단위 자동 정렬
/// - 겹침 발생 시 빨간 테두리 및 경고 메시지
/// - 12시간 가용 시간 초과 경고
/// - 카테고리별 색상 구분 및 날짜별 시간표 조회
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _slotHeight = 52.0; // 30분 1슬롯 기본 높이
  static const int _startHour = 6; // 06:00
  static const int _endHour = 24; // 24:00
  static const int _totalSlots = (_endHour - _startHour) * 2; // 36개 슬롯

  bool _isTrayExpanded = true;

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatSlotTime(int slotIndex) {
    final totalMinutes = (_startHour * 60) + (slotIndex * 30);
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int _slotIndexFromTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final totalMin = hour * 60 + minute;
    return ((totalMin - (_startHour * 60)) / 30).round().clamp(0, _totalSlots - 1);
  }

  void _changeDate(int days) {
    final provider = context.read<TaskProvider>();
    final newDate = provider.selectedDate.add(Duration(days: days));
    provider.setSelectedDate(newDate);
  }

  Future<void> _pickDate() async {
    final provider = context.read<TaskProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.pointNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.pointNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setSelectedDate(picked);
    }
  }

  Future<void> _handleDropOnSlot(Task task, int slotIndex) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final startTime = _formatSlotTime(slotIndex);
    final selectedDate = context.read<TaskProvider>().selectedDate;

    await context.read<TaskProvider>().placeTask(
          userId: userId,
          taskId: task.id,
          placedDate: selectedDate,
          startTime: startTime,
        );
  }

  void _showPlacedTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: task.category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(task.category.icon,
                          color: task.category.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pointNavy,
                            ),
                          ),
                          Text(
                            '${task.startTime} ~ ${task.endTime} (${task.durationString})',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                // 1. 완료 인증하기 (명세서 4-6)
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.pointNavy),
                  title: const Text('수행 완료 사진 인증하기'),
                  subtitle: const Text('목표를 달성하고 파트너 성장 보상을 받습니다'),
                  onTap: () {
                    Navigator.pop(ctx);
                    TaskProofDialog.show(context, task);
                  },
                ),
                // 2. 보관함으로 되돌리기 (명세서 4-4)
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined,
                      color: Colors.orange),
                  title: const Text('블록 보관함으로 되돌리기'),
                  subtitle: const Text('시간표 배치를 취소하고 보관함으로 이동합니다'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final userId = context.read<AuthProvider>().currentUser?.id;
                    if (userId != null) {
                      await context
                          .read<TaskProvider>()
                          .unplaceTask(userId: userId, taskId: task.id);
                    }
                  },
                ),
                // 3. 수정하기
                ListTile(
                  leading: const Icon(Icons.edit_outlined,
                      color: AppColors.pointNavy),
                  title: const Text('일정 수정하기'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskEditScreen(taskToEdit: task),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final selectedDate = taskProvider.selectedDate;
    final placedTasks = taskProvider.getPlacedTasksForDate(selectedDate);
    final storageTasks = taskProvider.storageTasks;
    final conflictingIds =
        taskProvider.getConflictingTaskIdsForDate(selectedDate);
    final isOverCapacity = taskProvider.isOverCapacity(selectedDate);
    final totalPlacedMin =
        taskProvider.getTotalPlacedMinutesForDate(selectedDate);

    final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayStr = weekdayNames[selectedDate.weekday - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('실천 시간표',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded, color: AppColors.pointNavy),
            tooltip: '오늘로 이동',
            onPressed: () => taskProvider.setSelectedDate(DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 1. 날짜 탐색 & 일일 가용시간 상태 바 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                      onPressed: () => _changeDate(-1),
                    ),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded,
                                size: 18, color: AppColors.pointNavy),
                            const SizedBox(width: 8),
                            Text(
                              '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일 ($weekdayStr)',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pointNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16),
                      onPressed: () => _changeDate(1),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 가용 시간 게이지 (명세서 4-4: 기본 12시간)
                Row(
                  children: [
                    const Text('배치 시간: ',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      '${totalPlacedMin ~/ 60}시간 ${totalPlacedMin % 60}분 / ${taskProvider.dailyCapacityHours}시간',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOverCapacity
                            ? AppColors.error
                            : AppColors.pointNavy,
                      ),
                    ),
                    const Spacer(),
                    if (isOverCapacity)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 14, color: AppColors.error),
                            SizedBox(width: 4),
                            Text(
                              '가용 시간 초과!',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── 겹침 경고 배너 (명세서 4-4) ──
          if (conflictingIds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFECEC),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ 겹치는 일정이 있습니다! 블록 위치를 조정해주세요.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── 2. 메인: 06:00 ~ 24:00 세로 스크롤 시간표 그리드 ──
          Expanded(
            child: Row(
              children: [
                // 좌측: 세로 시간 레이블 컬럼
                SizedBox(
                  width: 58,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _totalSlots,
                    itemBuilder: (context, index) {
                      final timeStr = _formatSlotTime(index);
                      final isHour = timeStr.endsWith(':00');

                      return Container(
                        height: _slotHeight,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, top: 4),
                        child: Text(
                          isHour ? timeStr : ':30',
                          style: TextStyle(
                            fontSize: isHour ? 12 : 10.5,
                            fontWeight:
                                isHour ? FontWeight.bold : FontWeight.normal,
                            color: isHour ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 우측: 드래그 타깃 그리드 & 배치된 블록 레이어
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      height: _totalSlots * _slotHeight,
                      child: Stack(
                        children: [
                          // 30분 슬롯 그리드 라인 & DragTarget 영역
                          Column(
                            children: List.generate(_totalSlots, (slotIndex) {
                              final isHour = slotIndex % 2 == 0;

                              return DragTarget<Task>(
                                onWillAcceptWithDetails: (details) => true,
                                onAcceptWithDetails: (details) {
                                  _handleDropOnSlot(details.data, slotIndex);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final isHovered = candidateData.isNotEmpty;

                                  return InkWell(
                                    onTap: () {
                                      // 빈 슬롯 클릭 시 보관함의 첫 번째 블록 배치 지원
                                      if (storageTasks.isNotEmpty) {
                                        _handleDropOnSlot(
                                            storageTasks.first, slotIndex);
                                      }
                                    },
                                    child: Container(
                                      height: _slotHeight,
                                      decoration: BoxDecoration(
                                        color: isHovered
                                            ? AppColors.primary
                                                .withValues(alpha: 0.25)
                                            : Colors.white,
                                        border: Border(
                                          top: BorderSide(
                                            color: isHour
                                                ? const Color(0xFFD6E4F8)
                                                : const Color(0xFFF1F5F9),
                                            width: isHour ? 1.0 : 0.8,
                                          ),
                                          bottom: BorderSide(
                                            color: const Color(0xFFF1F5F9),
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),

                          // 시간표 위에 배치된 블록들 (절대 좌표 배치)
                          ...placedTasks.map((task) {
                            if (task.startTime == null) {
                              return const SizedBox.shrink();
                            }
                            final slotIndex =
                                _slotIndexFromTime(task.startTime!);
                            final top = slotIndex * _slotHeight;
                            final height = task.slotCount * _slotHeight;
                            final isConflict =
                                conflictingIds.contains(task.id);
                            final isCompleted =
                                task.status == TaskStatus.completed;

                            return Positioned(
                              top: top + 2,
                              left: 4,
                              right: 8,
                              height: height - 4,
                              child: GestureDetector(
                                onTap: () => _showPlacedTaskOptions(task),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? const Color(0xFFE2E8F0)
                                        : task.category.color
                                            .withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isConflict
                                          ? Colors.red
                                          : (isCompleted
                                              ? Colors.grey
                                              : task.category.color),
                                      width: isConflict ? 2.5 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isCompleted
                                                ? Icons.check_circle_rounded
                                                : task.category.icon,
                                            size: 14,
                                            color: isCompleted
                                                ? Colors.green
                                                : Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              task.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: isCompleted
                                                    ? Colors.black87
                                                    : Colors.white,
                                                decoration: isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (isConflict)
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              size: 14,
                                              color: Colors.redAccent,
                                            ),
                                        ],
                                      ),
                                      if (height >= _slotHeight * 2) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${task.startTime} ~ ${task.endTime}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isCompleted
                                                ? Colors.black54
                                                : Colors.white70,
                                          ),
                                        ),
                                        if (task.goal.isNotEmpty)
                                          Text(
                                            task.goal,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isCompleted
                                                  ? Colors.black45
                                                  : Colors.white60,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 3. 하단: 블록 보관함 서랍 (명세서 4-4) ──
          _buildStorageTray(storageTasks),
        ],
      ),
    );
  }

  /// 하단 블록 보관함 트레이
  Widget _buildStorageTray(List<Task> storageTasks) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 서랍 토글 바
          InkWell(
            onTap: () => setState(() => _isTrayExpanded = !_isTrayExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      size: 18, color: AppColors.pointNavy),
                  const SizedBox(width: 8),
                  Text(
                    '블록 보관함 (${storageTasks.length}개)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pointNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '시간표로 드래그하여 배치해보세요',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                  const Spacer(),
                  Icon(
                    _isTrayExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.pointNavy,
                  ),
                ],
              ),
            ),
          ),

          // 보관함 아이템 목록
          if (_isTrayExpanded)
            Container(
              height: 110,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: storageTasks.isEmpty
                  ? Center(
                      child: Text(
                        '보관함이 비어있습니다. 우측 하단 [+] 버튼으로 일정을 추가하세요!',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: storageTasks.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final task = storageTasks[index];
                        // 명세서 4-4: 소요 시간에 비례한 블록 크기
                        final blockWidth = (80.0 + (task.slotCount - 1) * 35.0)
                            .clamp(80.0, 180.0);

                        return Draggable<Task>(
                          data: task,
                          feedback: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: blockWidth,
                              height: 80,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: task.category.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    task.durationString,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildStorageBlock(task, blockWidth),
                          ),
                          child: _buildStorageBlock(task, blockWidth),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageBlock(Task task, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: task.category.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: task.category.color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(task.category.icon, size: 14, color: task.category.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: task.category.color,
                  ),
                ),
              ),
            ],
          ),
          Text(
            task.durationString,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${task.slotCount * 30}분 블록',
              style: TextStyle(fontSize: 9.5, color: task.category.color),
            ),
          ),
        ],
      ),
    );
  }
}
