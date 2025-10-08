#!/usr/bin/env bash
# =========================================================
# 🚀 Docker TP3 — Étape 3 (Docker Compose)
# Démarre: MariaDB + PHP-FPM (mysqli) + NGINX via compose.yml
# =========================================================
set -euo pipefail

# -- Aller dans le dossier du script (chemin absolu) --
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Dossier courant: $PWD"

# -- Vérifs préalables --
[ -f "compose.yml" ] || { echo "❌ compose.yml introuvable"; exit 1; }
[ -f "config/default.conf" ] || { echo "❌ config/default.conf introuvable"; exit 1; }
[ -f "src/index.php" ] || { echo "❌ src/index.php introuvable"; exit 1; }
[ -f "src/test.php" ]  || { echo "❌ src/test.php introuvable"; exit 1; }
[ -f "Dockerfile" ]    || { echo "❌ Dockerfile (PHP-FPM mysqli) introuvable"; exit 1; }
[ -f "sql/create.sql" ]|| { echo "❌ sql/create.sql introuvable"; exit 1; }

# Vérifier que la conf NGINX a bien le SCRIPT_FILENAME absolu
if ! grep -q 'fastcgi_param[[:space:]]\+SCRIPT_FILENAME[[:space:]]\+/app\$fastcgi_script_name' config/default.conf; then
  echo "⚠️  Attention: config/default.conf ne contient pas:"
  echo "    fastcgi_param  SCRIPT_FILENAME /app\$fastcgi_script_name;"
  echo "    (risque de 404 côté PHP-FPM)"
fi

echo "==> (Re)construction de l'image PHP-FPM (mysqli) et lancement de la stack..."
docker compose -f compose.yml up -d --build

echo "==> Services en cours:"
docker compose ps

# -- Attendre que MariaDB soit healthy (healthcheck dans compose.yml) --
echo "==> Attente santé MariaDB (health=healthy)..."
DATA_CID="$(docker compose ps -q data)"
if [[ -z "${DATA_CID}" ]]; then
  echo "❌ Container 'data' introuvable"; docker compose ps; exit 1
fi

# Attente (max 90s) du statut healthy
for i in {1..90}; do
  HEALTH="$(docker inspect -f '{{.State.Health.Status}}' "$DATA_CID" 2>/dev/null || echo "unknown")"
  if [[ "$HEALTH" == "healthy" ]]; then
    echo "✅ MariaDB healthy."
    break
  fi
  sleep 1
  [[ $i -eq 90 ]] && { echo "❌ Timeout santé MariaDB (dern. logs)"; docker compose logs --no-color --tail=80 data; exit 1; }
done

# -- Afficher quelques infos utiles --
echo
echo "==> Vérifications rapides (non bloquantes):"
echo "   - PHP-FPM (mysqli):"
docker compose exec -T script php -m | grep -iq mysqli \
  && echo "     ✅ mysqli présent" \
  || echo "     ⚠️  mysqli non détecté (revérifier Dockerfile et build)"

echo
echo "==> URL:"
echo "   - http://localhost:8080"
echo "   - http://localhost:8080/test.php"
echo
echo "==> Commandes utiles:"
echo "   - Logs:     docker compose logs -f"
echo "   - Down:     docker compose down"
echo "   - Rebuild:  docker compose build script && docker compose up -d script"
echo "   - Reset DB: docker compose down -v   # (supprime aussi le volume dbdata)"
