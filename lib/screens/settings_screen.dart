import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.api,
    required this.onLogout,
  });

  final ApiClient api;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBlack,
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surfaceBlack,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton.icon(
            onPressed: () async {
              try {
                await api.logout();
              } catch (_) {}
              onLogout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.surfaceCard,
              foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderLight),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Выйти'),
          ),
        ),
      ),
    );
  }
}
