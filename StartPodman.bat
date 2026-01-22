@echo off
echo --- DEMARRAGE DE PODMAN ---
podman machine start

echo --- VERIFICATION DES CONTENEURS ---
:: On se déplace dans votre dossier (adaptez le chemin si besoin)
cd "C:\hai-edge-stack"

:: On force le démarrage pour être sûr (grâce au restart: always, cela ne recréera pas tout si c'est déjà là)
podman-compose up -d

echo --- TOUT EST PRET ---
timeout /t 5