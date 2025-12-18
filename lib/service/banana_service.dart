import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

// ============================================================================
// MODELS
// ============================================================================

/// Model representing a travel/lifestyle scene type for preselection
class TravelScene {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String systemPrompt;

  const TravelScene({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.systemPrompt,
  });

  /// Get all available scenes
  static const List<TravelScene> allScenes = [
    TravelScene(
      id: 'beach',
      name: 'Beach Vacation',
      description: 'Tropical vibes with ocean and sunset',
      emoji: '🏖️',
      systemPrompt:
          'Create a stunning beach vacation scene with tropical vibes, golden hour lighting, and ocean background',
    ),
    TravelScene(
      id: 'city',
      name: 'City Exploration',
      description: 'Urban streets, cafes, and architecture',
      emoji: '🏙️',
      systemPrompt:
          'Generate a vibrant city exploration scene with urban streets, cafes, modern architecture, and city lights',
    ),
    TravelScene(
      id: 'mountain',
      name: 'Mountain Adventure',
      description: 'Hiking, scenic overlooks, and forests',
      emoji: '⛰️',
      systemPrompt:
          'Create an epic mountain adventure scene with hiking trails, scenic overlooks, misty peaks, and forest landscapes',
    ),
    TravelScene(
      id: 'roadtrip',
      name: 'Road Trip',
      description: 'Desert, countryside, and vintage car vibes',
      emoji: '🛣️',
      systemPrompt:
          'Generate a classic road trip scene with desert landscapes, countryside views, vintage vehicle vibes, and open roads',
    ),
    TravelScene(
      id: 'cultural',
      name: 'Cultural Experience',
      description: 'Markets, temples, and local spots',
      emoji: '🏛️',
      systemPrompt:
          'Create an immersive cultural experience scene featuring local markets, temples, traditional architecture, and authentic local vibes',
    ),
    TravelScene(
      id: 'nightlife',
      name: 'Nightlife & Evening',
      description: 'City lights, rooftop, and evening vibes',
      emoji: '🌃',
      systemPrompt:
          'Generate a sophisticated nightlife scene with city lights, rooftop settings, neon signs, and vibrant evening atmosphere',
    ),
    TravelScene(
      id: 'cafe',
      name: 'Cozy Cafe Lifestyle',
      description: 'Coffee shop, bookstore, and aesthetic interior',
      emoji: '☕',
      systemPrompt:
          'Create a cozy lifestyle scene in a charming cafe or bookstore with aesthetic interior, warm lighting, and relaxed ambiance',
    ),
  ];
}

/// Response model containing multiple generated travel/lifestyle scene images
class GeminiImageResponse {
  final List<GeneratedImage> images;
  final String? text;
  final int count;

  GeminiImageResponse({required this.images, this.text, required this.count});

  factory GeminiImageResponse.fromJson(Map<dynamic, dynamic> json) {
    // Normalize map keys to strings for safety
    final normalized = _normalizeMap(json);

    final imagesList = (normalized['images'] as List<dynamic>?) ?? <dynamic>[];
    final images = imagesList.map<GeneratedImage>((img) {
      if (img is Map<String, dynamic>) {
        return GeneratedImage.fromJson(img);
      }
      if (img is Map) {
        return GeneratedImage.fromJson(_normalizeMap(img));
      }
      throw FormatException('Invalid image entry type: ${img.runtimeType}');
    }).toList();

    final text = normalized['text'] as String?;
    final rawCount = normalized['count'];
    final count = rawCount is int
        ? rawCount
        : int.tryParse(rawCount?.toString() ?? '') ?? images.length;

    return GeminiImageResponse(images: images, text: text, count: count);
  }

  /// Helper to normalize map keys to strings
  static Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> map) {
    return Map<String, dynamic>.fromEntries(
      map.entries.map((e) => MapEntry(e.key.toString(), e.value)),
    );
  }

  bool get hasImages => images.isNotEmpty;
  bool get hasExpectedCount => images.length >= count;
}

/// Model for a single generated image with base64 data
class GeneratedImage {
  final String data; // base64-encoded image bytes
  final String mimeType;

  GeneratedImage({required this.data, required this.mimeType});

