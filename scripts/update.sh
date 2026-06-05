#!/usr/bin/env bash
# Redeploy: pull all three repos and rebuild. Run from the droplet:
#   bash ~/eigg-deploy/scripts/update.sh                 # rebuild everything
#   bash ~/eigg-deploy/scripts/update.sh invest_backend invest_frontend   # just these
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PARENT="$(dirname "$REPO")"

echo "==> pulling repos"
git -C "$REPO" pull --ff-only
[ -d "$PARENT/eigg-prevent/.git" ] && git -C "$PARENT/eigg-prevent" pull --ff-only || true
[ -d "$PARENT/fraud-copilot/.git" ] && git -C "$PARENT/fraud-copilot" pull --ff-only || true

echo "==> rebuilding"
cd "$REPO"
docker compose up -d --build "$@"
docker compose ps
