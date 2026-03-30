#!/bin/bash
set -eo pipefail
# ...existing code...

TARGET_DIR=${1:-$TARGET_DIR}
USERNAME=${2:-$USERNAME}

echo "--- Configuration Java : $TARGET_DIR ---"

install_if_missing() {
  local cmd=$1 pkg=$2
  if command -v "$cmd" &> /dev/null; then
    return 0
  fi
  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y "$pkg"
  else
    echo "[ERREUR] $cmd absent et apt-get non disponible. Installez $pkg manuellement."
    exit 1
  fi
}

install_if_missing java default-jdk
install_if_missing mvn maven

cd "$TARGET_DIR" || exit 1

echo "Compilation de l'application..."
sudo -u "$USERNAME" mvn clean package -DskipTests

JAR_FILE=$(find target -name "*.jar" | head -n 1)

if [ -n "$JAR_FILE" ]; then
    echo "Arrêt de l'ancienne instance si nécessaire..."
    pkill -f "$JAR_FILE" || true 

    echo "Lancement de $JAR_FILE..."
    sudo -u "$USERNAME" nohup java -jar "$JAR_FILE" > app.log 2>&1 &
    
    echo "[OK] Application lancée en arrière-plan."
    echo "Logs disponibles ici : $TARGET_DIR/app.log"
else
    echo "[ERREUR] Aucun fichier JAR trouvé dans le dossier target."
    exit 1
fi