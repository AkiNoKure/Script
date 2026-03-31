#!/bin/bash
TARGET_DIR=$1
USERNAME=$2
cd "$TARGET_DIR" || exit 1

echo "--- Scan récursif des fichiers de configuration ---"
# Recherche de tous les fichiers .exemple ou .example dans tout le projet
FILES=$(find . -type f \( -name "*.exemple" -o -name "*.example" \))

if [ -z "$FILES" ]; then
    echo "Aucun fichier modèle (.exemple/.example) trouvé dans $TARGET_DIR"
else
    for f_ex in $FILES; do
        # On retire l'extension pour obtenir le nom du fichier final
        f_final="${f_ex%.exemple}"
        f_final="${f_final%.example}"
        
        if [ ! -f "$f_final" ]; then
            echo "Modèle trouvé : $f_ex"
            read -p "Créer et modifier $f_final ? (o/n) : " choix
            if [[ "$choix" =~ ^[oO]$ ]]; then
                cp "$f_ex" "$f_final"
                chown "$USERNAME" "$f_final"
                # Ouvre l'éditeur pour l'utilisateur
                sudo -u "$USERNAME" ${EDITOR:-nano} "$f_final"
            fi
        else
            echo "Le fichier $f_final existe déjà. Passage au suivant."
        fi
    done
fi

echo "--- Vérification du Build ---"
# Recherche du pom.xml même s'il n'est pas à la racine
POM_PATH=$(find . -name "pom.xml" | head -n 1)

if [ -n "$POM_PATH" ]; then
    BUILD_DIR=$(dirname "$POM_PATH")
    read -p "Fichier pom.xml trouvé dans $BUILD_DIR. Builder le projet ? (o/n) : " build_choice
    if [[ "$build_choice" =~ ^[oO]$ ]]; then
        cd "$BUILD_DIR"
        sudo -u "$USERNAME" mvn clean package -DskipTests
    fi
else
    echo "Erreur : Aucun fichier pom.xml détecté dans l'arborescence."
fi