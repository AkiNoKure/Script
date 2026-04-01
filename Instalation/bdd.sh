#!/bin/bash
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
TARGET_DIR=$1; USERNAME=$2; APP_TYPE=$3

echo -e "${BLUE}--- Analyse des ressources BDD ---${NC}"
SQL_REAL=$(find "$TARGET_DIR" -maxdepth 2 -type f -name "*.sql" ! -name "*exem*" | head -n 1)
SQL_EX=$(find "$TARGET_DIR" -maxdepth 2 -type f \( -name "*.sql.exemple" -o -name "*.sql.example" \) | head -n 1)
SQLITE_REAL=$(find "$TARGET_DIR" -maxdepth 2 -type f -name "*.sqlite" ! -name "*exem*" | head -n 1)
SQLITE_EX=$(find "$TARGET_DIR" -maxdepth 2 -type f \( -name "*.sqlite.exemple" -o -name "*.sqlite.example" \) | head -n 1)

if [ -n "$SQL_REAL" ] || [ -n "$SQL_EX" ]; then
    echo -e "${GREEN}Mode MariaDB détecté.${NC}"
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS jukebox_db;"
    sudo mysql -e "GRANT ALL PRIVILEGES ON jukebox_db.* TO '$USERNAME'@'localhost' IDENTIFIED BY 'password';"
    if [ -n "$SQL_REAL" ]; then 
        echo "Importation du fichier réel : $(basename "$SQL_REAL")"
        sudo mysql jukebox_db < "$SQL_REAL"
    elif [ -n "$SQL_EX" ]; then
        echo "Configuration à partir du modèle : $(basename "$SQL_EX")"
        FINAL="${SQL_EX%.*}"
        cp "$SQL_EX" "$FINAL"
        sudo -u "$USERNAME" nano "$FINAL" < /dev/tty > /dev/tty
        sudo mysql jukebox_db < "$FINAL"
    fi
elif [ -n "$SQLITE_REAL" ] || [ -n "$SQLITE_EX" ]; then
    echo -e "${GREEN}Mode SQLite détecté.${NC}"
    DEST="$TARGET_DIR/jukebox.sqlite"
    [ -n "$SQLITE_REAL" ] && cp "$SQLITE_REAL" "$DEST" || cp "$SQLITE_EX" "$DEST"
    chown "$USERNAME":www-data "$DEST"
    chmod 664 "$DEST"
else
    echo -e "${RED}AVERTISSEMENT : Aucune source BDD trouvée.${NC}"
fi