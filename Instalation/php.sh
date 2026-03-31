#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

# --- 1. Installation des dépendances ---
install_deps() {
    echo "--- Vérification des dépendances PHP ---"
    sudo apt-get update -qq
    # Installation de PHP, des extensions communes et de Composer
    sudo apt-get install -y php-cli php-zip unzip curl php-xml php-mbstring
    
    if ! command -v composer &> /dev/null; then
        echo "[INFO] Installation de Composer..."
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
        sudo chmod +x /usr/local/bin/composer
    fi
}

if [ ! -d "$TARGET_DIR" ]; then
    echo "[ERREUR] Le répertoire $TARGET_DIR n'existe pas."
    exit 1
fi

install_deps
cd "$TARGET_DIR" || exit 1

# --- 2. Scan et Correction des fichiers modèles ---
echo "--- Scan des fichiers de configuration (recherche large) ---"
# Recherche de tout fichier contenant "exem" ou "exam"
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        # Exclusion des dossiers techniques et dossiers de dépendances
        [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/vendor/"* ]] || [[ "$f_ex" == *"/node_modules/"* ]] && continue
        
        clean_name=$(basename "$f_ex")
        dir_name=$(dirname "$f_ex")
        
        # Détermination du nom final (ex: .env)
        # Retire les extensions .exemple/.example et les préfixes/suffixes avec _ ou -
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        f_final_path="$dir_name/$f_final"

        echo "Modèle détecté : $f_ex"
        echo "Voulez-vous configurer $f_final à partir de ce modèle ? (o/n)"
        read -r choix < /dev/tty
        
        if [[ "$choix" =~ ^[oO]$ ]]; then
            # Copie vers le fichier final
            cp "$f_ex" "$f_final_path"
            chown "$USERNAME" "$f_final_path"
            
            # Ouverture de l'éditeur pour configuration (ex: remplir la DB dans le .env)
            echo "Ouverture de nano pour configuration..."
            sudo -u "$USERNAME" nano "$f_final_path" < /dev/tty
            
            # Suppression du fichier exemple après modification (comme demandé)
            echo "Suppression du modèle : $f_ex"
            rm "$f_ex"
        fi
    done
else
    echo "Aucun fichier modèle détecté."
fi

# --- 3. Installation Composer ---
if [ -f "composer.json" ]; then
    echo "--- Installation des dépendances Composer ---"
    sudo -u "$USERNAME" composer install --no-dev --optimize-autoloader --no-interaction
    
    # Finalisation des permissions pour les frameworks type Laravel/Symfony
    echo "Réglage des permissions (storage/cache)..."
    sudo chown -R "$USERNAME":www-data .
    [ -d "storage" ] && chmod -R 775 storage
    [ -d "bootstrap/cache" ] && chmod -R 775 bootstrap/cache
else
    echo "Aucun fichier composer.json trouvé."
fi

echo "[OK] Déploiement PHP terminé."