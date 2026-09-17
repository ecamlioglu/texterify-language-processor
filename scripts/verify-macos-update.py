"""Check a generated appcast points at the exact notarized GitHub asset.

Cryptographic checks are performed separately by Sparkle sign_update/codesign.
"""
import hashlib
import plistlib
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

SPARKLE = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"
REPO = "https://github.com/ecamlioglu/texterify-language-processor"


def verify(feed, archive, plist, previous_feed=None):
    info = plistlib.loads(Path(plist).read_bytes())
    items = ET.parse(feed).findall("./channel/item")
    if len(items) != 1:
        raise ValueError("Expected exactly one stable macOS update")
    item = items[0]
    enclosure = item.find("enclosure")
    if enclosure is None:
        raise ValueError("Missing update archive")
    version = info["CFBundleShortVersionString"]
    expected_url = f"{REPO}/releases/download/macos-v{version}/{Path(archive).name}"
    checks = {
        "bundle identity": info["CFBundleIdentifier"] == "com.erdemdev.texterifyrenamer",
        "feed URL": info["SUFeedURL"] == f"{REPO}/releases/download/macos-updates/appcast.xml",
        "signed feed required": info.get("SURequireSignedFeed") is True,
        "verify before extraction": info.get("SUVerifyUpdateBeforeExtraction") is True,
        "build number": item.findtext(SPARKLE + "version") == info["CFBundleVersion"],
        "display version": item.findtext(SPARKLE + "shortVersionString") == version,
        "minimum macOS": item.findtext(SPARKLE + "minimumSystemVersion") == info["LSMinimumSystemVersion"],
        "GitHub asset": enclosure.get("url") == expected_url,
        "archive size": enclosure.get("length") == str(Path(archive).stat().st_size),
        "archive signature": bool(enclosure.get(SPARKLE + "edSignature")),
        "stable channel": item.find(SPARKLE + "channel") is None,
    }
    failed = [name for name, passed in checks.items() if not passed]
    if failed:
        raise ValueError("Invalid release: " + ", ".join(failed))
    if previous_feed:
        previous = ET.parse(previous_feed).findall("./channel/item")
        if not previous or int(info["CFBundleVersion"]) <= max(int(item.findtext(SPARKLE + "version")) for item in previous):
            raise ValueError("Build number must increase beyond the published update feed")
    print(f"Verified macOS {version} ({info['CFBundleVersion']}): {hashlib.sha256(Path(archive).read_bytes()).hexdigest()}")


if __name__ == "__main__":
    verify(*sys.argv[1:])
