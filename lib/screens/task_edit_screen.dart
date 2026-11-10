import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/character_provider.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_ui_kit.dart';

/// 레퍼런스 4 디자인: 픽셀 일정 추가하기 화면
class TaskEditScreen extends StatefulWidget {
  final Task? taskToEdit;

  const TaskEditScreen({super.key, this.taskToEdit});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _titleController = TextEditingController();

  DateTime _startDate = DateTime.now();
  late DateTime _endDate;

  int _alertHour = 9;
  int _alertMinute = 0;
  bool _isAm = true;

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.taskToEdit!;
      _titleController.text = t.title;
      _startDate = t.startDate;
      _endDate = t.endDate;
      if (t.startTime != null) {
        final parts = t.startTime!.split(':');
        final h = int.tryParse(parts[0]) ?? 9;
        _isAm = h < 12;
        _alertHour = _isAm ? h : (h == 12 ? 12 : h - 12);
        _alertMinute = int.tryParse(parts[1]) ?? 0;
      }
    } else {
      _endDate = _startDate; // 기본 당일(필요 시 프리셋 또는 직접 선택)
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _setPeriodPreset(int months) {
    setState(() {
      _endDate = DateTime(
        _startDate.year,
        _startDate.month + months,
        _startDate.day,
      );
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PixelColors.primaryBlueDark,
              onPrimary: Colors.white,
              onSurface: PixelColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 이름을 입력해주세요!')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final characterProvider = context.read<CharacterProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final hour24 = _isAm
        ? (_alertHour == 12 ? 0 : _alertHour)
        : (_alertHour == 12 ? 12 : _alertHour + 12);
    final startTimeStr =
        '${hour24.toString().padLeft(2, '0')}:${_alertMinute.toString().padLeft(2, '0')}';

    final id = _isEditing
        ? widget.taskToEdit!.id
        : 'task_${DateTime.now().millisecondsSinceEpoch}';

    final task = Task(
      id: id,
      title: title,
      goal: '',
      durationMin: 60, // 기본 1시간
      category: TaskCategory.personal,
      priority: TaskPriority.medium,
      alertBefore: 0,
      startDate: _startDate,
      endDate: _endDate,
      placedDate: _startDate,
      startTime: startTimeStr,
      status: TaskStatus.placed,
    );

    bool success;
    if (_isEditing) {
      success = await taskProvider.updateTask(userId, task);
    } else {
      success = await taskProvider.createTask(userId, task);
    }

    if (!mounted) return;

    if (success) {
      // 알림 스케줄링
      final taskStartTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        hour24,
        _alertMinute,
      );
      await NotificationService.instance.scheduleTaskNotification(
        taskId: task.id,
        taskTitle: task.title,
        characterName: characterProvider.currentCharacter?.name ?? '파트너',
        taskStartTime: taskStartTime,
        alertBeforeMin: 0,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? '일정이 수정되었습니다.'
                : '새 일정이 시간표에 추가되었습니다! 📅✨',
          ),
          backgroundColor: PixelColors.borderDark,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelColors.bgSky,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── 상단 스카이 시티 헤더 & 픽셀 배너 ──
            PixelSkyHeader(
              title: _isEditing ? '일정 수정하기' : '일정 추가하기',
              onBack: () => Navigator.pop(context),
            ),

            // ── 메인 폼 카드 영역 ──
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // 1. 목표이름 카드
                    PixelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              PixelIcon(PixelIconType.pencil, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '목표이름',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: PixelColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PixelBox(
                            height: 48,
                            step: 4.0,
                            shadowOffset: 0.0,
                            enableBevel: false,
                            backgroundColor: Colors.white,
                            borderColor: PixelColors.borderDark,
                            borderWidth: 2.2,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: TextField(
                                controller: _titleController,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: PixelColors.textDark,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '할 일 명칭을 입력하세요',
                                  hintStyle: TextStyle(
                                      fontSize: 14, color: PixelColors.textMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. 기간 카드
                    PixelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              PixelIcon(PixelIconType.calendar, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '기간',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: PixelColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 날짜 범위 표시 픽셀 박스: [ 00-00 ~ 00-00 ]
                          PixelBox(
                            height: 46,
                            width: double.infinity,
                            step: 4.0,
                            shadowOffset: 0.0,
                            enableBevel: false,
                            backgroundColor: Colors.white,
                            borderColor: PixelColors.borderDark,
                            borderWidth: 2.2,
                            child: Center(
                              child: Text(
                                '${_formatDate(_startDate)}  ~  ${_formatDate(_endDate)}',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: PixelColors.textDark,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 1개월 / 6개월 / 1년 프리셋 버튼 Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildPeriodPresetBtn('1개월', 1),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPeriodPresetBtn('6개월', 6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPeriodPresetBtn('1년', 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 직접 선택 버튼: [ 📅 직접 선택  ▶ ]
                          PixelBox(
                            height: 46,
                            width: double.infinity,
                            step: 4.0,
                            shadowOffset: 3.0,
                            lipHeight: 3.0,
                            backgroundColor: PixelColors.whiteButtonBg,
                            lipColor: PixelColors.whiteButtonLip,
                            borderColor: PixelColors.border,
                            borderWidth: 2.2,
                            onTap: _selectDateRange,
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PixelIcon(PixelIconType.calendar, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    '직접 선택',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      color: PixelColors.textDark,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  PixelIcon(
                                    PixelIconType.triangleRight,
                                    size: 13,
                                    primaryColor: PixelColors.textDark,
                                    accentColor: PixelColors.primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. 알림시간 카드
                    PixelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              PixelIcon(PixelIconType.clock, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '알림시간',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: PixelColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 시 / 분 / 오전오후 선택기
                          Row(
                            children: [
                              // 시 선택 (00시 ⬍)
                              Expanded(
                                child: _buildSpinnerBox(
                                  label:
                                      '${_alertHour.toString().padLeft(2, '0')}시',
                                  onInc: () => setState(() =>
                                      _alertHour = (_alertHour % 12) + 1),
                                  onDec: () => setState(() => _alertHour =
                                      _alertHour > 1 ? _alertHour - 1 : 12),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 분 선택 (00분 ⬍)
                              Expanded(
                                child: _buildSpinnerBox(
                                  label:
                                      '${_alertMinute.toString().padLeft(2, '0')}분',
                                  onInc: () => setState(() => _alertMinute =
                                      (_alertMinute + 10) % 60),
                                  onDec: () => setState(() => _alertMinute =
                                      _alertMinute >= 10
                                          ? _alertMinute - 10
                                          : 50),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 오전 / 오후 토글
                              Expanded(
                                child: PixelBox(
                                  height: 48,
                                  step: 3.5,
                                  shadowOffset: 2.0,
                                  enableBevel: false,
                                  backgroundColor: const Color(0xFFD5E7FC),
                                  borderColor: PixelColors.border,
                                  borderWidth: 2.2,
                                  padding: const EdgeInsets.all(3),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: PixelBox(
                                          step: 2.5,
                                          shadowOffset: _isAm ? 2.0 : 0.0,
                                          lipHeight: _isAm ? 2.5 : 0.0,
                                          backgroundColor: _isAm
                                              ? PixelColors.primaryBlue
                                              : Colors.transparent,
                                          lipColor: _isAm
                                              ? PixelColors.primaryBlueDark
                                              : null,
                                          borderColor: _isAm
                                              ? PixelColors.borderDark
                                              : Colors.transparent,
                                          borderWidth: _isAm ? 1.5 : 0,
                                          onTap: () =>
                                              setState(() => _isAm = true),
                                          child: Center(
                                            child: Text(
                                              '오전',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w900,
                                                color: _isAm
                                                    ? Colors.white
                                                    : PixelColors.textDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: PixelBox(
                                          step: 2.5,
                                          shadowOffset: !_isAm ? 2.0 : 0.0,
                                          lipHeight: !_isAm ? 2.5 : 0.0,
                                          backgroundColor: !_isAm
                                              ? PixelColors.primaryBlue
                                              : Colors.transparent,
                                          lipColor: !_isAm
                                              ? PixelColors.primaryBlueDark
                                              : null,
                                          borderColor: !_isAm
                                              ? PixelColors.borderDark
                                              : Colors.transparent,
                                          borderWidth: !_isAm ? 1.5 : 0,
                                          onTap: () =>
                                              setState(() => _isAm = false),
                                          child: Center(
                                            child: Text(
                                              '오후',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w900,
                                                color: !_isAm
                                                    ? Colors.white
                                                    : PixelColors.textDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 하단 일정추가 액션 버튼: 시안처럼 우측 정렬 [ 📅+ 일정추가 ]
                    Align(
                      alignment: Alignment.centerRight,
                      child: PixelButton(
                        width: 185,
                        text: _isEditing ? '수정완료' : '일정추가',
                        pixelIcon: const PixelIcon(
                          PixelIconType.calendarPlus,
                          size: 22,
                        ),
                        onPressed: _handleSave,
                      ),
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

  Widget _buildPeriodPresetBtn(String label, int months) {
    return PixelBox(
      height: 42,
      step: 3.5,
      shadowOffset: 3.0,
      lipHeight: 3.0,
      backgroundColor: const Color(0xFFCDE2FC),
      highlightColor: const Color(0xFFEAF4FF),
      lipColor: const Color(0xFFA2C6F5),
      borderColor: PixelColors.border,
      borderWidth: 2.0,
      onTap: () => _setPeriodPreset(months),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: PixelColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSpinnerBox({
    required String label,
    required VoidCallback onInc,
    required VoidCallback onDec,
  }) {
    return PixelBox(
      height: 48,
      step: 3.5,
      shadowOffset: 2.0,
      lipHeight: 2.5,
      backgroundColor: Colors.white,
      lipColor: const Color(0xFFD5E6FA),
      borderColor: PixelColors.border,
      borderWidth: 2.0,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: PixelColors.textDark,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onInc,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: PixelIcon(PixelIconType.triangleUp,
                      size: 11, primaryColor: PixelColors.primaryBlue),
                ),
              ),
              GestureDetector(
                onTap: onDec,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: PixelIcon(PixelIconType.triangleDown,
                      size: 11, primaryColor: PixelColors.primaryBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
