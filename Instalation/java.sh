#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

cd "$TARGET_DIR" || exit 1
# ... (Partie compilation identique) ...

echo "--- Scan des modèles Java ---"
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/build/"* ]] || [[ "$f_ex" == *"/dist/"* ]] && continue
        clean_name=$(basename "$f_ex")
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        f_final_path="$(dirname "$f_ex")/$f_final"

        echo "Configurer $f_final ? (o/n)"
        read -r choix < /dev/tty
        if [[ "$choix" =~ ^[oO]$ ]]; then
            cp "$f_ex" "$f_final_path"
            chown "$USERNAME" "$f_final_path"
            sudo -u "$USERNAME" nano "$f_final_path" < /dev/tty > /dev/tty
            rm "$f_ex"
        fi
    done
fi