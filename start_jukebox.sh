#!/bin/bash
# Auto-généré par deploy.sh
APP_PATH=""
USER_NAME=""
APP_TYPE=""

if [ "$APP_TYPE" == "java" ]; then
    JAR_FILE=$(find "$APP_PATH/dist" "$APP_PATH/target" -name "*.jar" 2>/dev/null | head -n 1)
    
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH"
        exec sudo -u "$USER_NAME" java -jar "$JAR_FILE"
    else
        echo "[$(date)] Erreur : Aucun JAR trouvé dans dist/ ou target/" >> /var/log/jukebox.log
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH"
    [ -d "public" ] && exec php -S 0.0.0.0:606 -t public/ || exec php -S 0.0.0.0:606
fi