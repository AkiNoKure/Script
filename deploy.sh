#!/bin/bash

# --- Initialisation des variables et Log ---
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

echo "--- [$(date)] Système de Déploiement Jukebox ---"

# --- Collecte des informations ---
ask_if_empty "USERNAME" "Nom de l'utilisateur système"

# Choix du répertoire de destination
read -p "Répertoire d'installation (Entrée pour /home/$USERNAME/application/clonerici) : " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-"/home/$USERNAME/application/clonerici"}

ask_if_empty "REPO_URL" "URL du dépôt Git"
ask_if_empty "APP_TYPE_INPUT" "Type d'application (1: Java, 2: PHP)"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$BASE_DIR/Instalation"
SERVICE_DIR="$BASE_DIR/Service"
START_SCRIPT="$BASE_DIR/start_jukebox.sh"

# --- Déploiement ---
echo "Préparation du répertoire $TARGET_DIR..."
sudo mkdir -p "$TARGET_DIR"
sudo chown "$USERNAME":"$USERNAME" "$TARGET_DIR"

if [ ! -d "$TARGET_DIR/.git" ]; then
    sudo -u "$USERNAME" git clone "$REPO_URL" "$TARGET_DIR"
else
    cd "$TARGET_DIR" && sudo -u "$USERNAME" git pull
fi

# --- Configuration de start_jukebox.sh ---
sed -i "s|^APP_PATH=.*|APP_PATH=\"$TARGET_DIR\"|" "$START_SCRIPT"
sed -i "s|^USER_NAME=.*|USER_NAME=\"$USERNAME\"|" "$START_SCRIPT"

if [ "$APP_TYPE_INPUT" == "1" ]; then
    APP_LABEL="java"
    sed -i "s|^APP_TYPE=.*|APP_TYPE=\"java\"|" "$START_SCRIPT"
else
    APP_LABEL="php"
    sed -i "s|^APP_TYPE=.*|APP_TYPE=\"php\"|" "$START_SCRIPT"
fi

# --- Build ---
case $APP_LABEL in
    "java") [ -f "$INSTALL_DIR/java.sh" ] && bash "$INSTALL_DIR/java.sh" "$TARGET_DIR" "$USERNAME" ;;
    "php")  [ -f "$INSTALL_DIR/php.sh" ] && bash "$INSTALL_DIR/php.sh" "$TARGET_DIR" "$USERNAME" ;;
esac

# --- Systemd ---
chmod +x "$START_SCRIPT"
if [ -f "$SERVICE_DIR/jukebox.service" ]; then
    sudo sed -i "s|^ExecStart=.*|ExecStart=/bin/bash $START_SCRIPT|" "$SERVICE_DIR/jukebox.service"
    sudo cp "$SERVICE_DIR/jukebox.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable jukebox.service
    sudo systemctl restart jukebox.service
    echo "[OK] Jukebox opérationnel. Logs disponibles dans $LOG_FILE"
fi