# Technical Reference: Collage Prevention System

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     ImageGenerationService                       │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  generateImages(imageFile, prompt, ...)                   │ │
│  │  → Orchestrates entire generation and validation flow     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  _generateWithRetries()                                    │ │
│  │  → Handles retries with corrective feedback               │ │
│  │  → Calls collage validation before returning              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  _validateResponse(response)                              │ │
│  │  → Checks minimum image count                             │ │
│  │  → Filters collages via CollageDetector                   │ │
│  │  → Ensures valid image count after filtering              │ │
│  │  → Returns ValidationResult or triggers retry             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  CollageDetector.isLikelyCollage(image)                   │ │
│  │  → Decodes image bytes                                    │ │
│  │  → Calculates aspect ratio                                │ │
│  │  → Compares against thresholds                            │ │
│  │  → Returns true/false + logs details                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Return filtered GeminiImageResponse or Retry             │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Flow Diagram: Generation and Validation

```
START: generateImages()
   ↓
[Encode image to Base64]
   ↓
[Build Prompt with scenes/outfit]
   ↓
[Get Cloud Function callable]
   ↓
[Start retry loop] ← attempts = 1 to maxAttempts
   ├─ [Call Cloud Function]
   │  ↓
   │  [Parse JSON response]
   │  ↓
   │  [Call _validateResponse()]
   │  ├─ Check: images.length == 1?
   │  │  └─ YES → Invalid (force multiple)
   │  │
   │  ├─ FOR EACH image:
   │  │  ├─ [Call isLikelyCollage()]
   │  │  │  ├─ Decode image
   │  │  │  ├─ Calculate aspectRatio
   │  │  │  ├─ Check: ratio > 1.6?
   │  │  │  ├─ Check: ratio < 0.625?
   │  │  │  └─ Return true/false
   │  │  │
   │  │  └─ If collage: Filter out, Log message
   │  │     If valid: Keep in validImages list
   │  │
   │  ├─ Check: validImages.isEmpty?
   │  │  └─ YES → Invalid (all collages)
   │  │
   │  ├─ Check: validImages.length == 1?
   │  │  └─ YES → Invalid (need 2+ after filtering)
   │  │
   │  └─ Check: validImages.length >= minAcceptableCount?
   │     ├─ YES → Valid! Update response, return valid
   │     └─ NO → Invalid (insufficient after filtering)
   │
   ├─ Is validation result valid?
   │  ├─ YES → Return response to user ✅
   │  └─ NO → Continue to next attempt
   │
   └─ Is this the last attempt?
      ├─ NO → Add retry note to prompt, retry
      └─ YES → Return null (all attempts exhausted)

END
```

## Code Flow: Validation Method

```dart
_validateResponse(GeminiImageResponse response)
{
  // Check 1: Single image rejection
  if (response.images.length == 1) {
    return ValidationResult.invalid(
      'Only 1 image returned. MUST return at least 2 distinct, separate images.'
    )
  }

  // Check 2: Collage filtering
  validImages = []
  for each image in response.images {
    isCollage = await _collageDetector.isLikelyCollage(image)
    if (isCollage) {
      log("Image ${index} detected as collage - filtering out")
    } else {
      validImages.add(image)
    }
  }

  // Check 3: Empty after filtering
  if (validImages.isEmpty) {
    return ValidationResult.invalid(
      'All images were detected as collages. Requesting separate images.'
    )
  }

  // Check 4: Only one valid image
  if (validImages.length == 1) {
    return ValidationResult.invalid(
      'Only 1 valid image remained after filtering collages. MUST return at least 2.'
    )
  }

  // Check 5: Minimum acceptable count
  if (validImages.length >= config.minAcceptableCount) {
    response.images = validImages  // Replace with valid only
    return ValidationResult.valid()
  }

  return ValidationResult.invalid(
    'Insufficient valid images (got ${validImages.length}, minimum ${config.minAcceptableCount})'
  )
}
```

## Collage Detection Logic

```dart
isLikelyCollage(GeneratedImage image): bool
{
  try {
    // Step 1: Decode image bytes to get dimensions
    bytes = image.toUint8List()
    codec = ui.instantiateImageCodec(bytes)
    frame = codec.getNextFrame()
    
    // Step 2: Extract dimensions
    width = frame.image.width.toDouble()
    height = frame.image.height.toDouble()
    
    // Step 3: Calculate aspect ratio
    aspectRatio = width / height
    
    // Step 4: Check against thresholds
    isCollage = aspectRatio > 1.6  OR  aspectRatio < 0.625
    
    // Step 5: Log result
    if (isCollage) {
      log("COLLAGE DETECTED: ratio=$aspectRatio (width=$width, height=$height)")
    } else {
      log("Image valid: ratio=$aspectRatio (width=$width, height=$height)")
    }
    
    return isCollage
    
  } catch (error) {
    log("Error detecting collage: $error")
    return false  // Assume valid if decode fails
  }
}
```

## Aspect Ratio Reference

