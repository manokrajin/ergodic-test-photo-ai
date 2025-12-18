import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../screen/widgets/outfit_selector.dart';

part 'outfit_selector_provider.g.dart';

@riverpod
class OutfitSelectorProvider extends _$OutfitSelectorProvider {
  @override
  OutfitStyle? build() {
    // Start with no selected outfit style
    return null;
  }

  /// Select an outfit style
  void setStyle(OutfitStyle style) {
    state = style;
  }

  /// Clear outfit selection (use original)
  void clearStyle() {
    state = null;
  }

  /// Check if a style is selected
  bool isSelected(OutfitStyle style) {
    return state?.id == style.id;
  }

  /// Get the selected style name
  String get selectedName => state?.name ?? 'Original Outfit';
}
