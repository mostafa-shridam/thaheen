// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(progressLocalDataSource)
final progressLocalDataSourceProvider = ProgressLocalDataSourceProvider._();

final class ProgressLocalDataSourceProvider
    extends
        $FunctionalProvider<
          ProgressLocalDataSource,
          ProgressLocalDataSource,
          ProgressLocalDataSource
        >
    with $Provider<ProgressLocalDataSource> {
  ProgressLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<ProgressLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgressLocalDataSource create(Ref ref) {
    return progressLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressLocalDataSource>(value),
    );
  }
}

String _$progressLocalDataSourceHash() =>
    r'2c4b970dfff180ab32a145d02779979966e72ef7';

/// The student's progress across every lesson, held in memory and mirrored to Hive.
///
/// Built synchronously from an already-open Hive box, so consumers get a plain
/// `Map` rather than an `AsyncValue` — a lesson list never flashes a spinner
/// just to find out which lessons are done.
///
/// [record] is the single write path. Widgets never touch the data source.

@ProviderFor(ProgressController)
final progressControllerProvider = ProgressControllerProvider._();

/// The student's progress across every lesson, held in memory and mirrored to Hive.
///
/// Built synchronously from an already-open Hive box, so consumers get a plain
/// `Map` rather than an `AsyncValue` — a lesson list never flashes a spinner
/// just to find out which lessons are done.
///
/// [record] is the single write path. Widgets never touch the data source.
final class ProgressControllerProvider
    extends $NotifierProvider<ProgressController, ProgressByLesson> {
  /// The student's progress across every lesson, held in memory and mirrored to Hive.
  ///
  /// Built synchronously from an already-open Hive box, so consumers get a plain
  /// `Map` rather than an `AsyncValue` — a lesson list never flashes a spinner
  /// just to find out which lessons are done.
  ///
  /// [record] is the single write path. Widgets never touch the data source.
  ProgressControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressControllerHash();

  @$internal
  @override
  ProgressController create() => ProgressController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressByLesson value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressByLesson>(value),
    );
  }
}

String _$progressControllerHash() =>
    r'7b83d8214adfcf8333fb254984d2a5bda0bd282b';

/// The student's progress across every lesson, held in memory and mirrored to Hive.
///
/// Built synchronously from an already-open Hive box, so consumers get a plain
/// `Map` rather than an `AsyncValue` — a lesson list never flashes a spinner
/// just to find out which lessons are done.
///
/// [record] is the single write path. Widgets never touch the data source.

abstract class _$ProgressController extends $Notifier<ProgressByLesson> {
  ProgressByLesson build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProgressByLesson, ProgressByLesson>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgressByLesson, ProgressByLesson>,
              ProgressByLesson,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The lesson the student was last watching and has not finished.
///
/// "Last" is decided by `updatedAt`, not by catalogue order, so the card always
/// points at what the student actually touched most recently — even if that was
/// lesson 2 of the second course. Returns `null` when nothing is part-watched,
/// which is what hides the card on a fresh install.

@ProviderFor(continueWatching)
final continueWatchingProvider = ContinueWatchingProvider._();

/// The lesson the student was last watching and has not finished.
///
/// "Last" is decided by `updatedAt`, not by catalogue order, so the card always
/// points at what the student actually touched most recently — even if that was
/// lesson 2 of the second course. Returns `null` when nothing is part-watched,
/// which is what hides the card on a fresh install.

final class ContinueWatchingProvider
    extends
        $FunctionalProvider<
          AsyncValue<ResumeTarget?>,
          ResumeTarget?,
          FutureOr<ResumeTarget?>
        >
    with $FutureModifier<ResumeTarget?>, $FutureProvider<ResumeTarget?> {
  /// The lesson the student was last watching and has not finished.
  ///
  /// "Last" is decided by `updatedAt`, not by catalogue order, so the card always
  /// points at what the student actually touched most recently — even if that was
  /// lesson 2 of the second course. Returns `null` when nothing is part-watched,
  /// which is what hides the card on a fresh install.
  ContinueWatchingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'continueWatchingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$continueWatchingHash();

  @$internal
  @override
  $FutureProviderElement<ResumeTarget?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ResumeTarget?> create(Ref ref) {
    return continueWatching(ref);
  }
}

String _$continueWatchingHash() => r'7ffa7ec170702baf3399df3f6c39ccec5cc13498';
