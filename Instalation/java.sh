#!/bin/bash
set -eo pipefail

TARGET_DIR=${1:-$TARGET_DIR}
USERNAME=${2:-$USERNAME}

echo "--- Configuration Java : $TARGET_DIR ---"

# Vérification des outils de build
command -v java &> /dev/null || { echo "[ERREUR] Java non trouvé"; exit 1; }
command -v mvn &> /dev/null || { echo "[ERREUR] Maven non trouvé"; exit 1; }

cd "$TARGET_DIR" || exit 1

echo "Compilation de l'application..."
sudo -u "$USERNAME" mvn clean package -DskipTests

# Recherche du JAR
JAR_FILE=$(find target -name "*.jar" | head -n 1)

if [ -n "$JAR_FILE" ]; then
    # --- Gestion du redémarrage automatique ---
    # On tue l'ancienne version si elle tourne encore sur ce port/projet
    echo "Arrêt de l'ancienne instance si nécessaire..."
    pkill -f "$JAR_FILE" || true 

    echo "Lancement de $JAR_FILE..."
    # Utilisation de disown pour détacher proprement le processus du shell
    sudo -u "$USERNAME" nohup java -jar "$JAR_FILE" > app.log 2>&1 &
    
    echo "[OK] Application lancée en arrière-plan."
    echo "Logs disponibles ici : $TARGET_DIR/app.log"
else
    echo "[ERREUR] Aucun fichier JAR trouvé dans le dossier target."
    exit 1
fi