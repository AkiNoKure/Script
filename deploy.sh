#!/bin/bash

LOG_FILE="/var/log/jukebox_deploy.log"

ask_if_empty() {
    local var_name=$1
    local prompt_msg=$2
    if [ -z "${!var_name}" ]; then
        read -p "$prompt_msg: " input_val
        eval "$var_name=\"$input_val\""
    fi
}

echo "--- [$(date)] Déploiement Jukebox ---"

# --- 1. Configuration des variables ---
ask_if_empty "USERNAME" "Nom de l'utilisateur système"
read -p "Répertoire d'installation (Défaut: /home/$USERNAME/Application/Jukebox) : " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-"/home/$USERNAME/Application/Jukebox"}

ask_if_empty "REPO_URL" "URL du dépôt Git"
ask_if_empty "APP_TYPE_INPUT" "Type (1: Java, 2: PHP)"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$BASE_DIR/Instalation"
SERVICE_DIR="$BASE_DIR/Service"
GUI_DIR="$BASE_DIR/GUI"
START_SCRIPT="$BASE_DIR/start_jukebox.sh"

# --- 2. Préparation du répertoire cible ---
if [ -d "$TARGET_DIR" ] && [ ! -d "$TARGET_DIR/.git" ]; then
    sudo rm -rf "${TARGET_DIR:?}"/*
fi

sudo mkdir -p "$TARGET_DIR"
sudo chown "$USERNAME":"$USERNAME" "$TARGET_DIR"

# --- 3. Clonage Git ---
if [ ! -d "$TARGET_DIR/.git" ]; then
    echo "Clonage du dépôt dans $TARGET_DIR..."
    sudo -u "$USERNAME" git clone "$REPO_URL" "$TARGET_DIR"/.
else
    echo "Mise à jour du dépôt existant..."
    cd "$TARGET_DIR" && sudo -u "$USERNAME" git pull
fi

# --- 4. Mise à jour de start_jukebox.sh ---
sed -i "s|^APP_PATH=.*|APP_PATH=\"$TARGET_DIR\"|" "$START_SCRIPT"
sed -i "s|^USER_NAME=.*|USER_NAME=\"$USERNAME\"|" "$START_SCRIPT"

if [ "$APP_TYPE_INPUT" == "1" ]; then
    APP_L="java"
else
    APP_L="php"
fi
sed -i "s|^APP_TYPE=.*|APP_TYPE=\"$APP_L\"|" "$START_SCRIPT"

# --- 5. Exécution de l'installation ---
if [ -f "$INSTALL_DIR/$APP_L.sh" ]; then
    bash "$INSTALL_DIR/$APP_L.sh" "$TARGET_DIR" "$USERNAME"
else
    echo "[ERREUR] Script d'installation $INSTALL_DIR/$APP_L.sh introuvable."
    exit 1
fi

# --- 6. Configuration du lancement (Service vs GUI) ---
echo "Finalisation : Configuration du système..."
chmod +x "$START_SCRIPT"

if [ "$APP_L" == "php" ]; then
    echo "Configuration du service Systemd (Mode Serveur)..."
    if [ -f "$SERVICE_DIR/jukebox.service" ]; then
        sudo sed -i "s|^ExecStart=.*|ExecStart=/bin/bash $START_SCRIPT|" "$SERVICE_DIR/jukebox.service"
        sudo cp "$SERVICE_DIR/jukebox.service" /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable jukebox.service
        sudo systemctl restart jukebox.service
    fi
else
    echo "Configuration de l'Auto-start graphique (Mode Java)..."
    AUTO_DIR="/home/$USERNAME/.config/autostart"
    sudo -u "$USERNAME" mkdir -p "$AUTO_DIR"
    if [ -f "$GUI_DIR/jukebox.desktop" ]; then
        sudo sed -i "s|^Exec=.*|Exec=/bin/bash $START_SCRIPT|" "$GUI_DIR/jukebox.desktop"
        sudo cp "$GUI_DIR/jukebox.desktop" "$AUTO_DIR/"
        sudo chown "$USERNAME":"$USERNAME" "$AUTO_DIR/jukebox.desktop"
        sudo chmod +x "$AUTO_DIR/jukebox.desktop"
    fi
    # Désactivation du service systemd pour Java (conflit d'affichage)
    sudo systemctl stop jukebox.service 2>/dev/null
    sudo systemctl disable jukebox.service 2>/dev/null
fi

echo "[OK] Déploiement terminé."