### Standard Instagram Formats
| Format | Aspect Ratio | Width:Height | Status |
|--------|-------------|--------------|--------|
| Portrait Story | 0.5625 | 9:16 | ✅ Valid (0.625-1.6) |
| Portrait Feed | 0.8 | 4:5 | ✅ Valid |
| Square | 1.0 | 1:1 | ✅ Valid |
| Landscape | 1.77 | 16:9 | ❌ Too wide (> 1.6) |

### Collage Indicators
| Layout | Aspect Ratio | Detection |
|--------|-------------|-----------|
| 2 vertical photos | ~0.4 | ❌ Too tall (< 0.625) |
| 3 horizontal photos | ~3.0 | ❌ Too wide (> 1.6) |
| 2x2 grid | ~1.0 | ✅ Might pass (see visual detection later) |
| 2x1 grid horizontal | ~2.0 | ❌ Too wide (> 1.6) |
| 1x2 grid vertical | ~0.5 | ❌ Too tall (< 0.625) |

## Configuration Parameters

```dart
class ImageGenerationConfig {
  /// Number of distinct scenes to generate (target)
  final int expectedCount = 5;
  
  /// Minimum acceptable images for valid response
  final int minAcceptableCount = 2;
  
  /// Maximum retry attempts before giving up
  final int maxAttempts = 2;
  
  /// Delay between retry attempts (milliseconds)
  final int retryDelayMs = 300;
  
  /// Aspect ratio thresholds for collage detection
  /// Images outside this range are flagged as collages
  final double maxAspectRatio = 1.6;    // Too wide → collage
  final double minAspectRatio = 0.625;  // Too tall → collage
}
```

## Prompt Engineering Strategy

### Layer 1: Prevention (Main Prompt)
```
⚠️ CRITICAL REQUIREMENTS - READ CAREFULLY:
- NO collages, grids, or multi-photo tiled layouts WHATSOEVER
- NO split images, side-by-side arrangements
- Each image must be SEPARATE, COMPLETE, FULL-FRAME
```

### Layer 2: Correction (Retry Prompt)
```
CRITICAL: NO COLLAGES, GRIDS, OR SPLIT IMAGES!
- ❌ WRONG: 2-3 photos arranged side-by-side
- ❌ WRONG: Grid layout with multiple photos
- ✅ RIGHT: Image 1, Image 2 as 2 separate full photos
```

### Layer 3: Reinforcement (JSON Format)
```
TECHNICAL JSON FORMAT:
{
  "images": [
    {"data": "<base64_image_1>", "mimeType": "image/png"},
    {"data": "<base64_image_2>", "mimeType": "image/png"}
  ]
}
```
Emphasis: Each array entry is a COMPLETE image, not a part.

## Error Handling

### Validation Failures & Recovery

| Failure | Cause | Recovery |
|---------|-------|----------|
| Single image | AI returned 1 image | Retry with emphasis on multiple |
| All collages | All images detected as collages | Retry with explicit collage warnings |
| Only 1 valid | After filtering, only 1 image left | Retry with stricter warnings |
| Insufficient count | Too few valid images after filtering | Retry if attempts remain |
| Parse error | JSON invalid | Log and retry |
| Decode error | Image bytes unreadable | Skip image, continue validation |

## Logging Patterns

### Success Indicators
```
[✅] "Image valid: aspect ratio 0.8 | dimensions: 1080x1350"
[✅] "Generation successful: 3 images"
[✅] "Retry successful: 3 images"
```

### Warning Indicators
```
[⚠️] "COLLAGE DETECTED: aspect ratio 2.1 (too wide) | dimensions: 1080x514"
[⚠️] "Image 1 detected as collage - filtering out"
[⚠️] "Single image detected - will trigger retry for multiple images"
```

### Error Indicators
```
[❌] "All 3 images were detected as collages"
[❌] "Only 1 image returned. MUST return at least 2 distinct"
[❌] "Error detecting collage: ImageCodecException..."
```

## Performance Considerations

| Operation | Duration | Notes |
|-----------|----------|-------|
| Image decode | ~100-300ms | Per image |
| Aspect ratio calculation | <1ms | Per image |
| Validation (3 images) | ~300-900ms | Sequential |
| Full generation attempt | ~3-5 seconds | Includes API call |
| Retry with backoff | ~300ms + attempt time | Configurable delay |

## Security & Constraints

- ✅ Image decoding fails gracefully (assumed valid)
- ✅ Null-safe operations throughout
- ✅ Configurable thresholds (not hardcoded)
- ✅ Detailed logging for debugging
- ✅ No external storage access
- ✅ All operations async-safe

## Future Enhancement Opportunities

1. **Pixel-based detection:** Scan for hard edges/boundaries between photos
2. **Edge detection:** OpenCV-like analysis for grid lines
3. **Content analysis:** ML model to detect scene boundaries
4. **User feedback:** Learn from user corrections
5. **Adaptive thresholds:** Adjust based on generation patterns
6. **Custom aspect ratios:** User-configurable constraints

---

**Last Updated:** 2025-12-18
**Status:** Production Ready

