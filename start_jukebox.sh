#!/bin/bash
APP_PATH=""
USER_NAME=""
APP_TYPE=""

LOG_RUN="/var/log/jukebox.log"
echo "[$(date)] Lancement $APP_TYPE" >> "$LOG_RUN"

if [ "$APP_TYPE" == "java" ]; then
    JAR_FILE=$(find "$APP_PATH/target" -name "*.jar" 2>/dev/null | head -n 1)
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH"
        exec sudo -u "$USER_NAME" java -jar "$JAR_FILE"
    else
        echo "Erreur : Aucun JAR." >> "$LOG_RUN"
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH"
    [ -d "public" ] && exec php -S 0.0.0.0:606 -t public/ || exec php -S 0.0.0.0:606
fi