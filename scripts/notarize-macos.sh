#!/bin/bash
# Notarize a signed app, staple its ticket, then create the distribution ZIP.
# No credentials are read from files or printed; use a local Keychain profile.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to your notarytool Keychain profile}"
: "${TEAM_ID:?Set TEAM_ID to the expected Developer ID team}"
source_app="$repo_root/dist/Texterify Renamer.app"
codesign --verify --deep --strict --verbose=2 "$source_app"
signature="$(codesign -d --verbose=4 "$source_app" 2>&1)"
[[ "$signature" == *"Authority=Developer ID Application:"* ]] || {
  echo "A Developer ID Application signature is required; ad-hoc builds cannot be released." >&2
  exit 1
}
actual_team="$(printf '%s\n' "$signature" | sed -n 's/^TeamIdentifier=//p')"
[[ "$actual_team" == "$TEAM_ID" ]] || { echo "Signing team mismatch." >&2; exit 1; }
[[ "$signature" == *"(runtime)"* && "$signature" == *"Timestamp="* ]] || {
  echo "Hardened Runtime and a secure timestamp are required." >&2
  exit 1
}
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$source_app/Contents/Info.plist")"
arch="$(lipo -archs "$source_app/Contents/MacOS/TexterifyRenamer")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid release version." >&2; exit 1; }
case "$arch" in
  arm64|x86_64) ;;
  'x86_64 arm64'|'arm64 x86_64') arch=universal ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac
release_name="Texterify-Renamer-$version-$arch"
release_dir="$repo_root/dist/releases/$release_name"
[[ ! -e "$release_dir" ]] || { echo "Release already exists: $release_dir" >&2; exit 1; }
mkdir -p "$repo_root/dist/notarization" "$repo_root/dist/releases"
work_dir="$(mktemp -d "$repo_root/dist/notarization/$release_name.XXXXXX")"
echo "Notarization work and logs: $work_dir"
# Keep the submitted app/logs on failure or timeout; do not resubmit blindly.
app="$work_dir/Texterify Renamer.app"
ditto "$source_app" "$app"
ditto -c -k --keepParent "$app" "$work_dir/submission.zip"
xcrun notarytool submit "$work_dir/submission.zip" \
  --keychain-profile "$NOTARY_PROFILE" --wait --timeout 20m \
  --output-format json > "$work_dir/submission.json"
status="$(plutil -extract status raw -o - "$work_dir/submission.json")"
if [[ "$status" != Accepted ]]; then
  echo "Notarization status: $status. See $work_dir/submission.json; no release was created." >&2
  exit 1
fi
xcrun stapler staple "$app"
xcrun stapler validate "$app"
codesign --verify --deep --strict --verbose=2 "$app"
spctl --assess --type execute --verbose=2 "$app"

mkdir "$work_dir/release"
ditto -c -k --keepParent "$app" "$work_dir/release/$release_name.zip"
# Verify the artifact after extraction, not only the source bundle.
mkdir "$work_dir/verify"
ditto -x -k "$work_dir/release/$release_name.zip" "$work_dir/verify"
codesign --verify --deep --strict --verbose=2 "$work_dir/verify/Texterify Renamer.app"
xcrun stapler validate "$work_dir/verify/Texterify Renamer.app"
(
  cd "$work_dir/release"
  shasum -a 256 "$release_name.zip" > SHA256SUMS.txt
  shasum -a 256 -c SHA256SUMS.txt
)
mv "$work_dir/release" "$release_dir"
echo "Verified release: $release_dir"
echo "Test a browser-downloaded copy on another Mac before publishing. Nothing was uploaded to GitHub."
