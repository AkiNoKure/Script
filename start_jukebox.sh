#!/bin/bash
APP_PATH=""
USER_NAME=""
APP_TYPE=""

if [ "$APP_TYPE" == "java" ]; then
    JAR_FILE=$(find "$APP_PATH" -name "*.jar" | grep "/dist/" | head -n 1)
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH"
        exec sudo -u "$USER_NAME" java -jar "$JAR_FILE"
    else
        exit 1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH"
    [ -d "public" ] && exec php -S 0.0.0.0:125 -t public/ || exec php -S 0.0.0.0:125
fi