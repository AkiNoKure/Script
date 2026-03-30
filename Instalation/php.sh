#!/bin/bash
set -eo pipefail

# Récupération des arguments ou variables d'environnement
TARGET_DIR=${1:-$TARGET_DIR}
USERNAME=${2:-$USERNAME}

echo "--- Configuration PHP : $TARGET_DIR ---"

# Vérification silencieuse des dépendances
command -v php &> /dev/null || { echo "[ERREUR] PHP absent"; exit 1; }
command -v composer &> /dev/null || { echo "[ERREUR] Composer absent"; exit 1; }

cd "$TARGET_DIR" || exit 1

# Installation sans interaction (--no-interaction)
echo "Installation des dépendances Composer..."
sudo -u "$USERNAME" composer install --no-dev --optimize-autoloader --no-interaction

# Gestion automatique du .env
if [ -f .env.example ] && [ ! -f .env ]; then
    sudo -u "$USERNAME" cp .env.example .env
    echo "Fichier .env créé à partir de l'exemple."
    # Optionnel : générer la clé si c'est du Laravel
    # sudo -u "$USERNAME" php artisan key:generate --force
fi

# Droits d'accès optimisés
echo "Finalisation des permissions..."
sudo chown -R "$USERNAME":www-data .
# On s'assure que les dossiers existent avant le chmod pour éviter les erreurs
mkdir -p storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

echo "[OK] Déploiement PHP terminé."