# hai-stack (Node-RED, PostgreSQL, Grafana) avec Podman sur Windows

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

### Tailscale ne démarre pas
Vérifiez que la variable `TS_USERSPACE=true` est bien présente dans le `docker-compose.yml`. Le mode kernel n'est pas supporté facilement sur Podman pour Windows.