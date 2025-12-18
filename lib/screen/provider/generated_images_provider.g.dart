// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_images_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GeneratedImages)
const generatedImagesProvider = GeneratedImagesProvider._();

final class GeneratedImagesProvider
    extends $AsyncNotifierProvider<GeneratedImages, GeminiImageResponse?> {
  const GeneratedImagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'generatedImagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$generatedImagesHash();

  @$internal
  @override
  GeneratedImages create() => GeneratedImages();
}

String _$generatedImagesHash() => r'434d63953d0a966c12d759a45b17834018346ba9';

abstract class _$GeneratedImages extends $AsyncNotifier<GeminiImageResponse?> {
  FutureOr<GeminiImageResponse?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<GeminiImageResponse?>, GeminiImageResponse?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<GeminiImageResponse?>,
                GeminiImageResponse?
              >,
              AsyncValue<GeminiImageResponse?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
