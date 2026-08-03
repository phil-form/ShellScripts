# 03 · Commandes essentielles de l'administrateur

> [!NOTE]
> **Objectifs du chapitre**
> - Visualiser une arborescence avec `tree`
> - Chercher du texte dans des fichiers avec `grep`
> - Modifier du texte sans ouvrir d'éditeur avec `sed`
> - Traiter des colonnes et calculer avec `awk`
> - Découper, trier et compter une sortie avec `cut`, `sort`, `uniq`, `wc` et `tr`
> - Retrouver des fichiers selon leur nom, leur date ou leur taille avec `find`
> - Analyser l'occupation disque avec `du` et `df`
> - Créer et extraire des archives avec `tar`

## Sommaire

1. [Lister une arborescence — `tree`](#lister-une-arborescence--tree)
2. [Extraire des informations — `grep`](#extraire-des-informations--grep)
3. [Remplacer du texte — `sed`](#remplacer-du-texte--sed)
4. [Traiter des colonnes — `awk`](#traiter-des-colonnes--awk)
5. [Découper, trier, compter — `cut`, `sort`, `uniq`, `wc`, `tr`](#découper-trier-compter--cut-sort-uniq-wc-tr)
6. [Trouver des fichiers — `find`](#trouver-des-fichiers--find)
7. [Analyse de l'espace disque — `du` et `df`](#analyse-de-lespace-disque--du-et-df)
8. [Archivage — `tar`](#archivage--tar)
9. [Autres commandes à connaître](#autres-commandes-à-connaître)
10. [Récapitulatif](#récapitulatif)

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

## Remplacer du texte — `sed`

`grep` **cherche**, `sed` **modifie**. C'est un éditeur de flux : il lit ligne par ligne, applique une transformation, et écrit le résultat sur la sortie standard.

### Substituer un mot

```bash
sed 's/localhost/127.0.0.1/' config.txt
```

```text
s   => substitute (remplacer)
/   => séparateur entre la recherche et le remplacement
```

> [!IMPORTANT]
> Par défaut, `sed` ne remplace que la **première occurrence de chaque ligne** et **n'écrit rien dans le fichier** : il affiche seulement le résultat.

Pour remplacer **toutes** les occurrences d'une ligne, on ajoute le drapeau `g` (*global*) :

```bash
sed 's/localhost/127.0.0.1/g' config.txt
```

### Modifier réellement le fichier

```bash
sed -i 's/localhost/127.0.0.1/g' config.txt
```

`-i` = *in place*, la modification est écrite dans le fichier.

> [!CAUTION]
> `sed -i` écrase le fichier **sans confirmation**. Sur un fichier de configuration système, gardez toujours une copie :
>
> ```bash
> sed -i.bak 's/^Port 22/Port 2222/' /etc/ssh/sshd_config
> ```
>
> `-i.bak` sauvegarde l'original dans `sshd_config.bak` avant de modifier.
> Le réflexe : lancez d'abord la commande **sans** `-i` pour vérifier le résultat à l'écran.

### Changer de séparateur

Quand le motif contient des `/` (un chemin, typiquement), on utilise un autre séparateur pour éviter les échappements :

```bash
# Illisible
sed 's/\/var\/www/\/srv\/www/g' fichier

# Lisible : le séparateur devient |
sed 's|/var/www|/srv/www|g' fichier
```

### Supprimer des lignes

```bash
# Supprimer les lignes contenant "DEBUG"
sed '/DEBUG/d' app.log
```

```bash
# Supprimer les lignes vides
sed '/^$/d' fichier.txt
```

```bash
# Supprimer la première ligne (l'en-tête d'un CSV par exemple)
sed '1d' data.csv
```

### Afficher une plage de lignes

`-n` coupe l'affichage automatique, et `p` (*print*) n'affiche que ce qu'on demande :

```bash
# Les lignes 10 à 20
sed -n '10,20p' /var/log/syslog
```

```bash
# De la ligne 100 jusqu'à la fin
sed -n '100,$p' /var/log/syslog
```

### Commenter / décommenter une directive

Un classique de l'administration système :

```bash
# Commenter la ligne qui commence par PermitRootLogin
sed -i 's/^PermitRootLogin/#PermitRootLogin/' /etc/ssh/sshd_config
```

```bash
# Décommenter la ligne contenant "max_connections"
sed -i '/max_connections/s/^#//' /etc/postgresql/15/main/postgresql.conf
```

### Enchaîner plusieurs transformations

```bash
sed -e 's/foo/bar/g' -e '/^$/d' fichier.txt
```

… ou avec un `;` :

```bash
sed 's/foo/bar/g; /^$/d' fichier.txt
```

### Les options à retenir

| Élément | Effet |
|---------|-------|
| `s/motif/remplacement/` | Remplacer la première occurrence de chaque ligne |
| `s/motif/remplacement/g` | Remplacer **toutes** les occurrences |
| `s/motif/remplacement/gi` | … en ignorant la casse |
| `-i` / `-i.bak` | Modifier le fichier sur place (avec sauvegarde) |
| `-n` … `p` | N'afficher que les lignes sélectionnées |
| `-E` | Expressions régulières étendues (`+`, `?`, `(a\|b)`) |
| `/motif/d` | Supprimer les lignes correspondant au motif |
| `1d` / `1,5d` / `$d` | Supprimer la ligne 1 / les lignes 1 à 5 / la dernière |
| `^` / `$` | Début / fin de ligne |
| `&` | Rappelle le texte trouvé (`s/erreur/[&]/` → `[erreur]`) |

---

## Traiter des colonnes — `awk`

Beaucoup de sorties Linux sont des **tableaux** : `ps aux`, `df -h`, `/etc/passwd`, les logs Apache… `awk` découpe automatiquement chaque ligne en colonnes et permet d'en extraire, de filtrer et de calculer.

### Afficher une colonne

```bash
ps aux | awk '{print $1}'
```

Les colonnes s'appellent `$1`, `$2`, `$3`… et `$0` désigne la **ligne entière**.

```bash
# L'utilisateur et la commande de chaque processus
ps aux | awk '{print $1, $11}'
```

> [!NOTE]
> Par défaut, `awk` découpe sur les **espaces et tabulations**, en ignorant les répétitions. C'est ce qui le rend plus fiable que `cut` sur une sortie alignée comme `ps aux` ou `df -h`.

### Changer le séparateur

```bash
awk -F: '{print $1}' /etc/passwd
```

```text
root
daemon
bin
sys
...
```

### Filtrer les lignes

Comme `grep`, mais on garde la puissance des colonnes :

```bash
# Les lignes contenant "error", dont on affiche la 1re et la 4e colonne
awk '/error/ {print $1, $4}' /var/log/apache2/error.log
```

Et avec une **condition** sur une colonne :

```bash
# Les vrais utilisateurs (UID >= 1000), 3e champ de /etc/passwd
awk -F: '$3 >= 1000 {print $1, $3}' /etc/passwd
```

```bash
# Les processus qui consomment plus de 5 % de CPU
ps aux | awk '$3 > 5.0 {print $2, $3, $11}'
```

### Calculer

```bash
# Somme de la mémoire (%MEM) consommée par tous les processus
ps aux | awk '{sum += $4} END {printf "%.1f %%\n", sum}'
```

```bash
# Nombre de lignes et taille moyenne d'un champ
awk -F: '{n++; total += length($1)} END {print n " lignes, longueur moyenne " total/n}' /etc/passwd
```

`END { … }` s'exécute **une fois à la fin**, quand toutes les lignes ont été lues. Son pendant `BEGIN { … }` s'exécute avant la première ligne (pratique pour afficher un en-tête).

### Exemple complet : les IP les plus actives d'un log

```bash
awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head
```

```text
   1420 192.168.1.24
    317 10.0.0.8
     94 203.0.113.7
```

```text
awk '{print $1}'  => extraire la 1re colonne (l'adresse IP)
sort              => regrouper les lignes identiques
uniq -c           => compter chaque IP
sort -rn          => trier par nombre décroissant
head              => garder le top 10
```

### Les éléments à retenir

| Élément | Effet |
|---------|-------|
| `$1`, `$2`, … | La 1re, la 2e colonne… |
| `$0` | La ligne entière |
| `$NF` | La **dernière** colonne (`NF` = *number of fields*) |
| `NR` | Le numéro de la ligne courante |
| `-F:` / `-F';'` | Séparateur de colonnes |
| `/motif/ { … }` | N'agir que sur les lignes correspondant au motif |
| `$3 > 100 { … }` | Condition sur la valeur d'une colonne |
| `BEGIN { … }` / `END { … }` | Bloc exécuté avant / après le traitement |
| `printf "%.2f\n", x` | Affichage formaté (2 décimales) |

> [!TIP]
> `grep` pour chercher, `sed` pour remplacer, `awk` pour les colonnes et les calculs. Dès qu'un « script `awk` » dépasse quelques lignes, il vaut mieux écrire un vrai script shell (chapitre 06) ou du Python.

---

## Découper, trier, compter — `cut`, `sort`, `uniq`, `wc`, `tr`

Ces petites commandes ne servent presque jamais seules : elles s'assemblent avec des pipes.

### `cut` — extraire des colonnes simples

```bash
cut -d: -f1 /etc/passwd
```

```text
-d: => le délimiteur est ":"
-f1 => je veux le champ n°1
```

```bash
# Plusieurs champs
cut -d: -f1,3,7 /etc/passwd
```

```bash
# Les 10 premiers caractères de chaque ligne
cut -c1-10 fichier.txt
```

> [!WARNING]
> `cut` traite **chaque** délimiteur comme une séparation : sur une sortie alignée avec plusieurs espaces (`ps aux`, `df -h`), il donne des colonnes vides. Dans ce cas, utilisez `awk`.

### `sort` — trier

```bash
sort fichier.txt
```

| Option | Effet |
|--------|-------|
| `-r` | Ordre inverse |
| `-n` | Tri **numérique** (sinon `10` passe avant `9`) |
| `-h` | Tri des tailles lisibles (`1K`, `2M`, `3G`) |
| `-u` | Supprimer les doublons |
| `-k2` | Trier sur la 2e colonne |
| `-t:` | Changer le séparateur de colonnes |

```bash
# Les utilisateurs triés par UID
sort -t: -k3 -n /etc/passwd
```

### `uniq` — dédoublonner et compter

```bash
sort fichier.txt | uniq -c
```

| Option | Effet |
|--------|-------|
| `-c` | Compter les occurrences |
| `-d` | N'afficher que les lignes en doublon |
| `-u` | N'afficher que les lignes uniques |

> [!IMPORTANT]
> `uniq` ne compare que les lignes **consécutives**. Il faut donc presque toujours un `sort` avant.

### `wc` — compter

```bash
wc -l /var/log/syslog
```

| Option | Effet |
|--------|-------|
| `-l` | Nombre de **lignes** |
| `-w` | Nombre de **mots** |
| `-c` | Nombre d'**octets** |

```bash
# Combien d'utilisateurs sur la machine ?
wc -l < /etc/passwd
```

### `tr` — transformer des caractères

```bash
# Tout en majuscules
echo "hello" | tr 'a-z' 'A-Z'
```

```bash
# Supprimer des caractères
echo "1 234 567" | tr -d ' '
```

```bash
# Compresser les espaces répétés en un seul (utile avant un cut)
ps aux | tr -s ' ' | cut -d' ' -f1,11
```

| Option | Effet |
|--------|-------|
| *(aucune)* | Remplacer un jeu de caractères par un autre |
| `-d` | Supprimer les caractères indiqués |
| `-s` | *Squeeze* : réduire les répétitions à une seule occurrence |

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

### Passer les résultats à une autre commande — `xargs`

`xargs` transforme une liste reçue sur l'entrée standard en **arguments** d'une commande. C'est l'alternative à `-exec`, et le seul moyen quand la liste vient d'ailleurs que de `find`.

```bash
find /var/log -name "*.gz" | xargs rm
```

Pourquoi `xargs` ? Beaucoup de commandes (`rm`, `grep`, `tar`…) attendent leurs cibles en argument, pas sur l'entrée standard : `find … | rm` ne fonctionne pas, `find … | xargs rm` oui.

```bash
# Chercher un motif uniquement dans les fichiers .conf
find /etc -name "*.conf" | xargs grep -l "listen"
```

Placer l'argument ailleurs qu'à la fin, avec `-I` :

```bash
# {} est remplacé par chaque résultat
find . -name "*.md" | xargs -I {} cp {} /tmp/sauvegarde/
```

> [!CAUTION]
> Un nom de fichier contenant un **espace** casse `xargs` : `mon rapport.md` devient deux arguments. La version robuste utilise le couple `-print0` / `-0` :
>
> ```bash
> find /var/log -name "*.gz" -print0 | xargs -0 rm
> ```

| Option | Effet |
|--------|-------|
| `-0` | Les entrées sont séparées par des `\0` (avec `find -print0`) |
| `-I {}` | Remplacer `{}` par l'argument, où qu'il soit dans la commande |
| `-n 1` | Un seul argument par appel de la commande |
| `-P 4` | Exécuter 4 appels en **parallèle** |
| `-t` | Afficher la commande avant de l'exécuter (pour vérifier) |

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

## Autres commandes à connaître

Elles ne méritent pas un chapitre, mais elles rendent service tous les jours.

### `tee` — écrire dans un fichier **et** à l'écran

```bash
apt update | tee /tmp/update.log
```

Utile quand une commande a besoin de `sudo` pour écrire un fichier — la redirection `>` classique échoue, car c'est le *shell* (non root) qui ouvre le fichier :

```bash
echo "127.0.0.1 monsite.local" | sudo tee -a /etc/hosts
```

`-a` = *append*, comme `>>`.

### `diff` — comparer deux fichiers

Le réflexe après avoir modifié une configuration :

```bash
diff /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
```

```bash
# Version plus lisible, avec du contexte
diff -u ancien.conf nouveau.conf
```

`diff -r dossier1 dossier2` compare deux arborescences entières.

### `stat` et `file` — les métadonnées d'un fichier

```bash
stat rapport.pdf
```

```text
  File: rapport.pdf
  Size: 24576      Blocks: 48   IO Block: 4096   regular file
Access: (0644/-rw-r--r--)  Uid: ( 1000/  rmdir)   Gid: ( 1000/  rmdir)
Modify: 2025-12-11 13:28:41.000000000 +0100
```

```bash
# De quel type est réellement ce fichier ? (l'extension peut mentir)
file archive.bin
```

```text
archive.bin: gzip compressed data, from Unix
```

### `watch` — répéter une commande

```bash
# Réafficher df -h toutes les 2 secondes
watch df -h
```

```bash
# Toutes les 5 secondes, en surlignant ce qui change
watch -n 5 -d "ls -l /var/spool/mail"
```

`CTRL + C` pour quitter.

### `which` et `type` — où est cette commande ?

```bash
which python3
```

```text
/usr/bin/python3
```

`type ma_commande` va plus loin : il indique s'il s'agit d'un binaire, d'un **alias** ou d'une fonction du shell.

### En résumé

| Commande | Rôle |
|----------|------|
| `tee` | Dupliquer une sortie : fichier + écran |
| `diff` | Comparer deux fichiers ou deux dossiers |
| `stat` | Métadonnées détaillées (taille, dates, permissions) |
| `file` | Type réel d'un fichier |
| `watch` | Répéter une commande à intervalle régulier |
| `which` / `type` | Localiser une commande, détecter un alias |
| `ln -s` | Créer un lien symbolique (voir chapitre 11) |
| `rsync` | Copier / synchroniser, y compris à distance (voir chapitre 05) |

---

## Récapitulatif

| Commande | Rôle |
|----------|------|
| `tree` | Visualiser une arborescence |
| `grep` | **Chercher** du texte |
| `sed` | **Remplacer** ou supprimer du texte |
| `awk` | Extraire des **colonnes**, filtrer, calculer |
| `cut` | Extraire des colonnes à délimiteur simple |
| `sort` / `uniq` / `wc` | Trier / dédoublonner / compter |
| `tr` | Transformer ou supprimer des caractères |
| `find` | Chercher des fichiers |
| `xargs` | Passer une liste en arguments à une commande |
| `du` | Mesurer l'espace utilisé |
| `df` | Mesurer l'espace disponible |
| `tar` | Archiver et compresser |
| `tee` / `diff` / `watch` | Dupliquer une sortie / comparer / surveiller |

> [!TIP]
> Le trio à retenir pour analyser des logs : `grep` filtre les lignes, `awk` en extrait les colonnes, `sort | uniq -c | sort -rn` compte et classe.
>
> ```bash
> grep "404" access.log | awk '{print $7}' | sort | uniq -c | sort -rn | head
> ```
>
> … soit : les 10 URL les plus souvent introuvables.

---

⬅️ [Précédent : 02.1 · Utilisateurs](02.1_user_management.md) · 🏠 [Sommaire](README.md) · [Suivant : 04 · Paquets et services ➡️](04_installation_et_services.md)
