#!/bin/bash
TARGET_DIR=$1
USERNAME=$2

cd "$TARGET_DIR" || exit 1

echo "-------------------------------------------------------"
echo "Verification de la configuration locale..."

mapfile -t FICHIERS_EXEMPLE < <(find . -name "*.exemple")

if [ ${#FICHIERS_EXEMPLE[@]} -eq 0 ]; then
    echo "Aucun fichier modele (.exemple) detecte."
else
    for f_ex in "${FICHIERS_EXEMPLE[@]}"; do
        f_final="${f_ex%.exemple}"
        if [ ! -f "$f_final" ]; then
            cp "$f_ex" "$f_final"
            chown "$USERNAME" "$f_final"
            echo "Fichier cree : $f_final (Editez-le manuellement si besoin)"
        fi
    done
fi

echo "Lancement de la compilation..."
# Remplacez par votre commande réelle (ex: mvn package ou ant)
if [ -f "./mvnw" ]; then
    sudo -u "$USERNAME" ./mvnw clean package -DskipTests
elif [ -f "pom.xml" ]; then
    sudo -u "$USERNAME" mvn clean package -DskipTests
else
    echo "Aucun outil de build (Maven) détecté."
fi