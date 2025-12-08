import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../service/banana_service.dart';
import 'banana_service_provider.dart';

part 'generated_images_provider.g.dart';

@riverpod
class GeneratedImages extends _$GeneratedImages {
  @override
  Future<GeminiImageResponse?> build() async {
    // initial state: no generated images
    return null;
  }

  /// Generate images using the Banana/Gemini backend
  Future<void> generate(File imageFile, String prompt) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(bananaServiceProvider);
      final resp = await service(imageFile, prompt);
      state = AsyncValue.data(resp);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
