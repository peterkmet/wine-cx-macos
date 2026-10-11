# Manual test checklist: one public repository `wine-cross`

PRD: `docs/superpowers/2026-10-11-single-repo.md`

## Build (GitHub Actions)

- [ ] After the push to `main`, the workflow "Build Wine CX" finishes green.
- [ ] The log shows `brew install mingw-w64` and the wrapper compile before `scripts/prepare.sh`.
- [ ] The log does not show `build-moltenvk.sh`.
- [ ] `validate-app.py` passes both times (the `dist` app and the extracted copy), including the MoltenVK UUID check.
- [ ] The artifact contains `Wine-CX-26.3.0-macos-x86_64.tar.xz`, `Wine-CX-26.3.0-LICENSES.tar.xz`, `crossover-sources-26.3.0.tar.gz` and `steamwebhelper-wrapper.exe`.
- [ ] `LICENSES/MoltenVK-Apache-2.0.txt` exists. In `LICENSES/components.json`, MoltenVK has the origin `CrossOver 26.3.0 app`.
- [ ] `dwarfdump --uuid "Wine CX.app/Contents/Resources/wine/lib/libMoltenVK.dylib"` prints `28CCB7B1-2908-3954-BAD3-9A4B4F8CE4D3`.

## Release

- [ ] A manual run with a new tag (not `v26.3.0`) creates a release with the four files above.
- [ ] The release notes name the CrossOver 26.3.0 MoltenVK and the wrapper, and keep the GStreamer line.

## Fonts

- [ ] `scripts/fetch-fonts.sh` fills `fonts/` with 30 Microsoft `.ttf`, 28 Source Han Sans `.otf` and `LICENSE-source-han-sans.txt`.
- [ ] A second run downloads nothing.
- [ ] With `cabextract` out of `PATH`, the script stops with `cabextract is missing: brew install cabextract`.
- [ ] `git status` shows nothing in `fonts/`.

## Steam

- [ ] Remove `msyh.ttc` and `simsun.ttc` from `prefix/drive_c/windows/Fonts` first.
- [ ] Without `dist/steamwebhelper-wrapper.exe`, `scripts/steam.command` stops with the "Missing dist/steamwebhelper-wrapper.exe" message.
- [ ] With an empty `fonts/`, it stops with the "No fonts in fonts/" message.
- [ ] With the release wrapper in `dist/`: after the first start, `steamwebhelper_orig.exe` is still about 7.5 MB and `steamwebhelper.exe` is the new wrapper.
- [ ] The Steam UI opens and shows text.
- [ ] `C:\windows\Fonts` contains `SourceHanSansSC-*.otf`.
- [ ] `regedit` shows `Microsoft YaHei` and `SimSun` mapped to `Source Han Sans SC` under `HKLM\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes`.
- [ ] The Unity game shows its text, also Chinese text, and does not flicker.

## Documentation

- [ ] The README procedure "Set up on a new Mac" works step by step after the repository rename.
