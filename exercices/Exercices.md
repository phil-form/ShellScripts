# 🐧 Fondamentaux Linux — Exercices (points 01 à 04)

> Un set d'exercices neufs pour les quatre premiers chapitres du support :
> **01 · Bases du terminal**, **02 · Permissions, utilisateurs & groupes**, **03 · Commandes essentielles**, **04 · Paquets, services & cron**.
> Fil rouge : vous préparez et administrez le serveur Debian de l'ASBL bruxelloise **Delvaux & Fils**. Corrigés dans le document séparé `Exercices_ch01-04_corrections.md`.

> [!CAUTION]
> Travaillez sur une VM ou un conteneur jetable — **jamais** sur votre machine principale. Les points 02 et 04 manipulent des utilisateurs, des permissions et des services : de quoi vous couper l'accès à votre propre système.
>
> Un bac à sable en une commande : `docker run -it --rm --name lab debian:12 bash`, puis `apt update && apt install -y sudo vim nano tree htop cron`.
 
---
---

# 📁 Point 01 — Les bases du terminal

*Chapitre [01 · Les bases du terminal](../01_base.md)*

> [!NOTE]
> **Objectifs** : se déplacer, créer/déplacer/supprimer des fichiers, rediriger les sorties, lire un fichier, utiliser un heredoc, chaîner avec un pipe, gérer les processus.

### Exercice 1.1 — Poser l'arborescence

L'ASBL veut ranger son serveur. Créez, **depuis votre home**, l'arborescence suivante :

```text
delvaux/
├── site/
│   ├── public/
│   └── src/
├── compta/
├── logs/
└── backups/
```

1. Créez toute l'arborescence en **une seule commande**.
2. Placez-vous dans `delvaux/site/src` et affichez le chemin absolu où vous vous trouvez.
3. Remontez d'un seul niveau, puis revenez directement à votre home avec un unique `cd`.
4. Affichez le contenu de `delvaux/` sous forme détaillée, fichiers cachés compris.
### Exercice 1.2 — Créer, copier, déplacer, supprimer

1. Dans `delvaux/site/src`, créez d'un coup les fichiers `index.php`, `style.css` et `app.js`.
2. Copiez `index.php` en `index.php.bak` dans le même dossier.
3. Renommez `app.js` en `main.js`.
4. Déplacez `style.css` dans `delvaux/site/public/`.
5. Supprimez `index.php.bak`, puis supprimez le dossier (vide) `delvaux/compta` — avec la commande **dédiée aux dossiers vides**.
### Exercice 1.3 — Redirections et heredoc

