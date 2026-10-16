#!/usr/bin/env bash
set -euo pipefail

if [[ "${GITHUB_ACTIONS:-}" != true || -z "${RUNNER_TEMP:-}" ]]; then
  echo "LocalDeck packaging runs only in GitHub Actions: localdeck-package.yml" >&2
  exit 2
fi
arch="${1:-}"
case "$arch" in arm64|x86_64) ;; *) echo "usage: build-localdeck.sh <arm64|x86_64>" >&2; exit 2 ;; esac
[[ "$(uname -m)" == "$arch" ]] || { echo "runner architecture does not match $arch" >&2; exit 2; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
work_dir="${RUNNER_TEMP}/localdeck-package-${arch}"
derived_data="$work_dir/DerivedData"
artifacts="$work_dir/artifacts"
mkdir -p "$artifacts"
exec > >(tee "$work_dir/package.log") 2>&1

scripts/ensure-ghosttykit.sh
# The isolated CI wrapper owns build deadlines and compiler crash prompts.
CMUX_XCODEBUILD_NONINTERACTIVE_LOG_PATH="$work_dir/build.log" \
  python3 scripts/ci/xcodebuild_noninteractive.py xcodebuild \
    -project cmux.xcodeproj -scheme cmux -configuration Release \
    -destination 'platform=macOS' -derivedDataPath "$derived_data" \
    -clonedSourcePackagesDirPath "$work_dir/SourcePackages" \
    ARCHS="$arch" ONLY_ACTIVE_ARCH=YES \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
    CODE_SIGN_ENTITLEMENTS= CMUX_CUA_HELPER_DISPLAY_NAME='LocalDeck Computer Use' \
    build

app="$derived_data/Build/Products/Release/LocalDeck.app"
[[ -d "$app" ]] || { echo "missing LocalDeck build product" >&2; exit 1; }
scripts/ci/verify-binary-archs.sh "$arch" \
  "$app/Contents/MacOS/LocalDeck" \
  "$app/Contents/Resources/bin/cmux" \
  "$app/Contents/Resources/bin/ghostty" \
  "$app/Contents/Resources/bin/cmux-diff-sidecar" \
  "$app/Contents/Resources/bin/cmux-paste-text-worker" \
  "$app/Contents/Frameworks/libcmux_command_palette_nucleo_ffi.dylib" \
  "$app/Contents/Library/cmux Computer Use.app/Contents/MacOS/cmux-cua" \
  "$app/Contents/PlugIns/CmuxDockTilePlugin.plugin/Contents/MacOS/CmuxDockTilePlugin"
# Bundled third-party frameworks may be universal, but must contain this job's slice.
while IFS= read -r -d '' binary; do
  if /usr/bin/file -b "$binary" | grep -q 'Mach-O'; then
    slices="$(lipo -archs "$binary")"
    [[ " $slices " == *" $arch "* ]] || { echo "missing $arch slice: $binary" >&2; exit 1; }
  fi
done < <(find "$app" -type f -print0)
python3 - "$app" <<'PY_CHECK'
from pathlib import Path
import plistlib
import sys

app = Path(sys.argv[1])
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'com.cmuxterm.local', info['CFBundleIdentifier']
assert info['CFBundleExecutable'] == 'LocalDeck', info['CFBundleExecutable']
resources = app / 'Contents/Resources'
for relative in ('LICENSE', 'THIRD_PARTY_LICENSES.md', 'terminfo', 'shell-integration',
                 'ghostty', 'markdown-viewer', 'agent-session-solid'):
    path = resources / relative
    assert path.exists(), f'missing bundled resource: {relative}'
    if path.is_dir():
        assert any(path.rglob('*')), f'empty bundled resource: {relative}'
assert (app / 'Contents/Library/cmux Computer Use.app/Contents/Resources/LICENSE.md').is_file()
PY_CHECK
/usr/bin/codesign --verify --deep --strict "$app"

stage="$work_dir/dmg"
mkdir -p "$stage"
ditto "$app" "$stage/LocalDeck.app"
ln -s /Applications "$stage/Applications"
ditto -c -k --sequesterRsrc --keepParent "$app" "$artifacts/LocalDeck-macos-${arch}.zip"
hdiutil create -volname LocalDeck -srcfolder "$stage" -format UDZO \
  "$artifacts/LocalDeck-macos-${arch}.dmg"
(cd "$artifacts" && shasum -a 256 ./*.zip ./*.dmg > SHA256SUMS)
printf '%s\n' "commit=${GITHUB_SHA}" "architecture=${arch}" "signing=ad-hoc" > "$artifacts/build-info.txt"
(cd "$artifacts" && shasum -a 256 -c SHA256SUMS)
