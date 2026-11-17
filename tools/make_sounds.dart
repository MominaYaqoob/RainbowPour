// Generates the game sounds (assets/audio/*.wav) from scratch: no samples,
// no copied audio. Run from the project root:
//   dart run tools/make_sounds.dart assets/audio
// Change the notes/envelopes below and run it again to tune the sounds.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int rate = 22050;

/// A mono float buffer in -1..1.
class Buf {
  Buf(double seconds) : d = Float64List((seconds * rate).round());
  final Float64List d;
  int get n => d.length;
}

double sine(double phase) => math.sin(2 * math.pi * phase);
double tri(double phase) {
  final p = phase - phase.floorToDouble();
  return 4 * (p < 0.5 ? p : 1 - p) - 1;
}

/// Adds a decaying bell-like note starting at [start] seconds. When [wrap]
/// is true the tail wraps around to the start (for a seamless loop).
void bell(
  Buf b,
  double start,
  double freq,
  double amp, {
  double decay = 0.25,
  double attack = 0.004,
  double len = 1.0,
  bool wrap = false,
  double harm2 = 0.3,
  double harm3 = 0.1,
}) {
  final s0 = (start * rate).round();
  final count = (len * rate).round();
  for (var i = 0; i < count; i++) {
    final t = i / rate;
    final env = (t < attack ? t / attack : 1.0) * math.exp(-t / decay);
    if (t > attack && env < 1e-4) break;
    final v =
        (sine(freq * t) +
            harm2 * sine(2 * freq * t) +
            harm3 * sine(3 * freq * t)) *
        env *
        amp;
    var idx = s0 + i;
    if (wrap) {
      idx %= b.n;
    } else if (idx >= b.n) {
      break;
    }
    b.d[idx] += v;
  }
}

/// Soft pad note (slow attack and release), wraps for loops.
void pad(Buf b, double start, double len, double freq, double amp) {
  final s0 = (start * rate).round();
  final count = (len * rate).round();
  final a = math.min(1.2, len * 0.3);
  final r = math.min(1.6, len * 0.4);
  for (var i = 0; i < count; i++) {
    final t = i / rate;
    final up = math.min(1.0, t / a);
    final down = math.min(1.0, (len - t) / r);
    final env = up * down;
    final v =
        (sine(freq * t) * 0.6 +
            sine(freq * 1.003 * t) * 0.4 +
            sine(2 * freq * t) * 0.12) *
        env *
        amp;
    b.d[(s0 + i) % b.n] += v;
  }
}

void normalize(Buf b, double peak) {
  var m = 0.0;
  for (final v in b.d) {
    m = math.max(m, v.abs());
  }
  if (m == 0) return;
  final g = peak / m;
  for (var i = 0; i < b.n; i++) {
    b.d[i] *= g;
  }
}

/// Fades the first and last [ms] so there is no click.
void edges(Buf b, double ms) {
  final k = (ms / 1000 * rate).round();
  for (var i = 0; i < k && i < b.n; i++) {
    final g = i / k;
    b.d[i] *= g;
    b.d[b.n - 1 - i] *= g;
  }
}

