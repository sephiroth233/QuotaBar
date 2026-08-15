#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
bundle_root="$project_root/dist/QuotaBar.app"
contents_root="$bundle_root/Contents"
binary_root="$contents_root/MacOS"
build_root="${TMPDIR:-/private/tmp}/quotabar-release-build"
module_cache="${TMPDIR:-/private/tmp}/quotabar-module-cache"

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

echo "Created $bundle_root"
