#!/bin/bash
# Arrêt immédiat si une commande échoue
set -e

LOG_FILE="/var/log/jukebox_deploy.log"
export TERM=${TERM:-xterm-256color}

ask_if_empty() {
    local var_name=$1
    local prompt_msg=$2
    if [ -z "${!var_name}" ]; then
        read -p "$prompt_msg: " input_val
        eval "$var_name=\"$input_val\""
    fi
}

echo "--- [$(date)] Début du déploiement Jukebox ---"

ask_if_empty "USERNAME" "Nom de l'utilisateur système"
read -p "Répertoire d'installation (Défaut: /home/$USERNAME/Application/Jukebox) : " TARGET_DIR
TARGET_DIR=${TARGET_DIR:-"/home/$USERNAME/Application/Jukebox"}

# --- Sauvegarde pré-déploiement ---
if [ -d "$TARGET_DIR" ]; then
    echo "Préparation de la sauvegarde (Fichiers + BDD)..."
    sudo mkdir -p "${TARGET_DIR}_backup"
    # Nettoyage de l'ancien backup pour éviter les mélanges
    sudo rm -rf "${TARGET_DIR}_backup"/*
    # Backup BDD
    sudo mysqldump jukebox_db > "${TARGET_DIR}_backup/jukebox_dump.sql" 2>/dev/null || true
    [ -f "$TARGET_DIR/jukebox.sqlite" ] && cp "$TARGET_DIR/jukebox.sqlite" "${TARGET_DIR}_backup/"
    # Backup Fichiers
    sudo cp -r "$TARGET_DIR"/* "${TARGET_DIR}_backup/" 2>/dev/null || true
fi

# --- Choix de la source ---
echo "Source du déploiement :"
echo "1) Dépôt Git"
echo "2) Archive locale (.zip, .tar.gz, .tgz)"
read -p "Votre choix : " SOURCE_CHOICE

sudo mkdir -p "$TARGET_DIR"
sudo chown "$USERNAME":"$USERNAME" "$TARGET_DIR"

if [ "$SOURCE_CHOICE" == "1" ]; then
    ask_if_empty "REPO_URL" "URL du dépôt Git"
    if [ ! -d "$TARGET_DIR/.git" ]; then
        echo "Clonage du dépôt..."
        sudo -u "$USERNAME" git clone "$REPO_URL" "$TARGET_DIR"/.
    else
        echo "Mise à jour via Git..."
        cd "$TARGET_DIR" && sudo -u "$USERNAME" git pull
    fi
else
    read -e -p "Chemin complet de l'archive : " ARCHIVE_PATH
    if [ -f "$ARCHIVE_PATH" ]; then
        echo "Extraction de l'archive..."
        if [[ "$ARCHIVE_PATH" == *.zip ]]; then
            sudo unzip -o "$ARCHIVE_PATH" -d "$TARGET_DIR"
        elif [[ "$ARCHIVE_PATH" == *.tar.gz ]] || [[ "$ARCHIVE_PATH" == *.tgz ]]; then
            sudo tar -xzf "$ARCHIVE_PATH" -C "$TARGET_DIR"
        fi
        sudo chown -R "$USERNAME":"$USERNAME" "$TARGET_DIR"
    else
        echo "ERREUR : Archive introuvable."; exit 1
    fi
fi

# --- Configuration du lanceur ---
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$BASE_DIR/Instalation"
SERVICE_DIR="$BASE_DIR/Service"
START_SCRIPT="$BASE_DIR/start_jukebox.sh"

ask_if_empty "APP_TYPE_INPUT" "Type (1: Java, 2: PHP)"
[ "$APP_TYPE_INPUT" == "1" ] && APP_L="java" || APP_L="php"

sed -i "s|^APP_PATH=.*|APP_PATH=\"$TARGET_DIR\"|" "$START_SCRIPT"
sed -i "s|^USER_NAME=.*|USER_NAME=\"$USERNAME\"|" "$START_SCRIPT"
sed -i "s|^APP_TYPE=.*|APP_TYPE=\"$APP_L\"|" "$START_SCRIPT"
chmod +x "$START_SCRIPT"

# --- Installation ---
if [ -f "$INSTALL_DIR/$APP_L.sh" ]; then
    bash "$INSTALL_DIR/$APP_L.sh" "$TARGET_DIR" "$USERNAME"
else
    echo "ERREUR : Fichier d'installation $APP_L.sh manquant."
    exit 1
fi

# --- Service Systemd ---
if [ -f "$SERVICE_DIR/jukebox.service" ]; then
    echo "Installation du service système..."
    sudo sed -i "s|^ExecStart=.*|ExecStart=/bin/bash $START_SCRIPT|" "$SERVICE_DIR/jukebox.service"
    sudo cp "$SERVICE_DIR/jukebox.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable jukebox.service
    sudo systemctl restart jukebox.service
fi

echo "Finalisation des permissions..."
sudo chmod -R a+x "$BASE_DIR"
sudo chmod a+x "$START_SCRIPT"

echo "--- [OK] Déploiement terminé avec succès ---"