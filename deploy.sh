#!/bin/bash
set -e

# Couleurs pour le suivi visuel
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}   INITIALISATION & DÉPLOIEMENT JUKEBOX (2026)      ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# 1. Installation Logiciels (Doc Section 3)
echo -e "${YELLOW}[1/7] Installation des dépendances système...${NC}"
sudo apt update -qq
sudo apt install -y apache2 php php-common php-mysql php-sqlite3 php-json php-curl php-mbstring php-xml php-zip mariadb-server openjdk-21-jdk openjdk-21-jre vlc phpmyadmin sqlite3 chromium wtype

# 2. Utilisateurs (Doc Section 4 & 5)
echo -e "${YELLOW}[2/7] Configuration des utilisateurs...${NC}"
for USR in "technicien_BTC" "jukebox_play"; do
    if ! id "$USR" &>/dev/null; then
        sudo adduser --disabled-password --gecos "" "$USR"
        echo "$USR:raspberry" | sudo chpasswd
    fi
done
sudo usermod -aG sudo jukebox_play

# 3. Détection d'état et changement de technologie
USERNAME="jukebox_play"
TARGET_DIR="/home/$USERNAME/Application/Jukebox"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
START_SCRIPT="$BASE_DIR/start_jukebox.sh"

if [ -d "$TARGET_DIR" ] && [ -f "$START_SCRIPT" ]; then
    CURRENT_APP=$(grep "APP_TYPE=" "$START_SCRIPT" | cut -d'"' -f2)
    echo -e "${BLUE}--> Installation existante détectée : ${GREEN}$CURRENT_APP${NC}"
    echo "1) Mettre à jour (conserver la techno actuelle)"
    echo "2) Écraser et changer de technologie (ex: Java vers PHP)"
    read -p "Votre choix : " INSTALL_MODE
    if [ "$INSTALL_MODE" == "2" ]; then
        echo -e "${RED}Nettoyage complet pour changement de technologie...${NC}"
        sudo systemctl stop jukebox.service 2>/dev/null || true
        sudo rm -rf "$TARGET_DIR"/*
    fi
fi

# 4. Sauvegarde
echo -e "${YELLOW}[3/7] Gestion de la sauvegarde pré-déploiement...${NC}"
if [ -d "$TARGET_DIR" ]; then
    sudo mkdir -p "${TARGET_DIR}_backup"
    sudo rm -rf "${TARGET_DIR}_backup"/*
    sudo mysqldump jukebox_db > "${TARGET_DIR}_backup/jukebox_dump.sql" 2>/dev/null || true [cite: 1]
    [ -f "$TARGET_DIR/jukebox.sqlite" ] && sudo cp "$TARGET_DIR/jukebox.sqlite" "${TARGET_DIR}_backup/" [cite: 1]
    sudo cp -r "$TARGET_DIR"/* "${TARGET_DIR}_backup/" 2>/dev/null || true [cite: 1]
fi

# 5. Récupération Source
echo -e "${YELLOW}[4/7] Récupération des sources du projet...${NC}"
echo "1) Dépôt Git  2) Archive locale"
read -p "Choix : " SOURCE_CHOICE
sudo mkdir -p "$TARGET_DIR"
if [ "$SOURCE_CHOICE" == "1" ]; then
    read -p "URL Git : " REPO_URL
    [ ! -d "$TARGET_DIR/.git" ] && sudo -u "$USERNAME" git clone "$REPO_URL" "$TARGET_DIR"/. || (cd "$TARGET_DIR" && sudo -u "$USERNAME" git pull)
else
    read -e -p "Chemin complet archive : " ARCHIVE_PATH
    if [[ "$ARCHIVE_PATH" == *.zip ]]; then sudo unzip -o "$ARCHIVE_PATH" -d "$TARGET_DIR" [cite: 1]
    else sudo tar -xzf "$ARCHIVE_PATH" -C "$TARGET_DIR"; fi [cite: 1]
fi

# 6. Type d'application et Installation
echo -e "${YELLOW}[5/7] Configuration spécifique de l'application...${NC}"
echo "Type : 1) Java  2) PHP"
read -p "Choix : " APP_TYPE_INPUT
[ "$APP_TYPE_INPUT" == "1" ] && APP_L="java" || APP_L="php"

sed -i "s|^APP_PATH=.*|APP_PATH=\"$TARGET_DIR\"|" "$START_SCRIPT" [cite: 1]
sed -i "s|^APP_TYPE=.*|APP_TYPE=\"$APP_L\"|" "$START_SCRIPT" [cite: 1]

bash "$BASE_DIR/Instalation/$APP_L.sh" "$TARGET_DIR" "$USERNAME"

# 7. Sécurité SSH
echo -e "${YELLOW}[6/7] Application des restrictions de sécurité...${NC}"
sudo deluser jukebox_play sudo || true
if ! grep -q "AllowUsers" /etc/ssh/sshd_config; then
    echo "AllowUsers administrateur technicien_BTC" | sudo tee -a /etc/ssh/sshd_config
    sudo systemctl restart ssh
fi

echo -e "${GREEN}[7/7] DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !${NC}"
echo -e "${BLUE}Rappel : Réglez le clavier en AZERTY via sudo raspi-config.${NC}"