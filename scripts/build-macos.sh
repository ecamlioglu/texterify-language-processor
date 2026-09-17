#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-release}"
if [[ "$configuration" != release && "$configuration" != debug ]]; then
  echo "Usage: scripts/build-macos.sh [release|debug]" >&2
  exit 2
fi

cmp "$repo_root/config/language_mappings.json" "$repo_root/macos/Sources/RenamerCore/Resources/default-config.json" || {
  echo "Default config changed. Sync macos/Sources/RenamerCore/Resources/default-config.json first." >&2
  exit 1
}
swift build --package-path "$repo_root/macos" -c "$configuration"
bin_dir="$(swift build --package-path "$repo_root/macos" -c "$configuration" --show-bin-path)"
mkdir -p "$repo_root/dist"
staging_dir="$(mktemp -d "$repo_root/dist/.package.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT
app_dir="$staging_dir/Texterify Renamer.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$bin_dir/TexterifyRenamer" "$app_dir/Contents/MacOS/"
cp "$repo_root/macos/Packaging/Info.plist" "$app_dir/Contents/Info.plist"
sparkle_root="$repo_root/macos/.build/artifacts/sparkle/Sparkle"
framework="$app_dir/Contents/Frameworks/Sparkle.framework"
mkdir -p "$app_dir/Contents/Frameworks"
ditto "$sparkle_root/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework" "$framework"
# The app has outgoing-network permission; only the installer XPC is needed.
rm -rf "$framework/Versions/B/XPCServices/Downloader.xpc"
for resource in "$bin_dir"/*.bundle; do
  [[ -d "$resource" ]] || continue
  ditto "$resource" "$app_dir/Contents/Resources/$(basename "$resource")"
done
icon_dir="$repo_root/macos/.build/AppIcon.iconset"
swift "$repo_root/macos/Packaging/make-icon.swift" "$icon_dir"
iconutil -c icns "$icon_dir" -o "$app_dir/Contents/Resources/AppIcon.icns"
cp "$repo_root/LICENSE" "$app_dir/Contents/Resources/LICENSE.txt"
cp "$repo_root/macos/.build/checkouts/ZIPFoundation/LICENSE" "$app_dir/Contents/Resources/ZIPFoundation-LICENSE.txt"
cp "$sparkle_root/LICENSE" "$app_dir/Contents/Resources/Sparkle-LICENSE.txt"

# Ad-hoc signing is for use on this Mac. Set SIGNING_IDENTITY to a Developer ID
# identity for distribution; notarization is a separate, explicit release step.
signing_options=(--timestamp=none)
if [[ "${SIGNING_IDENTITY:--}" != "-" ]]; then
  signing_options=(--timestamp)
fi
entitlements="$repo_root/macos/Packaging/App.entitlements"
if [[ "${SIGNING_IDENTITY:--}" == "-" ]]; then
  # Library Validation needs a team identity. Relax it only for local ad-hoc builds.
  entitlements="$staging_dir/Local.entitlements"
  cp "$repo_root/macos/Packaging/App.entitlements" "$entitlements"
  /usr/libexec/PlistBuddy -c 'Add com.apple.security.cs.disable-library-validation bool true' "$entitlements"
fi
for nested in "$framework/Versions/B/XPCServices/Installer.xpc" \
              "$framework/Versions/B/Autoupdate" "$framework/Versions/B/Updater.app" "$framework"; do
  codesign --force --sign "${SIGNING_IDENTITY:--}" --options runtime "${signing_options[@]}" "$nested"
done
codesign --force --sign "${SIGNING_IDENTITY:--}" --options runtime "${signing_options[@]}" \
  --entitlements "$entitlements" "$app_dir"
codesign --verify --deep --strict --verbose=2 "$app_dir"
rm -rf "$repo_root/dist/Texterify Renamer.app"
mv "$app_dir" "$repo_root/dist/Texterify Renamer.app"
echo "$repo_root/dist/Texterify Renamer.app"
