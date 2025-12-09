import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../service/storage_service.dart';
import 'provider/generated_images_provider.dart';
import 'provider/image_provider.dart';
import 'widgets/gallery_grid.dart';
import 'widgets/generate_button.dart';
import 'widgets/remix_app_bar.dart';
import 'widgets/results_grid.dart';
import 'widgets/section_header.dart';
import 'widgets/step_badge.dart';
import 'widgets/upload_card.dart';

/// Remix App - Transform selfies into travel/lifestyle scenes
///
/// Main screen for the Remix Studio application. Provides an intuitive
/// workflow for uploading photos, generating AI-powered travel scenes,
/// and managing saved results.
class RemixApp extends ConsumerStatefulWidget {
  const RemixApp({super.key});

  @override
  ConsumerState createState() => _RemixAppState();
}

class _RemixAppState extends ConsumerState<RemixApp>
    with TickerProviderStateMixin {
  // Services
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  // Constants
  static const String _fixedPrompt =
      'turn selfie image into a cinematic portrait photograph';

  // State
  Future<List<Map<String, dynamic>>>? _galleryFuture;
  bool _isSaving = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _refreshGallery();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  void _refreshGallery() {
    setState(() {
      _galleryFuture = _storageService.listUserImages();
    });
  }

  // ============================================================================
  // IMAGE OPERATIONS
  // ============================================================================

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      ref.read(imageProviderProvider.notifier).setImage(picked);
      ref.read(generatedImagesProvider.notifier).clear();
    }
  }

  Future<void> _onRemixPressed(XFile image) async {
    final file = File(image.path);
    await ref
        .read(generatedImagesProvider.notifier)
        .generate(file, _fixedPrompt);
  }

  Future<void> _saveImageBytes(Uint8List bytes, String suggestedName) async {
    setState(() => _isSaving = true);
    try {
      final name = suggestedName.contains('.')
          ? suggestedName
          : '$suggestedName.png';
      await _storageService.uploadBytes(bytes, fileName: name);
      _refreshGallery();
      if (mounted) {
        _showSuccessSnackBar('Saved to Gallery');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSavedImage(String fullPath) async {
    try {
      await _storageService.deleteImage(fullPath);
      _refreshGallery();
      if (mounted) {
        _showSuccessSnackBar('Deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete');
      }
    }
  }

  // ============================================================================
  // UI HELPERS
  // ============================================================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.92),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34C759), Color(0xFF30D158)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF3B30),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context, Widget imageHero) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'preview',
      barrierColor: Colors.black.withOpacity(0.92),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, a1, a2) => SafeArea(
        child: Stack(
          children: [
            Center(child: imageHero),
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      transitionBuilder: (context, a1, a2, child) {
        final curved = Curves.easeOutCubic.transform(a1.value);
        return Opacity(
          opacity: a1.value,
          child: Transform.scale(scale: 0.8 + 0.2 * curved, child: child),
        );
      },
    );
  }

  // ============================================================================
  // BUILD METHODS
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final XFile? image = ref.watch(imageProviderProvider);
    final generatedState = ref.watch(generatedImagesProvider);
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;

    return Scaffold(
      body: Container(
        decoration: _buildBackground(),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: RemixAppBar(fadeController: _fadeController),
              ),
              SliverToBoxAdapter(child: _buildHeroSection(image, isCompact)),
              if (image != null)
                SliverToBoxAdapter(
                  child: _buildGenerateSection(image, generatedState),
                ),
              SliverToBoxAdapter(
                child: _buildGeneratedSection(generatedState, isCompact),
              ),
              SliverToBoxAdapter(child: _buildGallerySection(isCompact)),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF5F7FA),
          const Color(0xFFE8EFF5),
          Colors.blue.shade50.withOpacity(0.3),
        ],
      ),
    );
  }

  // ============================================================================
  // SECTION BUILDERS
  // ============================================================================

  Widget _buildHeroSection(XFile? image, bool isCompact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            badge: StepBadges.step1,
            title: 'Choose Your Photo',
          ),
          const SizedBox(height: 16),
          UploadCard(
            image: image,
            onTap: _pickImage,
            onEdit: _pickImage,
            onPreview: () => _openImagePreview(image!),
            pulseController: _pulseController,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateSection(XFile image, AsyncValue generatedState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          const SectionHeader(badge: StepBadges.step2, title: 'Generate Magic'),
          const SizedBox(height: 16),
          GenerateButton(
            isLoading: generatedState.isLoading,
            onPressed: () => _onRemixPressed(image),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedSection(AsyncValue generatedState, bool isCompact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            badge: StepBadges.results,
            title: 'Your Creations',
          ),
          const SizedBox(height: 16),
          generatedState.when(
            data: (resp) {
              if (resp == null || resp.images.isEmpty) {
                return const ResultsEmptyState();
              }
              return ResultsGrid(
                images: resp.images,
                isCompact: isCompact,
                isSaving: _isSaving,
                onSave: _saveImageBytes,
                onPreview: _openGeneratedPreview,
              );
            },
            loading: () => _buildLoadingResults(isCompact),
            error: (e, st) => const ResultsErrorState(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(bool isCompact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(badge: StepBadges.gallery, title: 'My Gallery'),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _galleryFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _buildGalleryLoading(isCompact);
              }
              if (snap.hasError) {
                return _buildGalleryError();
              }

              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const GalleryEmptyState();
              }

              return GalleryGrid(
                items: items,
                isCompact: isCompact,
                onPreview: _openGalleryPreview,
                onDelete: _deleteSavedImage,
              );
            },
          ),
          if (_isSaving) ...[
            const SizedBox(height: 20),
            _buildSavingIndicator(),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // PREVIEW HANDLERS
  // ============================================================================

  void _openImagePreview(XFile image) {
    _openPreview(
      context,
      Hero(
        tag: 'input-image',
        child: Image.file(File(image.path), fit: BoxFit.contain),
      ),
    );
  }

  void _openGeneratedPreview(BuildContext context, int index, Uint8List bytes) {
    _openPreview(
      context,
      Hero(
        tag: 'gen-$index',
        child: Image.memory(bytes, fit: BoxFit.contain),
      ),
    );
  }

  void _openGalleryPreview(BuildContext context, int index, String url) {
    _openPreview(
      context,
      Hero(
        tag: 'saved-$index',
        child: NetworkImageWidget(url: url, preview: true),
      ),
    );
  }

  // ============================================================================
  // LOADING STATES
  // ============================================================================

  Widget _buildLoadingResults(bool isCompact) {
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
      itemCount: crossAxisCount * 2,
      itemBuilder: (context, i) => const ShimmerCard(),
    );
  }

  Widget _buildGalleryLoading(bool isCompact) {
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
      itemCount: crossAxisCount * 2,
      itemBuilder: (context, i) => const ShimmerPlaceholder(),
    );
  }

  Widget _buildGalleryError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load gallery',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Saving to gallery...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer card for loading state
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ShimmerPlaceholder()),
          Container(
            padding: const EdgeInsets.all(12),
            child: ShimmerPlaceholder(),
          ),
        ],
      ),
    );
  }
}
