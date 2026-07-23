#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SITE_DIR=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  scripts/deploy_site.sh WebSites/Account/firebase-host/app-folder [--dry-run]

App folder layout:
  HTML/contact.html
  HTML/privacy.html
  HTML/term.html
  Deploy/site-config.txt
  firebase.json

Host folder layout:
  .firebaserc

The Firebase project id is the firebase-host folder name.
Deploying one app publishes every sibling app under the same host so existing
paths on that host are not removed.
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
  local app_name="$3"

  cat > "$website_file" <<EOF
URL Website 
Contact URL: https://$project_id.web.app/$app_name/contact
Term URL: https://$project_id.web.app/$app_name/term
Privacy URL: https://$project_id.web.app/$app_name/privacy
EOF
}

read_project_id() {
  local firebaserc="$1"
  sed -n 's/.*"default"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$firebaserc" | head -n 1
}

normalize_app_path() {
  local app_name="$1"
  local value="$2"

  case "$value" in
    /contact|/privacy|/term)
      printf '/%s%s' "$app_name" "$value"
      ;;
    /*)
      printf '%s' "$value"
      ;;
    *)
      fail "ROOT_REDIRECT must start with /, e.g. /$app_name/contact"
      ;;
  esac
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
  "$ROOT_DIR"/WebSites/*/*/*) ;;
  *) fail "Site folder must be inside $ROOT_DIR/WebSites/<account>/<firebase-host>/<app-folder>" ;;
esac

APP_DIR="$SITE_DIR_ABS"
APP_NAME="$(basename "$APP_DIR")"
HOST_DIR="$(cd "$APP_DIR/.." && pwd)"
ACCOUNT_DIR="$(cd "$HOST_DIR/.." && pwd)"
ACCOUNT_NAME="$(basename "$ACCOUNT_DIR")"
PROJECT_ID="$(basename "$HOST_DIR")"
DISPLAY_NAME="${PROJECT_ID//-/ }"
HOST_PUBLIC_DIR="$HOST_DIR/FirebaseHostingPublic"
HOST_FIREBASE_JSON="$HOST_DIR/firebase.json"
HOST_FIREBASERC="$HOST_DIR/.firebaserc"
HTML_DIR="$APP_DIR/HTML"
DEPLOY_DIR="$APP_DIR/Deploy"
CONFIG_FILE="$DEPLOY_DIR/site-config.txt"
WEBSITE_FILE="$APP_DIR/Website.txt"
APP_FIREBASE_JSON="$APP_DIR/firebase.json"

[ -d "$HTML_DIR" ] || fail "Missing HTML folder: $HTML_DIR"
[ -d "$DEPLOY_DIR" ] || fail "Missing Deploy folder: $DEPLOY_DIR"
[ -f "$CONFIG_FILE" ] || fail "Missing Deploy/site-config.txt in $APP_DIR"

case "$PROJECT_ID" in
  *[!a-z0-9-]*|"") fail "Firebase host folder must use lowercase letters, numbers, and hyphens only: $HOST_DIR" ;;
esac

case "$APP_NAME" in
  *[!a-z0-9_-]*|"") fail "App folder must use lowercase letters, numbers, hyphens, or underscores only: $APP_DIR" ;;
esac

if [ -f "$HOST_FIREBASERC" ]; then
  FIREBASERC_PROJECT_ID="$(read_project_id "$HOST_FIREBASERC")"
  [ -n "$FIREBASERC_PROJECT_ID" ] || fail "Cannot read default project from $HOST_FIREBASERC"
  [ "$FIREBASERC_PROJECT_ID" = "$PROJECT_ID" ] || fail ".firebaserc project '$FIREBASERC_PROJECT_ID' does not match host folder '$PROJECT_ID'"
fi

ROOT_REDIRECT="/$APP_NAME/contact"

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
    ROOT_REDIRECT) ROOT_REDIRECT="$(normalize_app_path "$APP_NAME" "$value")" ;;
    *) fail "Unknown config key: $key" ;;
  esac
done < "$CONFIG_FILE"

case "$ROOT_REDIRECT" in
  /*) ;;
  *) fail "ROOT_REDIRECT must start with /, e.g. /$APP_NAME/contact" ;;
esac

for required_file in contact.html privacy.html term.html; do
  [ -f "$HTML_DIR/$required_file" ] || fail "Missing HTML/$required_file in $APP_DIR"
done

rm -f "$DEPLOY_DIR/firebase.json" "$DEPLOY_DIR/.firebaserc"
rm -rf "$DEPLOY_DIR/public"
rm -rf "$HOST_PUBLIC_DIR"
mkdir -p "$HOST_PUBLIC_DIR"

for sibling_app in "$HOST_DIR"/*; do
  [ -d "$sibling_app/HTML" ] || continue
  sibling_name="$(basename "$sibling_app")"
  case "$sibling_name" in
    *[!a-z0-9_-]*|"") fail "App folder must use lowercase letters, numbers, hyphens, or underscores only: $sibling_app" ;;
  esac

  for required_file in contact.html privacy.html term.html; do
    [ -f "$sibling_app/HTML/$required_file" ] || fail "Missing HTML/$required_file in $sibling_app"
  done

  mkdir -p "$HOST_PUBLIC_DIR/$sibling_name"
  cp -R "$sibling_app/HTML/." "$HOST_PUBLIC_DIR/$sibling_name/"
done

cat > "$HOST_FIREBASE_JSON" <<EOF
{
  "hosting": {
    "public": "FirebaseHostingPublic",
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

cat > "$HOST_FIREBASERC" <<EOF
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF

cat > "$APP_FIREBASE_JSON" <<EOF
{
  "hosting": {
    "public": "../FirebaseHostingPublic",
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

printf 'Account: %s\n' "$ACCOUNT_NAME"
printf 'Host folder: %s\n' "$HOST_DIR"
printf 'App folder: %s\n' "$APP_DIR"
printf 'Project ID: %s\n' "$PROJECT_ID"
printf 'App path: /%s\n' "$APP_NAME"

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
      printf 'Most likely the name is already used globally. Rename the host folder and run deploy again.\n' >&2
      printf 'Example: mv "%s" "%s-1"\n\n' "$HOST_DIR" "$HOST_DIR" >&2
      exit 1
    fi
  fi

  if (cd "$HOST_DIR" && firebase deploy --only hosting --project "$PROJECT_ID"); then
    for sibling_app in "$HOST_DIR"/*; do
      [ -d "$sibling_app/HTML" ] || continue
      write_website_file "$sibling_app/Website.txt" "$PROJECT_ID" "$(basename "$sibling_app")"
    done
    printf 'Website.txt written: %s\n' "$WEBSITE_FILE"
  else
    printf '\nERROR: Firebase deploy failed for "%s". Website.txt was not written or refreshed.\n' "$PROJECT_ID" >&2
    exit 1
  fi
fi

cat <<EOF

URLs:
https://$PROJECT_ID.web.app/$APP_NAME/contact
https://$PROJECT_ID.web.app/$APP_NAME/privacy
https://$PROJECT_ID.web.app/$APP_NAME/term

Root:
https://$PROJECT_ID.web.app
EOF
