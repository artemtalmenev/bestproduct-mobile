import 'package:flutter/material.dart';

/// Чип статуса задачи с иконкой и цветом (Сделать / В работе / Готова / Отменена).
class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({super.key, required this.status});

  final String status;

  static ({String label, Color color, IconData icon}) styleFor(String status) {
    switch (status) {
      case 'todo':
        return (label: 'Сделать', color: Colors.grey, icon: Icons.radio_button_unchecked);
      case 'in_progress':
        return (label: 'В работе', color: Colors.amber, icon: Icons.autorenew);
      case 'done':
        return (label: 'Готова', color: Colors.green, icon: Icons.check_circle);
      case 'cancelled':
        return (label: 'Отменена', color: Colors.red, icon: Icons.cancel);
      default:
        return (label: status, color: Colors.grey, icon: Icons.circle_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.15),
        border: Border.all(color: s.color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 16, color: s.color),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: TextStyle(fontSize: 12, color: s.color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
