import 'package:flutter/material.dart';

/// Step indicator badge with icon and label
class StepBadge extends StatelessWidget {
  final IconData icon;
  final String stepNumber;
  final Color color;

  const StepBadge({
    super.key,
    required this.icon,
    required this.stepNumber,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            stepNumber,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-defined step badges for consistency
class StepBadges {
  static const step1 = StepBadge(
    icon: Icons.photo_camera_rounded,
    stepNumber: 'Step 1',
    color: Color(0xFF007AFF),
  );

  static const step2 = StepBadge(
    icon: Icons.palette_outlined,
    stepNumber: 'Step 2',
    color: Color(0xFF6366F1),
  );

  static const step3 = StepBadge(
    icon: Icons.auto_fix_high_rounded,
    stepNumber: 'Step 3',
    color: Color(0xFF34C759),
  );

  static const results = StepBadge(
    icon: Icons.collections_rounded,
    stepNumber: 'Results',
    color: Color(0xFFFF9500),
  );

  static const gallery = StepBadge(
    icon: Icons.photo_library_rounded,
    stepNumber: 'Saved',
    color: Color(0xFF5856D6),
  );
}
