#!/bin/bash
# Ce fichier est auto-généré par deploy.sh - Ne pas modifier manuellement [cite: 1]

APP_PATH=""
USER_NAME=""
APP_TYPE=""

echo "Lancement du Jukebox ($APP_TYPE) pour l'utilisateur $USER_NAME..." [cite: 1]

if [ "$APP_TYPE" == "java" ]; then [cite: 1]
    # Recherche récursive du JAR dans target
    JAR_FILE=$(find "$APP_PATH/target" -name "*.jar" 2>/dev/null | head -n 1) [cite: 1]
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH" [cite: 1]
        exec sudo -u "$USER_NAME" java -jar "$JAR_FILE" [cite: 1]
    else
        echo "Erreur : Aucun JAR trouvé." [cite: 1]
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then [cite: 1]
    cd "$APP_PATH" [cite: 1]
    if [ -d "public" ]; then
        exec php -S 0.0.0.0:606 -t public/ [cite: 1]
    else
        exec php -S 0.0.0.0:606 [cite: 1]
    fi
fi