import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/welcome_splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskPROD',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ApiClient _api;
  bool _checkingSession = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _checkSession();
  }

  Future<void> _checkSession() async {
    const minSplashDuration = Duration(milliseconds: 1600);
    final stopwatch = Stopwatch()..start();

    try {
      final ok = await checkSession(_api);
      final elapsed = stopwatch.elapsed;
      if (elapsed < minSplashDuration) {
        await Future<void>.delayed(minSplashDuration - elapsed);
      }
      if (mounted) {
        setState(() {
          _checkingSession = false;
          _loggedIn = ok;
        });
      }
    } catch (_) {
      final elapsed = stopwatch.elapsed;
      if (elapsed < minSplashDuration) {
        await Future<void>.delayed(minSplashDuration - elapsed);
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
      onGoToRegister: () {
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
      },
    );
  }
}
