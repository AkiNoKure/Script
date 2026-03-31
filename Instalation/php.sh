#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

echo "--- Dépendances PHP ---"
sudo apt-get update -qq
sudo apt-get install -y php-cli php-zip unzip curl php-xml php-mbstring

cd "$TARGET_DIR" || exit 1

FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/vendor/"* ]] && continue
        
        clean_name=$(basename "$f_ex")
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example|ex|exemplaire)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        [ "$f_final" == "$clean_name" ] && f_final="${clean_name%.*}"
        f_final_path="$(dirname "$f_ex")/$f_final"

        echo "Modèle : $f_ex"
        echo "Configurer $f_final ? (o/n)"
        read -r choix < /dev/tty
        
        if [[ "$choix" =~ ^[oO]$ ]]; then
            cp "$f_ex" "$f_final_path"
            chown "$USERNAME" "$f_final_path"
            sudo -u "$USERNAME" nano "$f_final_path" < /dev/tty
            [ -f "$f_final_path" ] && rm "$f_ex"
        fi
    done
fi
sudo chown -R "$USERNAME":www-data .