# PRD: One public repository `wine-cross`

Date: 2026-10-11

## Goal

One public repository builds and assembles everything that runs Windows Steam games on an Apple Silicon Mac:

- Wine from the public CrossOver 26.3.0 sources. GitHub Actions builds it on an Intel runner. The user's Mac needs no Intel toolchain.
- The `libMoltenVK.dylib` of the CrossOver 26.3.0 app inside the Wine app.
- The scripts that create the prefix, install the fonts and start Steam.

Today the work is split over two repositories:

- `peterkmet/wine-cx-macos` is a public fork of `fiendish/wine-cx-macos`. It builds `Wine CX.app` and builds MoltenVK from the CrossOver sources with `scripts/build-moltenvk.sh`.
- `peterkmet/wine-cross` is private. It holds the scripts, the notes, 53 fonts with 2 license files, and the CrossOver `libMoltenVK.dylib`. The fonts use 380 MB.
- `scripts/steam.command` points `VK_DRIVER_FILES` to the CrossOver dylib, because the self-built MoltenVK flickers (`wine-cross/README.md`, log 2026-09-28, hypothesis 4).

## Scope

1. The fork packages the CrossOver `libMoltenVK.dylib` from `moltenvk/`. It no longer builds MoltenVK.
2. The workflow compiles `steamwebhelper-wrapper.exe` and publishes it with the release.
3. A font script downloads the Microsoft core fonts and Source Han Sans on the user's Mac.
4. The scripts and the documentation of `wine-cross` move into the fork.
5. The user renames the repositories after the run. This is a manual step, on command.

## Out of scope

- A local Wine build on the user's Mac.
- Wine binaries from the CrossOver app. The CrossOver license does not give a right to redistribute them.
- The root cause of the flicker with the self-built MoltenVK.
- Microsoft YaHei and SimSun files. They have no redistribution right and no download source.
- An arm64 Wine build.

## Behavior

```gherkin
Feature: One repository for the Wine setup

  Scenario: Build the Wine app
    Given a push to main
    When the workflow "Build Wine CX" finishes
    Then the artifact contains "Wine CX.app"
    And the MoltenVK in "Wine CX.app" has the same UUID as moltenvk/libMoltenVK.dylib
    And the artifact contains steamwebhelper-wrapper.exe
    And the workflow does not build MoltenVK

  Scenario: Publish a release
    Given a manual workflow run with the tag "v26.3.0"
    When the run finishes
    Then the release contains the Wine app archive, the license archive, the CrossOver source archive and steamwebhelper-wrapper.exe

  Scenario: Install the fonts
    Given cabextract is installed
    When the user runs scripts/fetch-fonts.sh
    Then fonts/ contains the Microsoft core fonts and Source Han Sans J, K, SC and TC
    And the script stops with an error when a download has a different SHA-256 or size

  Scenario: Install the fonts without cabextract
    Given cabextract is not installed
    When the user runs scripts/fetch-fonts.sh
    Then the script stops with an error that names "brew install cabextract"

  Scenario: Start Steam
    Given the Wine app and the wrapper in dist/ and the fonts in fonts/
    When the user runs scripts/steam.command
    Then Steam starts with the wrapper in place of steamwebhelper.exe
    And C:\windows\Fonts contains each file of fonts/
    And the registry maps "Microsoft YaHei" and "SimSun" to "Source Han Sans SC"
    And the Steam process uses the MoltenVK inside "Wine CX.app"

  Scenario: Start Steam without the wrapper or the fonts
    Given dist/steamwebhelper-wrapper.exe is absent or fonts/ is empty
    When the user runs scripts/steam.command
    Then the script stops with an error that names the missing part
```

## Decisions

- **Repository base.** The fork becomes `wine-cross`. The private `wine-cross` cannot become public, because its history contains the Microsoft fonts. Its files move into the fork as new commits, without its history.
- **Font backup.** The user renames the private repository to `wine-cross-private` and archives it. It keeps the 53 fonts as the backup.
- **MoltenVK license.** MoltenVK is licensed under Apache 2.0. The CrossOver license lists MoltenVK under Apache 2.0 in Appendix A and says that its grant does not supersede the licenses of free software components (`CrossOver.app/Contents/SharedSupport/CrossOver/license.txt`, section 2 and line 265). The public repository can contain the dylib with `moltenvk/LICENSE`.
- **MoltenVK in the app.** `moltenvk/libMoltenVK.dylib` and `moltenvk/LICENSE` move into the fork. `scripts/build-release.sh` installs this dylib in place of the MacPorts one. Today it does this with `build/libMoltenVK.dylib` (`scripts/build-release.sh:25-35`). The author removes `scripts/build-moltenvk.sh` and its workflow step. `moltenvk/MoltenVK_icd.json` stays in the private repository, because the app launcher sets `VK_DRIVER_FILES` to the ICD file in the app (`scripts/package-app.py:334`, `:459`).
- **MoltenVK check.** `scripts/package-app.py` rewrites the install names of each bundled dylib and `build-release.sh` signs the app again, so the dylib in the app is not identical byte for byte. The checks are: `cmp` of the `/opt/local` copy before packaging (today `build-release.sh:32`), and `validate-app.py` compares the `dwarfdump --uuid` output of the dylib in the app with `moltenvk/libMoltenVK.dylib`.
- **MoltenVK license entry.** `package-app.py` copies `moltenvk/LICENSE` to `dist/LICENSES/MoltenVK-Apache-2.0.txt` and records the origin "CrossOver 26.3.0 app" for MoltenVK in `components.json`. `validate-app.py` requires that file.
- **`VK_DRIVER_FILES` in `steam.command`.** The author removes it, because the app contains the CrossOver MoltenVK.
- **Wrapper.** The workflow installs the Homebrew bottle `mingw-w64` and compiles `scripts/steamwebhelper-wrapper.c`. `steam.command` takes the exe from `dist/` and no longer compiles it. A new Mac no longer needs `mingw-w64`.
- **Fonts.** `scripts/fetch-fonts.sh` downloads into `fonts/`. Git ignores `fonts/`. The script downloads:
  - the Microsoft core fonts installers `andale32.exe`, `arial32.exe`, `arialb32.exe`, `comic32.exe`, `courie32.exe`, `georgi32.exe`, `impact32.exe`, `times32.exe`, `trebuc32.exe`, `verdan32.exe` and `webdin32.exe` from the SourceForge `corefonts` project. It extracts them with `cabextract`. The license allows redistribution only as these installers, so only the user's Mac extracts the fonts.
  - Source Han Sans region subsets J, K, SC and TC from the `adobe-fonts/source-han-sans` GitHub releases, with the OFL license file.
  - Each download has a pinned URL, SHA-256 and size.
