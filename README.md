# Wine CX for macOS

A standalone Wine app built from the published CrossOver 26.3.0 source. It includes the open-source Wine changes, but not the non-free commercial parts.

## Install

1. Download [Wine-CX-26.3.0-macos-x86_64.tar.xz](https://github.com/fiendish/wine-cx-macos/releases/download/v26.3.0/Wine-CX-26.3.0-macos-x86_64.tar.xz)
2. Extract it
3. Move `Wine CX.app` to your `Applications` folder.

Apple Silicon Macs require installing Rosetta.

If MP3, WMA, or video does not play in a Windows program, install the separate [GStreamer 1.28.5 runtime](https://gstreamer.freedesktop.org/data/pkg/osx/1.28.5/gstreamer-1.0-1.28.5-universal.pkg). MUSHclient's WAV sounds do not need it.

## Fork changes

This fork builds MoltenVK from the CrossOver 26.3.0 sources instead of using the MacPorts MoltenVK. The CrossOver MoltenVK enables geometry shaders. `wined3d` needs them to offer Direct3D feature level 10_0 or higher, which Unity games require.

- `scripts/build-moltenvk.sh` builds MoltenVK with the SPIRV-Cross that the CrossOver sources bundle.
- `scripts/build-release.sh` replaces the MacPorts `libMoltenVK.dylib` with that build before packaging.
- A push to `main` builds the app as a workflow artifact only. A release needs a manual run with a tag.
