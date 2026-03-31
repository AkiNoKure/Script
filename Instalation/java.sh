#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

# --- 1. Installation des dépendances ---
install_deps() {
    echo "--- Mise à jour et installation des dépendances ---"
    sudo apt-get update -qq
    sudo apt-get install -y default-jdk ant
}

if [ ! -d "$TARGET_DIR" ]; then
    echo "[ERREUR] Le répertoire $TARGET_DIR n'existe pas."
    exit 1
fi

install_deps
cd "$TARGET_DIR" || exit 1

export JAVA_HOME=$(readlink -f $(which java) | sed "s:/bin/java::")
echo "Environnement : JAVA_HOME=$JAVA_HOME"

# --- 2. Scan exhaustif des fichiers modèles ---
echo "--- Scan des fichiers de configuration ---"
# Recherche de tout fichier contenant "exem" ou "exam"
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        [[ "$f_ex" == *"/.git/"* ]] && continue
        [[ "$f_ex" == *"/build/"* ]] && continue
        [[ "$f_ex" == *"/dist/"* ]] && continue
        [[ "$f_ex" == *.class ]] && continue
        
        clean_name=$(basename "$f_ex")
        dir_name=$(dirname "$f_ex")
        
        # Nettoyage du nom pour créer le fichier final
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        f_final_path="$dir_name/$f_final"

        if [ ! -f "$f_final_path" ]; then
            echo "Modèle détecté : $f_ex"
            # Utilisation de /dev/tty pour garantir l'interactivité sous sudo
            echo "Voulez-vous créer et modifier $f_final ? (o/n)"
            read -r choix < /dev/tty
            if [[ "$choix" =~ ^[oO]$ ]]; then
                cp "$f_ex" "$f_final_path"
                chown "$USERNAME" "$f_final_path"
                sudo -u "$USERNAME" nano "$f_final_path" < /dev/tty
            fi
        fi
    done
else
    echo "Aucun fichier modèle détecté."
fi

# --- 3. Compilation Ant ---
echo "--- Vérification du Build ---"
ANT_PATH=$(find . -name "build.xml" | head -n 1)

if [ -n "$ANT_PATH" ]; then
    BUILD_DIR=$(dirname "$ANT_PATH")
    cd "$BUILD_DIR"
    echo "Fichier build.xml trouvé dans : $BUILD_DIR"
    
    echo "Lancer la compilation ant jar ? (o/n)"
    read -r build_choice < /dev/tty
    if [[ "$build_choice" =~ ^[oO]$ ]]; then
        sudo -u "$USERNAME" JAVA_HOME="$JAVA_HOME" ant jar
    fi
else
    echo "Aucun fichier build.xml trouvé."
fi