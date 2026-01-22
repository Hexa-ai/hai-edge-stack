# hai-edge-stack (Node-RED, PostgreSQL, Grafana) avec Podman sur Windows

Ce projet déploie une stack complète pour l'IoT comprenant :

*   **Node-RED** : Logique et flux de données.
*   **PostgreSQL** : Stockage des données.
*   **PGAdmin** : Interface d'administration pour la base de données.
*   **Grafana** : Visualisation des données.
*   **Tailscale** : Accès distant sécurisé (VPN).

## 1. Prérequis

*   Avoir **Podman Desktop** installé.
*   **IMPORTANT** : La machine virtuelle Podman doit être démarrée. Ouvrez PowerShell et lancez :
    ```powershell
    podman machine start
    ```
*   Avoir l'outil **Podman Compose** (souvent inclus, sinon installable via Python : `pip install podman-compose`).

## 2. Lancement de la Stack

### Option A : Utiliser `podman-compose` (Recommandé)

C'est l'équivalent direct de `docker-compose`.

1.  **Vérification préalable** : Assurez-vous que Podman répond correctement.
    ```powershell
    podman ps
    ```
    Si cela renvoie une erreur, ne passez pas à la suite (voir la section *Troubleshooting*).

2.  **Lancement** : Ouvrez PowerShell dans le dossier du projet et lancez la commande :
    ```powershell
    podman-compose up -d
    ```

### Option B : Utiliser `docker-compose`

Si vous avez déjà `docker-compose.exe`, vous pouvez l'utiliser en redirigeant vers le socket Podman, mais l'option A est souvent plus simple et stable sur Windows.

## 3. Configuration des Services (Premier lancement)

Une fois les conteneurs démarrés, vous devez connecter les outils entre eux.

### A. Connecter PGAdmin à PostgreSQL

1.  Accédez à PGAdmin : http://localhost:5050
    *   **Email** : `admin@postgres.com`
    *   **Mot de passe** : `hai1@`

2.  Cliquez droit sur **Servers > Register > Server...**
3.  Dans l'onglet **General**, nommez le serveur (ex: "IoT Stack").
4.  Dans l'onglet **Connection**, renseignez les informations suivantes :
    *   **Host name/address** : `postgres` (le nom du service dans le fichier compose)
    *   **Port** : `5432`
    *   **Maintenance database** : `postgres`
    *   **Username** : `admin`
    *   **Password** : `hai1@`
5.  Cliquez sur **Save**.

### B. Connecter Grafana à PostgreSQL

### C. Configurer l'accès distant avec Tailscale

Pour rendre les services de cette stack (Node-RED, Grafana, etc.) accessibles à distance de manière sécurisée, vous pouvez utiliser Tailscale. Cela nécessite d'installer le client Tailscale directement sur votre machine Windows.

1.  **Installer Tailscale pour Windows** : Suivez les instructions sur le site officiel de Tailscale.

2.  **Exposer les services sur le réseau Tailscale** : Une fois les conteneurs démarrés, les services sont accessibles sur `localhost`. Pour les exposer sur votre réseau Tailscale, ouvrez PowerShell et lancez les commandes `tailscale serve`. Elles continueront de fonctionner en arrière-plan.

    ```powershell
    # Exposer Node-RED (port 1880)
    tailscale serve --bg --tcp 1880 tcp://localhost:1880
    # Exposer Grafana (port 3000)
    tailscale serve --bg --tcp 3000 tcp://localhost:3000
    # Exposer PGAdmin (port 5050)
    tailscale serve --bg --tcp 5050 tcp://localhost:5050
    ```

Une fois ces commandes exécutées, vous pourrez accéder à vos services depuis n'importe quel appareil de votre Tailnet en utilisant `http://<nom-de-votre-machine-windows>:<port>`.

1.  Accédez à Grafana : http://localhost:3000
    *   **Login** : `admin`
    *   **Password** : `hai1@`

