import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_functions/cloud_functions.dart';

/// Response model for Gemini image generation
class GeminiImageResponse {
  final List<GeneratedImage> images;
  final String? text;
  final int count;

  GeminiImageResponse({required this.images, this.text, required this.count});

  factory GeminiImageResponse.fromJson(Map json) {
    // json may be a Map<Object?, Object?> coming from platform channels; normalize it
    final normalized = Map<String, dynamic>.fromEntries(
      json.entries.map((e) => MapEntry(e.key.toString(), e.value)),
    );

    final imagesList = (normalized['images'] as List<dynamic>?) ?? <dynamic>[];
    final images = imagesList.map<GeneratedImage>((img) {
      if (img is Map<String, dynamic>) return GeneratedImage.fromJson(img);
      if (img is Map) {
        final map = Map<String, dynamic>.fromEntries(
          img.entries.map((e) => MapEntry(e.key.toString(), e.value)),
        );
        return GeneratedImage.fromJson(map);
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
}

/// Model for a single generated image
class GeneratedImage {
  final String data; // base64 string
  final String mimeType;

  GeneratedImage({required this.data, required this.mimeType});

  factory GeneratedImage.fromJson(Map json) {
    // Normalize keys to strings in case map has Object? keys
    final normalized = json is Map<String, dynamic>
        ? json
        : Map<String, dynamic>.fromEntries(
            json.entries.map((e) => MapEntry(e.key.toString(), e.value)),
          );

    final data = normalized['data'] as String?;
    if (data == null)
      throw FormatException('Missing `data` in GeneratedImage JSON');
    final mimeType = normalized['mimeType'] as String? ?? 'image/png';
    return GeneratedImage(data: data, mimeType: mimeType);
  }

  /// Convert base64 to bytes for display
  List<int> toBytes() {
    return base64Decode(data);
  }
}

/// Generate multiple images with Gemini
/// Returns a response containing all generated images
Future<GeminiImageResponse?> generateImagesWithGemini(
  File imageFile,
  String prompt, {
  int expectedCount = 5,
  int maxAttempts = 3,
}) async {
  try {
    // Read image as bytes
    final bytes = await imageFile.readAsBytes();

    // Convert to base64
    final base64Image = base64Encode(bytes);

    // Build an enforced prompt so the AI returns multiple *separate* images (not a collage)
    String _enforcePrompt(String userPrompt, int count) {
      // Keep the user's intent but append a clear instruction for the response format and style
      final buffer = StringBuffer();
      buffer.writeln(
        'You MUST return exactly $count separate images in a JSON object under the top-level key "images".',
      );
      buffer.writeln(
        'Each item in the "images" array must be an object with two fields: "data" (base64-encoded image bytes) and "mimeType" (e.g. "image/png").',
      );
      buffer.writeln('Important formatting rules (must follow exactly):');
      buffer.writeln(
        '- Do NOT return a single image that contains multiple photos tiled together (no collages, sprite sheets, or contact-sheet style images).',
      );
      buffer.writeln(
        '- Each array entry must be a complete, standalone image (full-frame photo).',
      );
      buffer.writeln(
        '- Do NOT include any explanatory text, commentary, or wrapping outside the JSON object. The function expects pure JSON.',
      );
      buffer.writeln(
        '- Images should be portrait or 4:5 crops suitable for Instagram where possible.',
      );
      buffer.writeln(
        '- Visual style: vibrant colors, warm highlights, candid compositions, slight film grain, and natural skin tones. Avoid overlays or multi-photo layouts.',
      );
      buffer.writeln(
        '- Ensure images are visually looks like in travelling, outdoor, or lifestyle photography styles.',
      );
      buffer.writeln();
      buffer.writeln('Example (exact) response format:');
      buffer.writeln('{');
      buffer.writeln('  "images": [');
      for (var i = 0; i < count; i++) {
        buffer.writeln(
          '    {"data": "<base64>", "mimeType": "image/png"}${i < count - 1 ? ',' : ''}',
        );
      }
      buffer.writeln('  ]');
      buffer.writeln('}');
      buffer.writeln();
      buffer.writeln('User instruction:');
      buffer.writeln(userPrompt);
      return buffer.toString();
    }

    String buildRetryNote(int attempt, int got) {
      return '\n\nNOTE: Previous attempt (#$attempt) produced $got image(s). This is invalid — you must return exactly $expectedCount separate images as described. Do NOT return collages or multiple photos inside a single image.';
    }

    final basePrompt = _enforcePrompt(prompt, expectedCount);

    // Prepare the callable
    final callable = FirebaseFunctions.instance.httpsCallable(
      'processImageWithNano',
    );

    // Try up to maxAttempts to get a correctly formatted multi-image response.
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final attemptPrompt = attempt == 1
          ? basePrompt
          : basePrompt + buildRetryNote(attempt - 1, 0);

      print('Calling Cloud Function (attempt $attempt)');
      final result = await callable.call({
        'image': base64Image,
        'prompt': attemptPrompt,
      });

      final raw = result.data;
      print('Cloud Function response received (type: ${raw.runtimeType})');

      try {
        final asMap = raw is Map
            ? Map<String, dynamic>.fromEntries(
                raw.entries.map((e) => MapEntry(e.key.toString(), e.value)),
              )
            : Map<String, dynamic>.fromEntries(
                (Map.from(
                  raw as Map,
                )).entries.map((e) => MapEntry(e.key.toString(), e.value)),
              );

        final response = GeminiImageResponse.fromJson(asMap);

        // If we received a single image, run a lightweight heuristic to detect collages
        // Heuristic: if only one image was returned, decode it and inspect aspect ratio.
        // Very wide or very tall images are more likely to be panorama/collage outputs.
        Future<bool> _isLikelyCollage(GeneratedImage img) async {
          try {
            final bytes = Uint8List.fromList(base64Decode(img.data));
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            final w = frame.image.width.toDouble();
            final h = frame.image.height.toDouble();
            final ratio = w / h;
            // If aspect ratio is extreme, treat as likely collage/panorama.
            if (ratio > 1.6 || ratio < 0.625) return true;
            return false;
          } catch (e) {
            // If decoding fails, don't assume collage; allow normal handling.
            return false;
          }
        }

        // Validation: ensure we received at least expectedCount separate images
        if (response.images.length >= expectedCount) {
          // Good response
          return response;
        }

        // If we only got one image, check for collage-like output and treat as invalid if so
        var got = response.images.length;
        if (got == 1) {
          final likely = await _isLikelyCollage(response.images.first);
          if (likely) {
            print(
              'Single returned image looks like a collage/panorama; forcing retry.',
            );
            got = 0; // force retry path
          }
        }

        // Received fewer images than requested — log and prepare for retry
        print('Received $got images (expected $expectedCount).');

        // If we've reached maxAttempts, return what we have (or null)
        if (attempt == maxAttempts) {
          return response;
        }

        // Otherwise, try a corrective immediate retry with a clear note referencing what we got
        await Future.delayed(const Duration(milliseconds: 400));
        final retryPrompt = basePrompt + buildRetryNote(attempt, got);
        print('Retrying with corrective note.');
        final retryResult = await callable.call({
          'image': base64Image,
          'prompt': retryPrompt,
        });
        final retryRaw = retryResult.data;

        final retryMap = retryRaw is Map
            ? Map<String, dynamic>.fromEntries(
                retryRaw.entries.map(
                  (e) => MapEntry(e.key.toString(), e.value),
                ),
              )
            : Map<String, dynamic>.fromEntries(
                (Map.from(
                  retryRaw as Map,
                )).entries.map((e) => MapEntry(e.key.toString(), e.value)),
              );

        final retryResponse = GeminiImageResponse.fromJson(retryMap);
        if (retryResponse.images.length >= expectedCount) return retryResponse;
        // otherwise, continue loop and attempt again
      } catch (e) {
        print('Failed to parse response on attempt $attempt: $e');
        if (attempt == maxAttempts) return null;
        await Future.delayed(const Duration(milliseconds: 400));
        continue;
      }
    }

    return null;
  } catch (e) {
    print('Error generating images: $e');
    return null;
  }
}
