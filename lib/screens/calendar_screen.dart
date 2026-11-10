import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_ui_kit.dart';
import 'task_edit_screen.dart';
import 'task_proof_dialog.dart';

/// 레퍼런스 신규 디자인: 픽셀 캘린더 보기 화면
class CalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  const CalendarScreen({super.key, this.initialDate});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _currentMonth = DateTime(initial.year, initial.month, 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<TaskProvider>().loadTasks(userId);
      }
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _formatTimeKorean(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '시간 미정';
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final isPm = hour >= 12;
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = isPm ? '오후' : '오전';
    return '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Widget? _getMarkerForDate(DateTime date, List<Task> tasks) {
    final dayTasks = tasks.where((t) {
      if (t.placedDate != null) {
        final p = DateTime(t.placedDate!.year, t.placedDate!.month, t.placedDate!.day);
        if (p == date) return true;
      }
      final s = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
      final e = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);
      return !date.isBefore(s) && !date.isAfter(e);
    }).toList();

    if (dayTasks.isEmpty) return null;

    // 실제 등록된 일정의 카테고리 및 제목에 따른 픽셀 마커
    if (dayTasks.any((t) => t.title.contains('산책') || t.title.contains('반려동물'))) {
      return const PixelIcon(PixelIconType.paw, size: 13);
    }
    if (dayTasks.any((t) => t.category == TaskCategory.exercise || t.title.contains('스트레칭') || t.title.contains('운동'))) {
      return const PixelIcon(PixelIconType.dumbbell, size: 14);
    }
    if (dayTasks.any((t) => t.category == TaskCategory.study || t.title.contains('공부'))) {
      return const PixelIcon(PixelIconType.book, size: 14);
    }
    if (dayTasks.any((t) => t.title.contains('물') || t.title.contains('수분'))) {
      return const PixelIcon(PixelIconType.droplet, size: 13);
    }

    // 기본 일정 마커: 블루 픽셀 도트 (■)
    return Container(
      width: 6.0,
      height: 6.0,
      color: PixelColors.primaryBlue,
    );
  }

  Widget _getIconForTask(Task task) {
    if (task.title.contains('산책') || task.title.contains('반려동물')) {
      return const PixelIcon(PixelIconType.paw, size: 22);
    }
    if (task.title.contains('물') || task.title.contains('수분')) {
      return const PixelIcon(PixelIconType.droplet, size: 22);
    }
    if (task.category == TaskCategory.exercise || task.title.contains('스트레칭') || task.title.contains('운동')) {
      return const PixelIcon(PixelIconType.dumbbell, size: 22);
    }
    if (task.category == TaskCategory.study || task.title.contains('공부')) {
      return const PixelIcon(PixelIconType.book, size: 22);
    }
    return const PixelIcon(PixelIconType.checkCircle, size: 22);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final allTasks = taskProvider.tasks;
    final selectedDayTasks = taskProvider.getTasksForCalendarDate(_selectedDate);

    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekdayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7; // 0=일요일

    return Scaffold(
      backgroundColor: PixelColors.bgSky,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── 1. 스카이 시티 헤더: [←] 📅 캘린더 보기 ──
            PixelSkyHeader(
              title: '캘린더 보기',
              customLeading: const PixelIcon(
                PixelIconType.calendar,
                size: 24,
              ),
              showPawDecorations: false,
              onBack: () => Navigator.pop(context),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  children: [
                    // ── 2. 월 네비게이터: [ < ]  2026년 11월  [ > ] ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // [ < ] 이전 달
                        PixelBox(
                          width: 46,
                          height: 40,
                          step: 4.0,
                          shadowOffset: 3.0,
                          borderWidth: 2.2,
                          lipHeight: 3.0,
                          backgroundColor: PixelColors.whiteButtonBg,
                          lipColor: PixelColors.whiteButtonLip,
                          borderColor: PixelColors.borderDark,
                          onTap: _prevMonth,
                          child: const Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PixelIcon(PixelIconType.chevronLeft, size: 18),
                                Opacity(
                                  opacity: 0.0,
                                  child: Icon(Icons.chevron_left_rounded,
                                      size: 1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 중앙: [ 2026년 11월 ] 캡슐 바
                        PixelBox(
                          step: 4.5,
                          shadowOffset: 3.0,
                          borderWidth: 2.2,
                          lipHeight: 3.0,
                          backgroundColor: Colors.white,
                          lipColor: const Color(0xFFCDE2FA),
                          borderColor: PixelColors.borderDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 8),
                          child: Text(
                            '${_currentMonth.year}년 ${_currentMonth.month}월',
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: PixelColors.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),

                        // [ > ] 다음 달
                        PixelBox(
                          width: 46,
                          height: 40,
                          step: 4.0,
                          shadowOffset: 3.0,
                          borderWidth: 2.2,
                          lipHeight: 3.0,
                          backgroundColor: PixelColors.whiteButtonBg,
                          lipColor: PixelColors.whiteButtonLip,
                          borderColor: PixelColors.borderDark,
                          onTap: _nextMonth,
                          child: const Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PixelIcon(PixelIconType.chevronRight, size: 18),
                                Opacity(
                                  opacity: 0.0,
                                  child: Icon(Icons.chevron_right_rounded,
                                      size: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── 3. 메인 캘린더 그리드 카드 (레퍼런스 2 디자인) ──
                    PixelBox(
                      step: 6.0,
                      shadowOffset: 4.0,
                      backgroundColor: const Color(0xFFF0F6FF),
                      borderColor: PixelColors.borderDark,
                      borderWidth: 2.4,
                      child: Column(
                        children: [
                          // 요일 헤더 (일 ~ 토)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Color(0xFFABC8EA), width: 1.5),
                              ),
                            ),
                            child: const Row(
                              children: [
                                _WeekdayHeader(label: '일', color: Color(0xFFDE4A5B)),
                                _WeekdayHeader(label: '월', color: PixelColors.textDark),
                                _WeekdayHeader(label: '화', color: PixelColors.textDark),
                                _WeekdayHeader(label: '수', color: PixelColors.textDark),
                                _WeekdayHeader(label: '목', color: PixelColors.textDark),
                                _WeekdayHeader(label: '금', color: PixelColors.textDark),
                                _WeekdayHeader(label: '토', color: Color(0xFF3867D6)),
                              ],
                            ),
                          ),

                          // 날짜 그리드
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _buildDaysGrid(
                              daysInMonth: daysInMonth,
                              firstWeekday: firstWeekdayOfMonth,
                              allTasks: allTasks,
                            ),
                          ),

                          // 범례 (■: 일정이 있는 날 | 📖: 공부/집중 🏋️: 운동 💧: 건강관리)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE4F0FD),
                              border: Border(
                                top: BorderSide(
                                    color: Color(0xFFABC8EA), width: 1.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  color: PixelColors.primaryBlue,
                                ),
                                const Text(' : 일정이 있는 날',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: PixelColors.textDark)),
                                const SizedBox(width: 6),
                                const Text('|',
                                    style: TextStyle(
                                        color: Color(0xFFABC8EA),
                                        fontSize: 10)),
                                const SizedBox(width: 6),
                                const PixelIcon(PixelIconType.book, size: 13),
                                const Text(' : 공부/집중',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: PixelColors.textDark)),
                                const SizedBox(width: 6),
                                const PixelIcon(PixelIconType.dumbbell,
                                    size: 13),
                                const Text(' : 운동',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: PixelColors.textDark)),
                                const SizedBox(width: 6),
                                const PixelIcon(PixelIconType.droplet,
                                    size: 13),
                                const Text(' : 건강관리',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: PixelColors.textDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── 4. 하단 일정 카드: [📅 MM/dd 오늘의 일정]  [ 3개 ] ──
                    PixelBox(
                      step: 6.0,
                      shadowOffset: 4.0,
                      backgroundColor: const Color(0xFFF0F6FF),
                      borderColor: PixelColors.borderDark,
                      borderWidth: 2.4,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 헤더 바: [📅 MM/dd 오늘의 일정] & [ N개 ]
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const PixelIcon(PixelIconType.calendar,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')} 오늘의 일정',
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              PixelBox(
                                step: 3.5,
                                shadowOffset: 2.0,
                                borderWidth: 1.8,
                                lipHeight: 2.0,
                                backgroundColor: const Color(0xFFC8E0FD),
                                lipColor: const Color(0xFFA7CBF7),
                                borderColor: PixelColors.borderDark,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 3),
                                child: Text(
                                  '${selectedDayTasks.length}개',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: PixelColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 일정 목록
                          if (selectedDayTasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      '이 날짜에 등록된 일정이 없습니다.',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: PixelColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    PixelButton(
                                      text: '일정 추가하기',
                                      pixelIcon: const PixelIcon(
                                        PixelIconType.plus,
                                        size: 16,
                                        primaryColor: Colors.white,
                                      ),
                                      height: 44,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const TaskEditScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: selectedDayTasks.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final task = selectedDayTasks[idx];
                                final isCompleted =
                                    task.status == TaskStatus.completed;

                                return PixelBox(
                                  height: 50,
                                  step: 4.5,
                                  shadowOffset: 2.5,
                                  lipHeight: 2.5,
                                  backgroundColor: Colors.white,
                                  lipColor: const Color(0xFFD5E6FA),
                                  borderColor: isCompleted
                                      ? PixelColors.primaryBlueLight
                                      : const Color(0xFFABC8EA),
                                  borderWidth: 2.0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  onTap: isCompleted
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (_) =>
                                                TaskProofDialog(task: task),
                                          );
                                        },
                                  child: Row(
                                    children: [
                                      // 픽셀 체크박스 [☐] / [☑]
                                      PixelBox(
                                        width: 22,
                                        height: 22,
                                        step: 2.0,
                                        shadowOffset: 0.0,
                                        enableBevel: false,
                                        backgroundColor: isCompleted
                                            ? PixelColors.primaryBlue
                                            : Colors.white,
                                        borderColor: PixelColors.borderDark,
                                        borderWidth: 2.0,
                                        child: isCompleted
                                            ? const Center(
                                                child: PixelIcon(
                                                  PixelIconType.check,
                                                  size: 14,
                                                  primaryColor: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),

                                      // 카테고리 픽셀 아이콘
                                      _getIconForTask(task),
                                      const SizedBox(width: 8),

                                      // 일정 제목
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            color: isCompleted
                                                ? PixelColors.textMuted
                                                : PixelColors.textDark,
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      // 알림/수행 시각 픽셀 알약
                                      PixelBox(
                                        step: 3.0,
                                        shadowOffset: 0.0,
                                        enableBevel: false,
                                        backgroundColor:
                                            const Color(0xFFE4F0FD),
                                        borderColor: const Color(0xFF9EC0EB),
                                        borderWidth: 1.6,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        child: Text(
                                          _formatTimeKorean(task.startTime),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: PixelColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysGrid({
    required int daysInMonth,
    required int firstWeekday,
    required List<Task> allTasks,
  }) {
    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: rowIndex < rowCount - 1
                  ? const BorderSide(color: Color(0xFFD3E4F7), width: 1)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - firstWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 48));
              }

              final cellDate = DateTime(
                  _currentMonth.year, _currentMonth.month, dayNumber);
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;

              // 일요일: 빨강, 토요일: 파랑, 평일: 네이비
              Color textColor = PixelColors.textDark;
              if (colIndex == 0) textColor = const Color(0xFFDE4A5B);
              if (colIndex == 6) textColor = const Color(0xFF3867D6);

              final markerWidget = _getMarkerForDate(cellDate, allTasks);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                        right: colIndex < 6
                            ? const BorderSide(
                                color: Color(0xFFD3E4F7), width: 1)
                            : BorderSide.none,
                      ),
                    ),
                    child: Center(
                      child: isSelected
                          ? PixelBox(
                              width: 40,
                              height: 41,
                              step: 3.5,
                              shadowOffset: 2.5,
                              lipHeight: 3.0,
                              backgroundColor: const Color(0xFF538CE0),
                              highlightColor: const Color(0xFF9AC9FF),
                              lipColor: PixelColors.primaryBlueDark,
                              borderColor: PixelColors.borderDark,
                              borderWidth: 2.2,
                              onTap: () {},
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // 3개 사각 픽셀 도트 (■ ■ ■)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      3,
                                      (_) => Container(
                                        width: 3,
                                        height: 3,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 1),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  height: 12,
                                  child: markerWidget ?? const SizedBox.shrink(),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _WeekdayHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}
