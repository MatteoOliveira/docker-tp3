#!/usr/bin/env bash
# =========================================================
# 🚀 Docker TP3 — Étape 2 (DATA + SCRIPT + HTTP)
# Lancement: MariaDB + PHP-FPM (mysqli) + NGINX
# Dossier attendu: ce script vit dans etape2/
# =========================================================
set -euo pipefail

# --- Localisation du dossier du script (chemin absolu) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Dossier courant: $PWD"

# --- Vérifs fichiers requis ---
[ -f "config/default.conf" ] || { echo "❌ config/default.conf manquant"; exit 1; }
[ -f "src/index.php" ]       || { echo "❌ src/index.php manquant"; exit 1; }
[ -f "src/test.php" ]        || { echo "❌ src/test.php manquant"; exit 1; }
[ -f "sql/create.sql" ]      || { echo "❌ sql/create.sql manquant"; exit 1; }

echo "==> Nettoyage des anciens conteneurs (si présents)..."
docker rm -f http script data >/dev/null 2>&1 || true

echo "==> Réseau tp3net..."
docker network create tp3net >/dev/null 2>&1 || true

# --- Build PHP-FPM avec mysqli ---
echo "==> Build de l'image PHP-FPM (mysqli)..."
docker build -t php-fpm-mysqli:8.2 .

# --- Lancer MariaDB avec init via create.sql ---
# Note: on NE supprime PAS le volume de données pour garder la persistance.
# Si vous voulez forcer un ré-init, supprimez aussi le volume Docker associé.
echo "==> Lancement de MariaDB (init via sql/create.sql)..."
docker run -d \
  --name data \
  --network tp3net \
  -e MARIADB_ROOT_PASSWORD=root \
  -v "$PWD/sql:/docker-entrypoint-initdb.d:ro" \
  mariadb:11.4

# --- Attente readiness MariaDB ---
echo "==> Attente que MariaDB soit prêt..."
# Boucle d'attente (max ~60s)
for i in {1..60}; do
  if docker exec data sh -lc 'mariadb-admin ping -uroot -proot --silent' >/dev/null 2>&1; then
    echo "✅ MariaDB prêt."
    break
  fi
  sleep 1
  if [ "$i" -eq 60 ]; then
    echo "❌ MariaDB ne répond pas (timeout)."
    docker logs data --tail=100
    exit 1
  fi
done

# --- Lancer PHP-FPM (SCRIPT) ---
echo "==> Lancement de PHP-FPM (SCRIPT)..."
docker run -d \
  --name script \
  --network tp3net \
  -v "$PWD/src:/app" \
  php-fpm-mysqli:8.2

# Vérifier que mysqli est bien chargé (diagnostic non bloquant)
docker exec script php -m | grep -iq mysqli \
  && echo "✅ Extension mysqli chargée." \
  || echo "⚠️  mysqli non détecté (vérifiez le build)."

# --- Tester la syntaxe NGINX avant démarrage ---
echo "==> Test syntaxe NGINX..."
docker run --rm \
  --network tp3net \
  -v "$PWD/config/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$PWD/src:/app:ro" \
  nginx:1.29 nginx -t
