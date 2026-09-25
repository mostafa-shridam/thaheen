// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's navigation graph.
///
/// Exposed as a provider so later phases can add progress-aware redirects
/// (for example, refusing a deep link into a still-locked lesson) without
/// rebuilding the router or reaching for a global.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// The app's navigation graph.
///
/// Exposed as a provider so later phases can add progress-aware redirects
/// (for example, refusing a deep link into a still-locked lesson) without
/// rebuilding the router or reaching for a global.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app's navigation graph.
  ///
  /// Exposed as a provider so later phases can add progress-aware redirects
  /// (for example, refusing a deep link into a still-locked lesson) without
  /// rebuilding the router or reaching for a global.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'59732a21bb48e3138b0a512ed8364c33398889a1';
