#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/deploy_site.sh"
TMP_DIR="$(mktemp -d)"
HOST_DIR="$ROOT_DIR/WebSites/TestAccount/demo-support-test"
SITE_DIR="$HOST_DIR/miracast"
SIBLING_DIR="$HOST_DIR/allsharecast"
HTML_DIR="$SITE_DIR/HTML"
SIBLING_HTML_DIR="$SIBLING_DIR/HTML"
DEPLOY_DIR="$SITE_DIR/Deploy"
FIREBASE_JSON="$HOST_DIR/firebase.json"
FIREBASERC="$HOST_DIR/.firebaserc"
APP_FIREBASE_JSON="$SITE_DIR/firebase.json"
HOST_PUBLIC_DIR="$HOST_DIR/FirebaseHostingPublic"
FAKE_BIN="$TMP_DIR/bin"

trap 'rm -rf "$ROOT_DIR/WebSites/TestAccount" "$TMP_DIR"' EXIT
rm -rf "$ROOT_DIR/WebSites/TestAccount"
mkdir -p "$HTML_DIR" "$SIBLING_HTML_DIR" "$DEPLOY_DIR" "$SIBLING_DIR/Deploy" "$FAKE_BIN"

printf '%s\n' '<html><body>contact</body></html>' > "$HTML_DIR/contact.html"
printf '%s\n' '<html><body>privacy</body></html>' > "$HTML_DIR/privacy.html"
printf '%s\n' '<html><body>terms</body></html>' > "$HTML_DIR/term.html"
printf '%s\n' '<html><body>sibling contact</body></html>' > "$SIBLING_HTML_DIR/contact.html"
printf '%s\n' '<html><body>sibling privacy</body></html>' > "$SIBLING_HTML_DIR/privacy.html"
printf '%s\n' '<html><body>sibling terms</body></html>' > "$SIBLING_HTML_DIR/term.html"
printf '%s\n' 'ROOT_REDIRECT=/miracast/privacy' > "$DEPLOY_DIR/site-config.txt"
printf '%s\n' 'ROOT_REDIRECT=/allsharecast/contact' > "$SIBLING_DIR/Deploy/site-config.txt"

DRY_OUTPUT="$("$SCRIPT" "$SITE_DIR" --dry-run)"

test -f "$FIREBASE_JSON"
test -f "$FIREBASERC"
test -f "$APP_FIREBASE_JSON"
test -d "$HOST_PUBLIC_DIR/miracast"
test -d "$HOST_PUBLIC_DIR/allsharecast"
test -f "$HOST_PUBLIC_DIR/miracast/contact.html"
test -f "$HOST_PUBLIC_DIR/allsharecast/contact.html"
test ! -f "$SITE_DIR/Website.txt"
test ! -f "$DEPLOY_DIR/firebase.json"
test ! -f "$DEPLOY_DIR/.firebaserc"
test ! -d "$DEPLOY_DIR/public"

grep -q '"public": "FirebaseHostingPublic"' "$FIREBASE_JSON"
grep -q '"public": "../FirebaseHostingPublic"' "$APP_FIREBASE_JSON"
grep -q '"destination": "/miracast/privacy"' "$FIREBASE_JSON"
grep -q '"default": "demo-support-test"' "$FIREBASERC"

grep -q 'App folder: '"$SITE_DIR" <<< "$DRY_OUTPUT"
grep -q 'Project ID: demo-support-test' <<< "$DRY_OUTPUT"
grep -q 'App path: /miracast' <<< "$DRY_OUTPUT"
grep -q 'Dry run only' <<< "$DRY_OUTPUT"
grep -q 'https://demo-support-test.web.app/miracast/contact' <<< "$DRY_OUTPUT"
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
    test "$PWD" = "__HOST_DIR__"
    exit 0
    ;;
  *)
    printf 'unexpected firebase command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF
sed -i '' "s#__HOST_DIR__#$HOST_DIR#g" "$FAKE_BIN/firebase"
chmod +x "$FAKE_BIN/firebase"

WRITE_OUTPUT="$(PATH="$FAKE_BIN:$PATH" "$SCRIPT" "$SITE_DIR")"

test -f "$SITE_DIR/Website.txt"
test -f "$SIBLING_DIR/Website.txt"
grep -q 'Website.txt written' <<< "$WRITE_OUTPUT"
grep -q '^URL Website $' "$SITE_DIR/Website.txt"
grep -q '^Contact URL: https://demo-support-test.web.app/miracast/contact$' "$SITE_DIR/Website.txt"
grep -q '^Term URL: https://demo-support-test.web.app/miracast/term$' "$SITE_DIR/Website.txt"
grep -q '^Privacy URL: https://demo-support-test.web.app/miracast/privacy$' "$SITE_DIR/Website.txt"
grep -q '^Contact URL: https://demo-support-test.web.app/allsharecast/contact$' "$SIBLING_DIR/Website.txt"

rm -f "$SITE_DIR/Website.txt" "$SIBLING_DIR/Website.txt"
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
