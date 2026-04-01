#!/bin/bash
set -e

# Couleurs pour le suivi visuel
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}   INITIALISATION & DÉPLOIEMENT JUKEBOX (2026)      ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# 1. Installation Logiciels
echo -e "${YELLOW}[1/7] Installation des dépendances système...${NC}"
sudo apt update -qq
sudo apt install -y apache2 php php-common php-mysql php-sqlite3 php-json php-curl php-mbstring php-xml php-zip mariadb-server openjdk-21-jdk openjdk-21-jre vlc phpmyadmin sqlite3 chromium wtype

# 2. Utilisateurs
echo -e "${YELLOW}[2/7] Configuration des utilisateurs...${NC}"
for USR in "technicien_BTC" "jukebox_play"; do
    if ! id "$USR" &>/dev/null; then
        sudo adduser --disabled-password --gecos "" "$USR"
        echo "$USR:raspberry" | sudo chpasswd
    fi
done
sudo usermod -aG sudo jukebox_play

# 3. Détection d'état
USERNAME="jukebox_play"
TARGET_DIR="/home/$USERNAME/Application/Jukebox"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
START_SCRIPT="$BASE_DIR/start_jukebox.sh"

if [ -d "$TARGET_DIR" ] && [ -f "$START_SCRIPT" ]; then
    CURRENT_APP=$(grep "APP_TYPE=" "$START_SCRIPT" | cut -d'"' -f2)
    echo -e "${BLUE}--> Installation existante détectée : ${GREEN}$CURRENT_APP${NC}"
    echo "1) Mettre à jour"
    echo "2) Écraser et changer de technologie"
    read -p "Choix : " INSTALL_MODE
    if [ "$INSTALL_MODE" == "2" ]; then
        echo -e "${RED}Nettoyage complet pour changement de technologie...${NC}"
        sudo systemctl stop jukebox.service 2>/dev/null || true
        sudo rm -rf "$TARGET_DIR"/*
    fi
fi

# 4. Sauvegarde
echo -e "${YELLOW}[3/7] Gestion de la sauvegarde...${NC}"
if [ -d "$TARGET_DIR" ]; then
    sudo mkdir -p "${TARGET_DIR}_backup"
    sudo rm -rf "${TARGET_DIR}_backup"/*
    sudo mysqldump jukebox_db > "${TARGET_DIR}_backup/jukebox_dump.sql" 2>/dev/null || true
    [ -f "$TARGET_DIR/jukebox.sqlite" ] && sudo cp "$TARGET_DIR/jukebox.sqlite" "${TARGET_DIR}_backup/"
    sudo cp -r "$TARGET_DIR"/* "${TARGET_DIR}_backup/" 2>/dev/null || true
fi

# 5. Récupération Source
echo -e "${YELLOW}[4/7] Récupération des sources...${NC}"
echo "1) Dépôt Git  2) Archive locale"
read -p "Choix : " SOURCE_CHOICE
sudo mkdir -p "$TARGET_DIR"
sudo chown "$USERNAME":"$USERNAME" "$TARGET_DIR"

if [ "$SOURCE_CHOICE" == "1" ]; then
    read -p "URL Git : " REPO_URL
    if [ ! -d "$TARGET_DIR/.git" ]; then
        sudo -u "$USERNAME" git clone "$REPO_URL" "$TARGET_DIR"
    else
        cd "$TARGET_DIR" && sudo -u "$USERNAME" git fetch --all && sudo -u "$USERNAME" git reset --hard origin/$(sudo -u "$USERNAME" git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
    fi
else
    read -e -p "Chemin archive : " ARCHIVE_PATH
    if [[ "$ARCHIVE_PATH" == *.zip ]]; then 
        sudo unzip -o "$ARCHIVE_PATH" -d "$TARGET_DIR"
    else 
        sudo tar -xzf "$ARCHIVE_PATH" -C "$TARGET_DIR"
    fi
fi

# 6. Configuration Application
echo -e "${YELLOW}[5/7] Configuration spécifique...${NC}"
echo "Type : 1) Java  2) PHP"
read -p "Choix : " APP_TYPE_INPUT
[ "$APP_TYPE_INPUT" == "1" ] && APP_L="java" || APP_L="php"

sed -i "s|^APP_PATH=.*|APP_PATH=\"$TARGET_DIR\"|" "$START_SCRIPT"
sed -i "s|^APP_TYPE=.*|APP_TYPE=\"$APP_L\"|" "$START_SCRIPT"

bash "$BASE_DIR/Instalation/$APP_L.sh" "$TARGET_DIR" "$USERNAME"

# 7. Sécurité SSH
echo -e "${YELLOW}[6/7] Restrictions SSH...${NC}"
sudo deluser jukebox_play sudo || true
if ! grep -q "AllowUsers" /etc/ssh/sshd_config; then
    echo "AllowUsers administrateur technicien_BTC" | sudo tee -a /etc/ssh/sshd_config
    sudo systemctl restart ssh
fi

echo -e "${GREEN}[7/7] DÉPLOIEMENT TERMINÉ !${NC}"