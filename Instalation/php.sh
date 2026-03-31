#!/bin/bash
TARGET_DIR=$1
USERNAME=$2
cd "$TARGET_DIR" || exit 1

echo "--- Scan des fichiers de configuration ---"
mapfile -t FILES < <(find . -type f \( -name "*.exemple" -o -name "*.example" \))

for f_ex in "${FILES[@]}"; do
    f_final="${f_ex%.exemple}"
    f_final="${f_final%.example}"
    
    if [ ! -f "$f_final" ]; then
        cp "$f_ex" "$f_final"
        chown "$USERNAME" "$f_final"
        echo "Fichier créé : $f_final"
        read -p "Modifier $f_final maintenant ? (o/n) : " modif
        if [[ "$modif" =~ ^[oO]$ ]]; then
            sudo -u "$USERNAME" ${EDITOR:-nano} "$f_final"
        fi
    fi
done

sudo -u "$USERNAME" composer install --no-dev --optimize-autoloader --no-interaction