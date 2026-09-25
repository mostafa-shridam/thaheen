/// Clock-style duration formatting.
///
/// Digits stay Western (`0-9`) rather than Arabic-Indic (`٠-٩`): that is what
/// Gulf learning apps overwhelmingly use for timecodes, and it keeps a
/// timestamp legible next to a seek bar regardless of the interface language.
///
/// A timecode is a neutral-direction string, so `mm:ss` renders correctly in an
/// RTL layout without wrapping. Where two timecodes sit side by side, lay them
/// out as separate widgets in a `Row` and let `Directionality` order them —
/// never concatenate them into one `'a / b'` string, which would flip.
String formatClock(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  final paddedMinutes = minutes.toString().padLeft(2, '0');
  final paddedSeconds = seconds.toString().padLeft(2, '0');

  return hours > 0
      ? '$hours:$paddedMinutes:$paddedSeconds'
      : '$paddedMinutes:$paddedSeconds';
}

/// Convenience for the many places holding a plain second count.
String formatClockFromSeconds(int seconds) =>
    formatClock(Duration(seconds: seconds));