1. Écrivez la ligne `serveur Delvaux — prod` dans `delvaux/logs/notes.txt` (le fichier n'existe pas encore).
2. **Ajoutez** la ligne `mise en service : aujourd'hui` à ce même fichier, sans écraser la première.
3. Lancez `ls /dossier-qui-nexiste-pas` et redirigez **uniquement l'erreur** vers `delvaux/logs/erreurs.txt`.
4. Avec un **heredoc**, écrivez ce bloc en une fois dans `delvaux/site/src/config.ini` :
```ini
   [app]
   name = Delvaux
   env  = production
   port = 8080
```

### Exercice 1.4 — Lire un fichier

Un fichier `delvaux/logs/access.log` contient 500 lignes (générez-le avec la commande fournie dans le corrigé, ou `seq 1 500 > delvaux/logs/access.log`).

1. Affichez **tout** le fichier.
2. Affichez seulement les **10 premières** lignes.
3. Affichez seulement les **5 dernières** lignes.
### Exercice 1.5 — Chaîner avec un pipe

1. Comptez le nombre d'éléments dans `delvaux/site/src` (indice : `ls` + `wc -l` reliés par un pipe).
2. Affichez les **3 premières** lignes de la sortie de `ls -l delvaux/` sans créer de fichier intermédiaire.
### Exercice 1.6 — Les processus

1. Lancez en **arrière-plan** une commande qui dort 300 secondes.
2. Retrouvez son identifiant (PID) dans la liste des processus.
3. Arrêtez ce processus proprement à partir de son PID.
> [!TIP]
> Pour l'édition, refaites l'exercice 1.3 une fois dans **nano** (`CTRL+O` pour enregistrer, `CTRL+X` pour quitter) et une fois dans **vim** (`i` pour insérer, `ESC` puis `:wq` pour enregistrer et quitter). C'est en tapant qu'on retient les raccourcis.
 
---
---

# 🔐 Point 02 — Permissions, utilisateurs & groupes

*Chapitres [02 · Permissions](../02_file_permissions.md) et [02.1 · Utilisateurs et groupes](../02.1_user_management.md)*

> [!NOTE]
> **Objectifs** : lire et modifier des permissions (octal & symbolique), comprendre `r/w/x` sur un dossier, permissions spéciales, `chown`/`chgrp`, créer/gérer des utilisateurs et des groupes, `su`/`sudo`.

### Exercice 2.1 — Lire des permissions

Voici un `ls -l` sur le serveur de l'ASBL :

```text
-rwxr-x---  1 alice  staff   4096  cleanup.sh
-rw-r--r--  1 root   root     220  app.conf
drwxrwx---  2 bob    staff   4096  partage/
-rw-------  1 alice  alice   1675  id_rsa
```

Pour **chacune** des quatre lignes, répondez : quel est le type (fichier/dossier) ? Que peut faire le propriétaire, le groupe, les autres ? Traduisez aussi les permissions en **notation octale**.

### Exercice 2.2 — chmod en octal

Positionnez les droits suivants (donnez la commande `chmod` octale) :

| Fichier | Besoin | Droits voulus |
|---------|--------|---------------|
| `id_rsa` | clé privée, lisible par son seul propriétaire | `rw-------` |
| `app.conf` | config lisible par tous, modifiable par le propriétaire | `rw-r--r--` |
| `deploy.sh` | script partagé avec le groupe, invisible aux autres | `rwxr-x---` |
| `backup` (dossier) | dossier public traversable | `rwxr-xr-x` |

Puis, **dans l'autre sens** : que valent `640`, `700` et `775` en `rwx` ?

### Exercice 2.3 — chmod symbolique et récursif

1. Ajoutez le droit d'**exécution** au propriétaire de `deploy.sh` avec la notation **symbolique**.
2. Retirez le droit d'**écriture** au groupe et aux autres sur `app.conf`, en symbolique.
3. Appliquez `750` **récursivement** à tout le dossier `delvaux/site`.
### Exercice 2.4 — Le piège des dossiers

Vous créez un dossier `delvaux/partage` que trois collègues doivent se partager.

1. Sur un **fichier**, `r` permet de lire. Sur un **dossier**, à quoi servent respectivement `r`, `w` et `x` ? (Répondez en une phrase chacun.)
2. Faites en sorte que tout **nouveau** fichier créé dans `delvaux/partage` appartienne automatiquement au groupe du dossier (indice : un bit spécial sur le dossier).
3. Faites en sorte que, dans ce dossier partagé, **seul** le propriétaire d'un fichier puisse le supprimer (indice : un autre bit spécial).
### Exercice 2.5 — Utilisateurs et groupes

1. Créez l'utilisateur `bob`, **avec** sa *home directory* et le shell `/bin/bash`.
2. Créez le groupe `staff`.
3. Ajoutez `bob` **et** votre propre utilisateur au groupe `staff`, **sans** les retirer de leurs autres groupes.
4. Vérifiez les groupes de `bob`.
5. Donnez au dossier `delvaux/` (et tout son contenu) le groupe `staff`, puis passez ses droits à `rwxrwx---`.

### Exercice 2.6 — Changer d'identité

1. Exécutez la seule commande `whoami` en tant que `root`, **sans** ouvrir de session root.
2. Ouvrez une **vraie session** (environnement propre) en tant que `bob`, puis ressortez-en.

### Exercice 2.7 — Cycle de vie d'un compte

1. Changez le mot de passe de `bob`.
2. Renommez l'utilisateur `bob` en `robert`.
3. Verrouillez temporairement le compte `robert`, puis déverrouillez-le.
4. Supprimez l'utilisateur `robert` **ainsi que** sa *home directory*.
---