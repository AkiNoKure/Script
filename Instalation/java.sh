#!/bin/bash
set -eo pipefail

TARGET_DIR=$1
USERNAME=$2

# On se déplace dans le sous-dossier du projet si nécessaire
# (Le repo GitHub a un dossier PJ_internet_subscription à l'intérieur)
if [ -d "$TARGET_DIR/PJ_internet_subscription" ]; then
    cd "$TARGET_DIR/PJ_internet_subscription"
else
    cd "$TARGET_DIR"
fi

echo "Configuration de l'environnement Java (NetBeans Project)..."

# 1. Vérification de Java
command -v java &> /dev/null || { echo "[ERREUR] Java non trouvé"; exit 1; }

# 2. Tentative de compilation si un dossier src existe
if [ -d "src" ]; then
    echo "Compilation manuelle des sources..."
    mkdir -p build
    # On trouve tous les fichiers .java et on les compile vers le dossier build
    find src -name "*.java" > sources.txt
    javac -d build @sources.txt
    
    echo "Création du fichier JAR..."
    jar cfe target/app.jar Main -C build . 
    # Note : "Main" doit être remplacé par le nom de ta classe principale (ex: pj_internet_subscription.Main)
fi

# 3. Vérification du JAR
JAR_FILE=$(find . -name "*.jar" | head -n 1)

if [ -n "$JAR_FILE" ]; then
    echo "[OK] Fichier executable trouvé : $JAR_FILE"
    # On déplace le JAR à la racine pour start_jukebox.sh
    cp "$JAR_FILE" "$TARGET_DIR/app.jar"
else
    echo "[ERREUR] Aucun JAR trouvé et la compilation manuelle a échoué."
    exit 1
fi