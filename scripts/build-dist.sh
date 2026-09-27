#!/bin/bash

# Builds shareable packages into dist/:
#   omarchy-spacefast-<v>.tar.gz          everything (./install.sh)
#   omarchy-spacefast-share-<v>.tar.gz    Share → Web menu only
#   omarchy-spacefast-plugin-<v>.tar.gz   bar widget only
#   omarchy-spacefast-skill-<v>.tar.gz    agent skill only
#   omarchy-spacefast-plugin/             the plugin as its own git repo (for `omarchy plugin add`)

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
VERSION=$(bin/omarchy-spacefast version)
DIST="$ROOT/dist"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

# The plugin carries its own copy of the CLI (plugin loaders refuse symlinks).
cp bin/omarchy-spacefast plugin/bin/omarchy-spacefast
chmod +x plugin/bin/omarchy-spacefast
jq -e --arg v "$VERSION" '.version == $v' plugin/manifest.json >/dev/null ||
  { echo "plugin/manifest.json version does not match bin/omarchy-spacefast ($VERSION)" >&2; exit 1; }
if command -v omarchy-plugin-validate >/dev/null 2>&1; then
  omarchy-plugin-validate plugin
fi
for f in bin/omarchy-spacefast install.sh share/install.sh plugin/install.sh skill/install.sh; do
  bash -n "$f"
done

rm -rf "$DIST"
mkdir -p "$DIST"

pack() {
  local name="$1" dir="$2"
  tar -czf "$DIST/$name-$VERSION.tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")"
  echo "dist/$name-$VERSION.tar.gz"
}

# Everything.
all="$STAGE/omarchy-spacefast"
mkdir -p "$all"
cp -r README.md LICENSE install.sh bin share plugin skill "$all/"
pack omarchy-spacefast "$all"

# Share menu: needs the CLI next to its installer.
share="$STAGE/omarchy-spacefast-share"
mkdir -p "$share/bin"
cp share/install.sh share/menu.jsonc share/README.md LICENSE "$share/"
cp bin/omarchy-spacefast "$share/bin/"
pack omarchy-spacefast-share "$share"

# Bar widget.
plugin="$STAGE/omarchy-spacefast-plugin"
mkdir -p "$plugin"
cp -r plugin/. "$plugin/"
cp LICENSE "$plugin/"
pack omarchy-spacefast-plugin "$plugin"
cp -r "$plugin" "$DIST/omarchy-spacefast-plugin"

# Agent skill.
skill="$STAGE/omarchy-spacefast-skill"
mkdir -p "$skill"
cp -r skill/. "$skill/"
cp LICENSE "$skill/"
pack omarchy-spacefast-skill "$skill"

echo "dist/omarchy-spacefast-plugin/ (standalone plugin repo)"
