#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

if [ ! -d "$TARGET_DIR" ]; then
    echo "[ERREUR] Le répertoire $TARGET_DIR n'existe pas."
    exit 1
fi

cd "$TARGET_DIR" || exit 1
echo "--- Scan récursif des fichiers modèles (NetBeans) ---"

# Recherche incluant _exemple.java, Connexion.java.exemple, etc.
FILES=$(find . -type f \( -iname "*.exemple" -o -iname "*.example" -o -iname "_exemple*" -o -iname "_example*" \))

if [ -z "$FILES" ]; then
    echo "Aucun fichier modèle détecté."
else
    for f_ex in $FILES; do
        clean_name=$(echo "$f_ex" | sed 's|^\./||')
        # Nettoyage pour obtenir le nom de destination
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^_//')
        f_final_path="$TARGET_DIR/$f_final"

        if [ ! -f "$f_final_path" ]; then
            echo "Modèle trouvé : $clean_name"
            read -p "Créer $f_final ? (o/n) : " choix
            if [[ "$choix" =~ ^[oO]$ ]]; then
                mkdir -p "$(dirname "$f_final_path")"
                cp "$clean_name" "$f_final_path"
                chown "$USERNAME" "$f_final_path"
                read -p "Modifier $f_final maintenant ? (o/n) : " modif
                [[ "$modif" =~ ^[oO]$ ]] && sudo -u "$USERNAME" ${EDITOR:-nano} "$f_final_path"
            fi
        fi
    done
fi

echo "--- Vérification du Build (Ant/NetBeans) ---"
# Recherche du fichier build.xml propre à NetBeans/Ant
ANT_PATH=$(find . -name "build.xml" | head -n 1)

if [ -n "$ANT_PATH" ]; then
    BUILD_DIR=$(dirname "$ANT_PATH")
    cd "$BUILD_DIR"
    read -p "Fichier build.xml (Ant) trouvé. Compiler le projet ? (o/n) : " build_choice
    if [[ "$build_choice" =~ ^[oO]$ ]]; then
        # Installation de ant si manquant
        if ! command -v ant &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y ant
        fi
        sudo -u "$USERNAME" ant jar
    fi
else
    echo "Aucun fichier build.xml trouvé. Compilation impossible via Ant."
fi