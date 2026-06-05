#!/usr/bin/env bash
# EIGG droplet bootstrap. Run from inside the cloned eigg-deploy repo:
#   git clone https://github.com/jimandgeorge/eigg-deploy.git
#   cd eigg-deploy && bash scripts/bootstrap.sh
#
# Installs Docker, clones the sibling app repos, and checks prerequisites. It does
# NOT start the stack — you fill in .env and place the cert first, then run compose.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PARENT="$(dirname "$REPO_ROOT")"

echo "==> Installing Docker + git (if missing)"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
sudo apt-get install -y docker-compose-plugin git >/dev/null 2>&1 || true

echo "==> Firewall (22/80/443)"
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 22 >/dev/null; sudo ufw allow 80 >/dev/null; sudo ufw allow 443 >/dev/null
  sudo ufw --force enable >/dev/null || true
fi

echo "==> Cloning sibling repos into $PARENT"
clone() {  # $1 url, $2 dir
  if [ -d "$PARENT/$2/.git" ]; then
    echo "    $2 exists — pulling"; git -C "$PARENT/$2" pull --ff-only || true
  else
    git clone "$1" "$PARENT/$2"
  fi
}
clone https://github.com/jimandgeorge/eigg-prevent.git eigg-prevent
clone https://github.com/jimandgeorge/sharkwatch.git    fraud-copilot   # note: folder must be fraud-copilot

echo "==> Checking prerequisites"
[ -f "$REPO_ROOT/.env" ] || { cp "$REPO_ROOT/.env.example" "$REPO_ROOT/.env"; echo "    created .env from example — FILL IT IN"; }
[ -f /etc/cloudflare/eigg.io.pem ] && [ -f /etc/cloudflare/eigg.io.key ] \
  && echo "    cert present" || echo "    !! place the Cloudflare Origin Cert at /etc/cloudflare/eigg.io.{pem,key}"

cat <<DONE

Next:
  1) Edit $REPO_ROOT/.env   (secrets, Neon URL, API keys)
  2) Ensure /etc/cloudflare/eigg.io.pem + .key exist (chmod 600 the key)
  3) cd $REPO_ROOT && docker compose up -d --build
  4) curl -I https://prevent.eigg.io/health
DONE
