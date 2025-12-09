import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Upload card widget with animated empty state and image preview
class UploadCard extends StatelessWidget {
  final XFile? image;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final AnimationController pulseController;

  const UploadCard({
    super.key,
    required this.image,
    required this.onTap,
    required this.onEdit,
    required this.onPreview,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 380,
        decoration: _buildDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: image == null
              ? UploadEmptyState(pulseController: pulseController)
              : UploadImagePreview(
                  image: image!,
                  onEdit: onEdit,
                  onPreview: onPreview,
                ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      gradient: image == null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.blue.shade50.withOpacity(0.5)],
            )
          : null,
      color: image != null ? Colors.white : null,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: image == null
            ? const Color(0xFF007AFF).withOpacity(0.2)
            : Colors.transparent,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: image == null
              ? const Color(0xFF007AFF).withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
          blurRadius: 30,
          offset: const Offset(0, 10),
          spreadRadius: -5,
        ),
      ],
    );
  }
}

/// Empty state with pulsing upload button
class UploadEmptyState extends StatelessWidget {
  final AnimationController pulseController;

  const UploadEmptyState({super.key, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final pulse = pulseController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF9FAFB),
                Colors.blue.shade50.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulsingIcon(pulse),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildSubtitle(),
              const SizedBox(height: 24),
              _buildFeatureChips(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPulsingIcon(double pulse) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(
                const Color(0xFF007AFF),
                const Color(0xFF5856D6),
                pulse,
              )!,
              Color.lerp(
                const Color(0xFF5856D6),
                const Color(0xFF007AFF),
                pulse,
              )!,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.3 + pulse * 0.2),
              blurRadius: 30 + pulse * 10,
              spreadRadius: -5,
            ),
          ],
        ),
        child: const Icon(
          Icons.add_photo_alternate_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Tap to Upload',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF000000),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Choose from your gallery',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8E8E93),
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildFeatureChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FeatureChip(icon: Icons.hd_rounded, label: 'High Quality'),
        const SizedBox(width: 12),
        _FeatureChip(icon: Icons.speed_rounded, label: 'Fast AI'),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF007AFF).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF007AFF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF007AFF),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Image preview with edit button and status overlay
class UploadImagePreview extends StatelessWidget {
  final XFile image;
  final VoidCallback onEdit;
  final VoidCallback onPreview;

  const UploadImagePreview({
    super.key,
    required this.image,
    required this.onEdit,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [_buildImage(), _buildEditButton(), _buildStatusOverlay()],
    );
  }

  Widget _buildImage() {
    return Hero(
      tag: 'input-image',
      child: GestureDetector(
        onTap: onPreview,
        child: Image.file(File(image.path), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildEditButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.edit_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Photo ready',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
