#!/bin/bash
TARGET_DIR=$1
USERNAME=$2
cd "$TARGET_DIR" || exit 1

echo "--- Scan des configurations Java ---"
# Recherche récursive de .exemple et .example
mapfile -t FILES < <(find . -type f \( -name "*.exemple" -o -name "*.example" \))

for f_ex in "${FILES[@]}"; do
    f_final="${f_ex%.exemple}"
    f_final="${f_final%.example}"
    
    if [ ! -f "$f_final" ]; then
        read -p "Créer $f_final depuis modèle ? (o/n) : " choix
        if [[ "$choix" =~ ^[oO]$ ]]; then
            cp "$f_ex" "$f_final"
            chown "$USERNAME" "$f_final"
            read -p "Modifier le fichier maintenant ? (o/n) : " modif
            [ [[ "$modif" =~ ^[oO]$ ]] ] && sudo -u "$USERNAME" ${EDITOR:-nano} "$f_final"
        fi
    fi
done

# Build Maven automatique
if [ -f "pom.xml" ]; then
    sudo -u "$USERNAME" mvn clean package -DskipTests
fi