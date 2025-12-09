import 'package:flutter/material.dart';

import 'step_badge.dart';

/// Section header with badge and title
class SectionHeader extends StatelessWidget {
  final StepBadge badge;
  final String title;

  const SectionHeader({super.key, required this.badge, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        badge,
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFF000000),
          ),
        ),
      ],
    );
  }
}
