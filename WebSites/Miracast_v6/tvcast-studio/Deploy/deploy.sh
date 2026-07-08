#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$(cd "$DEPLOY_DIR/.." && pwd)"
"$SITE_DIR/../../../scripts/deploy_site.sh" "$SITE_DIR" "$@"
