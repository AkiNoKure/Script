#!/bin/bash

# --- Journalisation ---
LOG_FILE="/var/log/jukebox_deploy.log"
exec > >(tee -a "$LOG_FILE") 2>&1

ask_if_empty() {
    local var_name=$1
    local prompt_msg=$2
    if [ -z "${!var_name}" ]; then
        read -p "$prompt_msg: " input_val
        eval "$var_name=\"$input_val\""
    fi
}

echo "--- [$(date)] Déploiement Jukebox ---"

# --- Configuration du répertoire ---
ask_if_empty "USERNAME" "Nom de l'utilisateur système"
read -p "Répertoire d'installation (Défaut: /home/$USERNAME/Application/Jukebox) : " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-"/home/$USERNAME/Application/Jukebox"}

ask_if_empty "REPO_URL" "URL du dépôt Git"
ask_if_empty "APP_TYPE_INPUT" "Type (1: Java, 2: PHP)"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$BASE_DIR/Instalation"
START_SCRIPT="$BASE_DIR/start_jukebox.sh"



# --- Clonage ---
sudo mkdir -p "$TARGET_DIR"
sudo chown "$USERNAME":"$USERNAME" "$TARGET_DIR"

if [ ! -d "$TARGET_DIR/.git" ]; then
    sudo -u "$USERNAME" git clone "$REPO_URL" "$TARGET_DIR"
else
    cd "$TARGET_DIR" && sudo -u "$USERNAME" git pull
fi

# --- Mise à jour start_jukebox.sh ---
sed -i "s|^APP_PATH=.*|APP_PATH=\"$TARGET_DIR\"|" "$START_SCRIPT"
sed -i "s|^USER_NAME=.*|USER_NAME=\"$USERNAME\"|" "$START_SCRIPT"
[ "$APP_TYPE_INPUT" == "1" ] && APP_L="java" || APP_L="php"
sed -i "s|^APP_TYPE=.*|APP_TYPE=\"$APP_L\"|" "$START_SCRIPT"
# Correction du chemin d'appel pour garantir la transmission des variables
if [ -f "$INSTALL_DIR/$APP_L.sh" ]; then
    bash "$INSTALL_DIR/$APP_L.sh" "$TARGET_DIR" "$USERNAME"
else
    echo "Erreur : Script d'installation $INSTALL_DIR/$APP_L.sh introuvable."
    exit 1
fi
# --- Exécution du script d'installation ---
bash "$INSTALL_DIR/$APP_L.sh" "$TARGET_DIR" "$USERNAME"