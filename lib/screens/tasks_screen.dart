import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/task_status_chip.dart';
import 'task_edit_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.api,
    required this.onLogout,
    this.isSelected = true,
  });

  final ApiClient api;
  final VoidCallback onLogout;
  /// True когда пользователь на этой вкладке — при переключении на вкладку список обновляется.
  final bool isSelected;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновить список при каждом заходе на вкладку «Задачи»
    if (!oldWidget.isSelected && widget.isSelected) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.getTasks();
      if (mounted) {
        setState(() {
          _tasks = list;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 401 ? _sessionErrorMessage : e.code;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 401
          ? _sessionErrorMessage
          : (e.message ?? 'Ошибка загрузки');
      setState(() {
        _error = msg;
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

  static const String _sessionErrorMessage =
      'Сессия не сохранилась. На веб с другого домена cookie не отправляются — нажмите «Выйти» и войдите снова или используйте приложение на Android.';


  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('«${task.title}»'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.api.deleteTask(task.id);
      if (mounted) _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.code)),
        );
      }
    }
  }

  void _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TaskEditScreen(api: widget.api, task: null),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    if (created == true && mounted) _load();
  }

  void _openEdit(Task task) async {
    final updated = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TaskEditScreen(api: widget.api, task: task),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    if (updated == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBlack,
      appBar: AppBar(
        title: const Text('Задачи', style: TextStyle(color: AppTheme.textPrimary)),
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
                        onPressed: _load,
                        child: const Text('Повторить'),
                      ),
                      if (_error == _sessionErrorMessage) ...[
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: widget.onLogout,
                          child: const Text('Выйти и войти снова'),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _tasks.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: const Center(
                                child: Text(
                                  'Нет задач. Создайте первую.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final t = _tasks[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 200 + (index * 30).clamp(0, 200)),
                              curve: Curves.easeOut,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 8 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                color: AppTheme.surfaceCard,
                                child: ListTile(
                                  title: Text(
                                    t.title,
                                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: t.description != null && t.description!.isNotEmpty
                                      ? Text(
                                          t.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                        )
                                      : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TaskStatusChip(status: t.status),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: AppTheme.textSecondary),
                                      onPressed: () => _openEdit(t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: AppTheme.textMuted),
                                      onPressed: () => _deleteTask(t),
                                    ),
                                  ],
                                ),
                                onTap: () => _openEdit(t),
                              ),
                            ),
                          );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppTheme.textPrimary,
        foregroundColor: AppTheme.surfaceBlack,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

