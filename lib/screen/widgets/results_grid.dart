import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Grid of generated results with staggered animations
class ResultsGrid extends StatelessWidget {
  final List<dynamic> images;
  final bool isCompact;
  final Function(Uint8List, String) onSave;
  final Function(BuildContext, int, Uint8List) onPreview;
  final bool isSaving;

  const ResultsGrid({
    super.key,
    required this.images,
    required this.isCompact,
    required this.onSave,
    required this.onPreview,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isCompact ? 2 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final gen = images[index];
        final bytes = Uint8List.fromList(gen.toBytes());

        return ResultCard(
          index: index,
          bytes: bytes,
          isSaving: isSaving,
          onTap: () => onPreview(context, index, bytes),
          onSave: () => onSave(bytes, 'remix_$index.png'),
        );
      },
    );
  }
}

/// Single result card with staggered animation
class ResultCard extends StatelessWidget {
  final int index;
  final Uint8List bytes;
  final bool isSaving;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const ResultCard({
    super.key,
    required this.index,
    required this.bytes,
    required this.isSaving,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Hero(tag: 'gen-$index', child: _buildCard()),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildImage(), _buildFooter()],
      ),
    );
  }

  Widget _buildImage() {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'AI Generated',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
                letterSpacing: -0.3,
              ),
            ),
          ),
          _buildDownloadButton(),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Material(
      color: const Color(0xFF007AFF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isSaving ? null : onSave,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: const Icon(
            Icons.download_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Empty state for results section
class ResultsEmptyState extends StatelessWidget {
  const ResultsEmptyState({super.key});

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
        Icons.collections_outlined,
        size: 36,
        color: Color(0xFF8E8E93),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'No Results Yet',
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
      'Upload a photo and generate\nto see results here',
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

/// Error state for results section
class ResultsErrorState extends StatelessWidget {
  const ResultsErrorState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF3B30).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B30).withOpacity(0.08),
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
            const Color(0xFFFF3B30).withOpacity(0.15),
            const Color(0xFFFF3B30).withOpacity(0.08),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.error_outline_rounded,
        size: 36,
        color: Color(0xFFFF3B30),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Something Went Wrong',
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
      'Please try again',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8E8E93),
        letterSpacing: -0.3,
      ),
    );
  }
}
