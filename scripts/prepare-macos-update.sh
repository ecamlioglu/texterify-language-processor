#!/bin/bash
# Prepare signed Sparkle metadata for an already-notarized release. No publishing.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
release_dir="${1:?Usage: bash scripts/prepare-macos-update.sh dist/releases/Texterify-Renamer-VERSION-arm64}"
release_dir="$(cd "$release_dir" && pwd)"
tools_dir="$repo_root/macos/.build/artifacts/sparkle/Sparkle/bin"
account=com.erdemdev.texterifyrenamer
archives=("$release_dir"/Texterify-Renamer-*.zip)
[[ ${#archives[@]} == 1 && -f "${archives[0]}" ]] || { echo "Expected one release ZIP." >&2; exit 1; }
archive="${archives[0]}"
work="$(mktemp -d "$repo_root/dist/.update-metadata.XXXXXX")"
trap 'rm -rf "$work"' EXIT
(cd "$release_dir" && shasum -a 256 -c SHA256SUMS.txt)
ditto -x -k "$archive" "$work/extracted"
app="$work/extracted/Texterify Renamer.app"
plist="$app/Contents/Info.plist"
codesign --verify --deep --strict "$app"
xcrun stapler validate "$app"
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$plist")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
key="$("$tools_dir/generate_keys" --account "$account" -p)"
[[ "$key" == "$(/usr/libexec/PlistBuddy -c 'Print SUPublicEDKey' "$plist")" ]] || {
  echo "Sparkle public key does not match the packaged app." >&2; exit 1;
}
mkdir "$work/feed"
cp "$archive" "$work/feed/"
"$tools_dir/generate_appcast" --account "$account" --maximum-deltas 0 \
  --download-url-prefix "https://github.com/ecamlioglu/texterify-language-processor/releases/download/macos-v$version/" \
  "$work/feed"
"$tools_dir/sign_update" --account "$account" --verify "$work/feed/appcast.xml"
python3 "$repo_root/scripts/verify-macos-update.py" "$work/feed/appcast.xml" "$archive" "$plist"
cp "$work/feed/appcast.xml" "$release_dir/appcast.xml"
echo "Signed update feed ready: $release_dir/appcast.xml (not published)"
