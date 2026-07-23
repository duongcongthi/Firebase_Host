#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$(cd "$DEPLOY_DIR/.." && pwd)"
ROOT_DIR="$SITE_DIR"

while [ "$ROOT_DIR" != "/" ] && [ ! -x "$ROOT_DIR/scripts/deploy_site.sh" ]; do
  ROOT_DIR="$(dirname "$ROOT_DIR")"
done

[ -x "$ROOT_DIR/scripts/deploy_site.sh" ] || {
  printf 'Error: cannot find scripts/deploy_site.sh\n' >&2
  exit 1
}

"$ROOT_DIR/scripts/deploy_site.sh" "$SITE_DIR" "$@"
