#!/bin/bash

# omarchy-spacefast: publish to the web from Omarchy with Spacefast.
#
#   ./install.sh                    everything: menu, bar widget, agent skill
#   ./install.sh share skill        just the pieces you name (share, plugin, skill)
#   ./install.sh --uninstall        remove everything (or name pieces to remove)
#   ./install.sh --no-cli           do not install the Spacefast CLI (curl fallback still works)

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PARTS=()
FLAGS=()
UNINSTALL=0

for arg in "$@"; do
  case "$arg" in
  share | menu) PARTS+=(share) ;;
  plugin | widget | bar) PARTS+=(plugin) ;;
  skill) PARTS+=(skill) ;;
  all) PARTS+=(share plugin skill) ;;
  --uninstall) UNINSTALL=1; FLAGS+=("$arg") ;;
  --no-cli) FLAGS+=("$arg") ;;
  -h | --help) sed -n 3,9p "$0"; exit 0 ;;
  *) echo "Unknown option: $arg (use share, plugin, skill)" >&2; exit 1 ;;
  esac
done
((${#PARTS[@]})) || PARTS=(share plugin skill)

run_part() {
  local part="$1" args=()
  for flag in "${FLAGS[@]}"; do
    # The skill has no CLI to install.
    [[ $part == skill && $flag == --no-cli ]] && continue
    args+=("$flag")
  done
  echo "==> $part"
  bash "$HERE/$part/install.sh" "${args[@]}"
}

for part in "${PARTS[@]}"; do
  run_part "$part"
done

if ((!UNINSTALL)); then
  echo
  echo "Done. Try: Omarchy menu → Trigger → Share → Web, or ask your agent to put something online."
fi
