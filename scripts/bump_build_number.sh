#!/usr/bin/env bash
# Incrémente le build number (+N) dans pubspec.yaml et commit le changement.
# Usage : ./scripts/bump_build_number.sh

set -euo pipefail

PUBSPEC="$(dirname "$0")/../pubspec.yaml"

current=$(grep '^version:' "$PUBSPEC" | head -1 | sed 's/version: //')
name="${current%+*}"
build="${current##*+}"
new_build=$((build + 1))
new_version="${name}+${new_build}"

sed -i "s/^version: .*/version: ${new_version}/" "$PUBSPEC"

echo "Version : ${current} → ${new_version}"

git add "$PUBSPEC"
git commit -m "chore: bump build number to ${new_build} (${name})"
