import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

const _weekdaysLower = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
const _months = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

const double _hourSlotHeight = 72;
const double _timeColumnWidth = 56;
const Color _taskBlockColor = Color(0xFF5B9EEA);

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class DayScheduleScreen extends StatefulWidget {
  const DayScheduleScreen({
    super.key,
    required this.api,
    required this.initialDate,
    this.initialTasks,
  });

  final ApiClient api;
  final DateTime initialDate;
  final List<Task>? initialTasks;

  @override
  State<DayScheduleScreen> createState() => _DayScheduleScreenState();
}

class _DayScheduleScreenState extends State<DayScheduleScreen> {
  late DateTime _selectedDate;
  late List<Task> _tasks;
  late ScrollController _scrollController;
  bool _loading = true;
  String? _error;
  int _loadedMonth = 0;
  int _loadedYear = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate);
    _loadedMonth = _selectedDate.month;
    _loadedYear = _selectedDate.year;
    _tasks = widget.initialTasks ?? [];
    _loading = widget.initialTasks == null;
    _scrollController = ScrollController(initialScrollOffset: _initialScrollOffset(_selectedDate));
    if (_loading) {
      _loadMonth();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _initialScrollOffset(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDate(date, now);
    final rawHour = isToday ? now.hour - 1 : 8;
    final hour = rawHour < 0 ? 0 : (rawHour > 23 ? 23 : rawHour);
    return hour * _hourSlotHeight;
  }

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.getTasks(
        month: _selectedDate.month,
        year: _selectedDate.year,
      );
      if (!mounted) return;
      setState(() {
        _tasks = list;
        _loading = false;
        _loadedMonth = _selectedDate.month;
        _loadedYear = _selectedDate.year;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 401 ? 'Сессия истекла' : e.code;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка загрузки';
        _loading = false;
      });
    }
  }

  void _shiftDay(int delta) {
    final next = _dateOnly(_selectedDate.add(Duration(days: delta)));
    final monthChanged = next.month != _loadedMonth || next.year != _loadedYear;
    setState(() {
      _selectedDate = next;
      if (monthChanged) {
        _loading = true;
        _error = null;
        _tasks = [];
      }
    });
    if (monthChanged) {
      _loadMonth();
    }
    _jumpToInitialOffset(next);
  }

  void _jumpToInitialOffset(DateTime date) {
    final target = _initialScrollOffset(date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final safeTarget = target < 0 ? 0 : (target > max ? max : target);
      _scrollController.jumpTo(safeTarget);
    });
  }

  List<Task> get _tasksForDay {
    final items = _tasks.where((task) {
      final dueAt = task.dueAt?.toLocal();
      if (dueAt == null) return false;
      return _isSameDate(dueAt, _selectedDate);
    }).toList();
    items.sort((a, b) {
      final aDue = a.dueAt?.toLocal();
      final bDue = b.dueAt?.toLocal();
      if (aDue == null && bDue == null) return 0;
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      return aDue.compareTo(bDue);
    });
    return items;
  }

  Map<int, List<Task>> _groupTasksByHour(List<Task> tasks) {
    final map = <int, List<Task>>{};
    for (final task in tasks) {
      final dueAt = task.dueAt?.toLocal();
      if (dueAt == null) continue;
      map.putIfAbsent(dueAt.hour, () => []).add(task);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final aDue = a.dueAt?.toLocal();
        final bDue = b.dueAt?.toLocal();
        if (aDue == null && bDue == null) return 0;
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      });
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final dayTasks = _tasksForDay;
    final tasksByHour = _groupTasksByHour(dayTasks);
    final monthLabel = _months[_selectedDate.month - 1];

    return Scaffold(
      backgroundColor: AppTheme.surfaceBlack,
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(monthLabel, style: const TextStyle(color: AppTheme.textPrimary)),
            const Icon(Icons.arrow_drop_down, color: AppTheme.textPrimary),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textPrimary),
            onPressed: _loading ? null : () => _shiftDay(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textPrimary),
            onPressed: _loading ? null : () => _shiftDay(1),
          ),
        ],
        backgroundColor: AppTheme.surfaceBlack,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.textPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadMonth,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.textPrimary,
                          foregroundColor: AppTheme.surfaceBlack,
                        ),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _DayHeader(
                      date: _selectedDate,
                      taskCount: dayTasks.length,
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadMonth,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: 24,
                          itemBuilder: (_, index) {
                            final hourTasks = tasksByHour[index] ?? [];
                            return _HourSlot(
                              hour: index,
                              tasks: hourTasks,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.taskCount,
  });

  final DateTime date;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdaysLower[date.weekday - 1];
    final monthLabel = _months[date.month - 1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                weekday,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppTheme.textPrimary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    color: AppTheme.surfaceBlack,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${date.day} $monthLabel',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (taskCount > 0)
            Text(
              '$taskCount задач(и)',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _HourSlot extends StatelessWidget {
  const _HourSlot({
    required this.hour,
    required this.tasks,
  });

  final int hour;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final label = '${_twoDigits(hour)}:00';
    return SizedBox(
      height: _hourSlotHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Container(height: 1, color: AppTheme.borderLight),
                ),
                if (tasks.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: tasks
                          .map((task) => _ScheduleTaskCard(task: task))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTaskCard extends StatelessWidget {
  const _ScheduleTaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final dueAt = task.dueAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _taskBlockColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (dueAt != null)
            Text(
              _formatTime(dueAt),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
