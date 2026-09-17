#!/bin/bash
# Explicit publication: versioned ZIP first, stable signed feed LAST.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
release_dir="${1:?Usage: bash scripts/publish-macos-release.sh RELEASE_DIR}"
release_dir="$(cd "$release_dir" && pwd)"
repo=ecamlioglu/texterify-language-processor
tools_dir="$repo_root/macos/.build/artifacts/sparkle/Sparkle/bin"
account=com.erdemdev.texterifyrenamer
[[ -z "$(git status --porcelain -- macos config scripts .github)" ]] || {
  echo "Commit and push the app, config, scripts and workflows before publishing." >&2; exit 1;
}
[[ "$(gh repo view "$repo" --json isPrivate --jq .isPrivate)" == false ]] || {
  echo "The update feed must be publicly downloadable without credentials." >&2; exit 1;
}
archives=("$release_dir"/Texterify-Renamer-*.zip)
[[ ${#archives[@]} == 1 && -f "${archives[0]}" ]] || exit 1
archive="${archives[0]}"
work="$(mktemp -d "$repo_root/dist/.publish.XXXXXX")"
trap 'rm -rf "$work"' EXIT
(cd "$release_dir" && shasum -a 256 -c SHA256SUMS.txt)
ditto -x -k "$archive" "$work/extracted"
app="$work/extracted/Texterify Renamer.app"
plist="$app/Contents/Info.plist"
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$plist")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
tag="macos-v$version"
revision="$(git rev-parse HEAD)"
[[ "$(gh api "repos/$repo/commits/$tag" --jq .sha)" == "$revision" ]] || {
  echo "Push $tag at the reviewed source commit before publishing." >&2; exit 1;
}
cmp macos/Packaging/Info.plist "$plist"
codesign --verify --deep --strict "$app"
xcrun stapler validate "$app"
spctl --assess --type execute "$app"
"$tools_dir/sign_update" --account "$account" --verify "$release_dir/appcast.xml"
python3 scripts/verify-macos-update.py "$release_dir/appcast.xml" "$archive" "$plist"
if gh release view macos-updates --repo "$repo" >/dev/null 2>&1; then
  curl --fail --silent --show-error --location \
    "https://github.com/$repo/releases/download/macos-updates/appcast.xml" -o "$work/previous.xml"
  "$tools_dir/sign_update" --account "$account" --verify "$work/previous.xml"
  python3 scripts/verify-macos-update.py "$release_dir/appcast.xml" "$archive" "$plist" "$work/previous.xml"
fi

notes="docs/releases/macos-$version.md"
[[ -f "$notes" ]] || { echo "Missing release notes: $notes" >&2; exit 1; }
published=false
if gh release view "$tag" --repo "$repo" --json isDraft > "$work/release.json" 2>/dev/null; then
  if [[ "$(plutil -extract isDraft raw -o - "$work/release.json")" == false ]]; then published=true; fi
else
  gh release create "$tag" --repo "$repo" --verify-tag --draft --latest=false \
    --title "Texterify Renamer $version (macOS)" --notes-file "$notes"
fi
if [[ "$published" == false ]]; then
  gh release upload "$tag" --repo "$repo" "$archive" "$release_dir/SHA256SUMS.txt" "$release_dir/appcast.xml" --clobber
  gh release edit "$tag" --repo "$repo" --draft=false --latest=false
fi

# Verify the public CDN bytes before advertising the update to installed apps.
curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
  "https://github.com/$repo/releases/download/$tag/$(basename "$archive")" -o "$work/download.zip"
cmp "$archive" "$work/download.zip"

if ! gh release view macos-updates --repo "$repo" >/dev/null 2>&1; then
  gh release create macos-updates --repo "$repo" --target "$revision" --prerelease --latest=false \
    --title 'macOS update feed' --notes 'Signed update metadata for Texterify Renamer. Download the app from a macos-v release.'
fi
gh release upload macos-updates --repo "$repo" "$release_dir/appcast.xml" --clobber
curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
  "https://github.com/$repo/releases/download/macos-updates/appcast.xml" -o "$work/public-appcast.xml"
cmp "$release_dir/appcast.xml" "$work/public-appcast.xml"
"$tools_dir/sign_update" --account "$account" --verify "$work/public-appcast.xml"
echo "Published and verified: https://github.com/$repo/releases/tag/$tag"
