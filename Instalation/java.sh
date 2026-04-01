#!/bin/bash
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
TARGET_DIR=$1; USERNAME=$2
cd "$TARGET_DIR" || exit 1

echo -e "${BLUE}--- [JAVA] Initialisation ---${NC}"
bash "$(dirname "$0")/../bdd.sh" "$TARGET_DIR" "$USERNAME" "java"

# Modèles
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))
for f_ex in $FILES; do
    [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/dist/"* ]] && continue
    f_final=$(basename "$f_ex" | sed -E 's/\.(exemple|example)$//I')
    echo "Configurer $f_final ? (o/n)"
    read -r choix < /dev/tty
    if [[ "$choix" =~ ^[oO]$ ]]; then
        cp "$f_ex" "./$f_final"
        sudo -u "$USERNAME" nano "./$f_final" < /dev/tty > /dev/tty
    fi
done

# Compilation
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-armhf"
ANT_PATH=$(find . -name "build.xml" | head -n 1)
if [ -n "$ANT_PATH" ]; then
    sudo -u "$USERNAME" ant -f "$ANT_PATH" jar
fi

# Lancement de l'application Java (GUI ou console)
JAR_FILE=$(find . -type f -name "*.jar" | grep "/dist/" | head -n 1)
if [ -n "$JAR_FILE" ]; then
    echo -e "${GREEN}Lancement de l'application Java : $JAR_FILE${NC}"
    sudo -u "$USERNAME" java -jar "$JAR_FILE" &
else
    echo -e "${BLUE}Aucun fichier JAR trouvé dans ./dist/. L'application n'a pas