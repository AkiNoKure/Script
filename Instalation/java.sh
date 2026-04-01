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
[ -n "$ANT_PATH" ] && sudo -u "$USERNAME" ant -f "$ANT_PATH" jar

# Kiosque
USER_HOME="/home/$USERNAME"
mkdir -p "$USER_HOME/.config/labwc"
echo "chromium http://localhost:51043 --kiosk --noerrdialogs --disable-infobars --no-first-run --enable-features=OverlayScrollbar --start-maximized &" > "$USER_HOME/.config/labwc/autostart"
echo "$USER_HOME/switchtab.sh &" >> "$USER_HOME/.config/labwc/autostart"

cat <<EOF > "$USER_HOME/switchtab.sh"
#!/bin/bash
while [[ -z \$(pgrep chromium) ]]; do sleep 5; done
while true; do wtype -M ctrl -P Tab -p Tab; sleep 10; done
EOF
chmod +x "$USER_HOME/switchtab.sh"
chown -R "$USERNAME":"$USERNAME" "$USER_HOME"