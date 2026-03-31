#!/bin/bash
APP_PATH="/home/jukebox_play/Application/Jukebox"
USER_NAME="jukebox_play"
APP_TYPE="java"
LOG_FILE="/tmp/jukebox_start.log"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "--- Démarrage du script ---"

# --- Correction Problème 2 : Attente systématique ---
if [ "$APP_TYPE" == "java" ]; then
    log_msg "Mode Java : Attente de 15s pour stabiliser l'interface graphique..."
    sleep 15
    
    # Forcer DISPLAY si vide (Standard Raspberry Pi)
    if [ -z "$DISPLAY" ]; then
        export DISPLAY=:0
        log_msg "DISPLAY était vide, forcé à :0"
    fi
fi

# Attendre que le répertoire existe
while [ ! -d "$APP_PATH" ]; do 
    log_msg "En attente du répertoire : $APP_PATH"
    sleep 2
done

if [ "$APP_TYPE" == "java" ]; then
    JAR_FILE=$(find "$APP_PATH" -name "*.jar" | grep "/dist/" | head -n 1)
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH" || exit 1
        log_msg "Lancement du JAR : $JAR_FILE"
        # Lancement avec redirection des erreurs vers le terminal visible
        java -jar "$JAR_FILE" 2>&1 | tee -a "$LOG_FILE"
    else
        log_msg "ERREUR : Aucun JAR trouvé dans $APP_PATH/dist/"
        read -p "Appuyez sur Entrée pour fermer..." # Garde le terminal ouvert en cas d'erreur
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH" || exit 1
    sudo fuser -k 125/tcp 2>/dev/null
    exec php -S 0.0.0.0:125
fi