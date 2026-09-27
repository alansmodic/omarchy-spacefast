#!/bin/bash

# Installs the Spacefast bar widget from this folder. When the plugin has its
# own git repository, `omarchy plugin add <url> --enable` does the same and
# also supports `omarchy plugin update`.
#
#   ./install.sh               install and enable
#   ./install.sh --no-enable   install only
#   ./install.sh --uninstall   disable and remove

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ID=$(jq -r '.id' "$HERE/manifest.json")
TARGET="$HOME/.config/omarchy/plugins/$ID"

ENABLE=1
UNINSTALL=0
INSTALL_CLI=1
for arg in "$@"; do
  case "$arg" in
  --no-enable) ENABLE=0 ;;
  --no-cli) INSTALL_CLI=0 ;;
  --uninstall) UNINSTALL=1 ;;
  -h | --help) sed -n 3,10p "$0"; exit 0 ;;
  *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# Installs `sf` the way Omarchy ships its other npm tools, then makes sure it
# actually runs. mise refuses packages whose supply-chain trust evidence got
# weaker between releases; when that happens, leave no broken wrapper behind
# (omarchy-spacefast would pick it up) and fall back to npx or curl.
install_sf_cli() {
  command -v sf >/dev/null 2>&1 && return 0
  if ! command -v omarchy-mise-install >/dev/null 2>&1; then
    echo "Tip: install the Spacefast CLI for sign-in and share links: npm install -g spacefast"
    return 0
  fi
  omarchy-mise-install npm:spacefast sf
  local out
  if out=$("$HOME/.local/bin/sf" --version 2>&1); then
    echo "Installed the sf command (Spacefast CLI $(head -1 <<<"$out"))"
  else
    rm -f "$HOME/.local/bin/sf"
    echo "Could not install the sf command through mise:" >&2
    grep -m1 -iE 'error|trust' <<<"$out" | sed 's/^/  /' >&2 || true
    echo "Publishing still works (npx spacefast, or curl without Node)." >&2
  fi
}

command -v omarchy-shell >/dev/null 2>&1 || { echo "This needs Omarchy's shell (omarchy-shell)" >&2; exit 1; }

if ((UNINSTALL)); then
  omarchy plugin disable "$ID" >/dev/null 2>&1 || true
  rm -rf "$TARGET"
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  echo "Removed the Spacefast bar widget"
  exit 0
fi

if [[ -d $TARGET/.git ]]; then
  echo "$TARGET is a git checkout; update it with: omarchy plugin update $ID" >&2
  exit 1
fi

# Copy without symlinks, which the plugin loader refuses.
rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -rL "$HERE/." "$TARGET/"
rm -f "$TARGET/install.sh"
chmod +x "$TARGET/bin/omarchy-spacefast"

omarchy plugin validate "$TARGET" >/dev/null

((INSTALL_CLI)) && install_sf_cli

omarchy-shell shell rescanPlugins >/dev/null
if ((ENABLE)); then
  for _ in $(seq 40); do
    omarchy plugin list --json 2>/dev/null | jq -e --arg id "$ID" 'any(.[]; .id == $id)' >/dev/null && break
    sleep 0.05
  done
  omarchy plugin enable "$ID" --section right
fi

echo "Installed the Spacefast bar widget ($ID)."
echo "Click it for your spaces, right-click to publish a folder."
