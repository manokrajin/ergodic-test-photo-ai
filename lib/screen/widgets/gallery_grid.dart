import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Gallery grid for saved photos
class GalleryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isCompact;
  final Function(BuildContext, int, String) onPreview;
  final Function(String) onDelete;

  const GalleryGrid({
    super.key,
    required this.items,
    required this.isCompact,
    required this.onPreview,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isCompact ? 3 : 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final url = item['downloadUrl'] as String?;
        final path = item['path'] as String? ?? '';

        return GalleryItem(
          index: i,
          url: url,
          onTap: url != null ? () => onPreview(context, i, url) : null,
          onDelete: () => onDelete(path),
        );
      },
    );
  }
}

/// Single gallery item
class GalleryItem extends StatelessWidget {
  final int index;
  final String? url;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const GalleryItem({
    super.key,
    required this.index,
    required this.url,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'saved-$index',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [_buildImage(), _buildDeleteButton()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (url != null) {
      return NetworkImageWidget(url: url!);
    }
    return Container(color: const Color(0xFFF9F9F9));
  }

  Widget _buildDeleteButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onDelete,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Network image with loading shimmer
class NetworkImageWidget extends StatelessWidget {
  final String url;
  final bool preview;

  const NetworkImageWidget({
    super.key,
    required this.url,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: preview ? BoxFit.contain : BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const ShimmerPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF9F9F9),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Color(0xFFD1D1D6),
              size: 32,
            ),
          ),
        );
      },
    );
  }
}

/// Empty state for gallery
class GalleryEmptyState extends StatelessWidget {
  const GalleryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildIcon(),
          const SizedBox(height: 24),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildSubtitle(),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8E8E93).withOpacity(0.1),
            const Color(0xFF8E8E93).withOpacity(0.05),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.photo_library_outlined,
        size: 36,
        color: Color(0xFF8E8E93),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'No Saved Photos',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF000000),
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Download your creations\nto see them here',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8E8E93),
        letterSpacing: -0.3,
        height: 1.4,
      ),
    );
  }
}

/// Shimmer loading placeholder
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5EA),
      highlightColor: const Color(0xFFF9F9F9),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
