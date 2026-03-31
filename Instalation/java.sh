#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

# --- 1. Installation des dépendances ---
install_deps() {
    echo "--- Mise à jour et installation des dépendances ---"
    sudo apt-get update -qq
    
    # Installation du JDK le plus récent disponible et de Ant
    # 'default-jdk' pointe toujours vers la version stable la plus récente du dépôt
    sudo apt-get install -y default-jdk ant
}

if [ ! -d "$TARGET_DIR" ]; then
    echo "[ERREUR] Le répertoire $TARGET_DIR n'existe pas."
    exit 1
fi

install_deps
cd "$TARGET_DIR" || exit 1

# Définition dynamique du JAVA_HOME
export JAVA_HOME=$(readlink -f $(which java) | sed "s:/bin/java::")
echo "Environnement : JAVA_HOME=$JAVA_HOME"
java -version

# --- 2. Scan exhaustif des fichiers modèles ---
echo "--- Scan des fichiers de configuration (recherche large) ---"
# Recherche de tout fichier contenant "exem" ou "exam" (insensible à la casse)
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        # Exclusion des fichiers compilés ou dossiers de build
        [[ "$f_ex" == *"/.git/"* ]] && continue
        [[ "$f_ex" == *"/build/"* ]] && continue
        [[ "$f_ex" == *"/dist/"* ]] && continue
        [[ "$f_ex" == *.class ]] && continue
        
        clean_name=$(basename "$f_ex")
        dir_name=$(dirname "$f_ex")
        
        # Nettoyage du nom pour créer le fichier final
        # Retire les extensions .exemple/.example et les préfixes/suffixes avec _ ou -
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        f_final_path="$dir_name/$f_final"

        if [ ! -f "$f_final_path" ]; then
            echo "Modèle détecté : $f_ex"
            read -p "Créer et modifier $f_final ? (o/n) : " choix
            if [[ "$choix" =~ ^[oO]$ ]]; then
                cp "$f_ex" "$f_final_path"
                chown "$USERNAME" "$f_final_path"
                echo "Ouverture de l'éditeur pour $f_final..."
                sudo -u "$USERNAME" ${EDITOR:-nano} "$f_final_path" < /dev/tty"
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
    
    read -p "Lancer la compilation (ant jar) ? (o/n) : " build_choice
    if [[ "$build_choice" =~ ^[oO]$ ]]; then
        # Exécution de Ant avec le JAVA_HOME défini
        sudo -u "$USERNAME" JAVA_HOME="$JAVA_HOME" ant jar
        
        if [ $? -eq 0 ]; then
            echo "[OK] Compilation terminée avec succès."
        else
            echo "[ERREUR] La compilation a échoué."
        fi
    fi
else
    echo "Aucun fichier build.xml trouvé. Vérifiez la structure du projet."
fi