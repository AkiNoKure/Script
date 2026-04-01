# Projet Jukebox - Campus La Futaie

## 1. Contexte du projet
Ce projet a été réalisé dans le cadre d'un concours interne au Campus La Futaie. L'objectif est de concevoir un Jukebox fonctionnel intégrant des composants matériels et une infrastructure logicielle automatisée.

L'équipe assure :
* La mise en place du matériel (boutons, affichage, son).
* Le développement de scripts de déploiement et de gestion de base de données.
* La documentation technique pour la maintenance.

## 2. Installation initiale du projet
Pour installer l'environnement de scripts sur une nouvelle machine cible, clonez le dépôt principal :

git clone [https://github.com/AkiNoKure/Script.git](https://github.com/AkiNoKure/Script.git)
cd Script
chmod +x *.sh Instalation/*.sh

## 3. Architecture des scripts
Le système repose sur une structure modulaire :
* deploy.sh : Script principal de gestion du déploiement.
* bdd.sh : Script de gestion de la base de données (import/export).
* Instalation/ : Dossier contenant les modules de configuration :
    * java.sh : Déploiement d'applications Java/Maven.
    * php.sh : Déploiement d'applications PHP/Composer.

## 4. Utilisation des scripts

### Déploiement (deploy.sh)
Le script deploy.sh permet de cloner un dépôt applicatif tiers et de l'installer.

Mode Interactif :
./deploy.sh

Mode Automatique :
USERNAME=user REPO_URL=[https://github.com/url](https://github.com/url) TARGET_DIR=/var/www/jukebox APP_TYPE=1 ./deploy.sh

Note : APP_TYPE=1 pour PHP, APP_TYPE=2 pour Java.

### Gestion de la base de données (bdd.sh)
Exporter la base :
./bdd.sh export nom_base

Importer une base :
./bdd.sh import nom_base fichier.sql

## 5. Maintenance et persistance
Par défaut, le processus s'arrête à la fermeture du terminal. Pour maintenir l'application active en arrière-plan, utilisez nohup ou screen.

Exemple avec nohup :
nohup ./deploy.sh > deploy.log 2>&1 &

## 6. Procédure complète de déploiement
1. Récupération des scripts : Cloner le dépôt Script (voir section 2).
2. Préparation : S'assurer que la machine possède Git et les accès sudo.
3. Exécution du déploiement : Lancer deploy.sh.
4. Configuration BDD : Utiliser bdd.sh pour importer le schéma SQL.

## 7. Prérequis techniques
* Système Linux (Debian/Ubuntu recommandé).
* Droits sudo configurés pour l'utilisateur.
* Git installés.

---
Documentation mise à jour - Campus La Futaie - 2026
