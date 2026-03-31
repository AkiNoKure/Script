#!/bin/bash
TARGET_DIR=$1
USERNAME=$2
cd "$TARGET_DIR" || exit 1

echo "--- Scan des fichiers de configuration ---"
# Recherche récursive de .exemple ou .example
mapfile -t FILES < <(find . -type f \( -name "*.exemple" -o -name "*.example" \))

for f_ex in "${FILES[@]}"; do
    f_final="${f_ex%.exemple}"
    f_final="${f_final%.example}"
    
    if [ ! -f "$f_final" ]; then
        read -p "Créer $f_final depuis modèle ? (o/n) : " choix
        if [[ "$choix" =~ ^[oO]$ ]]; then
            cp "$f_ex" "$f_final"
            chown "$USERNAME" "$f_final"
            read -p "Voulez-vous modifier $f_final maintenant ? (o/n) : " modif
            if [[ "$modif" =~ ^[oO]$ ]]; then
                sudo -u "$USERNAME" ${EDITOR:-nano} "$f_final"
            fi
        fi
    fi
done

echo "Souhaitez-vous builder le projet ? (o/n)"
read -r build_choice
if [[ "$build_choice" =~ ^[oO]$ ]]; then
    if [ -f "pom.xml" ]; then
        sudo -u "$USERNAME" mvn clean package -DskipTests
    else
        echo "Aucun fichier pom.xml trouvé pour le build."
    fi
fi