import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Owns Hive's lifecycle and the names of every box in the app.
///
/// Hive is the *only* local storage engine here: watch positions, completion
/// flags and user preferences all live in these two boxes. Both are
/// `Box<String>` holding JSON (or plain scalar) values rather than generated
/// `TypeAdapter`s — see `LessonProgressModel` for the reasoning.
abstract final class HiveBoxes {
  static const String settings = 'thaheen_settings';
  static const String lessonProgress = 'thaheen_lesson_progress';

  static bool _ready = false;

  /// True once [init] has successfully opened every box.
  ///
  /// Storage failing is not fatal: the app runs with progress held in memory
  /// for the session, which is far better than a red screen on launch. Callers
  /// check this before reading or writing.
  static bool get isReady => _ready;

  /// Opens every box. Never throws — a failure degrades the app to
  /// session-only persistence and is reported through [isReady].
  static Future<bool> init() async {
    try {
      await Hive.initFlutter();
      await _openBoxes();
    } on Object catch (error, stack) {
      _ready = false;
      // Surfaced in the console only; the UI degrades silently rather than
      // blocking a student from watching lessons offline.
      debugPrint('Hive initialisation failed, continuing without persistence: $error');
      debugPrintStack(stackTrace: stack);
    }
    return _ready;
  }

  static Box<String>? get settingsBox =>
      _ready && Hive.isBoxOpen(settings) ? Hive.box<String>(settings) : null;

  static Box<String>? get lessonProgressBox => _ready && Hive.isBoxOpen(lessonProgress)
      ? Hive.box<String>(lessonProgress)
      : null;

  static Future<void> _openBoxes() async {
    await Future.wait(<Future<void>>[
      Hive.openBox<String>(settings),
      Hive.openBox<String>(lessonProgress),
    ]);
    _ready = true;
  }

  /// Test hook: opens the boxes against a plain directory.
  ///
  /// `initFlutter` needs the `path_provider` plugin, which a unit test does not
  /// have. This takes the directory directly so persistence can be tested for
  /// real — writing, closing and reading back — rather than against a fake.
  @visibleForTesting
  static Future<void> initAt(String path) async {
    Hive.init(path);
    await _openBoxes();
  }

  /// Test hook: closes every box, simulating an app restart.
  @visibleForTesting
  static Future<void> close() async {
    await Hive.close();
    _ready = false;
  }

  /// Test hook: wipes both boxes.
  @visibleForTesting
  static Future<void> clear() async {
    await settingsBox?.clear();
    await lessonProgressBox?.clear();
  }
}
