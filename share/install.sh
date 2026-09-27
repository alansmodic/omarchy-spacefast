#!/bin/bash

# Installs the "Share → Web" entries in the Omarchy menu and the
# omarchy-spacefast command they run.
#
#   ./install.sh               install
#   ./install.sh --uninstall   remove the menu entries and the command
#   ./install.sh --no-cli      skip installing the Spacefast CLI (curl fallback still works)

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_DIR="$HOME/.local/bin"
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BEGIN_MARK=">>> omarchy-spacefast"
END_MARK="<<< omarchy-spacefast"

UNINSTALL=0
INSTALL_CLI=1
for arg in "$@"; do
  case "$arg" in
  --uninstall) UNINSTALL=1 ;;
  --no-cli) INSTALL_CLI=0 ;;
  -h | --help) sed -n 3,9p "$0"; exit 0 ;;
  *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

find_cli_source() {
  local candidate
  for candidate in "$HERE/bin/omarchy-spacefast" "$HERE/../bin/omarchy-spacefast"; do
    [[ -f $candidate ]] && { echo "$candidate"; return; }
  done
  echo "omarchy-spacefast script not found next to this installer" >&2
  exit 1
}

remove_menu_block() {
  [[ -f $MENU_FILE ]] || return 0
  local tmp
  tmp=$(mktemp)
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    index($0, b) { skip = 1; next }
    skip && index($0, e) { skip = 0; next }
    !skip { print }
  ' "$MENU_FILE" >"$tmp"
  cat "$tmp" >"$MENU_FILE"
  rm -f "$tmp"
}

add_menu_block() {
  mkdir -p "$(dirname "$MENU_FILE")"
  [[ -f $MENU_FILE ]] || printf '{\n}\n' >"$MENU_FILE"
  remove_menu_block

  # Insert right after the opening brace. Every entry ends with a comma, and
  # the menu parser accepts trailing commas, so whatever follows stays valid.
  local tmp
  tmp=$(mktemp)
  awk -v block="$HERE/menu.jsonc" '
    !done && /^[[:space:]]*\{/ {
      print
      while ((getline line < block) > 0) print line
      done = 1
      next
    }
    { print }
  ' "$MENU_FILE" >"$tmp"
  if ! grep -q "$BEGIN_MARK" "$tmp"; then
    rm -f "$tmp"
    echo "Could not find the opening { in $MENU_FILE; add the entries from menu.jsonc by hand." >&2
    exit 1
  fi
  cat "$tmp" >"$MENU_FILE"
  rm -f "$tmp"
}

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

install_cli() {
  ((INSTALL_CLI)) || return 0
  install_sf_cli
}

if ((UNINSTALL)); then
  remove_menu_block
  rm -f "$BIN_DIR/omarchy-spacefast"
  command -v omarchy-menu >/dev/null 2>&1 && omarchy-menu refresh >/dev/null 2>&1 || true
  echo "Removed Share → Web from the Omarchy menu"
  exit 0
fi

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }
mkdir -p "$BIN_DIR"
install -m 755 "$(find_cli_source)" "$BIN_DIR/omarchy-spacefast"
add_menu_block
install_cli
command -v omarchy-menu >/dev/null 2>&1 && omarchy-menu refresh >/dev/null 2>&1 || true

echo "Added Omarchy menu → Trigger → Share → Web (File, Folder, Clipboard, My Spaces, Sign in)"
echo "Command line: omarchy-spacefast publish <file|folder>"
