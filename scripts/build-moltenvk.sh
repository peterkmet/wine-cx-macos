#!/bin/bash
# Builds MoltenVK from the CrossOver sources. This MoltenVK enables geometry shaders,
# which wined3d needs to offer Direct3D feature level 10_0 or higher.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build="$repo_root/build"
src="$build/moltenvk-src"

rm -rf "$src"
mkdir -p "$src"
tar -xzf "$build/crossover-sources.tar.gz" -C "$src" sources/moltenvk

# fetchDependencies deletes External/SPIRV-Cross before it clones, so the bundled copy lives outside it
mv "$src/sources/moltenvk/External/SPIRV-Cross" "$src/SPIRV-Cross"

printf 'MACOSX_DEPLOYMENT_TARGET = 14.0\n' > "$build/moltenvk.xcconfig"
export XCODE_XCCONFIG_FILE="$build/moltenvk.xcconfig"

cd "$src/sources/moltenvk"
./fetchDependencies --macos --spirv-cross-root "$src/SPIRV-Cross"
make macos

lipo -thin x86_64 Package/Release/MoltenVK/dynamic/dylib/macOS/libMoltenVK.dylib \
    -output "$build/libMoltenVK.dylib"
file "$build/libMoltenVK.dylib"
