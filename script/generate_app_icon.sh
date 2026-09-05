#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SET="$ROOT_DIR/Sources/AppleMusicDeduplicator/Assets.xcassets/AppIcon.appiconset"
SOURCE_ICON="$ICON_SET/icon_512x512@2x.png"

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "Missing 1024-pixel source icon: $SOURCE_ICON" >&2
  exit 1
fi

# Keep the approved 1024-pixel asset as the source; refresh missing/older sizes.
for size in 16 32 128 256 512; do
  for scale in 1 2; do
    pixels=$((size * scale))
    suffix=""
    if [[ "$scale" == 2 ]]; then suffix="@2x"; fi
    output_icon="$ICON_SET/icon_${size}x${size}${suffix}.png"
    if [[ "$output_icon" == "$SOURCE_ICON" ]]; then continue; fi
    if [[ -f "$output_icon" && ! "$SOURCE_ICON" -nt "$output_icon" ]]; then continue; fi
    /usr/bin/sips -z "$pixels" "$pixels" "$SOURCE_ICON" \
      --out "$output_icon" >/dev/null
  done
done
