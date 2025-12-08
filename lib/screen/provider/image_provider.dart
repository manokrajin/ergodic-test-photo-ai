import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_provider.g.dart';

@riverpod
class ImageProvider extends _$ImageProvider {
  @override
  XFile? build() {
    // start with no selected image
    return null;
  }

  void setImage(XFile? file) {
    state = file;
  }

  void clear() {
    state = null;
  }
}
