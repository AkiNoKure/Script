#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

echo "--- Vérification des dépendances PHP ---"
sudo apt-get update -qq
sudo apt-get install -y php-cli php-zip unzip curl php-xml php-mbstring

cd "$TARGET_DIR" || exit 1

echo "--- Scan des fichiers de configuration ---"
# Recherche de tout fichier contenant "exem" ou "exam"
FILES=$(find . -type f \( -iname "*exem*" -o -iname "*exam*" \))

if [ -n "$FILES" ]; then
    for f_ex in $FILES; do
        # Exclusion des dossiers techniques
        [[ "$f_ex" == *"/.git/"* ]] || [[ "$f_ex" == *"/vendor/"* ]] && continue
        
        clean_name=$(basename "$f_ex")
        dir_name=$(dirname "$f_ex")
        
        # LOGIQUE DE NETTOYAGE CORRIGÉE
        # On retire .exemple, .example, exemple_, etc.
        f_final=$(echo "$clean_name" | sed -E 's/\.(exemple|example|ex|exemplaire)$//I; s/^(_|-)//; s/(_|-)(exemple|example)//I')
        
        # SECURITÉ : Si le nom final est identique au modèle, on force un nom différent
        if [ "$f_final" == "$clean_name" ]; then
            f_final="${clean_name%.*}" # On coupe juste l'extension
        fi
        
        f_final_path="$dir_name/$f_final"

        echo "Modèle détecté : $f_ex"
        echo "Voulez-vous configurer $f_final ? (o/n)"
        read -r choix < /dev/tty
        
        if [[ "$choix" =~ ^[oO]$ ]]; then
            # On vérifie qu'on ne copie pas le fichier sur lui-même
            if [ "$(realpath "$f_ex")" != "$(realpath "$f_final_path")" ]; then
                cp "$f_ex" "$f_final_path"
                chown "$USERNAME" "$f_final_path"
                
                echo "Ouverture de l'éditeur pour $f_final..."
                # Utilisation de /dev/tty pour nano (résout les problèmes de navigation)
                sudo -u "$USERNAME" nano "$f_final_path" < /dev/tty
                
                # On ne supprime le modèle que si le fichier final a bien été créé
                [ -f "$f_final_path" ] && rm "$f_ex"
            else
                echo "[ERREUR] Le nom cible est identique au modèle. Édition directe du modèle..."
                sudo -u "$USERNAME" nano "$f_ex" < /dev/tty
            fi
        fi
    done
fi

# --- Permissions Finales ---
echo "Réglage des permissions..."
sudo chown -R "$USERNAME":www-data .