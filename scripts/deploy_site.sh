#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SITE_DIR=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  scripts/deploy_site.sh WebSites/Product/site-folder [--dry-run]

Site folder layout:
  HTML/contact.html
  HTML/privacy.html
  HTML/term.html
  Deploy/site-config.txt
  firebase.json
  .firebaserc

The Firebase project id is always the site folder name.
Website.txt is written only after a successful deploy.
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

trim() {
  printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

strip_quotes() {
  local value="$1"
  case "$value" in
    \"*\") value="${value#\"}"; value="${value%\"}" ;;
    \'*\') value="${value#\'}"; value="${value%\'}" ;;
  esac
  printf '%s' "$value"
}

write_website_file() {
  local website_file="$1"
  local project_id="$2"

  cat > "$website_file" <<EOF
URL Website 
$project_id.web.app/contact
$project_id.web.app/term
$project_id.web.app/privacy
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ -z "$SITE_DIR" ]; then
        SITE_DIR="$arg"
      else
        fail "Only one site folder is supported."
      fi
      ;;
  esac
done

[ -n "$SITE_DIR" ] || fail "Site folder is required."
SITE_DIR_ABS="$(cd "$SITE_DIR" 2>/dev/null && pwd)" || fail "Site folder does not exist: $SITE_DIR"

case "$SITE_DIR_ABS" in
  "$ROOT_DIR"/WebSites/*/*) ;;
  *) fail "Site folder must be inside $ROOT_DIR/WebSites/<group>/<site-name>" ;;
esac

HTML_DIR="$SITE_DIR_ABS/HTML"
DEPLOY_DIR="$SITE_DIR_ABS/Deploy"
CONFIG_FILE="$DEPLOY_DIR/site-config.txt"
WEBSITE_FILE="$SITE_DIR_ABS/Website.txt"
FIREBASE_JSON="$SITE_DIR_ABS/firebase.json"
FIREBASERC="$SITE_DIR_ABS/.firebaserc"

[ -d "$HTML_DIR" ] || fail "Missing HTML folder: $HTML_DIR"
[ -d "$DEPLOY_DIR" ] || fail "Missing Deploy folder: $DEPLOY_DIR"
[ -f "$CONFIG_FILE" ] || fail "Missing Deploy/site-config.txt in $SITE_DIR_ABS"

PROJECT_ID="$(basename "$SITE_DIR_ABS")"
DISPLAY_NAME="${PROJECT_ID//-/ }"
ROOT_REDIRECT="/contact"

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  line="$(trim "$raw_line")"
  case "$line" in
    ""|\#*) continue ;;
  esac

  case "$line" in
    *=*) ;;
    *) fail "Invalid config line: $raw_line" ;;
  esac

  key="$(trim "${line%%=*}")"
  value="$(trim "${line#*=}")"
  value="$(strip_quotes "$value")"

  case "$key" in
    PROJECT_ID) ;;
    DISPLAY_NAME) ;;
    ROOT_REDIRECT) ROOT_REDIRECT="$value" ;;
    *) fail "Unknown config key: $key" ;;
  esac
done < "$CONFIG_FILE"

case "$PROJECT_ID" in
  *[!a-z0-9-]*|"") fail "PROJECT_ID must use lowercase letters, numbers, and hyphens only. Rename folder: $SITE_DIR_ABS" ;;
esac

case "$ROOT_REDIRECT" in
  /*) ;;
  *) fail "ROOT_REDIRECT must start with /, e.g. /contact" ;;
esac

for required_file in contact.html privacy.html term.html; do
  [ -f "$HTML_DIR/$required_file" ] || fail "Missing HTML/$required_file in $SITE_DIR_ABS"
done

rm -f "$DEPLOY_DIR/firebase.json" "$DEPLOY_DIR/.firebaserc"
rm -rf "$DEPLOY_DIR/public"

cat > "$FIREBASE_JSON" <<EOF
{
  "hosting": {
    "public": "HTML",
    "ignore": [
      "**/.*",
      "**/node_modules/**"
    ],
    "cleanUrls": true,
    "trailingSlash": false,
    "redirects": [
      {
        "source": "/",
        "destination": "$ROOT_REDIRECT",
        "type": 302
      }
    ]
  }
}
EOF

cat > "$FIREBASERC" <<EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF

printf 'Site folder: %s\n' "$SITE_DIR_ABS"
printf 'Project ID: %s\n' "$PROJECT_ID"

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'Dry run only. No Firebase project was created and nothing was deployed.\n'
  printf 'Website.txt was not written because deploy did not run.\n'
else
  command -v firebase >/dev/null 2>&1 || fail "Firebase CLI is not installed. Run: npm install -g firebase-tools"
  firebase login:list >/dev/null || fail "Firebase CLI is not logged in. Run: firebase login --no-localhost"

  if firebase projects:list --json | grep -q "\"projectId\": \"$PROJECT_ID\""; then
    printf 'Firebase project already exists: %s\n' "$PROJECT_ID"
  else
    printf 'Creating Firebase project: %s\n' "$PROJECT_ID"
    if firebase projects:create "$PROJECT_ID" --display-name "$DISPLAY_NAME" --non-interactive; then
      printf 'Firebase project created: %s\n' "$PROJECT_ID"
    else
      printf '\nERROR: Could not create Firebase project "%s".\n' "$PROJECT_ID" >&2
      printf 'Most likely the name is already used globally. Rename the site folder and run deploy again.\n' >&2
      printf 'Example: mv "%s" "%s-1"\n\n' "$SITE_DIR_ABS" "$SITE_DIR_ABS" >&2
      exit 1
    fi
  fi

  if (cd "$SITE_DIR_ABS" && firebase deploy --only hosting --project "$PROJECT_ID"); then
    write_website_file "$WEBSITE_FILE" "$PROJECT_ID"
    printf 'Website.txt written: %s\n' "$WEBSITE_FILE"
  else
    printf '\nERROR: Firebase deploy failed for "%s". Website.txt was not written or refreshed.\n' "$PROJECT_ID" >&2
    exit 1
  fi
fi

cat <<EOF

URLs:
https://$PROJECT_ID.web.app/contact
https://$PROJECT_ID.web.app/privacy
https://$PROJECT_ID.web.app/term

Root:
https://$PROJECT_ID.web.app
EOF
