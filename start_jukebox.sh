#!/bin/bash
APP_PATH="/home/jukebox_play/Application/Jukebox"
APP_TYPE="php"
LOG_FILE="/tmp/jukebox_start.log"

while [ ! -d "$APP_PATH" ]; do sleep 2; done

if [ "$APP_TYPE" == "java" ]; then
    JAR_FILE=$(find "$APP_PATH" -name "*.jar" | grep "/dist/" | head -n 1)
    if [ -n "$JAR_FILE" ]; then
        cd "$APP_PATH"
        exec java -jar "$JAR_FILE" >> "$LOG_FILE" 2>&1
    fi
elif [ "$APP_TYPE" == "php" ]; then
    cd "$APP_PATH"
    sudo fuser -k 51043/tcp 2>/dev/null || true
    exec php -S 0.0.0.0:51043 -t "$APP_PATH" >> "$LOG_FILE" 2>&1
fi