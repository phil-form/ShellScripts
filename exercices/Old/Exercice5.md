## Exercice 1 : Recherche

Trouver toutes les lignes contenant "ERROR" dans /var/log/syslog.
```shell
grep -R -m "ERROR" /var/log/syslog
```
Rechercher tous les fichiers .conf modifiés depuis moins de 24h.
```shell
find / -mtime -1 -name "*.conf"
```

## Exercice 2 : Espace disque

Lister les dossiers les plus lourds dans /home.
```shell
sudo du -h --max-depth=1 /home
```
Afficher l’espace disque disponible sur /dev/sda1.
```shell
df -h /dev/sda1
```

## Exercice 3 : Archivage

Créer un archive compressée du dossier /etc.
```shell
sudo tar -czvf etc.tar.gz /etc
```
Extraire une archive .tar.gz dans /tmp/test.
```shell
mkdir /tmp/test/
sudo tar -xzvf etc.tar.gz -C /tmp/test
```