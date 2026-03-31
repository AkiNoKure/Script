#!/bin/bash
set -eo pipefail

TARGET_DIR=$1
USERNAME=$2

echo "--- Configuration PHP : $TARGET_DIR ---"

install_if_missing() {
  local cmd=$1 pkgs=$2
  if ! command -v "$cmd" &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y $pkgs
  fi
}

install_if_missing php "php-cli php-zip unzip curl php-xml php-mbstring"

if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
fi

cd "$TARGET_DIR" || exit 1

echo "Installation des dépendances Composer..."
sudo -u "$USERNAME" composer install --no-dev --optimize-autoloader --no-interaction

if [ -f .env.example ] && [ ! -f .env ]; then
    sudo -u "$USERNAME" cp .env.example .env
fi

echo "Finalisation des permissions..."
sudo chown -R "$USERNAME":www-data .
mkdir -p storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache