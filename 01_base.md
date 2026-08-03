# 01 · Les bases du terminal Linux

> [!NOTE]
> **Objectifs du chapitre**
> - Se déplacer dans une arborescence depuis le terminal
> - Comprendre l'organisation du système de fichiers Linux
> - Créer, copier, déplacer et supprimer des fichiers et des dossiers
> - Rediriger les sorties d'une commande et les chaîner entre elles
> - Lire et éditer un fichier avec `nano` et `vim`
> - Inspecter et arrêter les processus en cours

## Sommaire

1. [Navigation dans le terminal](#navigation-dans-le-terminal)
2. [Le système de fichiers Linux](#le-système-de-fichiers-linux)
3. [Manipulation de fichiers et de dossiers](#manipulation-de-fichiers-et-de-dossiers)
4. [Redirection des sorties](#redirection-des-sorties)
5. [Afficher le contenu d'un fichier](#afficher-le-contenu-dun-fichier)
6. [Éditer un fichier](#éditer-un-fichier)
7. [Redirection avec EOF (heredoc)](#redirection-avec-eof-heredoc)
8. [Chaîner des commandes avec le pipe](#chaîner-des-commandes-avec-le-pipe)
9. [Gestion des processus](#gestion-des-processus)
10. [Récapitulatif](#récapitulatif)

---

## Navigation dans le terminal

Afficher l'emplacement actuel dans le terminal (**p**rint **w**orking **d**irectory) :

```bash
pwd
```

Se déplacer dans un dossier :

```bash
cd NomDuDossier
```

Se déplacer dans le dossier parent :

```bash
cd ..
```

Se déplacer dans un dossier situé dans le dossier parent :

```bash
cd ../NomDuDossier
```

> [!TIP]
> Quelques raccourcis de chemins qui reviennent tout le temps :
>
> | Raccourci | Signification |
> |-----------|---------------|
> | `.`  | Le dossier courant |
> | `..` | Le dossier parent |
> | `~`  | Le *home* de l'utilisateur courant (`/home/username`) |
> | `-`  | Le dossier précédent (`cd -` fait l'aller-retour) |
> | `/`  | La racine du système |

---

## Le système de fichiers Linux

Sous Linux, **tout part d'une seule racine notée `/`**. Il n'y a pas de lecteurs `C:` ou `D:` comme sous Windows : les disques, les clés USB et même certains périphériques sont « branchés » (*montés*) quelque part dans cette unique arborescence.

Sous cette racine, on trouve toujours à peu près les mêmes dossiers, chacun avec un rôle bien précis (c'est la norme *FHS — Filesystem Hierarchy Standard*).

```
/
├── bin    → commandes de base (ls, cp, cat…)
├── sbin   → commandes d'administration (réservées à root)
├── boot   → noyau Linux et fichiers de démarrage
├── etc    → fichiers de configuration du système
├── home   → dossiers personnels des utilisateurs
├── root   → dossier personnel de l'administrateur (root)
├── lib    → bibliothèques partagées par les programmes
├── usr    → programmes et données installés (le gros du système)
├── var    → données qui varient : logs, files d'attente, caches…
├── tmp    → fichiers temporaires (effacés au redémarrage)
├── opt    → logiciels tiers installés « à part »
├── mnt    → point de montage manuel (disques, partages réseau)
├── media  → montage automatique des supports amovibles (USB, CD…)
├── dev    → périphériques vus comme des fichiers (disques, terminaux…)
├── proc   → système de fichiers virtuel : état des processus et du noyau
└── sys    → système de fichiers virtuel : matériel et paramètres du noyau
```

| Dossier | Rôle | Exemple concret |
|---------|------|-----------------|
| `/bin`  | Commandes essentielles, disponibles pour tous | `/bin/ls`, `/bin/cp` |
| `/sbin` | Commandes d'administration système | `/sbin/reboot`, `/sbin/fdisk` |
| `/boot` | Noyau et amorçage (bootloader) | `/boot/vmlinuz`, GRUB |
| `/etc`  | **Toute la configuration** du système | `/etc/passwd`, `/etc/ssh/sshd_config` |
| `/home` | Fichiers personnels des utilisateurs | `/home/alice`, `/home/bob` |
| `/root` | *Home* de l'utilisateur root | `/root` |
| `/usr`  | Programmes installés et leurs ressources | `/usr/bin`, `/usr/share` |
| `/var`  | Données qui grossissent avec le temps | `/var/log`, `/var/www` |
| `/tmp`  | Fichiers temporaires, jetables | fichiers d'un installeur |
| `/dev`  | Périphériques matériels vus comme des fichiers | `/dev/sda`, `/dev/null` |
| `/proc` | Vue **virtuelle** des processus et du noyau | `/proc/cpuinfo`, `/proc/1234` |
| `/sys`  | Vue **virtuelle** du matériel et du noyau | `/sys/class/net` |

> [!NOTE]
> `/proc` et `/sys` n'existent pas sur le disque : ils sont générés **à la volée** par le noyau. Lire `/proc/cpuinfo` revient à demander au noyau les infos du processeur en direct.

> [!TIP]
> Deux dossiers à connaître par cœur au quotidien : **`/etc`** (là où on configure) et **`/var/log`** (là où on regarde ce qui s'est passé quand ça ne marche pas).

> [!CAUTION]
> Les dossiers `/`, `/etc`, `/bin`, `/boot`, `/usr`… appartiennent au système. On n'y touche qu'avec `sudo` et en sachant ce qu'on fait : une suppression malheureuse peut rendre la machine inutilisable.

---

## Manipulation de fichiers et de dossiers

Créer un fichier :

```bash
touch nomDuFichier
```

Supprimer un fichier :

```bash
rm nomDuFichier
```

Créer un nouveau dossier :

```bash
mkdir nomDuDossier
```

Supprimer un dossier **vide** :

```bash
rmdir nomDuDossier
```

Supprimer un dossier **et tout son contenu** :

```bash
rm -Rf nomDuDossier
```

> [!CAUTION]
> `rm -Rf` supprime **sans confirmation et sans corbeille** : il n'y a pas de retour en arrière.
> Vérifiez toujours le chemin avant de valider, surtout s'il commence par `/` ou s'il contient une variable — `rm -Rf "$DOSSIER/"` avec `DOSSIER` vide cible la racine.

Déplacer un fichier ou un dossier :

```bash
mv ./origine nouvelle/emplacement/
```

Cette commande déplace le fichier `origine` (situé dans le dossier courant) vers `./nouvelle/emplacement/origine`.

Renommer un fichier ou un dossier — c'est la même commande, on « déplace » vers un nouveau nom :

```bash
mv ancienNom nouveauNom
```

Copier un fichier :

```bash
cp origine copie
```

Crée un nouveau fichier nommé `copie` avec le même contenu que `origine`.

Copier un dossier (`-R` = récursif, donc avec son contenu) :

```bash
cp -R origine/ nouveauDossier/
```

---

## Redirection des sorties

Rediriger la sortie d'une commande dans un fichier :

```bash
echo "Hello" > example.txt
```

ou

```bash
echo "Hello" >> example.txt
```

La différence entre `>` et `>>` :

| Opérateur | Comportement |
|-----------|--------------|
| `>`  | **Écrase** le contenu du fichier (et le crée s'il n'existe pas) |
| `>>` | **Ajoute** à la fin du fichier |

Cela fonctionne avec n'importe quelle commande :

```bash
ls >> files.txt
```

Je peux aussi rediriger **uniquement les erreurs** :

```bash
ls 2> errors.txt
```

> [!NOTE]
> Chaque programme dispose de trois flux standards. Le chiffre placé devant `>` désigne le flux à rediriger :
>
> | Flux | Numéro | Rôle |
> |------|--------|------|
> | `stdin`  | `0` | Entrée standard (le clavier par défaut) |
> | `stdout` | `1` | Sortie standard (`>` est un raccourci pour `1>`) |
> | `stderr` | `2` | Sortie d'erreur |
>
> Tout rediriger au même endroit : `commande > sortie.log 2>&1`
> Tout jeter à la poubelle : `commande > /dev/null 2>&1`

---

## Afficher le contenu d'un fichier

Afficher tout le fichier :

```bash
cat filename.txt
```

Afficher les 10 premières lignes :

```bash
head filename
```

Afficher les 10 dernières lignes :

```bash
tail filename
```

Afficher les `n` premières / dernières lignes (ici 5) :

```bash
head -n 5 filename
```

```bash
tail -n 5 filename
```

> [!TIP]
> `tail -f fichier.log` suit le fichier **en direct** : les nouvelles lignes s'affichent au fur et à mesure qu'elles sont écrites. Indispensable pour surveiller des logs.
> Pour parcourir un fichier long : `less fichier` (flèches pour se déplacer, `/` pour chercher, `q` pour quitter).

---

## Éditer un fichier

Deux éditeurs sont disponibles nativement sur la plupart des distributions Linux.

### nano — le plus simple

```bash
nano filename
```

Raccourcis utiles :

| Raccourci | Action |
|-----------|--------|
| `CTRL + O` | Enregistrer |
| `CTRL + X` | Quitter |
| `CTRL + K` | Couper une ligne |
| `CTRL + U` | Coller la ligne coupée |
| `CTRL + W` | Chercher du texte |
| `CTRL + \` | Remplacer du texte |

### vim — le plus puissant

```bash
vim filename
```

Trois modes importants :

| Mode | Comment y entrer | À quoi ça sert |
|------|------------------|----------------|
| **Normal** | `ESC` (mode par défaut) | Se déplacer, supprimer, copier |
| **Insertion** | `i` | Taper du texte |
| **Commande** | `:` | Enregistrer, quitter, chercher/remplacer |

**Ajouter du texte, étape par étape :**

1. Ouvrir `vim`
2. Appuyer sur `i`
3. Taper le texte
4. `ESC` pour revenir au mode normal
5. `:wq` (ou `:x`) pour enregistrer et quitter

| Commande | Action |
|----------|--------|
| `:w`  | Enregistrer |
| `:q`  | Quitter |
| `:q!` | Quitter **sans** enregistrer |
| `:wq` / `:x` | Enregistrer et quitter |

> [!IMPORTANT]
> Sur Debian et d'autres distributions, `vim` n'est pas toujours installé, mais `vi` (son ancêtre) l'est presque toujours.

---

## Redirection avec EOF (heredoc)

Le *heredoc* permet d'écrire plusieurs lignes d'un coup dans un fichier — très pratique dans un script pour générer un fichier de configuration.

```bash
cat <<EOF >> output.txt
le contenu que je veux dans mon fichier
je peux faire des retours à la ligne
etc
...
et je clôture le fichier avec :
EOF
```

> [!TIP]
> Avec `<<EOF`, les variables sont interprétées (`$USER` est remplacé par sa valeur).
> Avec `<<'EOF'` (entre quotes), le texte est écrit **tel quel**, sans interprétation.

---

## Chaîner des commandes avec le pipe

Le `|` (*pipe*) redirige la **sortie** d'une commande vers l'**entrée** d'une autre.

Extraire toutes les lignes contenant `sha-256` :

```bash
cat /etc/postgresql/15/main/pg_hba.conf | grep sha-256
```

Trier une sortie :

```bash
ls / | sort
```

Compter le nombre de lignes contenant `sha-256` :

```bash
cat /etc/postgresql/15/main/pg_hba.conf | grep sha-256 | wc -l
```

On peut enchaîner autant de commandes que l'on veut : chaque `|` passe le résultat au maillon suivant.

---

## Gestion des processus

Afficher les processus en cours d'exécution :

```bash
ps aux
```

Version interactive :

```bash
top
```

Ou en beaucoup plus lisible (à installer) :

```bash
htop
```

### Chercher un processus précis

```bash
ps aux | grep node
```

Une fois que j'ai le **PID** (*process ID*) du processus, je peux le tuer :

```bash
kill -9 PID
```

> [!WARNING]
> `kill -9` (SIGKILL) tue le processus **brutalement** : il n'a pas l'occasion de fermer proprement ses fichiers ou ses connexions.
> Essayez toujours `kill PID` (SIGTERM, arrêt propre) en premier, et gardez `-9` pour les processus qui ne répondent plus.

---

## Récapitulatif

| Commande | Rôle |
|----------|------|
| `pwd` | Où suis-je ? |
| `cd` | Se déplacer |
| `ls` | Lister le contenu d'un dossier |
| `touch` / `mkdir` | Créer un fichier / un dossier |
| `rm` / `rmdir` | Supprimer un fichier / un dossier vide |
| `mv` | Déplacer ou renommer |
| `cp` | Copier |
| `cat` / `head` / `tail` | Lire un fichier (tout / début / fin) |
| `nano` / `vim` | Éditer un fichier |
| `>` / `>>` / `2>` | Rediriger la sortie / ajouter à la fin / rediriger les erreurs |
| `\|` | Chaîner deux commandes |
| `ps` / `top` / `htop` | Voir les processus |
| `kill` | Arrêter un processus |

> [!TIP]
> En cas de doute sur une commande : `man commande` (manuel complet) ou `commande --help` (aide rapide).

---

🏠 [Sommaire](README.md) · [Suivant : 02 · Permissions ➡️](02_file_permissions.md)
