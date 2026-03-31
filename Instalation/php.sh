#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

echo "--- Vérification des dépendances PHP ---"
sudo apt-get update -qq
sudo apt-get install -y php-cli php-zip unzip curl php-xml php-mbstring

cd "$TARGET_DIR" || exit 1

echo "--- Scan des fichiers de configuration ---"
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/vendor/"* ]] && continue
        clean_name=$(basename "$f_ex")
        dir_name=$(dirname "$f_ex")
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        f_final_path="$dir_name/$f_final"

        echo "Modèle détecté : $f_ex"
        echo "Voulez-vous configurer $f_final ? (o/n)"
        read -r choix < /dev/tty
        
        if [[ "$choix" =~ ^[oO]$ ]]; then
            cp "$f_ex" "$f_final_path"
            chown "$USERNAME" "$f_final_path"
            sudo -u "$USERNAME" nano "$f_final_path" < /dev/tty
            rm "$f_ex"
        fi
    done
fi

if [ -f "composer.json" ] && command -v composer &> /dev/null; then
    sudo -u "$USERNAME" composer install --no-dev --optimize-autoloader --no-interaction
fi

echo "Réglage des permissions..."
sudo chown -R "$USERNAME":www-data .
[ -d "storage" ] && chmod -R 775 storage
[ -d "bootstrap/cache" ] && chmod -R 775 bootstrap/cache