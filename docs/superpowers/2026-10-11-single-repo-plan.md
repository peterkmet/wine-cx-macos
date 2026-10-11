# One public repository `wine-cross` — implementation plan

PRD: `docs/superpowers/2026-10-11-single-repo.md`

**Goal:** The fork builds `Wine CX.app` with the CrossOver `libMoltenVK.dylib`, compiles the Steam webhelper wrapper, and holds the scripts and docs of the private `wine-cross` repository.

**Architecture:** The GitHub Actions workflow on `macos-15-intel` builds Wine through MacPorts (unchanged), installs `moltenvk/libMoltenVK.dylib` in place of the MacPorts MoltenVK, and adds `steamwebhelper-wrapper.exe` to `dist/release/`. On the user's Mac, `scripts/fetch-fonts.sh` fills `fonts/`, and `scripts/steam.command` starts Steam from `dist/`.

**Tech stack:** bash, zsh, Python 3 (standard library), GitHub Actions, MacPorts, Homebrew.

Source repository for moved files: `/Users/lego/github/wine-cross` (private, read only). Target repository: `/Users/lego/github/wine-cx-macos`, branch `feature/2026-10-11-single-repo`.

## Global Constraints

- Code and docs in English. Comments: one line, what the code does, never its history. Keep existing comments.
- Minimum code for the request; surgical diffs; match the existing style (bash scripts use `set -euo pipefail` and `repo_root=...` as in `scripts/build-release.sh:1-4`).
- Conventional Commits, one type per commit, one logical change per commit.
- No file in git may be a font: `git ls-files` lists no `.ttf`, `.ttc`, `.otf` or `*32.exe` file (PRD, Invariants).
- Do not download or run third-party code (libraries, packages) to check behavior (agentic-workflow skill, Run: No external code). Font files and installers that `fetch-fonts.sh` downloads are data, not code. Report what you could not verify.
- Run only the checks of the changed code (`bash -n`, `zsh -n`, `python3 -m py_compile`), never the full suite (agentic-workflow skill, Run: Author tests). A full build needs MacPorts and runs only in GitHub Actions (PRD, Goal).
- Test list (CLAUDE.md §2). Write a test only for: a check against a reference (original program, golden snapshot), a parser or data format, a rule with more than one outcome that no reference check or type check covers (dates, parsing, prices, state machines), a regression of a real bug (one test per bug). No tests for: constants and data tables; wiring, scaffold, CLI arguments, logging; what the compiler, a linter or a standard check catches; UI and layout (the user tests them manually); what another test already covers. No mutation tests.
- This change has no code on the test list. The checks are `validate-app.py` in the workflow and the manual checklist.
- Weakened assertions: none.
- Approval of the Weakened assertions list (agentic-workflow skill, Planning step 6): approved by the user on 2026-10-11.

## Tasks

### Task 1: Ignore local data and add the CrossOver MoltenVK

**Files:** `.gitignore`, `moltenvk/libMoltenVK.dylib`, `moltenvk/LICENSE`

1. Append to `.gitignore` (today: `.gitignore:1-7`):
   ```
   /fonts/
   /prefix/
   ```
2. Copy `/Users/lego/github/wine-cross/moltenvk/libMoltenVK.dylib` and `/Users/lego/github/wine-cross/moltenvk/LICENSE` into `moltenvk/`. Do not copy `MoltenVK_icd.json` (PRD, Decisions: MoltenVK in the app).
3. Check: `file moltenvk/libMoltenVK.dylib` prints `x86_64`; `dwarfdump --uuid moltenvk/libMoltenVK.dylib` prints `28CCB7B1-2908-3954-BAD3-9A4B4F8CE4D3`.
4. Commit `.gitignore` alone: `chore: ignore local fonts and prefix`. Commit `moltenvk/`: `feat: add the MoltenVK of the CrossOver 26.3.0 app`.

### Task 2: Package the CrossOver MoltenVK instead of building it

**Files:** `scripts/build-release.sh`, `scripts/build-moltenvk.sh` (delete), `.github/workflows/build.yml`

