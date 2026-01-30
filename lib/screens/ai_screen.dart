import 'package:flutter/material.dart';

import '../services/api_client.dart';

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
  String? _lastRequestId;

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
      _lastRequestId = null;
      _loading = true;
    });
    try {
      final req = await widget.api.createRequest(text);
      final id = req['id'] as String?;
      final response = req['response'] as String?;
      if (!mounted) return;
      if (response != null && response.isNotEmpty) {
        setState(() {
          _lastRequestId = id;
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
            _lastRequestId = requestId;
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
      appBar: AppBar(title: const Text('AI')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Опишите задачу или запрос',
                hintText: 'Например: создать задачу «Подготовить отчёт» на пятницу',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: _loading ? null : _send,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_loading ? 'Ожидание ответа...' : 'Отправить'),
            ),
            if (_lastResponse != null) ...[
              const SizedBox(height: 24),
              Text(
                'Ответ AI',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(_lastResponse!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
