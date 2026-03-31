#!/bin/bash
TARGET_DIR=$1
USERNAME=$2
cd "$TARGET_DIR" || exit 1

echo "--- Scan récursif des fichiers de configuration ---"

# Recherche étendue : .exemple, .example, _exemple.* et _example.*
# On utilise -iregex pour ignorer la casse et couvrir toutes les variantes
FILES=$(find . -type f \( -name "*.exemple" -o -name "*.example" -o -name "_exemple.*" -o -name "_example.*" \))

if [ -z "$FILES" ]; then
    echo "Aucun fichier modèle trouvé dans $TARGET_DIR"
else
    for f_ex in $FILES; do
        # Logique de nettoyage du nom de fichier
        # 1. On retire le chemin relatif ./
        clean_name=$(echo "$f_ex" | sed 's|^\./||')
        
        # 2. On détermine le nom cible en retirant l'extension ou le préfixe
        # Si c'est _exemple.java -> exemple.java
        # Si c'est config.exemple -> config
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//; s/^_//')
        
        # On reconstruit le chemin complet pour le test
        f_final_path="$TARGET_DIR/$f_final"

        if [ ! -f "$f_final_path" ]; then
            echo "Modèle détecté : $clean_name"
            read -p "Créer $f_final ? (o/n) : " choix
            if [[ "$choix" =~ ^[oO]$ ]]; then
                # Création du dossier parent si nécessaire
                mkdir -p "$(dirname "$f_final_path")"
                cp "$clean_name" "$f_final_path"
                chown "$USERNAME" "$f_final_path"
                
                read -p "Modifier $f_final maintenant ? (o/n) : " modif
                if [[ "$modif" =~ ^[oO]$ ]]; then
                    sudo -u "$USERNAME" ${EDITOR:-nano} "$f_final_path"
                fi
            fi
        fi
    done
fi

echo "--- Vérification du Build ---"
POM_PATH=$(find . -name "pom.xml" | head -n 1)

if [ -n "$POM_PATH" ]; then
    BUILD_DIR=$(dirname "$POM_PATH")
    read -p "pom.xml trouvé dans $BUILD_DIR. Builder ? (o/n) : " build_choice
    if [[ "$build_choice" =~ ^[oO]$ ]]; then
        cd "$BUILD_DIR"
        sudo -u "$USERNAME" mvn clean package -DskipTests
    fi
else
    echo "Aucun fichier pom.xml détecté."
fi