import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onSuccess,
    required this.onGoToRegister,
  });

  final ApiClient api;
  final VoidCallback onSuccess;
  final VoidCallback onGoToRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await widget.api.login(_emailController.text, _passwordController.text);
      if (mounted) {
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'USER_NOT_FOUND' => 'Пользователь не найден',
        'EMAIL_NOT_VERIFIED' => 'Подтвердите email (проверьте почту)',
        'INVALID_CREDENTIALS' => 'Неверный пароль',
        'INVALID_INPUT' => 'Проверьте email и пароль',
        'SERVER_MISCONFIGURATION' => 'Сервер не настроен (нет AUTH_SECRET)',
        'SERVER_ERROR' => 'Ошибка сервера. Попробуйте позже.',
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
        (404, _) => 'Пользователь не найден',
        (401, _) => 'Неверный пароль',
        (403, _) => 'Подтвердите email (проверьте почту)',
        (503, 'SERVER_MISCONFIGURATION') => 'Сервер не настроен (нет AUTH_SECRET)',
        (503, _) => 'Сервис временно недоступен',
        (500, _) => 'Ошибка сервера. Попробуйте позже.',
        _ => e.message ?? e.type.toString(),
      };
      final show = msg.startsWith('Пользователь') || msg.startsWith('Неверный') ||
          msg.startsWith('Подтвердите') || msg.startsWith('Ошибка') || msg.startsWith('Сервер') || msg.startsWith('Сервис')
          ? msg
          : 'Сеть: $msg';
      setState(() {
        _error = show;
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
                  const AppLogo(size: 72),
                  const SizedBox(height: 24),
                  const Text(
                    'Вход',
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
                      labelText: 'Пароль',
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
                        (v == null || v.isEmpty) ? 'Введите пароль' : null,
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
                        : const Text('Войти'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onGoToRegister,
                    child: const Text(
                      'Нет аккаунта? Регистрация',
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
