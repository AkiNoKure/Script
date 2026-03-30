#!/bin/bash
set -eo pipefail
# ...existing code...

TARGET_DIR=${1:-$TARGET_DIR}
USERNAME=${2:-$USERNAME}

echo "--- Configuration PHP : $TARGET_DIR ---"

install_if_missing() {
  local cmd=$1 pkgs=$2
  if command -v "$cmd" &> /dev/null; then
    return 0
  fi
  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y $pkgs
  else
    echo "[ERREUR] $cmd absent et apt-get non disponible. Installez $pkgs manuellement."
    exit 1
  fi
}

install_if_missing php "php-cli php-zip unzip curl"
install_if_missing composer "curl unzip"

if ! command -v composer &> /dev/null; then
  if command -v curl &> /dev/null; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
  else
    echo "[ERREUR] curl manquant pour installer composer automatiquement."
    exit 1
  fi
fi

cd "$TARGET_DIR" || exit 1

echo "Installation des dépendances Composer..."
sudo -u "$USERNAME" composer install --no-dev --optimize-autoloader --no-interaction

if [ -f .env.example ] && [ ! -f .env ]; then
    sudo -u "$USERNAME" cp .env.example .env
    echo "Fichier .env créé à partir de l'exemple."
fi

echo "Finalisation des permissions..."
sudo chown -R "$USERNAME":www-data .
mkdir -p storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

echo "[OK] Déploiement PHP terminé."