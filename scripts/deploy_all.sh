#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN_ARG=""

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN_ARG="--dry-run"
elif [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
Usage:
  scripts/deploy_all.sh [--dry-run]

Deploys every WebSites/<account>/<firebase-host>/<app>/ folder that contains
Deploy/site-config.txt.
EOF
  exit 0
elif [ "${1:-}" != "" ]; then
  printf 'Error: unknown argument: %s\n' "$1" >&2
  exit 1
fi

found=0
for config in "$ROOT_DIR"/WebSites/*/*/*/Deploy/site-config.txt; do
  [ -f "$config" ] || continue
  found=1
  site_dir="$(cd "$(dirname "$config")/.." && pwd)"
  printf '\n=== Deploying %s ===\n' "$site_dir"
  "$SCRIPT_DIR/deploy_site.sh" "$site_dir" $DRY_RUN_ARG
done

if [ "$found" -eq 0 ]; then
  printf 'No Deploy/site-config.txt files found under %s/WebSites\n' "$ROOT_DIR"
fi
