import 'package:flutter/material.dart';

/// Outfit style option for photo transformation
class OutfitStyle {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const OutfitStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  /// Get all available outfit styles
  static const List<OutfitStyle> allStyles = [
    OutfitStyle(
      id: 'casual',
      name: 'Casual Wear',
      description: 'Jeans, t-shirts, comfortable everyday style',
      icon: Icons.checkroom_outlined,
      color: Color(0xFF3B82F6),
    ),
    OutfitStyle(
      id: 'formal',
      name: 'Formal Attire',
      description: 'Suits, dresses, elegant professional look',
      icon: Icons.dry_cleaning_outlined,
      color: Color(0xFF8B5CF6),
    ),
    OutfitStyle(
      id: 'sporty',
      name: 'Athletic Wear',
      description: 'Gym clothes, sports outfit, active style',
      icon: Icons.sports_basketball_outlined,
      color: Color(0xFF10B981),
    ),
    OutfitStyle(
      id: 'beach',
      name: 'Beach Attire',
      description: 'Swimwear, summer clothes, tropical style',
      icon: Icons.beach_access_outlined,
      color: Color(0xFF06B6D4),
    ),
    OutfitStyle(
      id: 'elegant',
      name: 'Evening Wear',
      description: 'Gowns, tuxedos, glamorous formal dress',
      icon: Icons.card_giftcard_outlined,
      color: Color(0xFFEC4899),
    ),
    OutfitStyle(
      id: 'streetstyle',
      name: 'Street Style',
      description: 'Fashion-forward, trendy, urban vibe',
      icon: Icons.local_activity_outlined,
      color: Color(0xFFF59E0B),
    ),
    OutfitStyle(
      id: 'bohemian',
      name: 'Bohemian Style',
      description: 'Flowing clothes, artistic, free-spirited look',
      icon: Icons.grain_outlined,
      color: Color(0xFF14B8A6),
    ),
    OutfitStyle(
      id: 'keeporiginal',
      name: 'Keep Original',
      description: 'Don\'t change outfit, use current clothing',
      icon: Icons.check_circle_outlined,
      color: Color(0xFF6366F1),
    ),
  ];
}

/// Single outfit style card widget
class OutfitStyleCard extends StatelessWidget {
  final OutfitStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const OutfitStyleCard({
    super.key,
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? style.color : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [style.color.withOpacity(0.15), style.color.withOpacity(0.08)]
                : [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2),
                  ],
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: style.color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and selection indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(style.icon, color: style.color, size: 20),
                      ),
                      if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: style.color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Style name
                  Text(
                    style.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    style.description,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54.withOpacity(0.8),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Ripple effect
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: style.color.withOpacity(0.3),
                highlightColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outfit style selector grid
class OutfitStyleSelector extends StatelessWidget {
  final OutfitStyle? selectedStyle;
  final Function(OutfitStyle) onStyleSelected;

  const OutfitStyleSelector({
    super.key,
    required this.selectedStyle,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Change Outfit Style',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select how you want to appear in the photos',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black54.withOpacity(0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: OutfitStyle.allStyles.length,
          itemBuilder: (context, index) {
            final style = OutfitStyle.allStyles[index];
            final isSelected = selectedStyle?.id == style.id;

            return OutfitStyleCard(
              style: style,
              isSelected: isSelected,
              onTap: () => onStyleSelected(style),
            );
          },
        ),
      ],
    );
  }
}

/// Outfit style selector bottom sheet
class OutfitStyleSelectorBottomSheet extends StatefulWidget {
  final OutfitStyle? initialStyle;
  final Function(OutfitStyle) onConfirm;

  const OutfitStyleSelectorBottomSheet({
    super.key,
    this.initialStyle,
    required this.onConfirm,
  });

  @override
  State<OutfitStyleSelectorBottomSheet> createState() =>
      _OutfitStyleSelectorBottomSheetState();
}

class _OutfitStyleSelectorBottomSheetState
    extends State<OutfitStyleSelectorBottomSheet> {
  late OutfitStyle? _selectedStyle;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Outfit Styles',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: OutfitStyleSelector(
                    selectedStyle: _selectedStyle,
                    onStyleSelected: (style) {
                      setState(() => _selectedStyle = style);
                    },
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectedStyle == null
                            ? null
                            : () {
                                setState(() => _selectedStyle = null);
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: _selectedStyle == null
                                ? Colors.grey.shade300
                                : Colors.grey.shade400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedStyle == null
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedStyle != null) {
                            widget.onConfirm(_selectedStyle!);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