1. In `scripts/build-release.sh:25-35`, replace `"$repo_root/build/libMoltenVK.dylib"` with `"$repo_root/moltenvk/libMoltenVK.dylib"` in the `install` and the `cmp` line. Change the comment on line 25 to: `# Replaces the MacPorts MoltenVK with the MoltenVK of the CrossOver 26.3.0 app`.
2. `git rm scripts/build-moltenvk.sh`.
3. In `.github/workflows/build.yml:30`, remove the step `- run: scripts/build-moltenvk.sh`.
4. Check: `bash -n scripts/build-release.sh`; `grep -rn build-moltenvk scripts .github README.md` prints only `README.md:19` (Task 7 rewrites the README).
5. Commit: `feat: package the CrossOver MoltenVK instead of building it`.

### Task 3: Record and check the MoltenVK license and identity

**Files:** `scripts/package-app.py`, `scripts/validate-app.py`

1. In `copy_legal_files` (`scripts/package-app.py:194-200`), after the `MPL-2.0.txt` line, add:
   ```python
   copy_plain(ROOT / "moltenvk/LICENSE", LEGAL / "MoltenVK-Apache-2.0.txt")
   ```
2. After `components = [port_metadata(name) for name in sorted(owners)]` (`scripts/package-app.py:236`), add code that finds the component with `"name" == "MoltenVK"` and sets `"installed": "CrossOver 26.3.0 app"`, `"origin": "CrossOver 26.3.0 app"`, `"license": "Apache-2.0"`, and appends `"MoltenVK-Apache-2.0.txt"` to its `notice_files`. If no such component exists, append `{"name": "MoltenVK", "installed": "CrossOver 26.3.0 app", "origin": "CrossOver 26.3.0 app", "license": "Apache-2.0", "homepage": "https://github.com/KhronosGroup/MoltenVK", "notice_files": ["MoltenVK-Apache-2.0.txt"]}`. Assumption: the MacPorts port name is `MoltenVK` (`scripts/build-release.sh:20` checks a port with this name), and `port provides` names it as the owner of the replaced dylib. The fallback covers the case where it does not.
3. In `scripts/validate-app.py:145-155`, add `"MoltenVK-Apache-2.0.txt"` to the required legal files.
4. In `scripts/validate-app.py`, after the component checks (`:162-167`), add a check: the component `MoltenVK` exists and has `"origin": "CrossOver 26.3.0 app"`.
5. In `scripts/validate-app.py`, add a check that `dwarfdump --uuid` of `WINE / "lib/libMoltenVK.dylib"` and of `ROOT / "moltenvk/libMoltenVK.dylib"` print the same UUID. Use `subprocess.run(["/usr/bin/dwarfdump", "--uuid", ...], check=True, capture_output=True, text=True)` and compare the first token after `UUID:`. The app path comes from the ICD file: `library_path` `../../../../libMoltenVK.dylib` relative to `lib/wine/x86_64-unix/vulkan/icd.d` (`scripts/package-app.py:457-466`). Raise `RuntimeError` with both UUIDs on a difference, as the other checks do.
6. Check: `python3 -m py_compile scripts/package-app.py scripts/validate-app.py`.
7. Commit: `feat: record the CrossOver origin and license of MoltenVK`.

### Task 4: Compile the Steam webhelper wrapper in the workflow

**Files:** `scripts/steamwebhelper-wrapper.c` (new, moved), `.github/workflows/build.yml`

1. Copy `/Users/lego/github/wine-cross/scripts/steamwebhelper-wrapper.c` to `scripts/steamwebhelper-wrapper.c` unchanged.
2. In `.github/workflows/build.yml`, after the `scripts/build-release.sh` step, add two steps:
   ```yaml
         - run: brew install mingw-w64
         - run: x86_64-w64-mingw32-gcc -municode -mwindows -O2 -s -o dist/release/steamwebhelper-wrapper.exe scripts/steamwebhelper-wrapper.c
   ```
   The compiler flags come from `/Users/lego/github/wine-cross/scripts/steam.command:16`. The upload step (`build.yml:32-38`) uploads `dist/release/*`, so the artifact and the release get the exe.
