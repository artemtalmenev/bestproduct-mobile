import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';

const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const _months = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

String _taskDateKey(DateTime? dueAt) {
  if (dueAt == null) return '';
  final y = dueAt.year;
  final m = dueAt.month.toString().padLeft(2, '0');
  final d = dueAt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _year;
  late int _month;
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.getTasks(month: _month, year: _year);
      if (mounted) {
        setState(() {
          _tasks = list;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 401 ? 'Сессия истекла' : e.code;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки';
          _loading = false;
        });
      }
    }
  }

  void _prevMonth() {
    if (_month == 1) {
      _month = 12;
      _year--;
    } else {
      _month--;
    }
    setState(() {});
    _load();
  }

  void _nextMonth() {
    if (_month == 12) {
      _month = 1;
      _year++;
    } else {
      _month++;
    }
    setState(() {});
    _load();
  }

  Map<String, List<Task>> get _tasksByDay {
    final map = <String, List<Task>>{};
    for (final t in _tasks) {
      final key = _taskDateKey(t.dueAt);
      if (key.isEmpty) continue;
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_year, _month, 1);
    final lastDay = DateTime(_year, _month + 1, 0);
    final startOffset = (firstDay.weekday + 6) % 7;
    final daysInMonth = lastDay.day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final tasksByDay = _tasksByDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Повторить')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _loading ? null : _prevMonth,
                            ),
                            Text(
                              '${_months[_month - 1]} $_year',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _loading ? null : _nextMonth,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _weekdays
                              .map((w) => Expanded(
                                    child: Center(
                                      child: Text(
                                        w,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(rows, (row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: List.generate(7, (col) {
                                final cellIndex = row * 7 + col;
                                if (cellIndex < startOffset) {
                                  return const Expanded(child: SizedBox());
                                }
                                final day = cellIndex - startOffset + 1;
                                if (day > daysInMonth) {
                                  return const Expanded(child: SizedBox());
                                }
                                final key = '$_year-${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                                final dayTasks = tasksByDay[key] ?? [];
                                final isToday = _year == DateTime.now().year &&
                                    _month == DateTime.now().month &&
                                    day == DateTime.now().day;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Material(
                                      color: isToday
                                          ? Theme.of(context).colorScheme.primaryContainer
                                          : (dayTasks.isNotEmpty
                                                ? Theme.of(context).colorScheme.surfaceContainerHighest
                                                : Colors.transparent),
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: dayTasks.isEmpty
                                            ? null
                                            : () => _showDayTasks(context, day, dayTasks),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$day',
                                                style: TextStyle(
                                                  fontWeight: isToday ? FontWeight.bold : null,
                                                ),
                                              ),
                                              if (dayTasks.isNotEmpty)
                                                Text(
                                                  '${dayTasks.length}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _showDayTasks(BuildContext context, int day, List<Task> dayTasks) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$day ${_months[_month - 1]} — ${dayTasks.length} задач(и)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                controller: scrollController,
                itemCount: dayTasks.length,
                itemBuilder: (_, i) {
                  final t = dayTasks[i];
                  return ListTile(
                    title: Text(t.title),
                    subtitle: t.description != null && t.description!.isNotEmpty
                        ? Text(t.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: Chip(label: Text(t.status, style: const TextStyle(fontSize: 12))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