void writeWav(String path, Buf b) {
  final dataLen = b.n * 2;
  final bytes = ByteData(44 + dataLen);
  void ascii(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLen, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataLen, Endian.little);
  for (var i = 0; i < b.n; i++) {
    final v = (b.d[i].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(44 + i * 2, v, Endian.little);
  }
  File(path).writeAsBytesSync(bytes.buffer.asUint8List());
}

// ---------------------------------------------------------------- sounds

Buf tap() {
  final b = Buf(0.09);
  for (var i = 0; i < b.n; i++) {
    final t = i / rate;
    final f = 900 - 3500 * t; // quick pitch drop: a soft "pop"
    final env = math.exp(-t / 0.022);
    b.d[i] = sine(f * t) * env;
  }
  edges(b, 2);
  normalize(b, 0.55);
  return b;
}

Buf select() {
  final b = Buf(0.16);
  bell(b, 0.0, 587.3, 0.6, decay: 0.05, harm2: 0.15, harm3: 0, len: 0.12);
  bell(b, 0.045, 880.0, 0.6, decay: 0.06, harm2: 0.15, harm3: 0, len: 0.12);
  edges(b, 2);
  normalize(b, 0.55);
  return b;
}

Buf pour() {
  const len = 1.5;
  final b = Buf(len);
  final rng = math.Random(7);
  var lp = 0.0, lp2 = 0.0;
  for (var i = 0; i < b.n; i++) {
    final t = i / rate;
    // body of the stream: noise through two soft low-pass stages
    final noise = rng.nextDouble() * 2 - 1;
    final cut = 0.10 + 0.04 * sine(0.9 * t) + 0.03 * sine(2.3 * t);
    lp += cut * (noise - lp);
    lp2 += cut * (lp - lp2);
    final env = math.min(1.0, t / 0.18) * math.min(1.0, (len - t) / 0.35);
    b.d[i] = (lp2 * 3.2 + lp * 0.8) * env * 0.5;
  }
  // bubbles: short rising chirps at random times
  var t = 0.12;
  while (t < len - 0.25) {
    final f0 = 380 + rng.nextDouble() * 520;
    final dur = 0.045 + rng.nextDouble() * 0.05;
    final s0 = (t * rate).round();
    final c = (dur * rate).round();
    for (var i = 0; i < c && s0 + i < b.n; i++) {
      final u = i / rate;
      final f = f0 * (1 + 2.2 * u / dur);
      final env = math.sin(math.pi * i / c);
      b.d[s0 + i] += sine(f * u) * env * 0.16;
    }
    t += 0.05 + rng.nextDouble() * 0.11;
  }
  edges(b, 12);
  normalize(b, 0.7);
  return b;
}

Buf bottleFull() {
  final b = Buf(0.9);
  const notes = [1046.5, 1318.5, 1568.0, 2093.0];
  for (var i = 0; i < notes.length; i++) {
    bell(b, i * 0.075, notes[i], 0.5, decay: 0.16, len: 0.6);
  }
  // a soft low "thud" of the full bottle
  bell(b, 0.0, 330.0, 0.35, decay: 0.12, harm2: 0.1, harm3: 0, len: 0.4);
  edges(b, 3);
  normalize(b, 0.7);
  return b;
}

Buf win() {
  final b = Buf(2.0);
  const run = [523.25, 659.25, 783.99, 1046.5, 1318.5];
  for (var i = 0; i < run.length; i++) {
    bell(b, i * 0.13, run[i], 0.5, decay: 0.28, len: 1.0);
  }
  const chord = [523.25, 659.25, 783.99, 1046.5];
  for (final f in chord) {
    bell(b, 0.7, f, 0.32, decay: 0.7, len: 1.3, harm2: 0.25);
  }
  bell(b, 0.7, 2093.0, 0.14, decay: 0.45, len: 1.2, harm2: 0);
  edges(b, 4);
  normalize(b, 0.75);
  return b;
}

Buf fail() {
  final b = Buf(1.0);
  // two falling soft notes, a gentle "aww"
  for (var i = 0; i < 2; i++) {
    final start = i * 0.32;
    final f0 = i == 0 ? 330.0 : 262.0;
    final s0 = (start * rate).round();
    final c = (0.5 * rate).round();
    for (var k = 0; k < c && s0 + k < b.n; k++) {
      final t = k / rate;
      final f = f0 * (1 - 0.08 * t);
      final env = math.min(1.0, t / 0.02) * math.exp(-t / 0.2);
      b.d[s0 + k] += (tri(f * t) * 0.7 + sine(f * t) * 0.3) * env * 0.5;
    }
  }
  edges(b, 4);
  normalize(b, 0.6);
  return b;
}

Buf music() {
  // One loop: 4 chords of 4 s at 60 bpm (16 s). Tails wrap around, so the
  // loop point is seamless.
  const bar = 4.0;
  final b = Buf(4 * bar);
  // C major, A minor, F major, G major (low pad voicings)
  const chords = [
    [130.81, 196.00, 261.63, 329.63],
    [110.00, 164.81, 220.00, 261.63],
    [87.31, 130.81, 174.61, 261.63],
    [98.00, 146.83, 196.00, 246.94],
  ];
  for (var c = 0; c < 4; c++) {
    for (final f in chords[c]) {
      pad(b, c * bar - 0.2, bar + 0.8, f, 0.20);
    }
  }
  // soft arpeggio of the chord tones in eighth notes
  const arp = [
    [523.25, 659.25, 783.99, 659.25],
    [440.00, 523.25, 659.25, 523.25],
    [349.23, 440.00, 523.25, 440.00],
    [392.00, 493.88, 587.33, 493.88],
  ];
  for (var c = 0; c < 4; c++) {
    for (var k = 0; k < 8; k++) {
      final f = arp[c][k % 4];
      bell(
        b,
        c * bar + k * 0.5,
        f,
        0.11,
        decay: 0.35,
        len: 1.4,
        wrap: true,
        harm2: 0.12,
        harm3: 0,
      );
    }
  }
  // a quiet bell melody once per bar
  const melody = [1046.5, 880.0, 698.46, 783.99];
  for (var c = 0; c < 4; c++) {
    bell(
      b,
      c * bar + 2.0,
      melody[c],
      0.12,
      decay: 0.7,
      len: 2.4,
      wrap: true,
      harm2: 0.2,
      harm3: 0,
    );
  }
  normalize(b, 0.5);
  return b;
}

void main(List<String> args) {
  final dir = args.first;
  Directory(dir).createSync(recursive: true);
  writeWav('$dir/tap.wav', tap());
  writeWav('$dir/select.wav', select());
  writeWav('$dir/pour.wav', pour());
  writeWav('$dir/bottle_full.wav', bottleFull());
  writeWav('$dir/win.wav', win());
  writeWav('$dir/fail.wav', fail());
  writeWav('$dir/music_loop.wav', music());
  stdout.writeln('done');
}
