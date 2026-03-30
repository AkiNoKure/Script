# Projet Jukebox - Campus La Futaie

## 1. Contexte du projet
Ce projet a été réalisé dans le cadre d'un concours interne au Campus La Futaie. L'objectif est de concevoir un Jukebox fonctionnel et efficace, intégrant à la fois des composants matériels et une infrastructure logicielle robuste.

L'équipe se charge de l'intégralité de la chaîne de valeur :
* Mise en place du matériel (boutons physiques, système d'affichage et diffusion sonore).
* Développement des scripts de déploiement automatisés pour assurer la portabilité de la solution.
* Documentation technique pour la maintenance et les futures itérations.

## 2. Architecture des scripts
Le système de déploiement est conçu pour être hybride : il peut être exécuté manuellement par un administrateur via un terminal ou déclenché automatiquement par une interface web.

### Structure du répertoire
* **deploy.sh** : Script principal de gestion. Il centralise la collecte des informations (utilisateur, URL du dépôt, type d'application).
* **Instalation/** : Dossier contenant les modules de configuration spécifiques :
    * **java.sh** : Script dédié aux applications Java/Maven.
    * **php.sh** : Script dédié aux applications PHP/Composer.

## 3. Fonctionnement du déploiement
Les scripts utilisent un mécanisme de détection de variables pour s'adapter à l'environnement d'exécution.

### Mode Interactif (Terminal)
Si les variables nécessaires ne sont pas définies au lancement, le script `deploy.sh` pose des questions à l'utilisateur pour configurer le déploiement.

### Mode Automatique (Web / Script)
Pour un déploiement sans intervention humaine, les variables doivent être passées en amont de l'exécution.
Exemple de commande :
`USERNAME=user REPO_URL=http://... TARGET_DIR=/path APP_TYPE=1 ./deploy.sh`

## 4. Détails des modules d'installation

### Module PHP (`php.sh`)
* Vérification de la présence de PHP et Composer.
* Installation des dépendances via Composer avec optimisation de l'autoloader.
* Création automatique du fichier .env si un fichier .env.example est présent.
* Configuration des permissions sur les répertoires de stockage et de cache.

### Module Java (`java.sh`)
* Vérification de la présence de Java et Maven.
* Compilation du projet et génération du fichier JAR en ignorant les tests pour accélérer le déploiement.
* Identification automatique du fichier JAR généré.
* Lancement de l'application en arrière-plan avec redirection des flux vers un fichier app.log.

## 5. Prérequis techniques
* Système d'exploitation basé sur Linux (Debian/Ubuntu recommandé).
* Droits sudo configurés pour l'utilisateur exécutant les scripts afin de permettre le changement d'identité utilisateur (`sudo -u`).
* Git installé sur la machine cible.

---
*Documentation générée pour le concours interne - Campus La Futaie - 2026*
