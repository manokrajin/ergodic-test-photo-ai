import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service/banana_service.dart';

/// A simple provider that exposes the backend function used to send images
/// to the Cloud Function. This makes it easy to override in tests.
typedef BananaServiceFn =
    Future<GeminiImageResponse?> Function(
      File image,
      String prompt, {
      TravelScene? selectedScene,
      String? outfitStyle,
    });

final bananaServiceProvider = Provider<BananaServiceFn>((ref) {
  return (
    File image,
    String prompt, {
    TravelScene? selectedScene,
    String? outfitStyle,
  }) => generateImagesWithGemini(
    image,
    prompt,
    selectedScene: selectedScene,
    outfitStyle: outfitStyle,
  );
});
