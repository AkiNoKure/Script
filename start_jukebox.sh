#!/bin/bash
APP_PATH="/home/jukebox_play/Application/Jukebox"
USER_NAME="jukebox_play"
APP_TYPE="php"

# Attendre que le répertoire existe
while [ ! -d "$APP_PATH" ]; do sleep 1; done

if [ "$APP_TYPE" == "java" ]; then
    # Attente pour que la session graphique soit prête
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        sleep 5
    fi

    JAR_FILE=$(find "$APP_PATH" -name "*.jar" | grep "/dist/" | head -n 1)
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH" || exit 1
        echo "Lancement Java GUI : $JAR_FILE"
        java -jar "$JAR_FILE"
    else
        echo "[ERREUR] Aucun JAR trouvé."
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH" || exit 1
    sudo fuser -k 125/tcp 2>/dev/null
    if [ -d "public" ] && [ -f "public/index.php" ]; then
        exec php -S 0.0.0.0:125 -t public/
    else
        exec php -S 0.0.0.0:125
    fi
fi