  factory GeneratedImage.fromJson(Map<dynamic, dynamic> json) {
    final normalized = json is Map<String, dynamic>
        ? json
        : GeminiImageResponse._normalizeMap(json);

    final data = normalized['data'] as String?;
    if (data == null || data.isEmpty) {
      throw FormatException('Missing or empty `data` in GeneratedImage JSON');
    }

    final mimeType = normalized['mimeType'] as String? ?? 'image/png';
    return GeneratedImage(data: data, mimeType: mimeType);
  }

  /// Convert base64 string to bytes for image rendering
  List<int> toBytes() => base64Decode(data);

  /// Get decoded bytes as Uint8List
  Uint8List toUint8List() => Uint8List.fromList(toBytes());
}

// ============================================================================
// CONFIGURATION
// ============================================================================

/// Configuration for image generation service
class ImageGenerationConfig {
  /// Number of distinct travel scenes to generate (preferred)
  final int expectedCount;

  /// Minimum acceptable number of images to consider the response usable
  /// (e.g. at least 2 images is considered "multiple")
  final int minAcceptableCount;

  /// Maximum retry attempts if generation fails
  final int maxAttempts;

  /// Delay between retry attempts in milliseconds
  final int retryDelayMs;

  /// Aspect ratio threshold for collage detection
  /// Images with ratio > maxAspect or < minAspect are considered collages
  final double maxAspectRatio;
  final double minAspectRatio;

  const ImageGenerationConfig({
    this.expectedCount = 5,
    this.minAcceptableCount = 2,
    // Reduce default attempts to keep generation fast for UX
    this.maxAttempts = 3,
    this.retryDelayMs = 300,
    this.maxAspectRatio = 1.4,
    this.minAspectRatio = 0.71,
  });

  static const defaultConfig = ImageGenerationConfig();
}

// ============================================================================
// PROMPT BUILDER
// ============================================================================

/// Builds structured prompts for AI image generation
class PromptBuilder {
  final int imageCount;
  final String userPrompt;
  final TravelScene? selectedScene;
  final String? outfitStyle;

  const PromptBuilder({
    required this.imageCount,
    required this.userPrompt,
    this.selectedScene,
    this.outfitStyle,
  });

  /// Build instruction text for selected scene
  String _buildSceneInstruction() {
    if (selectedScene == null) {
      return '''SCENE VARIETY (aim for different scenes across the set):
- Beach vacation scene (tropical vibes, sunset, ocean background)
- City exploration scene (urban streets, cafes, architecture)
- Mountain/nature adventure scene (hiking, scenic overlooks, forests)
- Road trip scene (desert, countryside, vintage car vibes)
- Cultural/local experience scene (markets, temples, local spots)
- Nightlife/urban evening scene (city lights, rooftop, evening vibes)
- Cozy cafe/lifestyle scene (coffee shop, bookstore, aesthetic interior)''';
    }

    return '''PRIMARY SCENE (generate images matching this theme):
${selectedScene!.name}: ${selectedScene!.description}

Focus all generated images on this theme and style description.''';
  }

  /// Build instruction text for outfit styling
  String _buildOutfitInstruction() {
    if (outfitStyle == null || outfitStyle!.isEmpty) {
      return 'OUTFIT: Keep the person\'s original outfit and clothing from the input photo.';
    }

    final outfitGuides = {
      'casual':
          'OUTFIT: Dress in casual, comfortable everyday wear - t-shirts, jeans, sneakers, hoodies. Keep it relaxed and approachable.',
      'formal':
          'OUTFIT: Dress in formal professional attire - suits, dress shirts, ties, formal dresses, blazers. Professional and elegant.',
      'sporty':
          'OUTFIT: Wear athletic and sports clothing - gym wear, sports jerseys, sneakers, athletic leggings. Active and energetic style.',
      'beach':
          'OUTFIT: Wear beach and summer clothing - swimwear, beach cover-ups, light summer dresses, flip-flops. Resort-ready style.',
      'elegant':
          'OUTFIT: Wear glamorous evening wear - gowns, tuxedos, elegant dresses, high heels. Sophisticated and formal.',
      'streetstyle':
          'OUTFIT: Wear trendy street style fashion - layered outfits, fashionable accessories, modern urban wear. Stylish and contemporary.',
      'bohemian':
          'OUTFIT: Wear bohemian style - flowing clothes, earthy colors, artistic accessories, relaxed silhouettes. Free-spirited and artistic.',
      'keeporiginal':
          'OUTFIT: Keep the person\'s original outfit and clothing from the input photo.',
    };

    return outfitGuides[outfitStyle] ??
        'OUTFIT: Keep the person\'s original outfit and clothing from the input photo.';
  }