- **Font copy.** `steam.command` copies each file from `fonts/` that is absent in `C:\windows\Fonts` (`cp -n`). Today it copies only into an empty directory (`wine-cross/scripts/steam.command:25-28`), so a migrated prefix would not get Source Han Sans SC.
- **Font substitutes.** `scripts/crossover.reg` gets the key `[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes]` with `"Microsoft YaHei"="Source Han Sans SC"` and `"SimSun"="Source Han Sans SC"`.
- **Release.** The release flow of the fork stays: a push builds an artifact, and only a manual run with a tag makes a release. The release notes name this repository and the CrossOver MoltenVK. The new Mac procedure downloads the release with `gh release download`, so it does not depend on the 14-day artifact. It installs `cabextract` and `gh` with Homebrew in place of `mingw-w64`.
- **Name.** The app keeps the name `Wine CX.app`. "CrossOver" is a trademark, so it is not a product name.
- **Documentation.** `README.md` describes the goal, the licenses, the build and the procedure for a new Mac. The section "Fork changes" stays. The investigation log and the findings of the private `wine-cross/README.md` move to `docs/investigation.md`.
- **Wrapper redeploy.** `steam.command` moves `steamwebhelper.exe` to `steamwebhelper_orig.exe` only when the file is larger than 1000000 bytes (the genuine binary is about 7.5 MB, the wrapper about 17 KB). A smaller file is an older wrapper; the script overwrites it and keeps `steamwebhelper_orig.exe`. Otherwise a new wrapper from a release would overwrite the genuine binary.
- **Wrapper build order.** The workflow installs `mingw-w64` and compiles the wrapper to `$RUNNER_TEMP` before `scripts/prepare.sh`, and copies it into `dist/release/` after `scripts/build-release.sh`. A failure then stops the run before the Wine build of about 2 h.
- **Release tag.** `gh release create` fails for a tag that already has a release. The README tells the user to start the release run with a tag that has no release yet.
- **`.gitignore`.** The fork's `.gitignore` gets `/prefix/` and `/fonts/`. `/build/` and `/dist/` are already in it.
- **Local migration.** The user renames `~/github/wine-cross` to `~/github/wine-cross-private` and `~/github/wine-cx-macos` to `~/github/wine-cross`. `prefix/` moves to the new checkout. It contains Steam, the games and the sign-in. The old `fonts/` does not move: `fetch-fonts.sh` fills `fonts/` in the new checkout.
- **GitHub renames.** These are manual steps after the run, each on command of the user: rename `peterkmet/wine-cross` to `wine-cross-private` and archive it; then rename `peterkmet/wine-cx-macos` to `wine-cross`.
- **Tests.** No automated tests, because the change is scripts, wiring and docs (CLAUDE.md §2). The checks are the workflow run (`validate-app.py`, `cmp` and UUID of the dylib) and a manual game test. Before the game test, the user removes `msyh.ttc` and `simsun.ttc` from `prefix/drive_c/windows/Fonts`. Otherwise the test does not use the Source Han Sans SC substitute.

## Invariants

- `git ls-files` in the public repository lists no `.ttf`, `.ttc`, `.otf` or `*32.exe` file.
- `/fonts/` is in `.gitignore` before the first commit that adds a font script.

## Known consequences

- The self-built MoltenVK path goes away: `scripts/build-moltenvk.sh` and its universal arm64 dylib.
- `moltenvk/MoltenVK_icd.json` and `scripts/xcode-overrides.xcconfig` stay only in the private repository.
- A new Mac gets no Microsoft YaHei or SimSun glyphs. Source Han Sans SC replaces them.
- The old URL `github.com/peterkmet/wine-cx-macos` becomes a redirect to `wine-cross`.
- A new Mac needs a release of this repository. A build artifact is not enough after 14 days.

## Rollback

1. Rename `peterkmet/wine-cross` back to `wine-cx-macos`.
2. Unarchive `peterkmet/wine-cross-private` and rename it back to `wine-cross`.
3. Rename the local checkouts back and move `prefix/` back.

The user does not delete the private repository before a successful game test.

## Risks and assumptions

- Assumption: the `macos-15-intel` runner installs the Homebrew bottle `mingw-w64` in a few minutes.
- Assumption: the SourceForge `corefonts` files have the SHA-256 values that winetricks pins.
- Assumption: Unity text works with the core fonts and Source Han Sans, without `msyh.ttc` and `simsun.ttc`. The manual game test checks it.
