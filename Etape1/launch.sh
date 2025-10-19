set -e  # Stoppe le script si une commande échoue

echo "==> Suppression des anciens conteneurs (si existants)..."
docker rm -f script http >/dev/null 2>&1 || true

echo "==> Suppression / recréation du réseau tp3net..."
docker network rm tp3net >/dev/null 2>&1 || true
docker network create tp3net

echo "==> Vérification des fichiers..."
ls -l config/default.conf
ls -l src/index.php

echo "==> Lancement du conteneur PHP-FPM..."
docker run -d \
  --name script \
  --network tp3net \
  -v "$(pwd)/src:/app" \
  php:8.2-fpm

echo "==> Lancement du conteneur NGINX..."
docker run -d \
  --name http \
  --network tp3net \
  -p 8080:80 \
  -v "$(pwd)/config/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$(pwd)/src:/app:ro" \
  nginx:1.29

echo "==> Conteneurs lancés :"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"

echo "==> Test de configuration nginx dans le conteneur..."
docker exec -it http nginx -t || true

echo "==> Pour vérifier le site : http://localhost:8080"
