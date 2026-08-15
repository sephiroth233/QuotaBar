#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
distribution_root="$project_root/dist"
bundle_root="$distribution_root/QuotaBar.app"
build_root="${TMPDIR:-/private/tmp}/quotabar-release-build"
module_cache="${TMPDIR:-/private/tmp}/quotabar-module-cache"
stage_root="$(mktemp -d "${TMPDIR:-/private/tmp}/quotabar-package.XXXXXX")"
stage_bundle="$stage_root/QuotaBar.app"
contents_root="$stage_bundle/Contents"
binary_root="$contents_root/MacOS"

trap 'rm -rf "$stage_root"' EXIT

sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
fallback_sdk="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if ! xcodebuild -version >/dev/null 2>&1 && [[ -d "$fallback_sdk" ]]; then
    sdk_path="$fallback_sdk"
fi

cd "$project_root"
build_environment=(
    "SDKROOT=$sdk_path"
    "CLANG_MODULE_CACHE_PATH=$module_cache"
    "SWIFTPM_MODULECACHE_OVERRIDE=$module_cache"
)

env "${build_environment[@]}" swift build \
    -c release \
    --disable-sandbox \
    --scratch-path "$build_root"

bin_root="$(env "${build_environment[@]}" swift build \
    -c release \
    --disable-sandbox \
    --scratch-path "$build_root" \
    --show-bin-path)"

mkdir -p "$binary_root"
cp "$bin_root/QuotaBar" "$binary_root/QuotaBar"
cp "Support/Info.plist" "$contents_root/Info.plist"
xattr -cr "$stage_bundle"
codesign --force --deep --sign - "$stage_bundle"

mkdir -p "$distribution_root"
if [[ -e "$bundle_root" ]]; then
    rm -rf "$bundle_root"
fi
ditto --noextattr --noqtn "$stage_bundle" "$bundle_root"
codesign --verify --deep --strict "$bundle_root"

echo "Created $bundle_root"
