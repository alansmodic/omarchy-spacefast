#!/bin/bash

# Installs the omarchy-spacefast agent skill for Claude Code, Codex, pi, and
# any agent that reads ~/.agents/skills, the same places Omarchy links its own
# skills.
#
#   ./install.sh               install
#   ./install.sh --uninstall   remove

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NAME="omarchy-spacefast"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-spacefast/skills/$NAME"
TARGETS=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.pi/agent/skills"
)

UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
  --uninstall) UNINSTALL=1 ;;
  -h | --help) sed -n 3,9p "$0"; exit 0 ;;
  *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if ((UNINSTALL)); then
  for dir in "${TARGETS[@]}"; do
    link="$dir/$NAME"
    if [[ -L $link ]]; then rm -f "$link"; fi
  done
  rm -rf "$SHARE_DIR"
  rmdir "$(dirname "$SHARE_DIR")" "$(dirname "$(dirname "$SHARE_DIR")")" 2>/dev/null || true
  echo "Removed the $NAME skill"
  exit 0
fi

src="$HERE/$NAME"
[[ -f $src/SKILL.md ]] || { echo "SKILL.md not found in $src" >&2; exit 1; }

mkdir -p "$(dirname "$SHARE_DIR")"
rm -rf "$SHARE_DIR"
cp -r "$src" "$SHARE_DIR"

linked=()
for dir in "${TARGETS[@]}"; do
  # ~/.agents always; the others only for agents that are present.
  parent=$(dirname "$dir")
  [[ $dir == "$HOME/.agents/skills" || -d $parent ]] || continue
  mkdir -p "$dir"
  link="$dir/$NAME"
  if [[ -e $link && ! -L $link ]]; then
    echo "Skipping $link (a real directory is already there)" >&2
    continue
  fi
  ln -sfn "$SHARE_DIR" "$link"
  linked+=("$dir")
done

echo "Installed the $NAME skill for: ${linked[*]}"
echo "Agents will now offer Spacefast when you ask to put something on the web."
