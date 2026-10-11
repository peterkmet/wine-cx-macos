# Investigation

This page records the investigation that led to this setup: the log of each step and the observations, moved from the private `wine-cross` repository.

## Log

| Date | Step | Result |
|---|---|---|
| 2026-09-28 | Created `~/github/wine-cross` and a private GitHub repository. | Done |
| 2026-09-28 | Downloaded and extracted `crossover-sources-26.3.0.tar.gz` into `sources/`. | Done. SHA-256 `ac99c8ca4b3848f3e81784135f023df266b61c2345726ea55a50b3e030dd6872`, 832 MB extracted, Wine version 11.0. |
| 2026-09-28 | Ran `./fetchDependencies --macos && make macos` in `sources/moltenvk`. | Failed. The script tried to clone `https://github.com/peterkmet/SPIRV-Cross.git` and deleted the bundled `External/SPIRV-Cross`. |
| 2026-09-28 | Extracted the bundled SPIRV-Cross to `sources/SPIRV-Cross-cx` and ran `./fetchDependencies --macos --spirv-cross-root <path> && make macos`. | Failed. Xcode 27 rejects `MACOSX_DEPLOYMENT_TARGET = 10.15`; the supported range is 12.0 to 27.0. |
| 2026-09-28 | Added `scripts/xcode-overrides.xcconfig` with `MACOSX_DEPLOYMENT_TARGET = 12.0`, exported it as `XCODE_XCCONFIG_FILE`, and ran the same build again. | Done. `sources/moltenvk/Package/Release/MoltenVK/dynamic/dylib/macOS/libMoltenVK.dylib` is a universal binary (x86_64, arm64). |
| 2026-09-28 | Found prebuilt CrossOver-based Wine: `fiendish/wine-cx-macos` (CX 26.3.0), `srimanachanta/winecx-dist` (CX 26.1.0), Sikarugir (CX 24.0.7). | `wine-cx-macos` uses the MacPorts MoltenVK, not the CrossOver one. |
| 2026-09-28 | Reviewed all `wine-cx-macos` code (about 1600 lines). | No suspicious code. Downloads are pinned by SHA-256 and size; actions are pinned by commit. |
| 2026-09-28 | Forked it to the public `peterkmet/wine-cx-macos`, added `scripts/build-moltenvk.sh`, replaced the MacPorts MoltenVK in `build-release.sh`, and limited releases to manual tagged runs. | Local run of `build-moltenvk.sh` passed. GitHub Actions run `36429120194` started. |
| 2026-09-28 | Watched run `36429120194`. | Done in 2 h 10 min. The artifact contains `libMoltenVK.dylib` (x86_64) from the CrossOver sources. |
| 2026-09-28 | Created `prefix/` with `wineboot --init` and installed Steam with `SteamSetup.exe /S`. | Done |
| 2026-09-28 | Started Steam without the webhelper wrapper. | The webhelper disabled the GPU (`Disabled/CrashCount`), ran 5 processes, and reported `Browser requested transparent background, but it is not supported`. This matches the black window from the first attempt. |
| 2026-09-28 | Added `scripts/steamwebhelper-wrapper.c` and `scripts/steam.command`, installed `mingw-w64`, and restarted Steam. | One webhelper process with `--disable-gpu --single-process`; the sign-in page loaded. |
| 2026-09-28 | Copied Dungeon Village 2 (94 MB) and its `appmanifest_1983710.acf` from the CrossOver bottle. | Done |
| 2026-09-28 | Started `KairoGames.exe` directly, also with `steam_appid.txt`. | The game always calls `steam://run/1983710` and exits when Steam is not signed in. `steam_appid.txt` was removed. |
| 2026-09-28 | Copied `config/loginusers.vdf`, `config/config.vdf`, and `users/crossover/AppData/Local/Steam/local.vdf` from the CrossOver bottle. | Steam signed in without a password prompt (`Logged On ... 'OK'`). |
| 2026-09-28 | Started the game with `steam.exe -applaunch 1983710`. | `Player.log`: `Direct3D 11.0 [level 11.1]`, `Renderer: Apple M3 Max`. The game kept running. |
| 2026-09-28 | Control test: restarted Steam with `VK_DRIVER_FILES` pointing to the stock MoltenVK from `wine-stable-11.0_1` and started the game. | `d3d11: failed to create device and context (80004005)`, `Failed to initialize graphics.` Hypothesis confirmed. |
| 2026-09-28 | Restarted Steam with the CrossOver MoltenVK. | Steam is running and signed in. |
| 2026-09-28 | User test: started Dungeon Village 2 from our Steam. | Game and sound work. Text is missing. |
| 2026-09-28 | Hypothesis 1: MoltenVK needs full image view swizzle for the `A8` font texture. Restarted Steam with `MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE=1`. | Refuted. Text is still missing. |
| 2026-09-28 | Hypothesis 2: the MoltenVK builds differ. Restarted Steam with `VK_DRIVER_FILES` pointing to the CrossOver `libMoltenVK.dylib` and checked the game process with `lsof`. | Refuted. The game loaded the CrossOver MoltenVK, and text is still missing. |
| 2026-09-28 | Compared `C:\windows\Fonts`: the CrossOver bottle has 55 fonts, our prefix has none. | New lead. |
| 2026-09-28 | Hypothesis 3: Unity falls back to system fonts. Copied the 55 fonts from the CrossOver bottle into `prefix/drive_c/windows/Fonts`. | Confirmed. The game shows text. |
| 2026-09-28 | Added the 55 fonts to `fonts/` and a font copy step to `scripts/steam.command`. | The setup no longer needs the CrossOver bottle for fonts. |
| 2026-09-28 | Replaced the usage section with a procedure for a new Mac, and made `scripts/steam.command` create `build/logs`. | `build/` is ignored by git, so a fresh clone does not have it. |
| 2026-09-28 | User test: compared Dungeon Village 2 in CrossOver and in our Wine. | In our Wine, some objects disappear and appear again. CrossOver shows no flicker. |
| 2026-09-28 | Compared the CrossOver bottle and the CrossOver `bin/wine` launcher with our setup. | CrossOver sets `cb_access_map_w=1` (Direct3D), `AllowSetGamma=0` (Mac Driver), `WINEMSYNC=1`, and `ROSETTA_ADVERTISE_AVX=1`. The CrossOver app adds no settings for this bottle. |
| 2026-09-28 | Added `scripts/crossover.reg` and made `scripts/steam.command` import it and export `WINEMSYNC=1` and `ROSETTA_ADVERTISE_AVX=1`. | `reg query` shows both values. The flicker needs a manual check. |
| 2026-09-28 | User test with the CrossOver settings. | Refuted. The game still flickers: the background appears before the layer above it, and sometimes the whole game flickers. |
| 2026-09-28 | Hypothesis 4: our MoltenVK build causes the flicker. Restarted Steam with `VK_DRIVER_FILES` pointing to the `libMoltenVK.dylib` of the CrossOver app and checked the game process with `lsof`. | Confirmed. The game loaded the CrossOver MoltenVK and does not flicker. |
| 2026-09-28 | Added the CrossOver `libMoltenVK.dylib` to `moltenvk/` with an ICD file and the Apache 2.0 license, and made `scripts/steam.command` set `VK_DRIVER_FILES`. | The setup no longer uses the MoltenVK from the Wine CX build. |
| 2026-10-11 | Moved the scripts and notes of the private `wine-cross` repository into this repository. | The fonts are no longer stored in git. `scripts/fetch-fonts.sh` downloads them. |