  /// Build the complete prompt with all instructions
  /// MANDATORY: Requires multiple (2+) images. Single images will trigger retry.
  String build() {
    final sceneInstruction = _buildSceneInstruction();
    final outfitInstruction = _buildOutfitInstruction();

    return '''
TASK: Transform this selfie/portrait into $imageCount different travel and lifestyle scenes. MANDATORY: Return AT LEAST 2 COMPLETELY SEPARATE images.

⚠️ CRITICAL REQUIREMENTS - READ CAREFULLY:
1. MUST generate and return AT LEAST 2 images minimum.
2. Each image must be a SEPARATE, COMPLETE, FULL-FRAME photo.
3. NO collages, grids, or multi-photo tiled layouts WHATSOEVER.
4. NO split images, side-by-side arrangements, or photo grids.
5. Each image shows the person in a different scene/outfit/location.
6. Images must be visually distinct from each other.

🚫 WHAT NOT TO DO:
- Do NOT create one large image with multiple photos arranged side-by-side
- Do NOT create a grid of photos (2x2, 3x1, 1x3, etc)
- Do NOT crop/tile multiple scenes into a single image
- Do NOT create panoramic or split-layout images
- Do NOT use unusual aspect ratios that suggest collaging

✅ WHAT TO DO:
- Generate each image as a complete, standalone photo
- Each image should fill the entire frame (100% width and height)
- Each image represents one complete scene
- Return array of separately generated full-frame images

TECHNICAL JSON FORMAT:
Return ONLY a JSON object (no extra text):
{
  "images": [
    {"data": "<base64_image_1>", "mimeType": "image/png"},
    {"data": "<base64_image_2>", "mimeType": "image/png"},
    {"data": "<base64_image_3>", "mimeType": "image/png"}
  ]
}

IMPORTANT:
- The "images" array MUST contain at least 2 entries.
- Each array entry is a COMPLETE, FULL-FRAME image, not a part of an image.
- Do NOT include any text before or after the JSON object.
- Return ONLY the JSON object.

$sceneInstruction

$outfitInstruction

INSTAGRAM-READY SPECIFICATIONS FOR EACH IMAGE:
- Format: Portrait orientation (4:5 ratio) or square (1:1) - Instagram optimized
- Style: Warm, vibrant colors with slight film grain for authenticity
- Lighting: Natural, golden hour lighting where appropriate
- Composition: Subject (person from input) naturally integrated into each scene
- Aesthetic: Travel influencer / lifestyle blogger quality
- Keep the person's face, features, and clothing style consistent
- Make it look like genuine travel photos taken with a phone camera
- Add realistic depth, blur backgrounds naturally, enhance colors tastefully

EXAMPLE OF CORRECT OUTPUT - 3 SEPARATE FULL-FRAME IMAGES:
{
  "images": [
    {"data": "<base64_of_complete_beach_photo>", "mimeType": "image/png"},
    {"data": "<base64_of_complete_city_photo>", "mimeType": "image/png"},
    {"data": "<base64_of_complete_mountain_photo>", "mimeType": "image/png"}
  ]
}

USER'S CREATIVE DIRECTION:
$userPrompt

FINAL REMINDER:
✓ You MUST return at least 2 images
✓ You CAN return up to $imageCount images
✓ Aim for $imageCount if possible
✓ But NEVER return just 1 image
✓ NEVER return collages, grids, or split images
✓ Return any valid multiple (2+) rather than failing

''';
  }

  /// Build retry correction note — explicitly demands multiple distinct images
  String buildRetryNote(int attemptNumber, int receivedCount) {
    return '''

⚠️ CRITICAL RETRY (Attempt #$attemptNumber):
You returned only $receivedCount image(s). This is NOT acceptable.

MUST HAVE: Generate AT LEAST 2 COMPLETELY SEPARATE AND DISTINCT images.
DO NOT return just 1 image. DO NOT return a collage or grid.

CRITICAL: NO COLLAGES, GRIDS, OR SPLIT IMAGES!
- ❌ WRONG: 2-3 photos arranged side-by-side in one image
- ❌ WRONG: Grid layout with multiple photos
- ❌ WRONG: Split/tiled photos in a single frame
- ✅ RIGHT: Image 1 (complete full-frame photo), Image 2 (complete full-frame photo), Image 3 (complete full-frame photo)

Each image MUST be:
✓ A separate, complete, full-frame photo
✓ Fully independent scene - standalone image
✓ Different from other images
✓ Full-width and full-height (entire image space for one scene only)
✓ NO cropping together with other photos

If you're struggling, ensure each image file is independently valid and complete.

Now generate again with AT LEAST 2 completely separate, full-frame images 
''';
  }
}

