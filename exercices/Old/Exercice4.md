1) créer l'utilisateur de votre voisin.
```bash
sudo useradd -d /home/newuser -m newuser
```
2) créer un groupe devops
```bash
groupadd devops
```
3) assigner ce groupe à votre utilisateur et à celui de votre voisin.
```bash 
usermod -aG devops newuser
usermod -aG devops phil
```
4) assigner le groupe devops au dossier "projet" ainsi qu'à tous ses sous fichiers/dossiers.
```bash 
chgrp -R devops projet
```
5) passer les droits du dossier projet à rwxrwx---
```bash
chmod 770 projet
```
6) passer les droits sur le fichier main.sh à rwxr-xr--
```bash
chmod 754 projet/src/main.sh
```