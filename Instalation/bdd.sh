#!/bin/bash
# Script de gestion de base de données centralisé
TARGET_DIR=$1
USERNAME=$2
APP_TYPE=$3 # "java" ou "php"

echo "--- Configuration de la Base de Données ($APP_TYPE) ---"
echo "Quelle base de données souhaitez-vous implémenter ?"
echo "1) MariaDB (Serveur SQL)"
echo "2) SQLite (Fichier local)"
read -r db_choice < /dev/tty

case $db_choice in
    1)
        echo "Installation et configuration de MariaDB..."
        sudo apt-get update -qq && sudo apt-get install -y mariadb-server
        [ "$APP_TYPE" == "php" ] && sudo apt-get install -y php-mysql
        
        # Initialisation sécurisée
        sudo mysql -e "CREATE DATABASE IF NOT EXISTS jukebox_db;"
        sudo mysql -e "GRANT ALL PRIVILEGES ON jukebox_db.* TO '$USERNAME'@'localhost' IDENTIFIED BY 'password';"
        sudo mysql -e "FLUSH PRIVILEGES;"
        
        # Restauration (Priorité : Backup > Schéma Git)
        if [ -f "${TARGET_DIR}_backup/jukebox_dump.sql" ]; then
            echo "Restauration du backup MariaDB détecté..."
            sudo mysql jukebox_db < "${TARGET_DIR}_backup/jukebox_dump.sql"
        elif [ -f "$TARGET_DIR/database.sql" ]; then
            echo "Initialisation via le schéma database.sql..."
            sudo mysql jukebox_db < "$TARGET_DIR/database.sql"
        fi
        ;;
    2)
        echo "Configuration de SQLite..."
        [ "$APP_TYPE" == "php" ] && sudo apt-get install -y php-sqlite3
        
        DB_FILE="$TARGET_DIR/jukebox.sqlite"
        
        if [ -f "${TARGET_DIR}_backup/jukebox.sqlite" ]; then
            echo "Restauration du fichier SQLite existant..."
            cp "${TARGET_DIR}_backup/jukebox.sqlite" "$DB_FILE"
        else
            echo "Création d'une nouvelle base SQLite vide..."
            touch "$DB_FILE"
        fi
        
        # Permissions selon l'usage
        chown "$USERNAME":www-data "$DB_FILE"
        chmod 664 "$DB_FILE"
        ;;
    *)
        echo "Choix invalide, aucune base configurée."
        return 1
        ;;
esac