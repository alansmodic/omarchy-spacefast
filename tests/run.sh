#!/bin/bash
# Offline tests for bin/omarchy-spacefast. Runs under bash 3.2 (macOS) and
# bash 5 (Linux). Nothing touches the network, the Keychain, or real state.
#
#   bash tests/run.sh

set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CLI="$HERE/../bin/omarchy-spacefast"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/sf-tests.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
export SPACEFAST_STATE_DIR="$WORK/state" SPACEFAST_SECRETS=file SPACEFAST_API_URL=http://127.0.0.1:9 \
  OMARCHY_SPACEFAST_ENGINE=curl SPACEFAST_TOKEN=""
PASS=0 FAILS=0

check() { # check NAME EXPECTED ACTUAL
  if [[ $2 == "$3" ]]; then PASS=$((PASS + 1)); echo "ok   $1"
  else FAILS=$((FAILS + 1)); echo "FAIL $1"; echo "     expected: $2"; echo "     actual:   $3"; fi
}

# Run a function from the command with its helpers loaded.
fn() { bash -c 'source "$0" version >/dev/null; "$@"' "$CLI" "$@"; }

echo "bash $BASH_VERSION on $(uname -s)"

# --- file selection -------------------------------------------------------
site="$WORK/site"
mkdir -p "$site/assets" "$site/node_modules/pkg" "$site/.spacefast" "$site/cache" "$site/nested"
echo '<h1>hi</h1>' >"$site/index.html"
echo 'x' >"$site/assets/app.js"
echo 'S=1' >"$site/.env"
echo 'S=2' >"$site/nested/.env.local"
echo 'x' >"$site/node_modules/pkg/index.js"
echo '{}' >"$site/.spacefast/state.json"
echo 'x' >"$site/.DS_Store"
echo 'noise' >"$site/debug.log"
echo 'noise' >"$site/cache/blob"
echo 'ok' >"$site/nested/page with space.md"
ln -s /etc/hosts "$site/hosts-link"
printf '*.log\ncache/\n' >"$site/.gitignore"

check "folder, not a git repo: everything but the never-upload list" \
  ".gitignore assets/app.js cache/blob debug.log index.html nested/page with space.md" \
  "$(fn list_files "$site" | sort | tr '\n' ' ' | sed 's/ $//')"

git -C "$site" init -q && git -C "$site" add index.html && git -C "$site" -c user.name=t -c user.email=t@t commit -qm init
check "folder in a git repo: .gitignore applies too" \
  ".gitignore assets/app.js index.html nested/page with space.md" \
  "$(fn list_files "$site" | sort | tr '\n' ' ' | sed 's/ $//')"

check "secret warning" "Left out .env files" "$(fn secret_warning "$site")"
check "no secret warning" "" "$(fn secret_warning "$site/assets")"

fn make_zip "$site" "$WORK/site.zip"
check "zip holds exactly the listed files" \
  ".gitignore assets/app.js index.html nested/page with space.md" \
  "$(unzip -Z1 "$WORK/site.zip" | sort | tr '\n' ' ' | sed 's/ $//')"

# --- index pages ------------------------------------------------------------
one="$WORK/one"; mkdir -p "$one"; printf 'a < b & c' >"$one/notes.txt"
fn write_index "$one" 'Notes & "things"'
check "text file shown inline, escaped" "1" "$(grep -c '<pre>' "$one/index.html")"
check "text escaped" "1" "$(grep -c 'a &lt; b &amp; c' "$one/index.html")"
check "title escaped" "1" "$(grep -c '<title>Notes &amp; &quot;things&quot;</title>' "$one/index.html")"
check "index does not list itself" "0" "$(grep -c 'href="index.html' "$one/index.html")"

img="$WORK/img"; mkdir -p "$img"; echo png >"$img/Shot.PNG"
fn write_index "$img" "Shot"
check "uppercase image extension previews" "1" "$(grep -c '<img src="Shot.PNG"' "$img/index.html")"

check "clipboard HTML document kept as-is" "<!DOCTYPE html><b>x</b>" "$(fn text_page t '<!DOCTYPE html><b>x</b>')"
check "clipboard text escaped" "1" "$(fn text_page t '<script>x</script>' | grep -c '&lt;script&gt;')"

