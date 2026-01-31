import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class TaskEditScreen extends StatefulWidget {
  const TaskEditScreen({
    super.key,
    required this.api,
    required this.task,
  });

  final ApiClient api;
  final Task? task;

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _status = 'todo';
  DateTime? _dueAt;
  bool _clearDueAt = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _status = t?.status ?? 'todo';
    _dueAt = t?.dueAt?.toLocal();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (widget.task == null) {
        await widget.api.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          dueAt: _dueAt?.toIso8601String(),
        );
      } else {
        await widget.api.updateTask(
          widget.task!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          dueAt: _dueAt?.toIso8601String(),
          clearDueAt: _clearDueAt,
          status: _status,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка сети';
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickDueAt() async {
    final now = DateTime.now();
    final initial = _dueAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _clearDueAt = false;
    });
  }

  void _clearDueAtSelection() {
    setState(() {
      _dueAt = null;
      _clearDueAt = true;
    });
  }

  String _formatDueAt(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final day = twoDigits(dateTime.day);
    final month = twoDigits(dateTime.month);
    final year = dateTime.year;
    final hour = twoDigits(dateTime.hour);
    final minute = twoDigits(dateTime.minute);
    return '$day.$month.$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.task == null;
    return Scaffold(
      backgroundColor: AppTheme.surfaceBlack,
      appBar: AppBar(
        title: Text(
          isCreate ? 'Новая задача' : 'Редактировать',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surfaceBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата и время',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueAt != null ? _formatDueAt(_dueAt!) : 'Не задано',
                        style: TextStyle(
                          color: _dueAt != null ? AppTheme.textPrimary : AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _pickDueAt,
                      icon: const Icon(Icons.calendar_month_rounded, color: AppTheme.textSecondary),
                      tooltip: 'Выбрать дату',
                    ),
                    if (_dueAt != null)
                      IconButton(
                        onPressed: _loading ? null : _clearDueAtSelection,
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        tooltip: 'Очистить',
                      ),
                  ],
                ),
              ),
              if (!isCreate) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Статус',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'todo', child: Text('Сделать')),
                    DropdownMenuItem(value: 'in_progress', child: Text('В работе')),
                    DropdownMenuItem(value: 'done', child: Text('Готова')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Отменено')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'todo'),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isCreate ? 'Создать' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
