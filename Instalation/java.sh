#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

echo "--- Dépendances Java ---"
sudo apt-get update -qq
sudo apt-get install -y default-jdk ant

cd "$TARGET_DIR" || exit 1

bash "$(dirname "$0")/bdd.sh" "$TARGET_DIR" "$USERNAME" "java"

export JAVA_HOME=$(readlink -f $(which java) | sed "s:/bin/java::")
JAVA_VER=$(javac -version 2>&1 | awk '{print $2}' | cut -d'.' -f1)

# Mise à jour des versions de compilation dans project.properties
find . -name "project.properties" -exec sed -i "s/javac.source=.*/javac.source=$JAVA_VER/g" {} +
find . -name "project.properties" -exec sed -i "s/javac.target=.*/javac.target=$JAVA_VER/g" {} +

echo "--- Scan des modèles ---"
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/build/"* ]] || [[ "$f_ex" == *"/dist/"* ]] && continue
        
        clean_name=$(basename "$f_ex")
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        f_final_path="$(dirname "$f_ex")/$f_final"

        echo "Modèle détecté : $f_ex"
        echo "Configurer $f_final ? (o/n)"
        read -r choix < /dev/tty
        
        if [[ "$choix" =~ ^[oO]$ ]]; then
            # Backup si le fichier existe déjà
            [ -f "$f_final_path" ] && cp "$f_final_path" "${f_final_path}.bak"
            
            cp "$f_ex" "$f_final_path"
            base_class_name=$(echo "$f_final" | sed 's/\.java//')
            sed -i "s/${base_class_name}_exemple/${base_class_name}/g" "$f_final_path"
            sed -i "s/${base_class_name}_example/${base_class_name}/g" "$f_final_path"
            chown "$USERNAME" "$f_final_path"
            
            # Correction affichage nano
            sudo -u "$USERNAME" nano "$f_final_path" < /dev/tty > /dev/tty
            rm "$f_ex"
        fi
    done
fi

ANT_PATH=$(find . -name "build.xml" | head -n 1)
if [ -n "$ANT_PATH" ]; then
    cd "$(dirname "$ANT_PATH")"
    echo "Lancer compilation (ant jar) ? (o/n)"
    read -r build_choice < /dev/tty
    if [[ "$build_choice" =~ ^[oO]$ ]]; then
        sudo -u "$USERNAME" JAVA_HOME="$JAVA_HOME" ant clean
        sudo -u "$USERNAME" JAVA_HOME="$JAVA_HOME" ant jar
    fi
fi