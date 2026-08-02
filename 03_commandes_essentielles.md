# 03 · Commandes essentielles de l'administrateur

> [!NOTE]
> **Objectifs du chapitre**
> - Visualiser une arborescence avec `tree`
> - Chercher du texte dans des fichiers avec `grep`
> - Retrouver des fichiers selon leur nom, leur date ou leur taille avec `find`
> - Analyser l'occupation disque avec `du` et `df`
> - Créer et extraire des archives avec `tar`

## Sommaire

1. [Lister une arborescence — `tree`](#lister-une-arborescence--tree)
2. [Extraire des informations — `grep`](#extraire-des-informations--grep)
3. [Trouver des fichiers — `find`](#trouver-des-fichiers--find)
4. [Analyse de l'espace disque — `du` et `df`](#analyse-de-lespace-disque--du-et-df)
5. [Archivage — `tar`](#archivage--tar)
6. [Récapitulatif](#récapitulatif)

---

## Lister une arborescence — `tree`

```bash
tree
```

```text
.
├── 01_base.md
├── 02.1_user_management.md
├── 02_file_permissions.md
├── 03_commandes_essentielles.md
├── 04_installation_et_services.md
├── 05_securite.md
├── 06_shellscript
│   ├── 01_Base
│   ├── 02_operateur_logique
│   ├── 03_boucles
│   ├── 04_gestion_des_erreurs
│   ├── 05_Arguments
│   └── 06_fonctions
├── 07_docker.md
├── 08_docker_administration.md
├── 09_tmux.md
├── 10_shell_config.md
├── 11_advanced_config.md
├── exemple
│   ├── errors.txt
│   ├── exemple.txt
│   ├── exemple2.txt
│   ├── exercice.txt
│   ├── exerciceEditeur.txt
│   ├── fichier.txt
│   ├── out.txt
│   └── test.js
├── exercices
│   ├── Exercice3.md
│   └── Exercice4.md
└── README.md
```

Options utiles :

| Option | Effet |
|--------|-------|
| `tree -L 2` | Limiter la profondeur à 2 niveaux |
| `tree -d`   | N'afficher que les dossiers |
| `tree -a`   | Inclure les fichiers cachés |
| `tree -h`   | Afficher la taille des fichiers |

---

## Extraire des informations — `grep`

`grep` cherche un motif dans un fichier ou dans la sortie d'une autre commande.

```bash
grep "sudo" 02.1_user_management.md
```

```text
sudo commande
sudo -u username commande
sudo su
```

### Récupérer le numéro des lignes

```bash
grep -n "sudo" 02.1_user_management.md
```

```text
114:sudo commande
122:sudo -u username commande
136:sudo su
```

### Recherche récursive dans une arborescence

```bash
grep -R "sudo" ../ShellScripts
```

```text
../ShellScripts/exercices/Exercice4.md:sudo useradd -d /home/newuser -m newuser
../ShellScripts/02.1_user_management.md:sudo commande
../ShellScripts/02.1_user_management.md:sudo -u username commande
../ShellScripts/02.1_user_management.md:sudo su
../ShellScripts/03_commandes_essentielles.md:grep "sudo" 02.1_user_management.md
../ShellScripts/03_commandes_essentielles.md:sudo commande
../ShellScripts/03_commandes_essentielles.md:sudo -u username commande
../ShellScripts/03_commandes_essentielles.md:sudo su
```

> [!TIP]
> `../ShellScripts` peut se raccourcir en `.` si on est déjà dans le dossier.

### Ignorer la casse

```bash
grep -i "user" 02.1_user_management.md
```

### Filtrer la sortie d'une autre commande

```bash
ps aux | grep apache
```

### Les options à retenir

| Option | Effet |
|--------|-------|
| `-n` | Afficher le numéro de ligne |
| `-i` | Insensible à la casse |
| `-R` / `-r` | Recherche récursive dans les sous-dossiers |
| `-v` | Inverser : afficher les lignes qui **ne** contiennent **pas** le motif |
| `-c` | Compter le nombre de lignes correspondantes |
| `-l` | N'afficher que le **nom** des fichiers qui contiennent le motif |
| `-E` | Utiliser les expressions régulières étendues |
| `-A 3` / `-B 3` | Afficher 3 lignes **après** / **avant** chaque résultat |

---

## Trouver des fichiers — `find`

### Par nom

```bash
find / -name "passwd" 2> /dev/null
```

> [!NOTE]
> Le `2> /dev/null` redirige les erreurs (typiquement les « Permission denied » sur les dossiers système) vers le néant, pour ne garder que les résultats utiles.

### Par date de modification

Trouver tous les fichiers modifiés il y a moins de deux jours :

```bash
find dossier -mtime -2
```

### Par taille

Ici, les fichiers de plus de 10 MiB :

```bash
find /var/log -type f -size +10M
```

### Faire des actions sur les fichiers trouvés

```bash
# Supprime les fichiers de /tmp qui finissent par .tmp
find /tmp -type f -name "*.tmp" -delete
```

```bash
# Liste les détails de chaque fichier trouvé
# -exec => j'exécute une commande
# ls -lh => la commande exécutée
# {}     => l'élément trouvé
# \;     => fin de l'instruction
find . -type f -name "*.md" -exec ls -lh {} \;
```

Sortie :

```text
-rw-r--r-- 1 rmdir  staff     0B Dec 10 15:32 ./09_tmux.md
-rw-r--r-- 1 rmdir  staff   593B Dec 11 13:09 ./exercices/Exercice4.md
-rw-r--r-- 1 rmdir  staff   1.1K Dec 10 15:47 ./exercices/Exercice3.md
-rw-r--r-- 1 rmdir  staff    81B Dec 11 11:42 ./05_securite.md
-rw-r--r-- 1 rmdir  staff     0B Dec 10 15:33 ./11_advanced_config.md
-rw-r--r-- 1 rmdir  staff   3.6K Dec 10 14:35 ./01_base.md
-rw-r--r-- 1 rmdir  staff   2.7K Dec 11 09:53 ./02_file_permissions.md
-rw-r--r-- 1 rmdir  staff    86B Dec 11 11:40 ./04_installation_et_services.md
-rw-r--r-- 1 rmdir  staff    12B Dec 10 10:39 ./README.md
-rw-r--r-- 1 rmdir  staff   2.3K Dec 11 11:24 ./02.1_user_management.md
-rw-r--r-- 1 rmdir  staff     0B Dec 10 15:32 ./10_shell_config.md
-rw-r--r-- 1 rmdir  staff   2.8K Dec 11 13:28 ./03_commandes_essentielles.md
```

> [!TIP]
> `-exec commande {} +` (avec un `+` au lieu de `\;`) regroupe tous les résultats en **un seul appel** de la commande au lieu d'un appel par fichier. C'est nettement plus rapide sur de gros volumes.

### Les critères à retenir

| Critère | Effet |
|---------|-------|
| `-name "*.log"` | Par nom (sensible à la casse ; `-iname` ne l'est pas) |
| `-type f` / `-type d` / `-type l` | Fichier / dossier / lien symbolique |
| `-size +10M` / `-size -1k` | Plus grand que / plus petit que |
| `-mtime -2` | Modifié il y a moins de 2 jours (`-mmin -30` : 30 minutes) |
| `-user debian` | Appartenant à un utilisateur |
| `-perm -4000` | Avec un bit de permission donné (ici SUID) |
| `-maxdepth 2` | Limiter la profondeur de recherche |
| `-delete` / `-exec … \;` / `-exec … +` | Agir sur les résultats |

---

## Analyse de l'espace disque — `du` et `df`

### `du` — ce que **consomment** les dossiers

```bash
du -h --max-depth=1 /var
```

```text
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

On descend ensuite dans le dossier coupable :

```bash
du -h --max-depth=1 /var/log
```

```text
252K	/var/log/apt
4.1G	/var/log/journal
29M	/var/log/apache2
8.0K	/var/log/runit
4.0K	/var/log/private
792K	/var/log/unattended-upgrades
5.5G	/var/log
```

> [!TIP]
> Pour trouver rapidement les plus gros postes : `du -h --max-depth=1 /var | sort -hr | head`

### Trouver le poids total d'un ensemble de fichiers avec `find`

```bash
find /var/backups -name "*.backup" -exec du -ch {} + | grep total
```

### `df` — ce qu'il **reste** sur les partitions

```bash
df -h
```

```text
Filesystem      Size  Used Avail Use% Mounted on
udev            1.9G     0  1.9G   0% /dev
tmpfs           384M  500K  383M   1% /run
/dev/sda1        79G  6.6G   69G   9% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda15      124M   12M  113M  10% /boot/efi
tmpfs           384M     0  384M   0% /run/user/1000
```

| Commande | Question à laquelle elle répond |
|----------|--------------------------------|
| `df -h`  | Mes partitions sont-elles pleines ? |
| `du -h`  | Qu'est-ce qui prend de la place ? |

---

## Archivage — `tar`

### Créer une archive

```bash
tar -cvf backup.tar /dossier
```

```text
c => créer
v => verbose (sortie détaillée)
f => préciser dans quel fichier enregistrer l'archive
```

### Créer une archive compressée

```bash
tar -czvf backup.tar.gz /dossier
```

```text
c => créer
z => compresser avec gzip
v => verbose (sortie détaillée)
f => préciser dans quel fichier enregistrer l'archive
```

Équivalent en deux étapes :

```bash
tar -cvf backup.tar /dossier
gzip backup.tar
```

…qui produit `backup.tar.gz`.

### Extraire une archive

```bash
tar -xvf backup.tar
```

Archive compressée :

```bash
tar -xzvf backup.tar.gz
```

Extraire dans un dossier cible :

```bash
tar -xzvf backup.tar.gz -C /dossier_cible
```

> [!TIP]
> Avant d'extraire une archive inconnue, listez son contenu pour vérifier qu'elle ne va pas déverser 200 fichiers dans le dossier courant :
>
> ```bash
> tar -tvf backup.tar.gz
> ```

### Créer une tarball à partir d'un `find`

```bash
find . -type f -name "*.md" -print0 | tar --null -czvf mdbackups.tar.gz --files-from=-
```

```text
find :
  -type f        => chercher des fichiers
  -name "*.md"   => dont le nom finit par .md
  -print0        => séparer chaque résultat par un \0

tar :
  --null         => les entrées sont séparées par des \0 (sortie de la commande précédente)
  -czvf archive  => créer une archive compressée
  --files-from=- => la liste des fichiers provient de l'entrée standard (-),
                    donc de la sortie de find
```

> [!NOTE]
> Le couple `-print0` / `--null` sert à gérer correctement les noms de fichiers contenant des **espaces** ou des retours à la ligne. Sans lui, un fichier `mon rapport.md` serait traité comme deux entrées.

### Les options `tar` à retenir

| Option | Effet |
|--------|-------|
| `-c` | Créer une archive |
| `-x` | Extraire une archive |
| `-t` | Lister le contenu sans extraire |
| `-f` | Nom du fichier d'archive |
| `-v` | Verbose |
| `-z` / `-j` / `-J` | Compresser en gzip / bzip2 / xz |
| `-C /chemin` | Se placer dans ce dossier avant d'agir |

---

## Récapitulatif

| Commande | Rôle |
|----------|------|
| `tree` | Visualiser une arborescence |
| `grep` | Chercher du texte |
| `find` | Chercher des fichiers |
| `du` | Mesurer l'espace utilisé |
| `df` | Mesurer l'espace disponible |
| `tar` | Archiver et compresser |
| `sort` / `wc` / `head` | Trier / compter / tronquer une sortie |

---

⬅️ [Précédent : 02.1 · Utilisateurs](02.1_user_management.md) · 🏠 [Sommaire](README.md) · [Suivant : 04 · Paquets et services ➡️](04_installation_et_services.md)
