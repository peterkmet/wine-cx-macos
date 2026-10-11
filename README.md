# wine-cross

This repository builds Wine from the published CrossOver 26.3.0 sources with the MoltenVK of the CrossOver 26.3.0 app. The goal is to run Windows Steam games on an Apple Silicon Mac without the CrossOver app. The build includes the open-source Wine changes, but not the non-free commercial parts of CrossOver.

## Background

The goal is to run simple Kairosoft games (Unity, 2D) from the Windows Steam library on macOS 27 (Apple M3 Max).

A stock Wine 11.0 build ran Windows Steam only with a wrapper for `steamwebhelper.exe`. Dungeon Village 2 (Unity 2021.3, 32-bit) failed in every Direct3D 11 setup. With `wined3d` and stock MoltenVK, Wine reported feature level 9_3, and Unity stopped with `d3d11: failed to create device and context (80004005)`.

CrossOver 26.3.0 runs the same game through the regular Wine path: `d3d11.dll` → `wined3d.dll` → `winevulkan` → `libMoltenVK.dylib`. The CrossOver `libMoltenVK.dylib` contains geometry shader support. Stock MoltenVK does not. Direct3D feature level 10_0 requires geometry shaders.

**Result:** The CrossOver MoltenVK lets `wined3d` offer feature level 11_1, so Unity can create its device. Unity games also need Windows fonts in `C:\windows\Fonts` to draw text.

The full log of the investigation and the observations are in [docs/investigation.md](docs/investigation.md).

## Licensing

CodeWeavers publishes the CrossOver sources because Wine is licensed under LGPL. The source archive contains `wine`, `moltenvk`, `vkd3d`, `dxvk`, and supporting libraries.

The archive does not contain the CrossOver app, the CrossTie recipes, the compatibility database (`cxcompatdb`), the license check, or D3DMetal. A build from these sources has no license check. The result must not be called CrossOver, because the name is a trademark.

This repository contains scripts, notes, and the CrossOver MoltenVK in `moltenvk/`. It contains no fonts, no CrossOver sources, and no other build output.

- `moltenvk/libMoltenVK.dylib` comes from the CrossOver 26.3.0 app. MoltenVK is licensed under Apache 2.0, see `moltenvk/LICENSE`. The CrossOver license lists MoltenVK under Apache 2.0 (section 2, Appendix A).
- `scripts/fetch-fonts.sh` downloads the Windows fonts into `fonts/`, which git ignores:
  - Microsoft core fonts (Andale Mono, Arial, Arial Black, Comic Sans, Courier New, Georgia, Impact, Times New Roman, Trebuchet, Verdana, Webdings): the Microsoft license allows redistribution only as the original installers. The script downloads these installers, and only the user's Mac extracts the fonts.
  - Source Han Sans (`SourceHanSans*.otf`): SIL Open Font License, see `fonts/LICENSE-source-han-sans.txt` after the download.

## Fork changes