// ============================================================================
// COLLAGE DETECTOR
// ============================================================================

/// Detects if a generated image is likely a collage/grid instead of a single scene
// class CollageDetector {
//   final ImageGenerationConfig config;
//
//   const CollageDetector(this.config);
//
//   /// Check if image has suspicious aspect ratio indicating a collage
//   Future<bool> isLikelyCollage(GeneratedImage image) async {
//     try {
//       final bytes = image.toUint8List();
//       final codec = await ui.instantiateImageCodec(bytes);
//       final frame = await codec.getNextFrame();
//
//       final width = frame.image.width.toDouble();
//       final height = frame.image.height.toDouble();
//       final aspectRatio = width / height;
//
//       // Extreme aspect ratios suggest panorama/collage layout
//       final isCollage =
//           aspectRatio > config.maxAspectRatio ||
//           aspectRatio < config.minAspectRatio;
//
//       if (isCollage) {
//         developer.log(
//           'COLLAGE DETECTED: aspect ratio $aspectRatio (${aspectRatio > config.maxAspectRatio ? 'too wide' : 'too tall'}) | dimensions: ${width.toInt()}x${height.toInt()} | threshold: ${config.minAspectRatio}-${config.maxAspectRatio}',
//           name: 'CollageDetector',
//         );
//       } else {
//         developer.log(
//           'Image valid: aspect ratio $aspectRatio | dimensions: ${width.toInt()}x${height.toInt()}',
//           name: 'CollageDetector',
//         );
//       }
//
//       return isCollage;
//     } catch (e) {
//       developer.log(
//         'Error detecting collage: $e',
//         name: 'CollageDetector',
//         error: e,
//       );
//       // If decoding fails, assume it's not a collage
//       return false;
//     }
//   }
// }

// ============================================================================
// IMAGE GENERATION SERVICE
// ============================================================================

/// Service for transforming selfies into multiple travel/lifestyle scenes
///
/// This service uses AI to generate Instagram-ready images with different
/// backgrounds such as beach vacations, city explorations, mountain adventures,
/// road trips, and more.
///
/// Each generated image is a complete, standalone scene with the person from
/// the input photo naturally integrated into the environment.
class ImageGenerationService {
  final ImageGenerationConfig config;
  // final CollageDetector _collageDetector;

  ImageGenerationService({ImageGenerationConfig? config})
    : config = config ?? ImageGenerationConfig.defaultConfig;
  // _collageDetector = CollageDetector(
  //   config ?? ImageGenerationConfig.defaultConfig,
  // );

  /// Generate multiple travel/lifestyle scene images from a single selfie
  ///
  /// [imageFile] - The input selfie/portrait photo
  /// [prompt] - User's creative direction for the generation
  /// [selectedScene] - Preselected travel scene to focus on (optional)
  /// [outfitStyle] - Preferred outfit style for the person (optional)
  ///
  /// Returns a [GeminiImageResponse] containing all generated scenes,
  /// or null if generation fails after all retry attempts.
  ///
  /// Example:
  /// ```dart
  /// final service = ImageGenerationService();
  /// final response = await service.generateImages(
  ///   File('selfie.jpg'),
  ///   'Create stunning travel photos',
  ///   selectedScene: TravelScene.allScenes[0],
  ///   outfitStyle: 'casual',
  /// );
  /// ```
  Future<GeminiImageResponse?> generateImages(
    File imageFile,
    String prompt, {
    TravelScene? selectedScene,
    String? outfitStyle,
  }) async {
    try {
      // Prepare image data
      final base64Image = await _encodeImageToBase64(imageFile);

      // Build prompt with selected scene and outfit style
      final promptBuilder = PromptBuilder(
        imageCount: config.expectedCount,
        userPrompt: prompt,
        selectedScene: selectedScene,
        outfitStyle: outfitStyle,
      );

      // Get Cloud Function callable
      final callable = _getCloudFunctionCallable();

      // Attempt generation with retries
      return await _generateWithRetries(
        callable: callable,
        base64Image: base64Image,
        promptBuilder: promptBuilder,
      );
    } catch (e) {
      developer.log(
        'Error in generateImages',
        name: 'ImageGenerationService',
        error: e,
      );
      return null;
    }
  }

