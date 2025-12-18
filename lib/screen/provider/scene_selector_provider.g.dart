// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_selector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SceneSelectorProvider)
const sceneSelectorProviderProvider = SceneSelectorProviderProvider._();

final class SceneSelectorProviderProvider
    extends $NotifierProvider<SceneSelectorProvider, TravelScene?> {
  const SceneSelectorProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sceneSelectorProviderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sceneSelectorProviderHash();

  @$internal
  @override
  SceneSelectorProvider create() => SceneSelectorProvider();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TravelScene? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TravelScene?>(value),
    );
  }
}

String _$sceneSelectorProviderHash() =>
    r'ffa31fd9383aa68acd1f48c9f0e87dd5b12ed02b';

abstract class _$SceneSelectorProvider extends $Notifier<TravelScene?> {
  TravelScene? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TravelScene?, TravelScene?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TravelScene?, TravelScene?>,
              TravelScene?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