This repository is a fork of [`fiendish/wine-cx-macos`](https://github.com/fiendish/wine-cx-macos).

- The app contains the MoltenVK of the CrossOver 26.3.0 app from `moltenvk/` in place of the MacPorts MoltenVK. `scripts/build-release.sh` replaces the MacPorts `libMoltenVK.dylib` with it before packaging. The CrossOver MoltenVK enables geometry shaders. `wined3d` needs them to offer Direct3D feature level 10_0 or higher, which Unity games require.
- The workflow compiles `scripts/steamwebhelper-wrapper.c` with MinGW-w64 into `steamwebhelper-wrapper.exe` and publishes it with the release. For Windows Steam, `steamwebhelper-wrapper.exe` replaces `steamwebhelper.exe` in `C:\Program Files (x86)\Steam\bin\cef\cef.win64`. The wrapper starts the original program, renamed to `steamwebhelper_orig.exe`, with `--disable-gpu --single-process`. Without the wrapper, the Steam window is black. `scripts/steam.command` puts the wrapper in place.
- A push to `main` builds the app as a workflow artifact only. A release needs a manual run with a tag.

## Build

The Wine app is built in GitHub Actions in this repository. The workflow builds Wine from the CrossOver 26.3.0 sources through MacPorts on an Intel runner (`macos-15-intel`) and replaces the MacPorts MoltenVK with the CrossOver MoltenVK from `moltenvk/`.

A push to `main` starts a build. The build takes about 2 hours and uploads `Wine-CX-26.3.0-macos-x86_64` as a workflow artifact for 14 days. A manual run with a tag also publishes a release with the app archive, the license archive, the CrossOver source archive, and `steamwebhelper-wrapper.exe`.

## Set up on a new Mac

Use this procedure to run the Wine setup on another Mac or after a clean installation. It takes about 20 minutes, or about 2.5 hours when a new Wine build is necessary.

Note: this procedure works after the rename of this repository to `peterkmet/wine-cross` and after a tagged run of the workflow. The release `v26.3.0` from before this change has the self-built MoltenVK and no wrapper.

Prerequisites:

- An Apple Silicon Mac with Homebrew.

1. Install Rosetta 2:

   ```bash
   softwareupdate --install-rosetta --agree-to-license
   ```

2. Install `cabextract` and the GitHub CLI, and sign in:

   ```bash
   brew install cabextract gh
   gh auth login
   ```

3. Clone this repository:

   ```bash
   git clone https://github.com/peterkmet/wine-cross.git ~/github/wine-cross
   cd ~/github/wine-cross
   ```

4. Download the latest release:

   ```bash
   gh release download -R peterkmet/wine-cross -D dist
   ```

   `dist/` then contains `Wine-CX-26.3.0-macos-x86_64.tar.xz`, `steamwebhelper-wrapper.exe`, the license archive, and the CrossOver source archive. If no release exists, start a workflow run with a tag that has no release yet, wait until it finishes (about 2 h 10 min), and do this step again:

   ```bash
   gh workflow run build.yml -R peterkmet/wine-cross -f tag=<tag>
   gh run watch -R peterkmet/wine-cross
   ```

5. Extract the app:

   ```bash
   tar -xf dist/Wine-CX-26.3.0-macos-x86_64.tar.xz -C dist
   ```

   The result is `dist/Wine CX.app`. Keep `dist/steamwebhelper-wrapper.exe` in place. If macOS blocks the app, remove the quarantine attribute:

   ```bash
   xattr -dr com.apple.quarantine "dist/Wine CX.app"
   ```

6. Download the Windows fonts into `fonts/`:

   ```bash
   scripts/fetch-fonts.sh
   ```

7. Create the Wine prefix and install Steam:

   ```bash
   export WINEPREFIX="$PWD/prefix"
   mkdir -p build
   "dist/Wine CX.app/Contents/Resources/wine/bin/wineboot" --init
   curl -sSL -o build/SteamSetup.exe https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe
   "dist/Wine CX.app/Contents/Resources/wine/bin/wine" build/SteamSetup.exe /S
   ```

   Optional: to keep the games, saved games, and Steam sign-in, copy the `prefix/` directory from the old Mac instead of this step. Steam can ask for a new sign-in after the move.

8. Start Steam:

   ```bash
   scripts/steam.command
   ```

   You can also double-click `scripts/steam.command` in Finder. The script puts `dist/steamwebhelper-wrapper.exe` in place of `steamwebhelper.exe`, copies the fonts from `fonts/` that `C:\windows\Fonts` does not have, imports the CrossOver registry settings from `scripts/crossover.reg` (with Source Han Sans SC in place of Microsoft YaHei and SimSun), and starts Steam with `-noverifyfiles`. The script stops with an error when `dist/steamwebhelper-wrapper.exe` is absent or `fonts/` is empty. Without the wrapper, the Steam window is black. Without the fonts, Unity games draw no text.

   The first start downloads a Steam update, so the sign-in window appears after about one minute.

9. Sign in with Steam Guard and install a game from the library.

10. Start the game and verify the result:

    ```bash
    grep -A1 'Direct3D:' prefix/drive_c/users/crossover/AppData/LocalLow/*/*/Player.log
    ```

    The expected result is `Version:  Direct3D 11.0 [level 11.1]`. The game must also show text.

If MP3, WMA, or video does not play in a Windows program, install the separate [GStreamer 1.28.5 runtime](https://gstreamer.freedesktop.org/data/pkg/osx/1.28.5/gstreamer-1.0-1.28.5-universal.pkg). MUSHclient's WAV sounds do not need it.
