#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

if [ ! -d "$TARGET_DIR" ]; then
    echo "[ERREUR] Le répertoire $TARGET_DIR n'existe pas."
    exit 1
fi

cd "$TARGET_DIR" || exit 1

# --- Correction JAVA_HOME pour Ant ---
export JAVA_HOME=$(readlink -f $(which java) | sed "s:/bin/java::")
echo "Utilisation de JAVA_HOME : $JAVA_HOME"

echo "--- Scan des fichiers modèles ---"
# Recherche insensible à la casse incluant les préfixes _ et extensions .exemple
FILES=$(find . -type f \( -iname "*.exemple" -o -iname "*.example" -o -iname "_exemple*" -o -iname "_example*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        clean_name=$(echo "$f_ex" | sed 's|^\./||')
        # On extrait le nom de base en retirant le préfixe _ ou l'extension .exemple
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^_//')
        f_final_path="$(dirname "$f_ex")/$f_final"

        if [ ! -f "$f_final_path" ]; then
            echo "Modèle détecté : $clean_name"
            read -p "Créer $f_final ? (o/n) : " choix
            if [[ "$choix" =~ ^[oO]$ ]]; then
                cp "$f_ex" "$f_final_path"
                chown "$USERNAME" "$f_final_path"
                echo "Fichier créé. Ouverture de l'éditeur..."
                sudo -u "$USERNAME" ${EDITOR:-nano} "$f_final_path"
            fi
        fi
    done
else
    echo "Aucun fichier modèle (.exemple, _exemple) détecté."
fi

echo "--- Vérification du Build (Ant) ---"
ANT_PATH=$(find . -name "build.xml" | head -n 1)

if [ -n "$ANT_PATH" ]; then
    BUILD_DIR=$(dirname "$ANT_PATH")
    cd "$BUILD_DIR"
    read -p "Projet Ant détecté dans $BUILD_DIR. Compiler ? (o/n) : " build_choice
    if [[ "$build_choice" =~ ^[oO]$ ]]; then
        # On lance Ant en passant explicitement le JDK
        sudo -u "$USERNAME" JAVA_HOME="$JAVA_HOME" ant jar
    fi
else
    echo "Aucun fichier build.xml trouvé."
fi