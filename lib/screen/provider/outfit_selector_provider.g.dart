// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_selector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OutfitSelectorProvider)
const outfitSelectorProviderProvider = OutfitSelectorProviderProvider._();

final class OutfitSelectorProviderProvider
    extends $NotifierProvider<OutfitSelectorProvider, OutfitStyle?> {
  const OutfitSelectorProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outfitSelectorProviderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outfitSelectorProviderHash();

  @$internal
  @override
  OutfitSelectorProvider create() => OutfitSelectorProvider();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OutfitStyle? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OutfitStyle?>(value),
    );
  }
}

String _$outfitSelectorProviderHash() =>
    r'562553a43607660b89e731800f44f3069d8e824d';

abstract class _$OutfitSelectorProvider extends $Notifier<OutfitStyle?> {
  OutfitStyle? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<OutfitStyle?, OutfitStyle?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OutfitStyle?, OutfitStyle?>,
              OutfitStyle?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
