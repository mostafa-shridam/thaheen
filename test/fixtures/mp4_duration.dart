import 'dart:io';
import 'dart:typed_data';

/// Reads an MP4's real duration straight out of its `mvhd` atom.
///
/// Exists so a test can check the catalogue against the *files* rather than
/// against a hand-maintained number — `durationSec` in `courses.json` is shown
/// to students before a video ever loads, so it must not drift from reality.
///
/// Walks only the top-level atom list into `moov`, which is all that is needed
/// to reach `mvhd`. Returns `null` if the structure is not what we expect.
Duration? readMp4Duration(File file) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);

  final moov = _findAtom(data, 0, bytes.length, 'moov');
  if (moov == null) return null;

  // `moov`'s payload starts 8 bytes in, past its own size and type.
  final mvhd = _findAtom(data, moov.start + 8, moov.end, 'mvhd');
  if (mvhd == null) return null;

  // Payload layout: 1 byte version, 3 bytes flags, then times.
  final payload = mvhd.start + 8;
  final version = data.getUint8(payload);

  final int timescale;
  final int units;
  if (version == 1) {
    // 64-bit: creation(8) modification(8) timescale(4) duration(8)
    timescale = data.getUint32(payload + 20);
    units = data.getUint64(payload + 24);
  } else {
    // 32-bit: creation(4) modification(4) timescale(4) duration(4)
    timescale = data.getUint32(payload + 12);
    units = data.getUint32(payload + 16);
  }

  if (timescale == 0) return null;
  return Duration(milliseconds: (units * 1000 / timescale).round());
}

class _Atom {
  const _Atom(this.start, this.end);

  final int start;
  final int end;
}

_Atom? _findAtom(ByteData data, int start, int end, String type) {
  var offset = start;
  while (offset + 8 <= end) {
    var size = data.getUint32(offset);
    final name = String.fromCharCodes(<int>[
      for (var i = 4; i < 8; i++) data.getUint8(offset + i),
    ]);

    // Size 1 means the real 64-bit size follows the type field.
    if (size == 1) size = data.getUint64(offset + 8);
    if (size < 8) return null;

    if (name == type) return _Atom(offset, offset + size);
    offset += size;
  }
  return null;
}
