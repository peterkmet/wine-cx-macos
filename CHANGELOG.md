# Changelog

## 2026-10-11

### Added

- The app contains the `libMoltenVK.dylib` of the CrossOver 26.3.0 app (Apache 2.0). `LICENSES/MoltenVK-Apache-2.0.txt` holds its license.
- The release contains `steamwebhelper-wrapper.exe`. It replaces `steamwebhelper.exe` for Windows Steam.
- `scripts/fetch-fonts.sh` downloads the Microsoft core fonts and Source Han Sans J, K, SC and TC into `fonts/`. It needs `cabextract`.
- `scripts/steam.command` starts Windows Steam from `dist/` with the prefix `prefix/`.
- `scripts/crossover.reg` maps the fonts "Microsoft YaHei" and "SimSun" to "Source Han Sans SC".
- `docs/investigation.md` holds the investigation log and the observations.

### Changed

- The workflow no longer builds MoltenVK from the CrossOver sources.
- `README.md` describes the licenses, the build and the setup on a new Mac.

### Removed

- `scripts/build-moltenvk.sh`.
