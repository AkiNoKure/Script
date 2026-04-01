#!/bin/bash
APP_PATH="/home/jukebox_play/Application/Jukebox"
USER_NAME="jukebox_play"
APP_TYPE="php"
LOG_FILE="/tmp/jukebox_start.log"

log_msg() {
    echo "[$(date '+%H-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Attente du répertoire (indispensable au boot)
while [ ! -d "$APP_PATH" ]; do 
    log_msg "Répertoire $APP_PATH introuvable, attente..."
    sleep 2
done

if [ "$APP_TYPE" == "java" ]; then
    JAR_FILE=$(find "$APP_PATH" -name "*.jar" | grep "/dist/" | head -n 1)
    if [ -n "$JAR_FILE" ]; then
        log_msg "Lancement Java : $JAR_FILE"
        cd "$APP_PATH"
        exec java -jar "$JAR_FILE" >> "$LOG_FILE" 2>&1
    else
        log_msg "ERREUR : JAR introuvable."
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH" || exit 1
    sudo fuser -k 51043/tcp 2>/dev/null || true
    log_msg "Lancement PHP sur port 51043 dans $APP_PATH"
    # Lancement explicite sur toutes les interfaces
    exec php -S 0.0.0.0:51043 >> "$LOG_FILE" 2>&1
fi