# --- state and secrets ------------------------------------------------------
mkdir -p "$SPACEFAST_STATE_DIR"
cat >"$SPACEFAST_STATE_DIR/spaces.json" <<'JSON'
{"spc_old":{"spaceId":"spc_old","title":"Old","anonymous":true,"claimKey":"sfc_secret","previewUrl":"https://p/__/sfc_secret","claimUrl":"https://c#sfc_secret","expiresAt":"2999-01-01T00:00:00.000Z","publishedAt":"2026-01-01T00:00:00Z"},
 "spc_owned":{"spaceId":"spc_owned","title":"Owned","anonymous":false,"publishedAt":"2026-01-02T00:00:00Z","source":"/x"}}
JSON
fn state_init
check "0.1 secrets moved out of spaces.json" "0" "$(grep -c sfc_secret "$SPACEFAST_STATE_DIR/spaces.json")"
check "secrets file holds them" "sfc_secret" "$(jq -r '.spc_old.claimKey' "$SPACEFAST_STATE_DIR/secrets.json")"
check "secrets file is private" "600" "$(stat -f %Lp "$SPACEFAST_STATE_DIR/secrets.json" 2>/dev/null || stat -c %a "$SPACEFAST_STATE_DIR/secrets.json")"
check "secret_get" "https://p/__/sfc_secret" "$(fn secret_get spc_old | jq -r .previewUrl)"
check "find by source" "spc_owned" "$(fn state_find_source /x)"

out=$("$CLI" spaces --json)
check "spaces --json lists both" "Old,Owned" "$(jq -r '[.spaces[].title] | sort | join(",")' <<<"$out")"
check "spaces --json never shows secrets" "0" "$(grep -c sfc_ <<<"$out")"
check "anonymous space flagged" "true" "$(jq -r '.spaces[] | select(.id == "spc_old") | .anonymous' <<<"$out")"

fn state_drop spc_old
check "drop removes the secret too" "null" "$(jq -r '.spc_old' "$SPACEFAST_STATE_DIR/secrets.json")"

# --- dates ------------------------------------------------------------------
check "epoch with fractional seconds" "1790647402" "$(fn epoch 2026-09-29T02:03:22.798Z)"
check "epoch of garbage" "0" "$(fn epoch nope)"
check "relative hours" "2h" "$(fn relative_until "$(date -u -r $(($(date +%s) + 7300)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d @$(($(date +%s) + 7300)) +%Y-%m-%dT%H:%M:%SZ)")"

# bash 3.2 reads the bytes of a UTF-8 character after $name as part of the
# name, so every such variable must be braced.
check "no \$name directly before a non-ASCII character" "" \
  "$(LC_ALL=C grep -nE '\$[A-Za-z_][A-Za-z0-9_]*[^ -~[:space:]]' "$CLI" | head -3)"

# --- signed in with several teams and no default: refuse before uploading ---
cat >"$SPACEFAST_STATE_DIR/account.json" <<'JSON'
{"email":"t@example.com","teams":[{"id":"t1","slug":"one","name":"One"},{"id":"t2","slug":"two","name":"Two"}],"team":null}
JSON
msg=$(SPACEFAST_TOKEN=sfa_fake "$CLI" publish "$site/index.html" --no-notify --no-copy 2>&1)
check "several teams, none picked: asks for one" "1" "$(grep -c 'Pick the team' <<<"$msg")"
check "--team picks one by slug" "t2" "$(SPACEFAST_TEAM=two fn team_id)"
rm -f "$SPACEFAST_STATE_DIR/account.json"

# --- commands that need no network ------------------------------------------
check "status --json" "anonymous false" "$("$CLI" status --json | jq -r '"\(.engine) \(.authenticated)"')"
check "team needs sign-in" "1" "$("$CLI" team >/dev/null 2>&1; echo $?)"
check "unknown command exits 1" "1" "$("$CLI" nope >/dev/null 2>&1; echo $?)"

echo
echo "$PASS passed, $FAILS failed"
((FAILS == 0))
