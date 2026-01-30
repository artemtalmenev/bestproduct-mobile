import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best Product',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
    try {
      final ok = await checkSession(_api);
      if (mounted) {
        setState(() {
          _checkingSession = false;
          _loggedIn = ok;
        });
      }
    } catch (_) {
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
          MaterialPageRoute(
            builder: (ctx) => RegisterScreen(
              api: _api,
              onSuccess: () {
                Navigator.pop(ctx);
                _onLoginSuccess();
              },
              onGoToLogin: () => Navigator.pop(ctx),
            ),
          ),
        );
      },
    );
  }
}
