import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../widgets/welcome_splash.dart';

/// Корневой экран: проверка сессии → сплэш → логин или главный shell.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final ApiClient _api;
  bool _checkingSession = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _checkSession();
  }

  static const _minSplashDuration = Duration(milliseconds: 1600);

  Future<void> _checkSession() async {
    final stopwatch = Stopwatch()..start();
    try {
      final ok = await checkSession(_api);
      final elapsed = stopwatch.elapsed;
      if (elapsed < _minSplashDuration) {
        await Future<void>.delayed(_minSplashDuration - elapsed);
      }
      if (mounted) {
        setState(() {
          _checkingSession = false;
          _loggedIn = ok;
        });
      }
    } catch (_) {
      final elapsed = stopwatch.elapsed;
      if (elapsed < _minSplashDuration) {
        await Future<void>.delayed(_minSplashDuration - elapsed);
      }
      if (mounted) {
        setState(() {
          _checkingSession = false;
          _loggedIn = false;
        });
      }
    }
  }

  void _goToLogin() {
    setState(() => _loggedIn = false);
  }

  void _onLoginSuccess() {
    setState(() => _loggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const WelcomeSplash();
    }
    if (_loggedIn) {
      return HomeShell(
        api: _api,
        onLogout: _goToLogin,
      );
    }
    return LoginScreen(
      api: _api,
      onSuccess: _onLoginSuccess,
      onGoToRegister: _goToRegister,
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RegisterScreen(
          api: _api,
          onSuccess: () {
            Navigator.pop(context);
            _onLoginSuccess();
          },
          onGoToLogin: () => Navigator.pop(context),
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}
