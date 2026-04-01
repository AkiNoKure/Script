#!/bin/bash
# Couleurs pour le suivi
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

TARGET_DIR=$1
USERNAME=$2
cd "$TARGET_DIR" || exit 1

echo -e "${BLUE}--- [PHP] Initialisation de l'environnement ---${NC}"

# Appel du gestionnaire de base de données
bash "$(dirname "$0")/bdd.sh" "$TARGET_DIR" "$USERNAME" "php"

# 1. Gestion des fichiers de configuration modèles
echo -e "${BLUE}--- [PHP] Scan des fichiers modèles ---${NC}"
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))
if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/vendor/"* ]] && continue
        clean_name=$(basename "$f_ex")
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example|ex|exemplaire)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        [ "$f_final" == "$clean_name" ] && f_final="${clean_name%.*}"
        
        echo -e "Modèle détecté : ${GREEN}$f_ex${NC}"
        echo "Configurer $f_final ? (o/n)"
        read -r choix < /dev/tty
        if [[ "$choix" =~ ^[oO]$ ]]; then
            cp "$f_ex" "./$f_final"
            chown "$USERNAME" "./$f_final"
            sudo -u "$USERNAME" nano "./$f_final" < /dev/tty > /dev/tty
            rm "$f_ex"
        fi
    done
fi

# 2. Configuration Kiosque (Doc Section 7.b & 7.c)
echo -e "${BLUE}--- [PHP] Configuration du mode Kiosque ---${NC}"
USER_HOME="/home/$USERNAME"
mkdir -p "$USER_HOME/.config/labwc"

# Autostart labwc (Port 51043 conforme à la doc)
echo "chromium http://localhost:51043 --kiosk --noerrdialogs --disable-infobars --no-first-run --enable-features=OverlayScrollbar --start-maximized &" > "$USER_HOME/.config/labwc/autostart"
echo "$USER_HOME/switchtab.sh &" >> "$USER_HOME/.config/labwc/autostart"

# Script switchtab.sh conforme à la doc
cat <<EOF > "$USER_HOME/switchtab.sh"
#!/bin/bash
while [[ -z \$(pgrep chromium) ]]; do sleep 5; done
while true; do wtype -M ctrl -P Tab -p Tab; sleep 10; done
EOF

chmod +x "$USER_HOME/switchtab.sh"
chown -R "$USERNAME":"$USERNAME" "$USER_HOME"

# 3. Permissions finales pour le serveur Web
echo -e "${BLUE}--- [PHP] Réglage des permissions ---${NC}"
sudo chown -R "$USERNAME":www-data .
sudo chmod -R 755 .
echo -e "${GREEN}[OK] Environnement PHP prêt.${NC}"