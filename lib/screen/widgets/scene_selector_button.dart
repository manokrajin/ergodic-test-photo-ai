import 'package:flutter/material.dart';

import '../../service/banana_service.dart';

/// Button to open scene selector
/// Shows the selected scene or "Choose Scenes" if none selected
class SceneSelectorButton extends StatelessWidget {
  final TravelScene? selectedScene;
  final VoidCallback onTap;

  const SceneSelectorButton({
    super.key,
    this.selectedScene,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedScene != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0xFF6366F1).withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
            color: isSelected
                ? const Color(0xFF6366F1).withOpacity(0.08)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.palette_outlined,
                size: 18,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                isSelected
                    ? '${selectedScene!.emoji} ${selectedScene!.name}'
                    : 'Choose a Scene',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
