# Projet Jukebox - Campus La Futaie

## 1. Contexte du projet
Ce projet a été réalisé dans le cadre d'un concours interne au Campus La Futaie. L'objectif est de concevoir un Jukebox fonctionnel intégrant des composants matériels et une infrastructure logicielle automatisée.

L'équipe assure :
* La mise en place du matériel (boutons, affichage, son).
* Le développement de scripts de déploiement et de gestion de base de données.
* La documentation technique pour la maintenance.

## 2. Architecture des scripts
Le système repose sur une structure modulaire pour le déploiement et la gestion des données.

### Structure du répertoire
* **deploy.sh** : Script principal de gestion du déploiement (interactif ou automatique).
* **bdd.sh** : Script de gestion de la base de données (exportation, importation et configuration).
* **Instalation/** : Dossier contenant les modules de configuration spécifiques :
    * **java.sh** : Déploiement d'applications Java/Maven.
    * **php.sh** : Déploiement d'applications PHP/Composer.

## 3. Fonctionnement
### Déploiement (deploy.sh)
Le script s'adapte à l'environnement :
* **Mode Interactif** : Questions posées à l'utilisateur si les variables sont absentes.
* **Mode Automatique** : Utilisation des variables d'environnement (ex: `USERNAME=user REPO_URL=http://... APP_TYPE=1 ./deploy.sh`).

### Base de données (bdd.sh)
Ce script permet d'automatiser les interactions avec le serveur de base de données, notamment pour la sauvegarde et la restauration des schémas nécessaires au Jukebox.

## 4. Détails des modules d'installation
### Module PHP (php.sh)
* Vérification de PHP et Composer.
* Installation des dépendances.
* Gestion du fichier `.env` et des permissions (stockage/cache).

### Module Java (java.sh)
* Vérification de Java et Maven.
* Compilation et génération du fichier JAR (optimisée sans tests).
* Exécution en arrière-plan avec journalisation dans `app.log`.

## 5. Prérequis techniques
* Système Linux (Debian/Ubuntu recommandé).
* Droits **sudo** configurés pour l'utilisateur.
* **Git** et **MariaDB/MySQL** installés.

---
*Documentation mise à jour - Campus La Futaie - 2026*