  /// Encode image file to base64 string
  Future<String> _encodeImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Get Firebase Cloud Function callable
  HttpsCallable _getCloudFunctionCallable() {
    return FirebaseFunctions.instance.httpsCallable('processImageWithNano');
  }

  /// Generate images with retry logic
  Future<GeminiImageResponse?> _generateWithRetries({
    required HttpsCallable callable,
    required String base64Image,
    required PromptBuilder promptBuilder,
  }) async {
    final basePrompt = promptBuilder.build();

    for (var attempt = 1; attempt <= config.maxAttempts; attempt++) {
      developer.log(
        'Generation attempt $attempt/${config.maxAttempts}',
        name: 'ImageGenerationService',
      );

      try {
        // Build prompt for this attempt (add retry note if needed)
        final prompt = attempt == 1
            ? basePrompt
            : basePrompt + promptBuilder.buildRetryNote(attempt - 1, 0);

        // Call Cloud Function
        final response = await _callCloudFunction(
          callable: callable,
          base64Image: base64Image,
          prompt: prompt,
        );

        if (response == null) {
          developer.log(
            'Attempt $attempt: Failed to parse response',
            name: 'ImageGenerationService',
            level: 900,
          );
          await _delayBeforeRetry();
          continue;
        }

        // Validate response
        final validation = await _validateResponse(response);

        if (validation.isValid) {
          developer.log(
            'Generation successful: ${response.images.length} images',
            name: 'ImageGenerationService',
          );
          return response;
        }

        developer.log(
          'Attempt $attempt: ${validation.reason} (got ${response.images.length}, expected ${config.expectedCount})',
          name: 'ImageGenerationService',
          level: 900,
        );

        // If last attempt, don't return collages/partial results
        if (attempt == config.maxAttempts) {
          developer.log(
            'Max attempts reached. Validation failed, returning null instead of partial/collage results',
            name: 'ImageGenerationService',
            level: 900,
          );
          return null;
        }

        // Retry with corrective note
        await _delayBeforeRetry();
        final retryResponse = await _retryWithCorrection(
          callable: callable,
          base64Image: base64Image,
          basePrompt: basePrompt,
          promptBuilder: promptBuilder,
          attemptNumber: attempt,
          receivedCount: response.images.length,
        );

        if (retryResponse != null) {
          final retryValidation = await _validateResponse(retryResponse);
          if (retryValidation.isValid) {
            developer.log(
              'Retry successful: ${retryResponse.images.length} images',
              name: 'ImageGenerationService',
            );
            return retryResponse;
          }
        }
      } catch (e) {
        developer.log(
          'Attempt $attempt failed',
          name: 'ImageGenerationService',
          error: e,
          level: 1000,
        );
        if (attempt == config.maxAttempts) {
          return null;
        }
        await _delayBeforeRetry();
      }
    }

    developer.log(
      'All attempts exhausted',
      name: 'ImageGenerationService',
      level: 1000,
    );
    return null;
  }

  /// Call Cloud Function to generate images
  Future<GeminiImageResponse?> _callCloudFunction({
    required HttpsCallable callable,
    required String base64Image,
    required String prompt,
  }) async {
    try {
      final result = await callable.call({
        'image': base64Image,
        'prompt': prompt,
      });

      final rawData = result.data;
      developer.log(
        'Response received (type: ${rawData.runtimeType})',
        name: 'ImageGenerationService',
      );

      // Parse response
      final map = rawData is Map<String, dynamic>
          ? rawData
          : GeminiImageResponse._normalizeMap(rawData as Map);

      return GeminiImageResponse.fromJson(map);
    } catch (e) {
      developer.log(
        'Error calling Cloud Function',
        name: 'ImageGenerationService',
        error: e,
        level: 1000,
      );
      return null;
    }
  }

