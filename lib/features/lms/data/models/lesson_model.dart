import 'package:thaheen_task/core/utils/json_object.dart';

/// One video lesson, as it appears in `assets/data/courses.json`.
///
/// Parsing is hand-written rather than generated: the catalogue is a fixed
/// bundled asset, and hand-written readers let us decide *per field* whether a
/// bad value should fail the record or fall back — which is exactly what the
/// "no red screens" requirement needs. See [JsonObject].
class LessonModel {
  const LessonModel({
    required this.id,
    required this.title,
    required this.durationSec,
    required this.video,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        id: json.readString('id'),
        title: json.readString('title'),
        // A missing duration is survivable: the player reports the real one.
        durationSec: json.readInt('durationSec'),
        video: json.readString('video'),
      );

  final String id;
  final String title;

  /// Duration declared by the catalogue, in seconds.
  ///
  /// This is the pre-playback estimate used to render the lesson list before a
  /// video is ever opened. Once the player reports a real duration, that value
  /// wins — see `LessonProgressModel.durationSec`.
  final int durationSec;

  /// Bundled asset path, e.g. `assets/videos/lesson_1.mp4`.
  final String video;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonModel &&
          other.id == id &&
          other.title == title &&
          other.durationSec == durationSec &&
          other.video == video;

  @override
  int get hashCode => Object.hash(id, title, durationSec, video);

  @override
  String toString() => 'LessonModel($id)';
}
