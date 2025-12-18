import 'package:flutter/material.dart';

import '../../screen/widgets/outfit_selector.dart';

/// Button to open outfit style selector
/// Shows the selected outfit style
class OutfitSelectorButton extends StatelessWidget {
  final OutfitStyle? selectedStyle;
  final VoidCallback onTap;

  const OutfitSelectorButton({
    super.key,
    this.selectedStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedStyle != null;

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
                  ? (selectedStyle?.color ?? const Color(0xFF6366F1))
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
            color: isSelected
                ? (selectedStyle?.color ?? const Color(0xFF6366F1)).withOpacity(
                    0.08,
                  )
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedStyle?.icon ?? Icons.checkroom_outlined,
                size: 18,
                color: isSelected
                    ? (selectedStyle?.color ?? const Color(0xFF6366F1))
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                isSelected ? selectedStyle!.name : 'Change Outfit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (selectedStyle?.color ?? const Color(0xFF6366F1))
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isSelected
                    ? (selectedStyle?.color ?? const Color(0xFF6366F1))
                    : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
