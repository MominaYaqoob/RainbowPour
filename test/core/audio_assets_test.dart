import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/core/audio_service.dart';

/// Reads a 16-bit PCM WAV file and returns its facts.
({int rate, int channels, int bits, double seconds, double peak, int clipped})
readWav(String path) {
  final bytes = File(path).readAsBytesSync();
  final bd = ByteData.sublistView(Uint8List.fromList(bytes));
  String tag(int o) => String.fromCharCodes(bytes.sublist(o, o + 4));
  expect(tag(0), 'RIFF', reason: '$path is not a RIFF file');
  expect(tag(8), 'WAVE');
  expect(tag(36), 'data');
  final channels = bd.getUint16(22, Endian.little);
  final rate = bd.getUint32(24, Endian.little);
  final bits = bd.getUint16(34, Endian.little);
  final n = (bytes.length - 44) ~/ 2;
  var peak = 0;
  var clipped = 0;
  for (var i = 0; i < n; i++) {
    final v = bd.getInt16(44 + i * 2, Endian.little).abs();
    peak = math.max(peak, v);
    if (v >= 32760) clipped++;
  }
  return (
    rate: rate,
    channels: channels,
    bits: bits,
    seconds: n / rate / channels,
    peak: peak / 32768,
    clipped: clipped,
  );
}

void main() {
  const sfx = {
    AudioAssets.tap: (0.03, 0.4),
    AudioAssets.select: (0.05, 0.4),
    AudioAssets.pour: (0.8, 2.2),
    AudioAssets.bottleFull: (0.3, 1.5),
    AudioAssets.win: (1.0, 3.5),
    AudioAssets.fail: (0.4, 2.0),
  };

  test('every sound effect is a real sound, not silence, and small', () {
    for (final entry in sfx.entries) {
      final path = 'assets/${entry.key}';
      final w = readWav(path);
      expect(w.bits, 16, reason: path);
      expect(w.channels, 1, reason: path);
      expect(w.peak, greaterThan(0.2), reason: '$path is too quiet or silent');
      expect(w.peak, lessThan(0.99), reason: '$path is too loud');
      expect(w.clipped, 0, reason: '$path clips');
      expect(
        w.seconds,
        inInclusiveRange(entry.value.$1, entry.value.$2),
        reason: '$path has an unexpected length',
      );
      expect(
        File(path).lengthSync(),
        lessThan(100 * 1024),
        reason: '$path is over 100 KB',
      );
    }
  });

  test('the music is a real, calm, loop-sized track under 1 MB', () {
    const path = 'assets/${AudioAssets.music}';
    final w = readWav(path);
    expect(w.peak, inInclusiveRange(0.2, 0.9));
    expect(w.clipped, 0);
    expect(w.seconds, inInclusiveRange(8, 30));
    expect(File(path).lengthSync(), lessThan(1024 * 1024));
  });

  test('the music loop starts and ends at the same level (no click)', () {
    final bytes = File('assets/${AudioAssets.music}').readAsBytesSync();
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    final n = (bytes.length - 44) ~/ 2;
    final first = bd.getInt16(44, Endian.little);
    final last = bd.getInt16(44 + (n - 1) * 2, Endian.little);
    // a jump bigger than 5% of full scale at the seam would be a click
    expect((first - last).abs(), lessThan(32768 * 0.05));
  });
}