3. In the release notes of `build.yml` (the heredoc `NOTES`), replace the text with: one sentence that the app is built from the published CrossOver 26.3.0 source and contains the MoltenVK of the CrossOver 26.3.0 app (Apache 2.0); the install steps; the line that `steamwebhelper-wrapper.exe` replaces `steamwebhelper.exe` for Windows Steam (see the README of this repository). Keep the GStreamer line.
4. Check: `x86_64-w64-mingw32-gcc -municode -mwindows -O2 -s -o "$TMPDIR/wrapper-check.exe" scripts/steamwebhelper-wrapper.c` passes on this Mac (`/opt/homebrew/bin/x86_64-w64-mingw32-gcc` exists). `python3 -c 'import yaml'` is not available; check the YAML by eye: indentation as the existing steps.
5. Commit: `feat: build the Steam webhelper wrapper in the workflow`.

### Task 5: Add the Steam start script and the registry settings

**Files:** `scripts/steam.command` (new), `scripts/crossover.reg` (new)

1. Copy `/Users/lego/github/wine-cross/scripts/crossover.reg` to `scripts/crossover.reg` and append:
   ```
   
   [HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes]
   "Microsoft YaHei"="Source Han Sans SC"
   "SimSun"="Source Han Sans SC"
   ```
2. Copy `/Users/lego/github/wine-cross/scripts/steam.command` to `scripts/steam.command` (keep the executable bit) and change it:
   - Line 2 comment: `# Starts Windows Steam with the Wine CX build in the prefix <repo>/prefix`.
   - Remove the `VK_DRIVER_FILES` export and its comment (lines 7-8).
   - Replace the wrapper block (lines 12-21): `wrapper="$root/dist/steamwebhelper-wrapper.exe"`; if it is absent, print `Missing dist/steamwebhelper-wrapper.exe: download the release (see README.md)` to stderr and `exit 1`; keep the `cmp`/`mv`/`cp` deploy and its comment. Remove the compile step.
   - Replace the font block (lines 23-28): if `fonts/` has no file, print `No fonts in fonts/: run scripts/fetch-fonts.sh` to stderr and `exit 1`; `mkdir -p "$fonts"`; `cp -n "$root/fonts/"* "$fonts/"`. Comment: `# Copies the Windows fonts that the prefix does not have; Unity games draw no text without them`.
   - Keep the `regedit` import and the Steam start.
3. Check: `zsh -n scripts/steam.command`; `test -x scripts/steam.command`.
4. Commit: `feat: add the Steam start script and registry settings`.

### Task 6: Download the fonts

**Files:** `scripts/fetch-fonts.sh` (new)

1. Assumption to check first: the SHA-256 and size of each core fonts installer. Read the `corefonts` section of the winetricks source as text (`https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks`, `w_download` lines for `andale32.exe`, `arial32.exe`, `arialb32.exe`, `comic32.exe`, `courie32.exe`, `georgi32.exe`, `impact32.exe`, `times32.exe`, `trebuc32.exe`, `verdan32.exe`, `webdin32.exe`). Do not run winetricks. Use the URL `https://downloads.sourceforge.net/corefonts/<file>`. Get the size from the download.
2. Assumption to check first: the asset names, SHA-256 and sizes of the Source Han Sans region subsets J, K, SC and TC in the latest release of `adobe-fonts/source-han-sans` (`gh release view -R adobe-fonts/source-han-sans --json assets`). Use the OTF region subset archives, and the `LICENSE.txt` of the same tag from `raw.githubusercontent.com`.
3. Write `scripts/fetch-fonts.sh` (bash, `set -euo pipefail`, `repo_root` as in `scripts/build-release.sh:4`):
   - If `cabextract` is absent: print `cabextract is missing: brew install cabextract` to stderr, `exit 1`.
   - A table of `url sha256 size` lines. For each line: download with `curl -fL` into `build/fonts-download/` (git-ignored by `/build/`), skip the download when the file exists with the right SHA-256; check the size and `shasum -a 256`; on a difference print the file, the expected and the found value, `exit 1`.
   - Extract each `*32.exe` with `cabextract -q -L -F '*.ttf' -d fonts/`; extract the `*.otf` files of each Source Han Sans archive into `fonts/` (flat, `unzip -j`); copy the license to `fonts/LICENSE-source-han-sans.txt`.
