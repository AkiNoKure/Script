#!/bin/bash

# --- 1. Initialisation des variables ---
ask_if_empty() {
    local var_name=$1
    local prompt_msg=$2
    if [ -z "${!var_name}" ]; then
        read -p "$prompt_msg: " input_val
        eval "$var_name=\"$input_val\""
    fi
}

echo "--- Système de Déploiement Jukebox (Campus La Futaie) ---"

# --- 2. Collecte des informations ---
ask_if_empty "USERNAME" "Nom de l'utilisateur système"
ask_if_empty "REPO_URL" "URL du dépôt Git"
ask_if_empty "TARGET_DIR" "Répertoire de destination (chemin complet)"
ask_if_empty "APP_TYPE_INPUT" "Type d'application (1: Java, 2: PHP)"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$BASE_DIR/Instalation"
SERVICE_DIR="$BASE_DIR/Service"
START_SCRIPT="$BASE_DIR/start_jukebox.sh"

# --- 3. Déploiement du code source ---
echo "Clonage ou mise à jour du dépôt..."
if [ ! -d "$TARGET_DIR" ]; then
    sudo -u "$USERNAME" git clone "$REPO_URL" "$TARGET_DIR"
else
    cd "$TARGET_DIR" && sudo -u "$USERNAME" git pull
fi

# --- 4. Configuration dynamique de start_jukebox.sh ---
echo "Mise à jour de la configuration de démarrage..."
sed -i "s|^APP_PATH=.*|APP_PATH=\"$TARGET_DIR\"|" "$START_SCRIPT"
sed -i "s|^USER_NAME=.*|USER_NAME=\"$USERNAME\"|" "$START_SCRIPT"

if [ "$APP_TYPE_INPUT" == "1" ]; then
    APP_LABEL="java"
    sed -i "s|^APP_TYPE=.*|APP_TYPE=\"java\"|" "$START_SCRIPT"
else
    APP_LABEL="php"
    sed -i "s|^APP_TYPE=.*|APP_TYPE=\"php\"|" "$START_SCRIPT"
fi

# --- 5. Exécution du build spécifique ---
case $APP_LABEL in
    "java") [ -f "$INSTALL_DIR/java.sh" ] && bash "$INSTALL_DIR/java.sh" "$TARGET_DIR" "$USERNAME" ;;
    "php")  [ -f "$INSTALL_DIR/php.sh" ] && bash "$INSTALL_DIR/php.sh" "$TARGET_DIR" "$USERNAME" ;;
esac

# --- 6. Activation du service systemd ---
chmod +x "$START_SCRIPT"
if [ -f "$SERVICE_DIR/jukebox.service" ]; then
    sudo sed -i "s|^ExecStart=.*|ExecStart=/bin/bash $START_SCRIPT|" "$SERVICE_DIR/jukebox.service"
    sudo cp "$SERVICE_DIR/jukebox.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable jukebox.service
    sudo systemctl restart jukebox.service
    echo "[OK] Jukebox opérationnel."
fi