#!/bin/bash
APP_PATH="/home/jukebox_play/Application/Jukebox"
USER_NAME="jukebox_play"
APP_TYPE="php"
LOG_FILE="/tmp/jukebox_start.log"

log_msg() {
    echo "[$(date '+%H-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

echo "--- Nouvelle tentative de démarrage ---" >> "$LOG_FILE"

# Attente du répertoire
while [ ! -d "$APP_PATH" ]; do 
    log_msg "ATTENTE : Répertoire $APP_PATH introuvable..."
    sleep 2
done

if [ "$APP_TYPE" == "php" ]; then
    log_msg "Diagnostic PHP en cours..."
    cd "$APP_PATH" || { log_msg "ERREUR : Impossible d'accéder à $APP_PATH"; exit 1; }

    # Vérification du contenu du dossier pour le log
    FILES_FOUND=$(ls -F | grep ".php" | tr '\n' ' ')
    log_msg "Fichiers PHP détectés dans $(pwd) : $FILES_FOUND"

    if [ -z "$FILES_FOUND" ]; then
        log_msg "ALERTE : Aucun fichier .php trouvé dans $APP_PATH. Le 404 est normal."
    fi

    # Nettoyage du port
    sudo fuser -k 51043/tcp 2>/dev/null || true
    
    log_msg "Lancement du serveur sur 0.0.0.0:51043"
    # L'option -t force le répertoire racine du serveur
    exec php -S 0.0.0.0:51043 -t "$APP_PATH" >> "$LOG_FILE" 2>&1
fi