#!/bin/bash
# Ce fichier est auto-généré par deploy.sh - Ne pas modifier manuellement

APP_PATH=""
USER_NAME=""
APP_TYPE=""

echo "Lancement du Jukebox ($APP_TYPE) pour l'utilisateur $USER_NAME..."

if [ "$APP_TYPE" == "java" ]; then
    JAR_FILE=$(find "$APP_PATH/target" -name "*.jar" | head -n 1)
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH"
        exec sudo -u "$USER_NAME" java -jar "$JAR_FILE"
    else
        echo "Erreur : Aucun JAR trouvé."
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH"

    if [ -d "public" ]; then
    exec php -S 0.0.0.0:606 -t public/
    else
    exec php -S 0.0.0.0:606
    fi
fi