import 'package:flutter/material.dart';

import '../services/api_client.dart';

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
      appBar: AppBar(title: const Text('Настройки')),
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
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ),
      ),
    );
  }
}
