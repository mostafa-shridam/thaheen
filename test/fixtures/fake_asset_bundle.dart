import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An [AssetBundle] backed by an in-memory map.
///
/// Lets data-source tests feed real, empty or deliberately corrupt catalogue
/// payloads without going anywhere near `rootBundle`.
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.assets);

  /// Asset path -> file contents. A path that is absent behaves like a missing
  /// asset and makes `load` throw, exactly as the real bundle does.
  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw FlutterError('Asset not found in FakeAssetBundle: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}
