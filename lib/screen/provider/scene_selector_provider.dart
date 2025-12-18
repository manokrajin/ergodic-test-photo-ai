import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../service/banana_service.dart';

part 'scene_selector_provider.g.dart';

@riverpod
class SceneSelectorProvider extends _$SceneSelectorProvider {
  @override
  TravelScene? build() {
    // Start with no selected scene
    return null;
  }

  /// Select a scene (only one can be selected at a time)
  void selectScene(TravelScene scene) {
    state = scene;
  }

  /// Clear the selected scene
  void clearSelection() {
    state = null;
  }

  /// Check if a scene is selected
  bool isSelected(TravelScene scene) {
    return state == scene;
  }

  /// Check if any scene is selected
  bool get hasSelection => state != null;
}
