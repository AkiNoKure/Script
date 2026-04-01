## Documentation Technique - Projet Jukebox (2026)

Cette documentation détaille l'infrastructure logicielle, les scripts de déploiement et la configuration système du projet Jukebox pour le Campus La Futaie.

---

## 1. Architecture du Système

Le projet repose sur une architecture modulaire permettant le déploiement d'applications **PHP** ou **Java**.

### Composants principaux
* **Gestionnaire de déploiement (`deploy.sh`)** : Pilote l'installation des dépendances, la création des utilisateurs et la récupération des sources.
* **Modules technologiques (`Instalation/`)** : Scripts spécifiques pour la configuration PHP (Composer/Kiosque) et Java (Maven/Ant).
* **Gestionnaire de données (`bdd.sh`)** : Automatise l'importation et la configuration des bases de données MariaDB ou SQLite.
* [cite_start]**Persistance (`jukebox.service`)** : Service Systemd assurant l'exécution continue de l'application. [cite: 1]

---

## 2. Infrastructure et Prérequis

### Dépendances Logicielles
Le script d'installation automatise l'ajout des paquets suivants :
* **Serveur Web & Langages** : Apache2, PHP (8.x+), OpenJDK 21.
* **Bases de données** : MariaDB Server, SQLite3, phpMyAdmin.
* **Utilitaires** : VLC, Chromium, wtype (pour le mode kiosque), Git.

### Comptes Utilisateurs
| Utilisateur | Rôle | Droits |
| :--- | :--- | :--- |
| `technicien_BTC` | Maintenance système | Sudoer (via SSH) |
| `jukebox_play` | Exécution de l'application | Accès restreint, membre de `www-data` |
| `administrateur` | Gestion globale | Accès SSH autorisé |

---

## 3. Procédures de Déploiement

### Mode Interactif
```bash
./deploy.sh
```
Le script guide l'utilisateur à travers :
1. La mise à jour des dépendances.
2. Le choix de la source (Dépôt Git ou Archive locale).
3. La sélection de la technologie (Java ou PHP).
4. La configuration des fichiers `.exemple`.

### Mode Automatique (Variables d'environnement)
Il est possible de court-circuiter l'interactivité pour l'automatisation :
```bash
USERNAME=user REPO_URL=[URL] TARGET_DIR=[PATH] APP_TYPE=[1|2] ./deploy.sh
```

---

## 4. Automatisation et Persistance

### Service Systemd (`jukebox.service`)
[cite_start]L'application est gérée comme un service système pour garantir son redémarrage en cas d'échec. [cite: 1]
* **Fichier** : `/etc/systemd/system/jukebox.service`
* **Commande de démarrage** : `systemctl start jukebox.service`
* [cite_start]**Redémarrage** : Automatique après 5 secondes en cas de crash. [cite: 1]

### Mode Kiosque (Spécifique PHP)
Pour les interfaces Web, un environnement Kiosque est configuré via `labwc` :
* Lancement automatique de Chromium en mode plein écran.
* Script `switchtab.sh` pour la permutation automatique des onglets toutes les 10 secondes via `wtype`.

---

## 5. Gestion des Données (`bdd.sh`)

Le script détecte automatiquement le moteur de base de données présent dans les sources :

* **MariaDB** :
    * Création de la base `jukebox_db`.
    * Création de l'utilisateur avec privilèges.
    * Importation du premier fichier `.sql` trouvé.
* **SQLite** :
    * Initialisation du fichier `jukebox.sqlite`.
    * Attribution des permissions au groupe `www-data`.

---

## 6. Maintenance et Sécurité

* **Sauvegarde** : Chaque nouveau déploiement génère une sauvegarde dans `${TARGET_DIR}_backup` incluant un dump SQL.
* **Sécurité SSH** : L'accès SSH est restreint aux utilisateurs `administrateur` et `technicien_BTC` via la directive `AllowUsers`.
* **Logs** : Les flux de sortie de l'application sont redirigés vers `/tmp/jukebox_start.log`.