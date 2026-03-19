import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/hackathon_model.dart';

class StatusBadge extends StatelessWidget {
  final HackathonStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      HackathonStatus.draft => Colors.grey,
      HackathonStatus.published => AppColors.success,
      HackathonStatus.ongoing => AppColors.info,
      HackathonStatus.completed => AppColors.secondaryGreen,
      HackathonStatus.cancelled => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
