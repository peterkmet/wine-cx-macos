#!/bin/zsh
# Starts Windows Steam with the Wine CX build in the prefix <repo>/prefix
root="${0:A:h:h}"
export WINEPREFIX="$root/prefix" WINEDEBUG=-all
# Matches the CrossOver 26.3.0 Steam bottle and launcher
export WINEMSYNC=1 ROSETTA_ADVERTISE_AVX=1
wine="$root/dist/Wine CX.app/Contents/Resources/wine/bin/wine"
mkdir -p "$root/build/logs"

# Deploys the webhelper wrapper again, because Steam updates overwrite it
cef="$WINEPREFIX/drive_c/Program Files (x86)/Steam/bin/cef/cef.win64"
wrapper="$root/dist/steamwebhelper-wrapper.exe"
if [[ ! -f "$wrapper" ]]; then
    echo "Missing dist/steamwebhelper-wrapper.exe: download the release (see README.md)" >&2
    exit 1
fi
if [[ -f "$cef/steamwebhelper.exe" ]] && ! cmp -s "$wrapper" "$cef/steamwebhelper.exe"; then
    mv "$cef/steamwebhelper.exe" "$cef/steamwebhelper_orig.exe"
    cp "$wrapper" "$cef/steamwebhelper.exe"
fi

# Copies the Windows fonts that the prefix does not have; Unity games draw no text without them
fonts="$WINEPREFIX/drive_c/windows/Fonts"
if [[ -z "$(ls -A "$root/fonts" 2>/dev/null)" ]]; then
    echo "No fonts in fonts/: run scripts/fetch-fonts.sh" >&2
    exit 1
fi
mkdir -p "$fonts"
cp -n "$root/fonts/"* "$fonts/"

# Applies the CrossOver Direct3D and Mac driver registry settings
"$wine" regedit /S "Z:$root/scripts/crossover.reg"

"$wine" "C:\\Program Files (x86)\\Steam\\steam.exe" -noverifyfiles "$@" > "$root/build/logs/steam.log" 2>&1 &