## Observations

- CrossOver 26.3.0 does not set a graphics backend in `cxbottle.conf` for the Steam bottle. The only bottle environment variable besides the creator ID is `WINEMSYNC=1`.
- Source archive: `https://media.codeweavers.com/pub/crossover/source/crossover-sources-26.3.0.tar.gz` (149 MB).
- The CrossOver MoltenVK enables geometry shaders in source: `sources/moltenvk/MoltenVK/MoltenVK/GPUObjects/MVKDevice.mm:2491` sets `_features.geometryShader = true;  // XXX Required by DXVK for D3D10`. This is the root cause of the feature level difference.
- The CrossOver `libMoltenVK.dylib` is built for x86_64 only, because the Wine Unix side runs as x86_64 under Rosetta.
- `fetchDependencies` derives the SPIRV-Cross URL from the first git remote of the enclosing repository (`git remote get-url`). Inside this repository it resolves to `peterkmet/SPIRV-Cross`. Before cloning, it deletes `External/SPIRV-Cross`. Always pass `--spirv-cross-root` with the CodeWeavers SPIRV-Cross from the archive.
- The build moved to GitHub Actions in the public fork `peterkmet/wine-cx-macos`, because public repositories get macOS runner minutes for free and the Intel runner (`macos-15-intel`) removes the need for an Intel Homebrew on this Mac. The Intel Homebrew was never installed.
- A push that changes `.github/workflows/` needs the `workflow` scope on the `gh` token: `gh auth refresh -h github.com -s workflow`.
- Security: the prebuilt `wine-cx-macos` release was not used, because it comes from an unknown author and runs with full access to the user account. Only a build from the reviewed fork is used.
- The CrossOver Wine build does not fix the black Steam window by itself. The CrossOver app probably applies a fix from its closed compatibility database. The webhelper wrapper is still necessary.
- Both CrossOver and this Wine build use the Windows user name `crossover`. Files under `drive_c/users/crossover/` can be copied between prefixes without path changes.
- The Wine CX launcher (`bin/wine`) sets `VK_DRIVER_FILES` only when it is empty. A test can point it to another MoltenVK ICD file without changes to the app.
- Kairosoft games call `steam://run/<appid>` at startup even with `steam_appid.txt`. They need a signed-in Steam client.
- `screencapture` fails from this shell (`could not create image from display`), so window content cannot be checked automatically. Text, sound, and input need a manual check.
- Unity games need Windows fonts in `C:\windows\Fonts`, although they bundle their own fonts. With an empty font directory, the game runs but draws no text. The missing text with DXVK in the first attempt probably had the same cause.
- The CrossOver bottle also maps macOS system fonts (for example Hiragino and Apple SD Gothic Neo) into the Windows font registry under `Software\Microsoft\Windows NT\CurrentVersion\Fonts`. This was not necessary for Dungeon Village 2.
- `cb_access_map_w=1` lets `wined3d` map constant buffers for write access. `scripts/steam.command` applies it and the other CrossOver settings at each start.
- The MoltenVK of the CrossOver app and the MoltenVK built in the fork are both version 1.2.10, but the builds differ: macOS SDK 15.1 and 15.5, minimum macOS 10.15 and 14.0, and other versions of the `fetchDependencies` libraries (glslang or SPIRV-Tools). Only the build of the fork flickers. Which difference causes the flicker is open.
- The fonts are stored in `fonts/` (55 files, 380 MB), so the setup no longer depends on a CrossOver bottle. A replacement with freely licensed fonts is open.