  /// Retry generation with corrective note
  Future<GeminiImageResponse?> _retryWithCorrection({
    required HttpsCallable callable,
    required String base64Image,
    required String basePrompt,
    required PromptBuilder promptBuilder,
    required int attemptNumber,
    required int receivedCount,
  }) async {
    developer.log(
      'Immediate retry with corrective feedback',
      name: 'ImageGenerationService',
    );

    final retryPrompt =
        basePrompt + promptBuilder.buildRetryNote(attemptNumber, receivedCount);

    return await _callCloudFunction(
      callable: callable,
      base64Image: base64Image,
      prompt: retryPrompt,
    );
  }

  /// Validate generated response
  /// Enforces minimum of 2 images, filters out collages, ensures separation
  /// If only 1 image, always reject and request retry
  /// If any images are detected as collages, they are removed from the response
  Future<ValidationResult> _validateResponse(
    GeminiImageResponse response,
  ) async {
    // STRICT: Reject any single image (collage or not)
    // This forces the AI to generate multiple distinct images
    if (response.images.length == 1) {
      developer.log(
        'Single image detected - will trigger retry for multiple images',
        name: 'ValidationResult',
        level: 800,
      );
      return ValidationResult.invalid(
        'Only 1 image returned. MUST return at least 2 distinct, separate images.',
      );
    }

    // Validate each image to ensure none are collages
    final validImages = <GeneratedImage>[];
    for (var i = 0; i < response.images.length; i++) {
      final image = response.images[i];
      // final isCollage = await _collageDetector.isLikelyCollage(image);

      // if (!isCollage) {
      //   developer.log(
      //     'Image ${i + 1} detected as collage - filtering out',
      //     name: 'ValidationResult',
      //     level: 800,
      //   );
      // } else {
      validImages.add(image);
      // }
    }

    // After filtering collages, check if we still have enough images
    if (validImages.isEmpty) {
      return ValidationResult.invalid(
        'All ${response.images.length} images were detected as collages. Requesting separate images.',
      );
    }

    if (validImages.length == 1) {
      return ValidationResult.invalid(
        'Only 1 valid image remained after filtering collages. MUST return at least 2 separate images.',
      );
    }

    // Accept responses that contain at least the minimum acceptable number of valid images
    if (validImages.length >= config.minAcceptableCount) {
      // Update response to only contain valid images
      response.images.clear();
      response.images.addAll(validImages);
      return ValidationResult.valid();
    }

    return ValidationResult.invalid(
      'Insufficient valid images (got ${validImages.length} after filtering, minimum ${config.minAcceptableCount})',
    );
  }

  /// Delay before retry attempt
  Future<void> _delayBeforeRetry() async {
    await Future.delayed(Duration(milliseconds: config.retryDelayMs));
  }
}

/// Result of response validation
class ValidationResult {
  final bool isValid;
  final String? reason;

  const ValidationResult._({required this.isValid, this.reason});

  factory ValidationResult.valid() => const ValidationResult._(isValid: true);

  factory ValidationResult.invalid(String reason) =>
      ValidationResult._(isValid: false, reason: reason);
}

// ============================================================================
// CONVENIENCE FUNCTION (Legacy API compatibility)
// ============================================================================

/// Generate multiple travel/lifestyle scene images from a single selfie
///
/// This is a convenience function that creates a service instance and
/// generates images. For more control, use [ImageGenerationService] directly.
///
/// [imageFile] - The input selfie/portrait photo
/// [prompt] - User's creative direction for the generation
/// [expectedCount] - Number of distinct scenes to generate (default: 5)
/// [maxAttempts] - Maximum retry attempts (default: 2)
/// [selectedScene] - Preselected travel scene to focus on (optional)
/// [outfitStyle] - Preferred outfit style for the person (optional)
///
/// Returns a [GeminiImageResponse] containing all generated scenes,
/// or null if generation fails.
Future<GeminiImageResponse?> generateImagesWithGemini(
  File imageFile,
  String prompt, {
  int expectedCount = 5,
  int maxAttempts = 2,
  TravelScene? selectedScene,
  String? outfitStyle,
}) async {
  final service = ImageGenerationService(
    config: ImageGenerationConfig(
      expectedCount: expectedCount,
      maxAttempts: maxAttempts,
    ),
  );

  return await service.generateImages(
    imageFile,
    prompt,
    selectedScene: selectedScene,
    outfitStyle: outfitStyle,
  );
}
