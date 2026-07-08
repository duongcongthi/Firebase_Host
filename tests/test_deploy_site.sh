#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/deploy_site.sh"
TMP_DIR="$(mktemp -d)"
SITE_DIR="$ROOT_DIR/WebSites/Test_App/demo-support-test"
HTML_DIR="$SITE_DIR/HTML"
DEPLOY_DIR="$SITE_DIR/Deploy"
FIREBASE_JSON="$SITE_DIR/firebase.json"
FIREBASERC="$SITE_DIR/.firebaserc"
FAKE_BIN="$TMP_DIR/bin"

trap 'rm -rf "$ROOT_DIR/WebSites/Test_App" "$TMP_DIR"' EXIT
rm -rf "$ROOT_DIR/WebSites/Test_App"
mkdir -p "$HTML_DIR" "$DEPLOY_DIR" "$FAKE_BIN"

printf '%s\n' '<html><body>contact</body></html>' > "$HTML_DIR/contact.html"
printf '%s\n' '<html><body>privacy</body></html>' > "$HTML_DIR/privacy.html"
printf '%s\n' '<html><body>terms</body></html>' > "$HTML_DIR/term.html"
printf '%s\n' 'ROOT_REDIRECT=/privacy' > "$DEPLOY_DIR/site-config.txt"

DRY_OUTPUT="$("$SCRIPT" "$SITE_DIR" --dry-run)"

test -f "$FIREBASE_JSON"
test -f "$FIREBASERC"
test ! -f "$SITE_DIR/Website.txt"
test ! -f "$DEPLOY_DIR/firebase.json"
test ! -f "$DEPLOY_DIR/.firebaserc"
test ! -d "$DEPLOY_DIR/public"

grep -q '"public": "HTML"' "$FIREBASE_JSON"
grep -q '"destination": "/privacy"' "$FIREBASE_JSON"
grep -q '"default": "demo-support-test"' "$FIREBASERC"

grep -q 'Site folder: '"$SITE_DIR" <<< "$DRY_OUTPUT"
grep -q 'Project ID: demo-support-test' <<< "$DRY_OUTPUT"
grep -q 'Dry run only' <<< "$DRY_OUTPUT"
grep -q 'https://demo-support-test.web.app/contact' <<< "$DRY_OUTPUT"
grep -q 'Website.txt was not written' <<< "$DRY_OUTPUT"

cat > "$FAKE_BIN/firebase" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
  login:list)
    exit 0
    ;;
  projects:list)
    printf '{"status":"success","result":[{"projectId": "demo-support-test"}]}\n'
    ;;
  deploy)
    exit 0
    ;;
  *)
    printf 'unexpected firebase command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$FAKE_BIN/firebase"

WRITE_OUTPUT="$(PATH="$FAKE_BIN:$PATH" "$SCRIPT" "$SITE_DIR")"

test -f "$SITE_DIR/Website.txt"
grep -q 'Website.txt written' <<< "$WRITE_OUTPUT"
grep -q '^URL Website $' "$SITE_DIR/Website.txt"
grep -q '^demo-support-test.web.app/contact$' "$SITE_DIR/Website.txt"
grep -q '^demo-support-test.web.app/term$' "$SITE_DIR/Website.txt"
grep -q '^demo-support-test.web.app/privacy$' "$SITE_DIR/Website.txt"

rm -f "$SITE_DIR/Website.txt"
cat > "$FAKE_BIN/firebase" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
  login:list)
    exit 0
    ;;
  projects:list)
    printf '{"status":"success","result":[]}\n'
    ;;
  projects:create)
    exit 1
    ;;
  *)
    printf 'unexpected firebase command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$FAKE_BIN/firebase"

set +e
CONFLICT_OUTPUT="$(PATH="$FAKE_BIN:$PATH" "$SCRIPT" "$SITE_DIR" 2>&1)"
CONFLICT_STATUS=$?
set -e

test "$CONFLICT_STATUS" -ne 0
test ! -f "$SITE_DIR/Website.txt"
grep -q 'Could not create Firebase project "demo-support-test"' <<< "$CONFLICT_OUTPUT"
grep -q 'Most likely the name is already used globally' <<< "$CONFLICT_OUTPUT"

cat > "$FAKE_BIN/firebase" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
  login:list)
    exit 0
    ;;
  projects:list)
    printf '{"status":"success","result":[{"projectId": "demo-support-test"}]}\n'
    ;;
  deploy)
    exit 1
    ;;
  *)
    printf 'unexpected firebase command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$FAKE_BIN/firebase"

set +e
DEPLOY_FAIL_OUTPUT="$(PATH="$FAKE_BIN:$PATH" "$SCRIPT" "$SITE_DIR" 2>&1)"
DEPLOY_FAIL_STATUS=$?
set -e

test "$DEPLOY_FAIL_STATUS" -ne 0
test ! -f "$SITE_DIR/Website.txt"
grep -q 'Firebase deploy failed for "demo-support-test"' <<< "$DEPLOY_FAIL_OUTPUT"
grep -q 'Website.txt was not written or refreshed' <<< "$DEPLOY_FAIL_OUTPUT"

echo "All deploy_site tests passed."
