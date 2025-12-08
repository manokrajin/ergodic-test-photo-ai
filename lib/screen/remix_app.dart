import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../service/storage_service.dart';
import 'provider/generated_images_provider.dart';
import 'provider/image_provider.dart';

class RemixApp extends ConsumerStatefulWidget {
  const RemixApp({super.key});

  @override
  ConsumerState createState() => _RemixAppState();
}

class _RemixAppState extends ConsumerState<RemixApp>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _promptController = TextEditingController(
    text: 'turn selfie image into a cinematic portrait photograph',
  );

  final StorageService _storageService = StorageService();

  Future<List<Map<String, dynamic>>>? _galleryFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // shimmer package handles its own animation internally
    _refreshGallery();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _refreshGallery() {
    setState(() {
      _galleryFuture = _storageService.listUserImages();
    });
  }

  Future<void> _saveImageBytes(Uint8List bytes, String suggestedName) async {
    setState(() => _isSaving = true);
    try {
      final name = suggestedName.contains('.')
          ? suggestedName
          : '$suggestedName.png';
      final path = await _storageService.uploadBytes(bytes, fileName: name);
      // refresh gallery
      _refreshGallery();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Saved to storage: $path'),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to save image: $e'),
          ),
        );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSavedImage(String fullPath) async {
    try {
      await _storageService.deleteImage(fullPath);
      _refreshGallery();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Deleted image'),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to delete image: $e'),
          ),
        );
    }
  }

  // Smooth full-screen preview with Hero and a gentle scale/fade transition
  Future<void> _openPreview(BuildContext context, Widget imageHero) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'preview',
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (context, a1, a2) =>
          SafeArea(child: Center(child: imageHero)),
      transitionBuilder: (context, a1, a2, child) {
        final curved = Curves.easeOut.transform(a1.value);
        return Opacity(
          opacity: a1.value,
          child: Transform.scale(scale: 0.9 + 0.1 * curved, child: child),
        );
      },
    );
  }

  // Helper: pick an image from gallery and update provider
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      ref.read(imageProviderProvider.notifier).setImage(picked);
      ref.read(generatedImagesProvider.notifier).clear();
    }
  }

  // Helper: trigger remix generation
  Future<void> _onRemixPressed(XFile image) async {
    final prompt = _promptController.text.trim();
    final file = File(image.path);
    await ref.read(generatedImagesProvider.notifier).generate(file, prompt);
  }

  // Build the header row (title and actions)
  Widget _buildHeader(XFile? image) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700);
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remix', style: titleStyle),
              const SizedBox(height: 6),
              Text(
                'Create stylish photos from your selfies — fast, private, and delightful.',
                style: subtitleStyle,
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              onPressed: image == null
                  ? null
                  : () async => await _onRemixPressed(image),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Remix'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build the prompt input card
  Widget _buildPromptCard({required bool isWide}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Describe the remix style (eg. cinematic, vintage)',
              ),
            ),
          ),
          IconButton(
            onPressed: () => _promptController.clear(),
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }

  // Build the input preview card
  Widget _buildInputPreview(
    XFile? image,
    TextStyle? subtitleStyle, {
    double? width,
    double? height,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 260,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: image == null
            ? Center(
                child: Text(
                  'Tap the gallery icon to pick an image',
                  style: subtitleStyle,
                ),
              )
            : GestureDetector(
                onTap: () => _openPreview(
                  context,
                  Hero(
                    tag: 'input-image',
                    child: Image.file(File(image.path), fit: BoxFit.contain),
                  ),
                ),
                child: Hero(
                  tag: 'input-image',
                  child: Image.file(File(image.path), fit: BoxFit.cover),
                ),
              ),
      ),
    );
  }

  // Build generated images grid
  Widget _buildGeneratedArea(AsyncValue generatedState, double maxW) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: generatedState.when(
        data: (resp) {
          if (resp == null || resp.images.isEmpty) {
            return SizedBox(
              key: const ValueKey('emptyGenerated'),
              height: 150,
              child: Center(
                child: Text('No remixes yet — tap Remix to create'),
              ),
            );
          }

          final crossCount = maxW > 1200 ? 4 : (maxW > 800 ? 3 : 2);

          return GridView.builder(
            key: ValueKey(resp.hashCode),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: resp.images.length,
            itemBuilder: (context, index) {
              final gen = resp.images[index];
              final bytes = Uint8List.fromList(gen.toBytes());

              return GestureDetector(
                onTap: () => _openPreview(
                  context,
                  Hero(
                    tag: 'gen-$index',
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
                child: Hero(
                  tag: 'gen-$index',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(bytes, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: const Color.fromRGBO(0, 0, 0, 0.45),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isSaving
                                  ? null
                                  : () async {
                                      final suggested = 'generated_$index.png';
                                      await _saveImageBytes(bytes, suggested);
                                    },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.save,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        // Show a small grid of shimmer tiles while generated images are loading
        loading: () {
          final crossCount = maxW > 1200 ? 4 : (maxW > 800 ? 3 : 2);
          // show 4 placeholders or crossCount placeholders depending on width
          final placeholderCount = crossCount * 2;
          return GridView.builder(
            key: const ValueKey('loadingGeneratedShimmer'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: placeholderCount,
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildShimmerPlaceholder(),
            ),
          );
        },
        error: (e, st) => SizedBox(
          key: const ValueKey('errorGenerated'),
          height: 120,
          child: Center(child: Text('Error generating images')),
        ),
      ),
    );
  }

  // Build gallery grid from storage
  Widget _buildGalleryArea(double maxW) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _galleryFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          // Show a shimmer placeholder while gallery items load
          return SizedBox(
            height: 100,
            child: _buildShimmerPlaceholder(height: 100),
          );
        }
        if (snap.hasError) return const Text('Failed to load gallery');

        final items = snap.data ?? [];
        if (items.isEmpty) return const Text('No saved photos yet');

        final crossCount = maxW > 1200 ? 6 : (maxW > 900 ? 4 : 3);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final url = item['downloadUrl'] as String?;
            final path = item['path'] as String? ?? '';

            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url != null)
                    GestureDetector(
                      onTap: () => _openPreview(
                        context,
                        Hero(
                          tag: 'saved-$i',
                          child: _buildNetworkImage(url, preview: true),
                        ),
                      ),
                      child: _buildNetworkImage(
                        url,
                        preview: false,
                        height: 120,
                      ),
                    )
                  else
                    Container(color: Colors.grey.shade200),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: const Color.fromRGBO(0, 0, 0, 0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async => await _deleteSavedImage(path),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Consolidated content builder to avoid duplicating wide/narrow layouts
  Widget _buildContent(
    bool isWide,
    double maxW,
    XFile? image,
    AsyncValue generatedState,
    TextStyle? subtitleStyle,
  ) {
    // Shared constants for section padding
    const sectionPadding = EdgeInsets.all(12);

    Widget buildSectionCard({required String title, required Widget child}) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: sectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      );
    }

    if (isWide) {
      // Wide: left column is upload/prompt, right column holds generated and saved sections
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Upload & Prompt
          Expanded(
            flex: 1,
            child: buildSectionCard(
              title: 'Upload & Prompt',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPromptCard(isWide: isWide),
                  const SizedBox(height: 12),
                  _buildInputPreview(
                    image,
                    subtitleStyle,
                    width: 260,
                    height: 260,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Right: Generated remixes + Saved photos
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionCard(
                  title: 'Generated Remixes',
                  child: _buildGeneratedArea(generatedState, maxW),
                ),
                const SizedBox(height: 16),
                buildSectionCard(
                  title: 'Saved Photos',
                  child: Column(
                    children: [
                      _buildGalleryArea(maxW),
                      if (_isSaving)
                        const Padding(
                          padding: EdgeInsets.only(top: 12.0),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Narrow layout: stack section cards vertically to make grouping obvious
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionCard(
          title: 'Upload & Prompt',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPromptCard(isWide: isWide),
              const SizedBox(height: 12),
              _buildInputPreview(image, subtitleStyle, height: 200),
            ],
          ),
        ),
        const SizedBox(height: 14),
        buildSectionCard(
          title: 'Generated Remixes',
          child: _buildGeneratedArea(generatedState, maxW),
        ),
        const SizedBox(height: 14),
        buildSectionCard(
          title: 'Saved Photos',
          child: Column(
            children: [
              _buildGalleryArea(maxW),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Shimmer placeholder implemented with the `shimmer` package
  Widget _buildShimmerPlaceholder({double? height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Network image with a shimmer loadingBuilder; preview flag chooses fit and no clipping
  Widget _buildNetworkImage(
    String url, {
    bool preview = false,
    double? height,
  }) {
    return Image.network(
      url,
      fit: preview ? BoxFit.contain : BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        // show shimmer sized like the image area
        return _buildShimmerPlaceholder(height: height);
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final XFile? image = ref.watch(imageProviderProvider);
    final generatedState = ref.watch(generatedImagesProvider);

    // Modern typography shortcuts
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final isWide = maxW > 900;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(image),
                      const SizedBox(height: 18),
                      _buildContent(
                        isWide,
                        maxW,
                        image,
                        generatedState,
                        subtitleStyle,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
