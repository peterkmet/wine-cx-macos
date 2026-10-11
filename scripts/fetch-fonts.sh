#!/bin/bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
download_dir="$repo_root/build/fonts-download"
fonts_dir="$repo_root/fonts"
han_release="https://github.com/adobe-fonts/source-han-sans/releases/download/2.005R"

if ! command -v cabextract >/dev/null
then
  echo "cabextract is missing: brew install cabextract" >&2
  exit 1
fi

# url sha256 size
downloads="
https://downloads.sourceforge.net/corefonts/andale32.exe 0524fe42951adc3a7eb870e32f0920313c71f170c859b5f770d82b4ee111e970 198384
https://downloads.sourceforge.net/corefonts/arial32.exe 85297a4d146e9c87ac6f74822734bdee5f4b2a722d7eaa584b7f2cbf76f478f6 554208
https://downloads.sourceforge.net/corefonts/arialb32.exe a425f0ffb6a1a5ede5b979ed6177f4f4f4fdef6ae7c302a7b7720ef332fec0a8 168176
https://downloads.sourceforge.net/corefonts/comic32.exe 9c6df3feefde26d4e41d4a4fe5db2a89f9123a772594d7f59afd062625cd204e 246008
https://downloads.sourceforge.net/corefonts/courie32.exe bb511d861655dde879ae552eb86b134d6fae67cb58502e6ff73ec5d9151f3384 646368
https://downloads.sourceforge.net/corefonts/georgi32.exe 2c2c7dcda6606ea5cf08918fb7cd3f3359e9e84338dc690013f20cd42e930301 392440
https://downloads.sourceforge.net/corefonts/impact32.exe 6061ef3b7401d9642f5dfdb5f2b376aa14663f6275e60a51207ad4facf2fccfb 173288
https://downloads.sourceforge.net/corefonts/times32.exe db56595ec6ef5d3de5c24994f001f03b2a13e37cee27bc25c58f6f43e8f807ab 661728
https://downloads.sourceforge.net/corefonts/trebuc32.exe 5a690d9bb8510be1b8b4fe49f1f2319651fe51bbe54775ddddd8ef0bd07fdac9 357200
https://downloads.sourceforge.net/corefonts/verdan32.exe c1cb61255e363166794e47664e2f21af8e3a26cb6346eb8d2ae2fa85dd5aad96 351992
https://downloads.sourceforge.net/corefonts/webdin32.exe 64595b5abc1080fba8610c5c34fab5863408e806aafe84653ca8575bed17d75a 185072
$han_release/07_SourceHanSansJ.zip c6b77d7aabdee4ff6cc24823e3f1048c41cd5bba9df61ca59b071183ec297195 95479981
$han_release/08_SourceHanSansK.zip 3f43910d3bd7bbbae283b9e05b05b2315a2a71e4880d015625994c6b309e9392 95317596
$han_release/09_SourceHanSansSC.zip ef7364f7ac2564be1ae9c1d74276de2653fe38b73449070398c4fc0b7e032ff1 95177106
$han_release/10_SourceHanSansTC.zip 28058dc7d729560c5fa5c850e7298905cac8de55c1e33cfd5cb13e3d7408989e 95332943
https://raw.githubusercontent.com/adobe-fonts/source-han-sans/2.005R/LICENSE.txt fcac737e761ec63dbfbdce11030a1780161920d80315edba9c8beff1c2bac5a2 4463
"

mkdir -p "$download_dir" "$fonts_dir"

while read -r url sha256 size
do
  [ -n "$url" ] || continue
  file="$download_dir/${url##*/}"

  # Skip the download when the file is already present and intact
  if [ ! -f "$file" ] || [ "$(shasum -a 256 "$file" | cut -d' ' -f1)" != "$sha256" ]
  then
    curl -fL -o "$file" "$url"
  fi

  found_size="$(stat -f %z "$file")"
  if [ "$found_size" != "$size" ]
  then
    echo "$file: size expected $size, found $found_size" >&2
    exit 1
  fi
  found_sha256="$(shasum -a 256 "$file" | cut -d' ' -f1)"
  if [ "$found_sha256" != "$sha256" ]
  then
    echo "$file: sha256 expected $sha256, found $found_sha256" >&2
    exit 1
  fi

  case "$file" in
    *32.exe) cabextract -q -L -F '*.ttf' -d "$fonts_dir" "$file" ;;
    *.zip) unzip -q -o -j "$file" '*.otf' -d "$fonts_dir" ;;
    */LICENSE.txt) cp "$file" "$fonts_dir/LICENSE-source-han-sans.txt" ;;
  esac
done <<< "$downloads"

echo "Fonts are in $fonts_dir"