4. Check: `bash -n scripts/fetch-fonts.sh`. If `cabextract` is on this Mac, run the script and compare `ls fonts/` with `/Users/lego/github/wine-cross/fonts/`: the Microsoft fonts of both lists match (case can differ), `msyh.ttc` and `simsun.ttc` are absent, Source Han Sans SC files are new, J, K and TC match the old list. The old `LICENSE-source-han-serif.txt` is not copied, because no Serif font is downloaded. If `cabextract` is absent, report it; do not install it.
5. Check: `git status --short` shows no file in `fonts/`.
6. Commit: `feat: add a script that downloads the Windows fonts`.

### Task 7: Merge the documentation

**Files:** `README.md`, `docs/investigation.md` (new)

Load the docs skill first.

1. Rewrite `README.md` (today 21 lines, `README.md:1-21`) with these sections, from `/Users/lego/github/wine-cross/README.md` and this plan:
   - Title `# wine-cross` and one paragraph: goal (Windows Steam games on an Apple Silicon Mac with Wine from the CrossOver 26.3.0 sources and the CrossOver MoltenVK, without the CrossOver app).
   - Background: short form of `wine-cross/README.md` section "Background" (lines 5-22), with a link to `docs/investigation.md`.
   - Licensing: from `wine-cross/README.md:23-39`, changed: no fonts in the repository; `fetch-fonts.sh` downloads them; Microsoft core fonts are redistributable only as the original installers, so only the user's Mac extracts them; Source Han Sans: SIL OFL; MoltenVK: Apache 2.0, from the CrossOver 26.3.0 app, the CrossOver license (section 2, Appendix A) lists it under Apache 2.0. Keep the trademark sentence.
   - Fork changes: from `README.md:15-21`, changed: the app contains the CrossOver MoltenVK from `moltenvk/`; the workflow compiles `steamwebhelper-wrapper.exe`; upstream is `fiendish/wine-cx-macos`.
   - Build: from `wine-cross/README.md:41-47`, with this repository in place of the fork.
   - Set up on a new Mac: from `wine-cross/README.md:49-137`, changed: `brew install cabextract gh` in place of `mingw-w64 gh`; the repository is public; step 4-5 download the latest release with `gh release download -R peterkmet/wine-cross -D dist` and extract the app archive into `dist/`; when no release exists, start a workflow run with a tag; a new step runs `scripts/fetch-fonts.sh`; step 7 no longer compiles the wrapper and stops when it or the fonts are absent.
   - Keep the GStreamer sentence from `README.md:13`.
   - A note at the start of "Set up on a new Mac": the procedure works after the rename to `peterkmet/wine-cross` and after a tagged run of the workflow. The release `v26.3.0` from before this change has the self-built MoltenVK and no wrapper.
2. Write `docs/investigation.md` with the sections "Log" and "Observations" from `wine-cross/README.md:138-end`, unchanged, and one introduction sentence. Add one log line for 2026-10-11: the scripts and notes moved into this repository; the fonts are downloaded by `scripts/fetch-fonts.sh`.
3. Check: every relative link in both files points to an existing file; `grep -n "peterkmet/wine-cx-macos" README.md docs/investigation.md` prints only lines that describe the old name.
4. Commit: `docs: merge the wine-cross documentation into the README`.

## After the run (manual, each step on command of the user)

1. Push the branch; the push to `main` after the merge starts the build (about 2 h). Check `validate-app.py` passed and the artifact holds `steamwebhelper-wrapper.exe`.
2. GitHub: rename `peterkmet/wine-cross` to `wine-cross-private` and archive it; rename `peterkmet/wine-cx-macos` to `wine-cross`; update the local `origin` URLs.
3. Local: rename the checkouts; move `prefix/`; run `scripts/fetch-fonts.sh`; download the release or artifact into `dist/`.
4. Manual game test with the checklist (remove `msyh.ttc` and `simsun.ttc` from the prefix first).
