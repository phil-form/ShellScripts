## Lister une arborescence

### tree

```bash
tree
```
```
.
├── 01_base.md
├── 02.1_user_management.md
├── 02_file_permissions.md
├── 03_commandes_essentielles.md
├── 04_installation_et_services.md
├── 05_securite.md
├── 06_shellscript
|         ├── 01_Base
|         ├── 02_operateur_logique
|         ├── 03_boucles
|         ├── 04_gestion_des_erreurs
|         └── 05_fonctions
├── 07_tmux.md
├── 08_bash_config.md
├── 09_advanced_config.md
├── exemple
|         ├── errors.txt
|         ├── exemple.txt
|         ├── exemple2.txt
|         ├── exercice.txt
|         ├── exerciceEditeur.txt
|         ├── fichier.txt
|         ├── out.txt
|         └── test.js
├── exercices
|         ├── Exercice3.md
|         └── Exercice4.md
└── readme.md
```

## Extraire des informations d'une sortie/d'un fichier

### grep

```bash
grep "sudo" 02.1_user_management.md
```
```shell
sudo commande
sudo -u username commande
sudo su
```

Récupérer le numéro des lignes
```bash
grep -n "sudo" 02.1_user_management.md
```
```shell
114:sudo commande
122:sudo -u username commande
136:sudo su
```

Faire une recherche récursive d'un mots clé :
```bash
grep -R "sudo" ../ShellScripts
```
```shell
../ShellScripts/exercices/Exercice4.md:sudo useradd -d /home/newuser -m newuser
../ShellScripts/02.1_user_management.md:sudo commande
../ShellScripts/02.1_user_management.md:sudo -u username commande
../ShellScripts/02.1_user_management.md:sudo su
../ShellScripts/03_commandes_essentielles.md:grep "sudo" 02.1_user_management.md
../ShellScripts/03_commandes_essentielles.md:sudo commande
../ShellScripts/03_commandes_essentielles.md:sudo -u username commande
../ShellScripts/03_commandes_essentielles.md:sudo su
../ShellScripts/03_commandes_essentielles.md:grep -n "sudo" 02.1_user_management.md
../ShellScripts/03_commandes_essentielles.md:114:sudo commande
../ShellScripts/03_commandes_essentielles.md:122:sudo -u username commande
../ShellScripts/03_commandes_essentielles.md:136:sudo su
```

Je peux raccourcir le ../ShellScript en .

Préciser d'être insensible à la casse
```bash
grep -i "user" 02.1_user_management.md
```

Filtrer la sortie d'une autre commande :
```bash
ps aux | grep apache
```

## Trouver des fichiers/dossiers

### Find 

rechercher un/des fichier(s) par nom :
```bash
find / -name "passwd" 2> /dev/null
```

Trouver tous les fichiers qui ont moins de deux jours :
```shell
find dossier -mtime -2
```

Trouver par taille (ici je cherche les fichiers de plus de 10MiB)
```bash
find /var/logs -type f -size +10M 
```

Faire des actions sur les fichiers trouvé
```bash
# Delete les fichiers dans /tmp qui finissent par .tmp
find /tmp -type f -name "*.tmp" -delete
```

```bash
# Faire une liste des détails des fichiers trouvé
# exec => j'execute une commande
# ls -lh => la commande exécutée
# {} => l'élément trouvé
# \; => finir l'instruction
find . -type f -name "*.md" -exec ls -lh {} \;
```
sortie : 
```shell
-rw-r--r-- 1 rmdir  staff     0B Dec 10 15:32 ./07_tmux.md
-rw-r--r-- 1 rmdir  staff   593B Dec 11 13:09 ./exercices/Exercice4.md
-rw-r--r-- 1 rmdir  staff   1.1K Dec 10 15:47 ./exercices/Exercice3.md
-rw-r--r-- 1 rmdir  staff    81B Dec 11 11:42 ./05_securite.md
-rw-r--r-- 1 rmdir  staff     0B Dec 10 15:33 ./09_advanced_config.md
-rw-r--r-- 1 rmdir  staff   3.6K Dec 10 14:35 ./01_base.md
-rw-r--r-- 1 rmdir  staff   2.7K Dec 11 09:53 ./02_file_permissions.md
-rw-r--r-- 1 rmdir  staff    86B Dec 11 11:40 ./04_installation_et_services.md
-rw-r--r-- 1 rmdir  staff    12B Dec 10 10:39 ./readme.md
-rw-r--r-- 1 rmdir  staff   2.3K Dec 11 11:24 ./02.1_user_management.md
-rw-r--r-- 1 rmdir  staff     0B Dec 10 15:32 ./08_bash_config.md
-rw-r--r-- 1 rmdir  staff   2.8K Dec 11 13:28 ./03_commandes_essentielles.md
```

## Analyse de l'espace disque

### du

Cette commande permet d'analyser l'espace disque utilisé par les dossiers/fichiers.
```bash
du -h --max-depth=1 /var
```
sortie: 
```shell
4.0K	/var/spool
40K	/var/tmp
1.2M	/var/backups
82M	/var/cache
4.0K	/var/local
5.5G	/var/log
4.0K	/var/mail
20K	/var/www
4.0K	/var/opt
153M	/var/lib
5.7G	/var
```

```bash
du -h --max-depth=1 /var/log
```
sortie:
```shell
252K	/var/log/apt
4.1G	/var/log/journal
29M	/var/log/apache2
8.0K	/var/log/runit
4.0K	/var/log/private
792K	/var/log/unattended-upgrades
5.5G	/var/log
```

### Trouver le poids total de fichiers avec find

```shell
find /var/backups -name "*.backup" -exec du -ch {} + | grep total
```

### df 

Analyser l'espace restant sur les partitions
```shell
df -h
```
sortie :
```shell
Filesystem      Size  Used Avail Use% Mounted on
udev            1.9G     0  1.9G   0% /dev
tmpfs           384M  500K  383M   1% /run
/dev/sda1        79G  6.6G   69G   9% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda15      124M   12M  113M  10% /boot/efi
tmpfs           384M     0  384M   0% /run/user/1000
```

## Archivage

### tar

Ici j'archive un dossier avec tar dans un une archive .tar.
```shell
tar -cvf backup.tar /dossiers
```
```txt
c => crée
v => verbose (sortie plus détaillées)
f => dire dans quel fichier enregistrer l'archive
```

Compresser et archiver un dossier

```shell
tar -czvf backup.tar.gz /dossier
```
```txt
c => crée
z => compresser avec gunzip
v => verbose (sortie plus détaillées)
f => dire dans quel fichier enregistrer l'archive
```

ou 
```shell
tar -cvf backup.tar /dossier
gzip backup.tar
```
va produire backup.tar.gz

Extraire une archive
```shell
tar -xvf backup.tar
```

Extraire une archive compressée
```shell
tar -xzvf backup.tar.gz
```

Extraire dans un dossier cible :
```shell
tar -xzvf backup.tar.gz -C /dossier_cible
```

Créer une tarball avec find : 
```shell
find . -type f -name "*.md" -print0 | tar --null -czvf mdbackups.tar.gz --file-from=-  
```
```txt
find : 
-type f => chercher un fichier
-name "*.md" => dont le nom fini par .md
-print0 => séparé chaque fichier trouvé par find par un \0

tar :
--null => préciser la séparation par des \0 (sortie de la commande précédente)
-czvf mdbackups.tar.gz => créer une archive compressée des fichiers trouvé avec find
--file-from=- => précise que les fichiers proviennent la l'entrée standard (-), donc
                 de la sortie de la commande find 
```