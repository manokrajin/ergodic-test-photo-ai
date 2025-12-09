# Banana Service - Travel Scene Generator

Production-ready service for transforming selfies into multiple Instagram-ready travel/lifestyle scenes using AI.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Best Practices](#best-practices)
- [Error Handling](#error-handling)
- [Testing](#testing)

---

## 🎯 Overview

The Banana Service transforms a single selfie into multiple distinct travel/lifestyle scenes suitable for Instagram posting. Each generated image features the subject naturally integrated into different environments (beach, city, mountain, etc.).

### Key Features

✅ **Multiple Scene Generation** - Produces 5+ distinct travel scenes from one photo  
✅ **Instagram Optimization** - 4:5 portrait or 1:1 square format  
✅ **Quality Assurance** - Anti-collage detection and validation  
✅ **Robust Retry Logic** - Automatic retry with corrective feedback  
✅ **Type-Safe Models** - Strongly typed Dart classes  
✅ **Production Ready** - Comprehensive error handling and logging  

---

## 🏗️ Architecture

### Component Structure

```
banana_service.dart
├── Models
│   ├── GeminiImageResponse     - Container for all generated images
│   └── GeneratedImage          - Single image with base64 data
│
├── Configuration
│   └── ImageGenerationConfig   - Service configuration
│
├── Prompt Engineering
│   └── PromptBuilder          - AI prompt construction
│
├── Quality Control
│   ├── CollageDetector        - Detects invalid collage images
│   └── ValidationResult       - Validation outcome
│
└── Core Service
    └── ImageGenerationService - Main orchestration
```

### Data Flow

```
User Input (Selfie)
    ↓
[ImageGenerationService]
    ↓
[Encode to Base64]
    ↓
[Build Prompt] → [PromptBuilder]
    ↓
[Call Cloud Function] → Firebase
    ↓
[Parse Response]
    ↓
[Validate] → [CollageDetector]
    ↓
[Retry if needed] ← [Max 3 attempts]
    ↓
[Return Results]
```

---

## 🚀 Quick Start

### Basic Usage

```dart
import 'dart:io';
import 'package:your_app/service/banana_service.dart';

// Simple usage with default settings
final response = await generateImagesWithGemini(
  File('path/to/selfie.jpg'),
  'Create stunning travel photos',
);

if (response != null && response.hasImages) {
  // Access generated images
  for (var image in response.images) {
    final bytes = image.toUint8List();
    // Display or save the image
  }
}
```

### Advanced Usage with Custom Configuration

```dart
final service = ImageGenerationService(
  config: ImageGenerationConfig(
    expectedCount: 7,        // Generate 7 scenes
    maxAttempts: 5,          // Try up to 5 times
    retryDelayMs: 500,       // 500ms delay between retries
    maxAspectRatio: 2.0,     // Custom collage detection
    minAspectRatio: 0.5,
  ),
);

final response = await service.generateImages(
  File('selfie.jpg'),
  'Transform me into different travel destinations',
);
```

---

## 📚 API Reference

### ImageGenerationService

Main service class for generating travel scenes.

#### Constructor

```dart
ImageGenerationService({
  ImageGenerationConfig? config,
})
```

#### Methods

##### `generateImages(File imageFile, String prompt)`

Generate multiple travel/lifestyle scenes from a selfie.

**Parameters:**
- `imageFile` (File) - Input selfie/portrait photo
- `prompt` (String) - User's creative direction

**Returns:**
- `Future<GeminiImageResponse?>` - Generated scenes or null on failure

**Example:**
```dart
final response = await service.generateImages(
  File('photo.jpg'),
  'Create beach and city scenes',
);
```

---

### GeminiImageResponse

Container for all generated images.

#### Properties

```dart
List<GeneratedImage> images  // All generated images
String? text                 // Optional response text
int count                    // Expected image count
```

#### Getters

```dart
bool hasImages              // Check if any images exist
bool hasExpectedCount       // Check if count matches expectation
```

---

### GeneratedImage

Single generated image with base64 data.

#### Properties

```dart
String data                 // Base64-encoded image bytes
String mimeType            // Image MIME type (e.g., 'image/png')
```

#### Methods

```dart
List<int> toBytes()        // Convert to byte list
Uint8List toUint8List()    // Convert to Uint8List
```

---

### ImageGenerationConfig

Configuration for the generation service.

#### Properties

```dart
int expectedCount          // Number of scenes to generate (default: 5)
int maxAttempts           // Max retry attempts (default: 3)
int retryDelayMs          // Delay between retries (default: 400ms)
double maxAspectRatio     // Max aspect ratio (default: 1.6)
double minAspectRatio     // Min aspect ratio (default: 0.625)
```

#### Constants

```dart
ImageGenerationConfig.defaultConfig  // Default configuration
```

---

### PromptBuilder

Constructs structured AI prompts.

#### Constructor

```dart
PromptBuilder({
  required int imageCount,
  required String userPrompt,
})
```

#### Methods

```dart
String build()                                    // Build complete prompt
String buildRetryNote(int attempt, int received) // Build retry correction
```

---

### CollageDetector

Detects if an image is a collage/grid.

#### Methods

```dart
Future<bool> isLikelyCollage(GeneratedImage image)
```

Analyzes aspect ratio to detect collages. Returns `true` if the image appears to be a multi-photo layout.

---

## ⚙️ Configuration

### Default Configuration

```dart
const ImageGenerationConfig(
  expectedCount: 5,           // Generate 5 distinct scenes
  maxAttempts: 3,            // Retry up to 3 times
  retryDelayMs: 400,         // 400ms between retries
  maxAspectRatio: 1.6,       // Collage detection threshold
  minAspectRatio: 0.625,     // Collage detection threshold
)
```

### Custom Configuration Examples

#### High Quality (More Scenes)

```dart
final config = ImageGenerationConfig(
  expectedCount: 10,         // Generate 10 scenes
  maxAttempts: 5,           // More retry attempts
  retryDelayMs: 600,        // Longer delay for quality
);
```

#### Fast Mode (Fewer Retries)

```dart
final config = ImageGenerationConfig(
  expectedCount: 3,          // Only 3 scenes
  maxAttempts: 2,           // Quick fail
  retryDelayMs: 200,        // Fast retry
);
```

#### Strict Validation

```dart
final config = ImageGenerationConfig(
  maxAspectRatio: 1.4,      // Stricter collage detection
  minAspectRatio: 0.7,
);
```

---

## 💡 Best Practices

### 1. Error Handling

Always check for null responses and handle errors gracefully:

```dart
final response = await service.generateImages(file, prompt);

if (response == null) {
  // Handle generation failure
  print('Failed to generate images');
  return;
}

if (!response.hasImages) {
  // Handle empty response
  print('No images generated');
  return;
}

if (!response.hasExpectedCount) {
  // Handle partial results
  print('Got ${response.images.length} of ${response.count} expected');
}
```

### 2. Resource Management

Dispose of image bytes properly:

```dart
try {
  final bytes = image.toUint8List();
  // Use bytes...
} catch (e) {
  print('Error decoding image: $e');
}
```

### 3. User Feedback

Provide progress updates during generation:

```dart
// Show loading indicator
showLoadingDialog();

final response = await service.generateImages(file, prompt);

// Hide loading
hideLoadingDialog();

if (response != null) {
  showSuccessMessage('Generated ${response.images.length} images!');
} else {
  showErrorMessage('Generation failed. Please try again.');
}
```

### 4. Prompt Optimization

Provide clear, specific prompts:

```dart
// ✅ Good
'Create travel scenes with beach sunset, city cafe, and mountain views'

// ❌ Too vague
'Make it nice'
```

### 5. Image Quality

Use high-quality input images:
- Minimum resolution: 512x512
- Clear, well-lit face
- Good focus
- Minimal blur

---

## 🐛 Error Handling

### Common Errors and Solutions

#### 1. Null Response

**Cause:** Cloud Function failure, network issues, or all retries exhausted

**Solution:**
```dart
if (response == null) {
  // Check internet connection
  // Verify Firebase configuration
  // Check Cloud Function logs
}
```

#### 2. Insufficient Images

**Cause:** AI didn't generate enough scenes

**Solution:**
```dart
if (!response.hasExpectedCount) {
  // Accept partial results or retry manually
  // Adjust expectedCount in config
}
```

#### 3. Collage Detection

**Cause:** AI returned a grid/collage instead of separate images

**Solution:**
- Service automatically retries with corrective prompt
- Adjust `maxAspectRatio` and `minAspectRatio` if needed

#### 4. Format Exception

**Cause:** Invalid JSON response from Cloud Function

**Solution:**
```dart
try {
  final response = await service.generateImages(file, prompt);
} catch (e) {
  if (e is FormatException) {
    print('Invalid response format: $e');
    // Log error for debugging
  }
}
```

---

## 🧪 Testing

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/service/banana_service.dart';

void main() {
  group('PromptBuilder', () {
    test('builds correct prompt structure', () {
      final builder = PromptBuilder(
        imageCount: 5,
        userPrompt: 'Test prompt',
      );
      
      final prompt = builder.build();
      
      expect(prompt, contains('TASK:'));
      expect(prompt, contains('5 completely different'));
      expect(prompt, contains('Test prompt'));
    });
  });

  group('ImageGenerationConfig', () {
    test('uses default values', () {
      const config = ImageGenerationConfig();
      
      expect(config.expectedCount, 5);
      expect(config.maxAttempts, 3);
      expect(config.retryDelayMs, 400);
    });
  });
}
```

### Integration Test Example

```dart
void main() {
  testWidgets('Image generation flow', (tester) async {
    final service = ImageGenerationService();
    final testImage = File('test_assets/selfie.jpg');
    
    final response = await service.generateImages(
      testImage,
      'Create test scenes',
    );
    
    expect(response, isNotNull);
    expect(response!.images, isNotEmpty);
  });
}
```

---

## 📊 Performance Considerations

### Optimization Tips

1. **Image Size:** Compress input images before sending
   ```dart
   final compressed = await compressImage(file, quality: 85);
   ```

2. **Caching:** Cache generated results
   ```dart
   final cacheKey = '${file.path}_${prompt.hashCode}';
   if (cache.containsKey(cacheKey)) {
     return cache[cacheKey];
   }
   ```

3. **Parallel Processing:** Don't block UI
   ```dart
   compute(generateImages, params);
   ```

4. **Timeout Handling:** Add timeouts
   ```dart
   final response = await service
     .generateImages(file, prompt)
     .timeout(Duration(minutes: 2));
   ```

---

## 🔐 Security Notes

1. **API Keys:** Never expose Firebase API keys in client code
2. **Input Validation:** Validate file size and type before processing
3. **Rate Limiting:** Implement client-side rate limiting
4. **Error Messages:** Don't expose internal errors to users

---

## 📝 Changelog

### Version 2.0.0 (Production Ready)
- ✅ Refactored for production use
- ✅ Added comprehensive documentation
- ✅ Improved code organization
- ✅ Enhanced type safety
- ✅ Better error handling

### Version 1.0.0 (Initial)
- Initial implementation
- Basic prompt engineering
- Simple retry logic

---

## 📞 Support

For issues or questions:
1. Check the error logs
2. Review Cloud Function logs in Firebase Console
3. Verify configuration settings
4. Test with different input images

---

## 📄 License

Copyright © 2025 - All rights reserved.

