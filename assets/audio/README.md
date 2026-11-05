# Audio files

These seven files are **silent placeholders** so the app runs. Replace them with
real sounds and keep the names and the `.wav` extension (if you want `.mp3` or
`.ogg`, change the paths in `lib/core/audio_service.dart`, class `AudioAssets`,
one place).

| File | Played when |
|------|-------------|
| `tap.wav` | any button is pressed |
| `select.wav` | a bottle is selected or put back |
| `pour.wav` | a pour starts |
| `bottle_full.wav` | a bottle is completed |
| `win.wav` | level or challenge complete |
| `fail.wav` | level failed, stuck, or time up |
| `music_loop.wav` | background music, looped |

Size advice for release: each sound effect under about 100 KB, the music loop
under about 1 MB. Short compressed files keep the app small.
