// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalogue_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wiring for the course catalogue.
///
/// These providers are the composition root of the data layer. They are
/// `keepAlive` because the catalogue is a bundled asset that cannot change
/// while the app runs — re-reading and re-parsing it on every navigation would
/// be pure waste.
///
/// Tests override [courseAssetDataSourceProvider] rather than reaching for
/// `rootBundle`.

@ProviderFor(courseAssetDataSource)
final courseAssetDataSourceProvider = CourseAssetDataSourceProvider._();

/// Wiring for the course catalogue.
///
/// These providers are the composition root of the data layer. They are
/// `keepAlive` because the catalogue is a bundled asset that cannot change
/// while the app runs — re-reading and re-parsing it on every navigation would
/// be pure waste.
///
/// Tests override [courseAssetDataSourceProvider] rather than reaching for
/// `rootBundle`.

final class CourseAssetDataSourceProvider
    extends
        $FunctionalProvider<
          CourseAssetDataSource,
          CourseAssetDataSource,
          CourseAssetDataSource
        >
    with $Provider<CourseAssetDataSource> {
  /// Wiring for the course catalogue.
  ///
  /// These providers are the composition root of the data layer. They are
  /// `keepAlive` because the catalogue is a bundled asset that cannot change
  /// while the app runs — re-reading and re-parsing it on every navigation would
  /// be pure waste.
  ///
  /// Tests override [courseAssetDataSourceProvider] rather than reaching for
  /// `rootBundle`.
  CourseAssetDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseAssetDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseAssetDataSourceHash();

  @$internal
  @override
  $ProviderElement<CourseAssetDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CourseAssetDataSource create(Ref ref) {
    return courseAssetDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourseAssetDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourseAssetDataSource>(value),
    );
  }
}

String _$courseAssetDataSourceHash() =>
    r'864adece729a9771c62ae8a3f869e2ed009ae426';

/// Every course in the catalogue, parsed once per app session.

@ProviderFor(courseCatalogue)
final courseCatalogueProvider = CourseCatalogueProvider._();

/// Every course in the catalogue, parsed once per app session.

final class CourseCatalogueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourseModel>>,
          List<CourseModel>,
          FutureOr<List<CourseModel>>
        >
    with
        $FutureModifier<List<CourseModel>>,
        $FutureProvider<List<CourseModel>> {
  /// Every course in the catalogue, parsed once per app session.
  CourseCatalogueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseCatalogueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseCatalogueHash();

  @$internal
  @override
  $FutureProviderElement<List<CourseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourseModel>> create(Ref ref) {
    return courseCatalogue(ref);
  }
}

String _$courseCatalogueHash() => r'080c09e96d8de746c22a0ef5d2c1f9d1c51c1f12';

/// A single course by id, or `null` when the id is not in the catalogue.
///
/// Watching this instead of filtering inside a widget keeps the lookup out of
/// `build()` and lets the details screen rebuild only when *its* course changes.

@ProviderFor(courseById)
final courseByIdProvider = CourseByIdFamily._();

/// A single course by id, or `null` when the id is not in the catalogue.
///
/// Watching this instead of filtering inside a widget keeps the lookup out of
/// `build()` and lets the details screen rebuild only when *its* course changes.

final class CourseByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<CourseModel?>,
          CourseModel?,
          FutureOr<CourseModel?>
        >
    with $FutureModifier<CourseModel?>, $FutureProvider<CourseModel?> {
  /// A single course by id, or `null` when the id is not in the catalogue.
  ///
  /// Watching this instead of filtering inside a widget keeps the lookup out of
  /// `build()` and lets the details screen rebuild only when *its* course changes.
  CourseByIdProvider._({
    required CourseByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'courseByIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courseByIdHash();

  @override
  String toString() {
    return r'courseByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CourseModel?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CourseModel?> create(Ref ref) {
    final argument = this.argument as String;
    return courseById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CourseByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courseByIdHash() => r'7137409c0b32704216401e9b9437041ce2038704';

/// A single course by id, or `null` when the id is not in the catalogue.
///
/// Watching this instead of filtering inside a widget keeps the lookup out of
/// `build()` and lets the details screen rebuild only when *its* course changes.

final class CourseByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CourseModel?>, String> {
  CourseByIdFamily._()
    : super(
        retry: null,
        name: r'courseByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// A single course by id, or `null` when the id is not in the catalogue.
  ///
  /// Watching this instead of filtering inside a widget keeps the lookup out of
  /// `build()` and lets the details screen rebuild only when *its* course changes.

  CourseByIdProvider call(String courseId) =>
      CourseByIdProvider._(argument: courseId, from: this);

  @override
  String toString() => r'courseByIdProvider';
}
