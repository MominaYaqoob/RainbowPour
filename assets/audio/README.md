# Audio files

These seven files are **generated sounds** (made by `tools/make_sounds.dart`:
synthesised from sine/triangle waves and noise, no samples, nothing copied).
They are real, but simple. To use professional sounds, replace a file and keep
the **name and the `.wav` extension** (if you want `.mp3` or `.ogg`, change the
paths in `lib/core/audio_service.dart`, class `AudioAssets`, one place).

To change the generated sounds: edit `tools/make_sounds.dart` (notes, decay,
volume) and run, from the project root:

```bash
dart run tools/make_sounds.dart assets/audio
```

| File | Played when | What it is |
|------|-------------|-----------|
| `tap.wav` | any button is pressed | soft "pop" |
| `select.wav` | a bottle is selected or put back | two quick rising blips |
| `pour.wav` | a pour starts | water stream with bubbles (1.5 s) |
| `bottle_full.wav` | a bottle is completed | sparkling 4-note "ding" |
| `win.wav` | level or challenge complete | short fanfare and a chord (2 s) |
| `fail.wav` | level failed, stuck, or time up | two falling notes |
| `music_loop.wav` | background music, looped | calm pad and soft arpeggio, 16 s, seamless loop |

Format: 22.05 kHz, 16-bit, mono WAV. Size advice for release: each sound effect
under about 100 KB, the music loop under about 1 MB (now 705 KB). A test
(`test/core/audio_assets_test.dart`) checks that every file is a valid WAV, is
not silent, does not clip and stays inside these limits.
