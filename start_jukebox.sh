#!/bin/bash
APP_PATH="/home/jukebox_play/Application/Jukebox"
USER_NAME="jukebox_play"
APP_TYPE="php"

# --- Sécurité : Attendre que le répertoire existe ---
while [ ! -d "$APP_PATH" ]; do sleep 1; done

if [ "$APP_TYPE" == "java" ]; then
    JAR_FILE=$(find "$APP_PATH" -name "*.jar" | grep "/dist/" | head -n 1)
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH" || exit 1
        echo "Lancement de l'application Java : $JAR_FILE"
        exec sudo -u "$USER_NAME" java -jar "$JAR_FILE"
    else
        echo "[ERREUR] Aucun fichier JAR trouvé dans $APP_PATH/dist/"
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH" || exit 1
    sudo fuser -k 125/tcp 2>/dev/null
    echo "Démarrage PHP sur le port 125..."
    if [ -d "public" ] && [ -f "public/index.php" ]; then
        exec php -S 0.0.0.0:125 -t public/
    else
        exec php -S 0.0.0.0:125
    fi
fi