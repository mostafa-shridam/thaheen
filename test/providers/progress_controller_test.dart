import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'
    show Override, ProviderContainer;
import 'package:thaheen_task/features/lms/data/datasources/progress_local_data_source.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';

/// Records what reached "disk", so a test can tell live state apart from
/// persisted state.
class _SpyProgressSource implements ProgressLocalDataSource {
  _SpyProgressSource();

  /// Starts empty: these tests are about what `record` does, not about
  /// rehydrating an existing store — `test/data/` covers that.
  static const ProgressByLesson seed = <String, LessonProgressModel>{};

  final List<LessonProgressModel> writes = <LessonProgressModel>[];
  int clearCount = 0;

  @override
  ProgressByLesson readAll() => seed;

  @override
  LessonProgressModel readOne(String lessonId) => seed.forLesson(lessonId);

  @override
  Future<void> write(LessonProgressModel progress) async => writes.add(progress);

  @override
  Future<void> clear() async => clearCount++;
}

/// Covers the contract the player relies on: **state is live, persistence lags.**
///
/// Context, stated accurately: the "progress only updates after you leave and
/// come back" bug was *not* in this class — `record` always advanced `state`
/// synchronously. The bug was that `LessonPlayerPage` only *called* `record`
/// on a five-second timer that was itself skipped once playback stopped, so a
/// lesson watched to the end registered nothing until `dispose`.
///
/// The player now records once per second, which is what makes the debounce
/// below load-bearing: without it, that fix would mean a Hive write every
/// second. These tests pin the half of the contract that is unit-testable —
/// that state moves on every call while writes are coalesced, and that
/// completion is never left unwritten. The player-side half needs a video
/// platform channel and is not covered here.
void main() {
  late _SpyProgressSource source;
  late ProviderContainer container;

  ProgressByLesson get$() => container.read(progressControllerProvider);
  ProgressController notifier() =>
      container.read(progressControllerProvider.notifier);

  setUp(() {
    source = _SpyProgressSource();
    container = ProviderContainer(
      overrides: <Override>[
        progressLocalDataSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<bool> tick(int positionSec) => notifier().record(
        lessonId: 'l1',
        positionSec: positionSec,
        reportedDurationSec: 100,
        declaredDurationSec: 100,
      );

  group('state is live', () {
    test('a single tick is visible immediately, before any write', () async {
      await tick(3);

      expect(get$().forLesson('l1').positionSec, 3);
      expect(
        source.writes,
        isEmpty,
        reason: 'an in-progress position should still be debounced',
      );
    });

    test('every call advances state, however often they arrive', () async {
      // The player now calls this once per second; each one must be visible.
      for (final second in <int>[1, 2, 3, 4]) {
        await tick(second);
        expect(get$().forLesson('l1').positionSec, second);
      }
    });

    test('crossing 90% flips completion in state at once', () async {
      await tick(89);
      expect(get$().forLesson('l1').completed, isFalse);

      await tick(90);
      expect(
        get$().forLesson('l1').completed,
        isTrue,
        reason: 'the unlock rule must not wait for a debounce',
      );
    });
  });

  group('persistence', () {
    test('completion is written through immediately', () async {
      await tick(90);

      // Completion unlocks the next lesson, so it may never sit in memory.
      expect(source.writes, hasLength(1));
      expect(source.writes.single.completed, isTrue);
    });

    test('flush writes the pending position', () async {
      await tick(4);
      expect(source.writes, isEmpty);

      await notifier().flush();

      expect(source.writes, hasLength(1));
      expect(source.writes.single.positionSec, 4);
    });

    test('flush coalesces many ticks into one write', () async {
      for (final second in <int>[1, 2, 3, 4]) {
        await tick(second);
      }
      await notifier().flush();

      // Four ticks, one write — the debounce still does its job.
      expect(source.writes, hasLength(1));
      expect(source.writes.single.positionSec, 4);
    });

    test('flush with nothing pending writes nothing', () async {
      await notifier().flush();
      expect(source.writes, isEmpty);
    });
  });

  group('no-op ticks', () {
    test('repeating the same second changes nothing', () async {
      await tick(7);
      final first = get$();

      final completed = await tick(7);

      expect(completed, isFalse);
      expect(identical(get$(), first), isTrue,
          reason: 'an identical tick must not replace the state map');
    });
  });

  group('completion signal', () {
    test('record reports completion exactly once', () async {
      expect(await tick(90), isTrue);
      // Still completed, but no longer *newly* completed — otherwise the player
      // would celebrate on every subsequent tick.
      expect(await tick(95), isFalse);
    });
  });

  group('resetAll', () {
    test('clears storage and state, and drops pending writes', () async {
      await tick(4);
      await notifier().resetAll();

      expect(source.clearCount, 1);
      expect(get$(), isEmpty);

      // The pending tick must not resurrect itself on a later flush.
      await notifier().flush();
      expect(source.writes, isEmpty);
    });
  });
}