2.  Allez dans **Connections > Data Sources > Add data source**.
3.  Sélectionnez **PostgreSQL**.
4.  Configurez la source de données :
    *   **Host** : `postgres:5432`
    *   **Database** : `postgres`
    *   **User** : `admin`
    *   **Password** : `hai1@`
    *   **TLS/SSL Mode** : `disable`
5.  Cliquez sur **Save & Test**.

## 4. Gestion de la Base de Données

### Sauvegarder (Export / Dump)

Cette commande crée un fichier `.sql` contenant toute votre base de données. À exécuter depuis PowerShell dans le dossier du projet.

```powershell
podman exec -t postgres pg_dumpall -c -U admin > backup_iot.sql
```
*   `postgres` : Nom du conteneur.
*   `-c` : Ajoute les commandes pour nettoyer (DROP) les objets avant de les recréer.
*   `-U admin` : Utilisateur de la base de données.

### Restaurer (Import)

Pour importer un fichier SQL (ex: `backup_iot.sql`) dans la base de données.

*   **Avec PowerShell** :
    ```powershell
    Get-Content backup_iot.sql | podman exec -i postgres psql -U admin -d postgres
    ```

*   **Avec l'Invite de commande (CMD)** :
    ```cmd
    type backup_iot.sql | podman exec -i postgres psql -U admin -d postgres
    ```

## 5. Problèmes Fréquents (Troubleshooting)

### Erreur "Exit status 125" ou "CalledProcessError"
Si `podman-compose` échoue immédiatement, vérifiez les points suivants :
1.  La machine Podman est bien démarrée : `podman machine start`.
2.  La commande de base fonctionne : `podman info`.

### Permissions sur les Volumes (Node-RED / Grafana)
Si vous voyez des erreurs `EACCES: permission denied` dans les logs :
1.  Créez manuellement les dossiers de données dans Windows :
    ```powershell
    mkdir data\node-red
    mkdir data\grafana
    ```
2.  Redémarrez la stack :
    ```powershell
    podman-compose restart
    ```

### Conteneurs qui ne se voient pas (Réseau)
Podman utilise `netavark` pour la gestion réseau. Vérifiez que tous les conteneurs sont bien sur le même réseau :
```powershell
podman network inspect iot-network
```
## 6. Démarrage Automatique de la Stack (Windows)

Pour que votre stack Podman et vos services démarrent automatiquement à l'ouverture de votre session Windows, vous pouvez créer un simple script et le placer dans le dossier de démarrage.

### Étape 1 : Vérifier le script de démarrage

Le script `StartPodman.bat` est déjà inclus dans ce dépôt. Il lance la machine virtuelle Podman et démarre les conteneurs.

**Action requise :** Vous devez simplement vous assurer que le chemin à l'intérieur du script correspond à l'emplacement de votre projet sur votre ordinateur.

1.  Faites un clic-droit sur le fichier `StartPodman.bat` et sélectionnez **Modifier**.
2.  Vérifiez la ligne `cd "C:\hai-edge-stack"`.
3.  Si vous avez cloné le projet dans un autre dossier, modifiez ce chemin en conséquence.
4.  Enregistrez et fermez le fichier.

### Étape 2 : Placer un raccourci dans le dossier "Démarrage"

Pour que Windows exécute ce script à chaque connexion :

1.  Appuyez sur les touches `Windows + R` pour ouvrir la fenêtre "Exécuter".
2.  Tapez `shell:startup` et cliquez sur **OK**. Le dossier "Démarrage" de votre session s'ouvrira.
3.  Dans une autre fenêtre, naviguez jusqu'au dossier de votre projet (où se trouve `StartPodman.bat`).
4.  Faites un clic-droit sur `StartPodman.bat` et sélectionnez **Copier**.
5.  Retournez dans le dossier "Démarrage", faites un clic-droit dans un espace vide et sélectionnez **Coller le raccourci**.

C'est tout ! La prochaine fois que vous démarrerez Windows, vos services se lanceront automatiquement en arrière-plan.