// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ImageProvider)
const imageProviderProvider = ImageProviderProvider._();

final class ImageProviderProvider
    extends $NotifierProvider<ImageProvider, XFile?> {
  const ImageProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageProviderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageProviderHash();

  @$internal
  @override
  ImageProvider create() => ImageProvider();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(XFile? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<XFile?>(value),
    );
  }
}

String _$imageProviderHash() => r'63c2f332aea525b0059d400404ba1ec7146ae975';

abstract class _$ImageProvider extends $Notifier<XFile?> {
  XFile? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<XFile?, XFile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<XFile?, XFile?>,
              XFile?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
