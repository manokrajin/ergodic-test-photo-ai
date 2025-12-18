# Collage Prevention Enhancement - Banana Service

## Problem
The Nano Banana (ImageGenerationService) was outputting images with multiple split/collaged images combined into a single frame instead of separate, individual images.

## Solution Implemented
Enhanced the `banana_service.dart` to prevent collages through three layers of enforcement:

### 1. **Enhanced Validation (`_validateResponse` method)**
- Now actively detects and filters out collaged images using the existing `CollageDetector`
- Checks aspect ratio of each image to identify suspicious collage layouts
- Removes any detected collages before returning the response
- Enforces that at least 2 valid, separate images remain
- If any collages are filtered out and count drops below minimum, triggers retry

**Key Logic:**
```dart
// Validate each image to ensure none are collages
for (var i = 0; i < response.images.length; i++) {
  final image = response.images[i];
  final isCollage = await _collageDetector.isLikelyCollage(image);
  
  if (isCollage) {
    // Log and remove collage
  } else {
    validImages.add(image);
  }
}
```

### 2. **Strengthened Main Prompt**
Enhanced the AI instruction prompt with:
- Explicit warnings against collages, grids, and split images
- Clear examples of what NOT to do (❌ side-by-side, grids, tiles)
- Clear examples of what TO do (✅ separate full-frame images)
- Emphasis on "full-frame" and "standalone" images
- Reminder that each image should fill 100% of the frame

### 3. **Enhanced Retry Logic**
Updated `buildRetryNote()` to include:
- Explicit collage warnings in retry attempts
- Visual examples showing wrong vs. right approaches
- Emphasis on full-frame, complete photos
- Clear distinction between "one large collage" vs. "multiple separate images"

## Configuration Details

### Collage Detection Thresholds
Located in `ImageGenerationConfig`:
```dart
// Aspect ratio threshold for collage detection
final double maxAspectRatio = 1.6;    // Default max
final double minAspectRatio = 0.625;  // Default min
```

Images with aspect ratios outside these bounds are flagged as collages. Adjust these values if needed for different image formats:
- Standard portrait (4:5): 0.8 - within acceptable range ✓
- Standard square (1:1): 1.0 - within acceptable range ✓
- Horizontal panorama: 2.5+ - outside range, detected as collage ✗
- Vertical collage: 0.4 - outside range, detected as collage ✗

## Behavior Changes

### Before
- Generated images could contain multiple photos arranged as a collage/grid
- No validation to filter out collages
- Collage detection existed but wasn't enforced

### After
- Any detected collages are automatically filtered out
- Response is validated to contain only separate, full-frame images
- If collages are detected and removed below minimum count, automatic retry occurs
- AI receives explicit warnings about collages in both initial prompt and retry notes
- Much higher likelihood of receiving truly separate, individual images

## Testing Recommendations

1. **Monitor Logs**: Check developer logs for collage detection messages:
   ```
   "Image 1 detected as collage - filtering out"
   "All 3 images were detected as collages. Requesting separate images."
   ```

2. **Validate Outputs**: Verify that generated images:
   - Are truly separate, not combined
   - Have normal aspect ratios (0.625 - 1.6 range)
   - Show distinct scenes, not variations of the same scene

3. **Retry Behavior**: If collages are detected:
   - Service will automatically filter them out
   - If not enough valid images remain, automatic retry triggers
   - Retry prompt includes anti-collage warnings

## Files Modified
- `/lib/service/banana_service.dart`
  - Enhanced `_validateResponse()` method
  - Enhanced `buildRetryNote()` method
  - Enhanced `build()` prompt builder method

## Backwards Compatibility
✅ All changes are backwards compatible. The API remains unchanged - only the validation logic is enhanced.

