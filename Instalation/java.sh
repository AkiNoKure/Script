#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

# --- 1. Installation des dépendances ---
echo "--- Vérification des dépendances ---"
sudo apt-get update -qq
sudo apt-get install -y default-jdk ant

cd "$TARGET_DIR" || exit 1

export JAVA_HOME=$(readlink -f $(which java) | sed "s:/bin/java::")
JAVA_VER=$(javac -version 2>&1 | awk '{print $2}' | cut -d'.' -f1)
echo "Environnement : JAVA_HOME=$JAVA_HOME (Version $JAVA_VER)"

# --- 2. Harmonisation de la version Java (Fix Release 24) ---
echo "--- Patch de la version Java du projet (Cible: $JAVA_VER) ---"
find . -name "project.properties" -exec sed -i "s/javac.source=.*/javac.source=$JAVA_VER/g" {} +
find . -name "project.properties" -exec sed -i "s/javac.target=.*/javac.target=$JAVA_VER/g" {} +

# --- 3. Scan et Correction des fichiers modèles ---
echo "--- Scan des fichiers de configuration ---"
# Recherche de tout fichier contenant "exem" ou "exam"
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        # Exclusion des dossiers techniques
        [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/build/"* ]] || [[ "$f_ex" == *"/dist/"* ]] || [[ "$f_ex" == *.class ]] && continue
        
        clean_name=$(basename "$f_ex")
        dir_name=$(dirname "$f_ex")
        
        # Détermination du nom final (ex: Cl_Connexion.java)
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        f_final_path="$dir_name/$f_final"

        echo "Modèle détecté : $f_ex"
        echo "Voulez-vous configurer $f_final à partir de ce modèle ? (o/n)"
        read -r choix < /dev/tty
        
        if [[ "$choix" =~ ^[oO]$ ]]; then
            # Copie vers le fichier final
            cp "$f_ex" "$f_final_path"
            
            # Correction du nom de la classe à l'intérieur du fichier pour éviter les erreurs de compilation
            base_class_name=$(echo "$f_final" | sed 's/\.java//')
            sed -i "s/${base_class_name}_exemple/${base_class_name}/g" "$f_final_path"
            sed -i "s/${base_class_name}_example/${base_class_name}/g" "$f_final_path"
            
            chown "$USERNAME" "$f_final_path"
            
            # Ouverture de l'éditeur pour saisie des identifiants
            echo "Ouverture de nano pour configuration..."
            sudo -u "$USERNAME" nano "$f_final_path" < /dev/tty
            
            # Suppression du fichier exemple après modification réussie
            echo "Suppression du modèle : $f_ex"
            rm "$f_ex"
        fi
    done
else
    echo "Aucun fichier modèle détecté."
fi

# --- 4. Compilation Ant ---
ANT_PATH=$(find . -name "build.xml" | head -n 1)
if [ -n "$ANT_PATH" ]; then
    cd "$(dirname "$ANT_PATH")"
    echo "Lancer la compilation (ant jar) ? (o/n)"
    read -r build_choice < /dev/tty
    if [[ "$build_choice" =~ ^[oO]$ ]]; then
        sudo -u "$USERNAME" JAVA_HOME="$JAVA_HOME" ant clean
        sudo -u "$USERNAME" JAVA_HOME="$JAVA_HOME" ant jar
    fi
fi