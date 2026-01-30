import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.api,
    required this.onSuccess,
    required this.onGoToLogin,
  });

  final ApiClient api;
  final VoidCallback onSuccess;
  final VoidCallback onGoToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successMessage;
  String? _verifyUrl;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _successMessage = null;
      _verifyUrl = null;
      _loading = true;
    });
    try {
      final data = await widget.api.register(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      final verifyUrl = data['verifyUrl'] as String?;
      setState(() {
        _loading = false;
        _verifyUrl = verifyUrl;
        _successMessage = verifyUrl != null
            ? 'Регистрация прошла. Письмо с подтверждением могло не дойти — нажмите на ссылку ниже:'
            : 'Регистрация прошла. Подтвердите email по ссылке из письма, затем войдите.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'EMAIL_TAKEN' => 'Этот email уже занят',
        'INVALID_INPUT' => 'Email и пароль (мин. 8 символов)',
        _ => e.code,
      };
      setState(() {
        _error = msg;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.data is Map ? (e.response!.data as Map)['error'] as String? : null;
      final msg = switch ((e.response?.statusCode, code)) {
        (409, _) => 'Этот email уже занят',
        (503, _) => 'Сервис временно недоступен',
        (500, _) => 'Ошибка сервера. Попробуйте позже.',
        _ => e.message ?? 'Ошибка сети',
      };
      setState(() {
        _error = msg;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceBlack,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'Регистрация',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_successMessage != null) ...[
                    Text(
                      _successMessage!,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (_verifyUrl != null) ...[
                      const SizedBox(height: 12),
                      _VerifyLink(url: _verifyUrl!),
                    ],
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Email',
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
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Введите email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Пароль (мин. 8 символов)',
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
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Введите пароль';
                      if (v.length < 8) return 'Минимум 8 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _submit();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.textPrimary,
                      foregroundColor: AppTheme.surfaceBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.surfaceBlack),
                          )
                        : const Text('Зарегистрироваться'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onGoToLogin,
                    child: const Text(
                      'Уже есть аккаунт? Вход',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Кликабельная ссылка подтверждения: открывает в браузере или показывает диалог «Копировать».
class _VerifyLink extends StatelessWidget {
  const _VerifyLink({required this.url});
  final String url;

  Future<void> _openOrCopy(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched && context.mounted) {
        _showCopyDialog(context);
      }
    } catch (_) {
      if (context.mounted) _showCopyDialog(context);
    }
  }

  void _showCopyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Открыть ссылку', style: TextStyle(color: AppTheme.textPrimary)),
        content: SelectableText(url, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ссылка скопирована. Вставьте в браузере.'),
                    backgroundColor: AppTheme.surfaceCard,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.textPrimary, foregroundColor: AppTheme.surfaceBlack),
            child: const Text('Копировать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openOrCopy(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Text(
            url,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
