# Bundled fonts

The app ships its three font families as assets. Nothing is downloaded at runtime,
so the UI renders identically offline, in widget tests, and in golden tests.

| Family | File | Weights used | License |
|--------|------|--------------|---------|
| Plus Jakarta Sans | `plus_jakarta_sans/PlusJakartaSans-Variable.ttf` | 600, 700, 800 | SIL Open Font License 1.1 (`plus_jakarta_sans/OFL.txt`) |
| Inter | `inter/Inter-Variable.ttf` | 400, 500, 600 | SIL Open Font License 1.1 (`inter/OFL.txt`) |
| JetBrains Mono | `jetbrains_mono/JetBrainsMono-Variable.ttf` | 400, 500 | SIL Open Font License 1.1 (`jetbrains_mono/OFL.txt`) |

Sources: the official Google Fonts repository (`github.com/google/fonts`, folders
`ofl/plusjakartasans`, `ofl/inter`, `ofl/jetbrainsmono`). The files are the
upstream **variable** fonts; `pubspec.yaml` declares one entry per weight the app
uses and `AppTypography` pins the `wght` axis with `FontVariation`, so a token
cannot silently render at the font's default weight.

The SIL Open Font License permits bundling and redistribution inside an
application. Each license file must stay next to its font.
