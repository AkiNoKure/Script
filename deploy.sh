#!/bin/bash

# --- 1. Initialisation des variables ---
# Cette fonction vérifie si une variable est vide et pose la question si nécessaire
ask_if_empty() {
    local var_name=$1
    local prompt_msg=$2
    if [ -z "${!var_name}" ]; then
        read -p "$prompt_msg: " input_val
        eval "$var_name=\"$input_val\""
    fi
}

echo "--- Système de Déploiement Automatique ---"

# --- 2. Collecte des informations ---
# Si exécuté via Web, ces variables doivent être passées en amont (export VAR=...)
ask_if_empty "USERNAME" "Nom de l'utilisateur système (ex: www-data)"
ask_if_empty "REPO_URL" "URL du dépôt Git"
ask_if_empty "TARGET_DIR" "Répertoire de destination (chemin complet)"
ask_if_empty "APP_TYPE" "Type d'application (1: Java, 2: PHP)"

# Définition du dossier des scripts d'installation (basé sur ton arborescence)
INSTALL_DIR="$(dirname "$0")/Instalation"

# --- 3. Déploiement ---
echo "Clonage du dépôt dans $TARGET_DIR..."
sudo -u "$USERNAME" git clone "$REPO_URL" "$TARGET_DIR"

case $APP_TYPE in
    1)
        SCRIPT="$INSTALL_DIR/java.sh"
        ;;
    2)
        SCRIPT="$INSTALL_DIR/php.sh"
        ;;
    *)
        echo "[ERREUR] Choix invalide : $APP_TYPE"
        exit 1
        ;;
esac

# --- 4. Exécution du sous-script ---
if [ -f "$SCRIPT" ]; then
    bash "$SCRIPT" "$TARGET_DIR" "$USERNAME"
else
    echo "[ERREUR] Script $SCRIPT introuvable."
    exit 1
fi