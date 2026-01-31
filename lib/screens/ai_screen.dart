import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  String? _error;
  String? _lastResponse;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _error = null;
      _lastResponse = null;
      _loading = true;
    });
    try {
      final req = await widget.api.createRequest(text);
      final id = req['id'] as String?;
      final response = req['response'] as String?;
      if (!mounted) return;
      if (response != null && response.isNotEmpty) {
        setState(() {
          _lastResponse = response;
          _loading = false;
        });
        return;
      }
      if (id != null) {
        _pollUntilResponse(id);
      } else {
        setState(() => _loading = false);
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
          _error = 'Ошибка сети';
          _loading = false;
        });
      }
    }
  }

  Future<void> _pollUntilResponse(String requestId) async {
    const maxAttempts = 60;
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      try {
        final list = await widget.api.getRequests();
        Map<String, dynamic>? req;
        for (final r in list) {
          if (r['id'] == requestId) {
            req = r;
            break;
          }
        }
        final response = req?['response'] as String?;
        if (response != null && response.isNotEmpty && mounted) {
          setState(() {
            _lastResponse = response;
            _loading = false;
          });
          return;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _lastResponse = 'Ответ AI не получен за 2 минуты. Проверьте историю запросов.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBlack,
      appBar: AppBar(
        title: const Text('AI', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surfaceBlack,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Опишите задачу или запрос',
                hintText: 'Например: создать задачу «Подготовить отчёт» на пятницу',
                filled: true,
                fillColor: AppTheme.surfaceInput,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.textSecondary),
                ),
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                hintStyle: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: _loading ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.textPrimary,
                foregroundColor: AppTheme.surfaceBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.surfaceBlack),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_loading ? 'Ожидание ответа...' : 'Отправить'),
            ),
            if (_lastResponse != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Ответ AI',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: child,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: SelectableText(
                    _lastResponse!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
