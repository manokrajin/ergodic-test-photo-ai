import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_functions/cloud_functions.dart';

// ============================================================================
// MODELS
// ============================================================================

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
  /// Number of distinct travel scenes to generate
  final int expectedCount;

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
    this.maxAttempts = 3,
    this.retryDelayMs = 400,
    this.maxAspectRatio = 1.6,
    this.minAspectRatio = 0.625,
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

  const PromptBuilder({required this.imageCount, required this.userPrompt});

  /// Build the complete prompt with all instructions
  String build() {
    return '''
TASK: Transform this selfie/portrait into $imageCount completely different travel and lifestyle scenes.

CRITICAL REQUIREMENTS:
1. You MUST return exactly $imageCount separate images in a JSON object under the top-level key "images".
2. Each item in the "images" array must be an object with two fields: "data" (base64-encoded image bytes) and "mimeType" (e.g. "image/png").
3. Do NOT return a single image with multiple photos tiled together (no collages, grids, or sprite sheets).
4. Each array entry must be a complete, standalone scene (full-frame photo).
5. Do NOT include any text, commentary, or wrapping outside the JSON object.

SCENE VARIETY (Each image must be DIFFERENT):
- Beach vacation scene (tropical vibes, sunset, ocean background)
- City exploration scene (urban streets, cafes, architecture)
- Mountain/nature adventure scene (hiking, scenic overlooks, forests)
- Road trip scene (desert, countryside, vintage car vibes)
- Cultural/local experience scene (markets, temples, local spots)
- Nightlife/urban evening scene (city lights, rooftop, evening vibes)
- Cozy cafe/lifestyle scene (coffee shop, bookstore, aesthetic interior)

INSTAGRAM-READY SPECIFICATIONS:
- Format: Portrait orientation (4:5 ratio) or square (1:1) - Instagram optimized
- Style: Warm, vibrant colors with slight film grain for authenticity
- Lighting: Natural, golden hour lighting where appropriate
- Composition: Subject (person from input) naturally integrated into each scene
- Aesthetic: Travel influencer / lifestyle blogger quality
- Keep the person's face, features, and clothing style consistent across all scenes
- Make it look like genuine travel photos taken with a phone camera
- Add realistic depth, blur backgrounds naturally, enhance colors tastefully

EXAMPLE JSON FORMAT (exact structure required):
{
  "images": [
${_buildExampleImages()}
  ]
}

USER'S CREATIVE DIRECTION:
$userPrompt

REMEMBER: Create $imageCount DISTINCT travel/lifestyle scenes. Each must be a separate, standalone image suitable for Instagram posting.
''';
  }

  /// Build retry correction note
  String buildRetryNote(int attemptNumber, int receivedCount) {
    return '''

⚠️ RETRY CORRECTION (Attempt #$attemptNumber):
Previous attempt produced only $receivedCount image(s), but you MUST return exactly $imageCount separate travel/lifestyle scenes.

REMINDER:
- Each scene must be COMPLETELY DIFFERENT (beach, city, mountain, road trip, etc.)
- Do NOT return a collage or grid layout
- Each image must be a standalone, full-frame photo
- Create $imageCount distinct Instagram-ready travel photos''';
  }

  /// Build example JSON images array
  String _buildExampleImages() {
    final examples = <String>[];
    for (var i = 0; i < imageCount; i++) {
      final comma = i < imageCount - 1 ? ',' : '';
      examples.add(
        '    {"data": "<base64_encoded_image_bytes>", "mimeType": "image/png"}$comma',
      );
    }
    return examples.join('\n');
  }
}

// ============================================================================
// COLLAGE DETECTOR
// ============================================================================

/// Detects if a generated image is likely a collage/grid instead of a single scene
class CollageDetector {
  final ImageGenerationConfig config;

  const CollageDetector(this.config);

  /// Check if image has suspicious aspect ratio indicating a collage
  Future<bool> isLikelyCollage(GeneratedImage image) async {
    try {
      final bytes = image.toUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      final width = frame.image.width.toDouble();
      final height = frame.image.height.toDouble();
      final aspectRatio = width / height;

      // Extreme aspect ratios suggest panorama/collage layout
      final isCollage =
          aspectRatio > config.maxAspectRatio ||
          aspectRatio < config.minAspectRatio;

      if (isCollage) {
        developer.log(
          'Collage detected: aspect ratio $aspectRatio (width: $width, height: $height)',
          name: 'CollageDetector',
        );
      }

      return isCollage;
    } catch (e) {
      developer.log(
        'Error detecting collage: $e',
        name: 'CollageDetector',
        error: e,
      );
      // If decoding fails, assume it's not a collage
      return false;
    }
  }
}

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
  final CollageDetector _collageDetector;

  ImageGenerationService({ImageGenerationConfig? config})
    : config = config ?? ImageGenerationConfig.defaultConfig,
      _collageDetector = CollageDetector(
        config ?? ImageGenerationConfig.defaultConfig,
      );

  /// Generate multiple travel/lifestyle scene images from a single selfie
  ///
  /// [imageFile] - The input selfie/portrait photo
  /// [prompt] - User's creative direction for the generation
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
  /// );
  /// ```
  Future<GeminiImageResponse?> generateImages(
    File imageFile,
    String prompt,
  ) async {
    try {
      // Prepare image data
      final base64Image = await _encodeImageToBase64(imageFile);

      // Build prompt
      final promptBuilder = PromptBuilder(
        imageCount: config.expectedCount,
        userPrompt: prompt,
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

        // If last attempt, return what we have
        if (attempt == config.maxAttempts) {
          developer.log(
            'Max attempts reached, returning partial results',
            name: 'ImageGenerationService',
            level: 900,
          );
          return response;
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
  Future<ValidationResult> _validateResponse(
    GeminiImageResponse response,
  ) async {
    // Check if we have enough images
    if (response.images.length >= config.expectedCount) {
      return ValidationResult.valid();
    }

    // If we only got one image, check if it's a collage
    if (response.images.length == 1) {
      final isCollage = await _collageDetector.isLikelyCollage(
        response.images.first,
      );

      if (isCollage) {
        return ValidationResult.invalid(
          'Single image appears to be a collage/panorama',
        );
      }
    }

    return ValidationResult.invalid(
      'Insufficient images (got ${response.images.length}, expected ${config.expectedCount})',
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
/// [maxAttempts] - Maximum retry attempts (default: 3)
///
/// Returns a [GeminiImageResponse] containing all generated scenes,
/// or null if generation fails.
Future<GeminiImageResponse?> generateImagesWithGemini(
  File imageFile,
  String prompt, {
  int expectedCount = 5,
  int maxAttempts = 3,
}) async {
  final service = ImageGenerationService(
    config: ImageGenerationConfig(
      expectedCount: expectedCount,
      maxAttempts: maxAttempts,
    ),
  );

  return await service.generateImages(imageFile, prompt);
}
