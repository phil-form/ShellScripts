# 02 · Les permissions de fichiers (POSIX)

> [!NOTE]
> **Objectifs du chapitre**
> - Lire et décoder une ligne de permissions affichée par `ls -l`
> - Modifier des permissions en notation octale et en notation symbolique
> - Comprendre ce que signifient `r`, `w` et `x` sur un **dossier**
> - Connaître les permissions spéciales (SUID, SGID, sticky bit)
> - Changer le propriétaire et le groupe d'un fichier

## Sommaire

1. [Lire les permissions POSIX](#lire-les-permissions-posix)
2. [Le cas particulier des dossiers](#le-cas-particulier-des-dossiers)
3. [Modifier les permissions avec chmod](#modifier-les-permissions-avec-chmod)
4. [Appliquer en masse](#appliquer-en-masse)
5. [Permissions spéciales](#permissions-spéciales)
6. [Types de fichiers](#types-de-fichiers)
7. [Changer le propriétaire et le groupe](#changer-le-propriétaire-et-le-groupe)
8. [Récapitulatif](#récapitulatif)

---

## Lire les permissions POSIX

```text
-rwxr-xr-- 1 username usergroup 219K May 15  2020 script.sh
```

Décomposons la première colonne :

```text
 -    rwx      r-x      r--
 │     │        │        │
type  user    group    others
```

| Lettre | Signification | Sur un fichier |
|--------|---------------|----------------|
| `r` | **read** | Lire le contenu |
| `w` | **write** | Modifier le contenu |
| `x` | **execute** | Exécuter le fichier (script, binaire) |
| `-` | — | Droit absent |

Les trois groupes de trois caractères, dans l'ordre :

| Groupe | Concerne | Dans l'exemple |
|--------|----------|----------------|
| 1er (`rwx`) | Le **propriétaire** du fichier | `username` |
| 2e (`r-x`)  | Le **groupe** propriétaire | `usergroup` |
| 3e (`r--`)  | Tous les **autres** utilisateurs | tout le monde |

Donc, dans ce cas-ci :

- l'utilisateur `username` peut **lire / écrire / exécuter** le fichier ;
- les membres de `usergroup` peuvent **lire et exécuter** ;
- les autres ne peuvent que **lire** le fichier.

---

## Le cas particulier des dossiers

```text
drwxr-xr-- 1 username usergroup 219K May 15  2020 dossier
```

Le `d` en tête indique qu'il s'agit d'un **d**irectory (dossier). Sur un dossier, les trois droits n'ont pas du tout le même sens que sur un fichier :

| Droit | Sur un dossier |
|-------|----------------|
| `r` | Lister le contenu (`ls`) |
| `w` | Ajouter, renommer et supprimer des fichiers / sous-dossiers **dans** le dossier |
| `x` | Traverser le dossier, c'est-à-dire y entrer (`cd`) et accéder à ce qu'il contient |

> [!IMPORTANT]
> Sans le droit `x` sur un dossier, le droit `r` ne sert quasiment à rien : on peut voir les noms des fichiers, mais pas les ouvrir.
> À l'inverse, `w` sur un dossier permet de **supprimer** un fichier même si on n'a aucun droit sur ce fichier — c'est le dossier qui décide.

---

## Modifier les permissions avec chmod

### Notation octale

Les permissions sont codées en octal, un chiffre de 0 à 7 par groupe :

| Valeur | Droit |
|--------|-------|
| `4` | lecture (`r`) |
| `2` | écriture (`w`) |
| `1` | exécution (`x`) |

On additionne ces chiffres pour composer un droit :

| Chiffre | Calcul | Résultat |
|---------|--------|----------|
| `7` | 4+2+1 | `rwx` |
| `6` | 4+2   | `rw-` |
| `5` | 4+1   | `r-x` |
| `4` | 4     | `r--` |
| `3` | 2+1   | `-wx` |
| `2` | 2     | `-w-` |
| `1` | 1     | `--x` |
| `0` | —     | `---` |

### Exemple 1 — verrouiller un script pour son seul propriétaire

```bash
chmod 700 script.sh
```

Équivalent en notation symbolique :

```bash
chmod u=rwx,g=,o= script.sh
```

| | Permissions |
|---|---|
| **Avant** | `-rwxr-xr-- 1 username usergroup 219K May 15  2020 script.sh` |
| **Après** | `-rwx------ 1 username usergroup 219K May 15  2020 script.sh` |

### Exemple 2 — un fichier partagé avec son groupe

```bash
chmod 664 script.sh
```

Équivalent en notation symbolique :

```bash
chmod u=rw,g=rw,o=r script.sh
```

| | Permissions |
|---|---|
| **Avant** | `-rwx------ 1 username usergroup 219K May 15  2020 script.sh` |
| **Après** | `-rw-rw-r-- 1 username usergroup 219K May 15  2020 script.sh` |

> [!TIP]
> La notation symbolique accepte aussi `+` et `-` pour **ajouter** ou **retirer** un droit sans toucher au reste :
>
> | Commande | Effet |
> |----------|-------|
> | `chmod +x script.sh`   | Rend le fichier exécutable pour tout le monde |
> | `chmod u+x script.sh`  | Exécutable pour le propriétaire uniquement |
> | `chmod o-r fichier`    | Retire la lecture aux autres |
> | `chmod a=r fichier`    | Lecture seule pour tous (`a` = *all*) |

---

## Appliquer en masse

Modifier plusieurs fichiers d'un coup :

```bash
chmod 700 *.sh
```

Modifier un dossier et appliquer les mêmes permissions à tout son contenu (`-R` = récursif) :

```bash
chmod -R 700 dossier/
```

> [!WARNING]
> `chmod -R 700` applique aussi le droit `x` aux **fichiers** contenus dans le dossier, ce qui est rarement voulu.
> La bonne pratique est de séparer les deux cas :
>
> ```bash
> find dossier/ -type d -exec chmod 700 {} +   # dossiers : besoin du x pour être traversés
> find dossier/ -type f -exec chmod 600 {} +   # fichiers : pas de x
> ```

---

## Permissions spéciales

### SUID et SGID

```text
-rwsr-xr-x  →  le x du propriétaire est remplacé par un s
```

Le bit **SUID** (sur l'utilisateur) ou **SGID** (sur le groupe) permet d'exécuter le fichier **avec les droits du propriétaire / du groupe propriétaire** du fichier, et non avec ceux de l'utilisateur qui le lance.

Ajouter le bit :

```bash
chmod u+s file.sh
```

```bash
chmod g+s file.sh
```

Le retirer :

```bash
chmod u-s file.sh
```

```bash
chmod g-s file.sh
```

### SGID sur un dossier

Sur un **dossier**, `g+s` a un autre effet, très utile pour un espace de travail partagé : tout fichier créé à l'intérieur hérite automatiquement du **groupe du dossier** au lieu du groupe de son créateur.

```bash
chmod g+s /srv/projet_partage
```

### Sticky bit

```bash
chmod +t /tmp
```

Sur un dossier en écriture pour tous, le *sticky bit* (`drwxrwxrwt`) fait que **seul le propriétaire d'un fichier peut le supprimer**. C'est ce qui protège `/tmp`.

---

## Types de fichiers

Le tout premier caractère de la ligne indique le type de l'élément :

```bash
ls -l /
```

```text
lrwxrwxrwx   1 root root    7 Dec  2  2024 bin -> usr/bin
```

Ici `/bin` est un **lien symbolique** qui pointe vers `/usr/bin`.

| Caractère | Type |
|-----------|------|
| `-` | Fichier ordinaire |
| `d` | Dossier (*directory*) |
| `l` | Lien symbolique |
| `c` | Périphérique en mode caractère (ex. `/dev/null`) |
| `b` | Périphérique en mode bloc (ex. `/dev/sda`) |
| `s` | Socket |
| `p` | Tube nommé (*named pipe*) |

---

## Changer le propriétaire et le groupe

### Changer le propriétaire

```bash
chown newusername file
```

| | Résultat |
|---|---|
| **Avant** | `-rw-rw-r-- 1 username    usergroup 219K May 15  2020 file` |
| **Après** | `-rw-rw-r-- 1 newusername usergroup 219K May 15  2020 file` |

### Changer le groupe

```bash
chgrp newgroup file
```

| | Résultat |
|---|---|
| **Avant** | `-rw-rw-r-- 1 username usergroup 219K May 15  2020 file` |
| **Après** | `-rw-rw-r-- 1 username newgroup  219K May 15  2020 file` |

> [!TIP]
> `chown` sait faire les deux d'un coup, et accepte lui aussi `-R` :
>
> ```bash
> chown newusername:newgroup file
> chown -R www-data:www-data /var/www
> ```
>
> Changer le propriétaire d'un fichier nécessite les droits root.

---

## Récapitulatif

| Commande | Rôle |
|----------|------|
| `ls -l` | Afficher les permissions |
| `chmod 750 f` | Définir les permissions (octal) |
| `chmod u+x f` | Ajouter / retirer un droit (symbolique) |
| `chmod -R` | Appliquer récursivement |
| `chmod u+s` / `g+s` / `+t` | SUID / SGID / sticky bit |
| `chown user f` | Changer le propriétaire |
| `chgrp group f` | Changer le groupe |
| `chown user:group f` | Changer les deux |

**Valeurs qui reviennent le plus souvent :**

| Octal | Symbolique | Usage typique |
|-------|------------|---------------|
| `600` | `rw-------` | Fichier privé (clé SSH, secret) |
| `644` | `rw-r--r--` | Fichier de config lisible par tous |
| `700` | `rwx------` | Script ou dossier privé |
| `750` | `rwxr-x---` | Script partagé avec son groupe |
| `755` | `rwxr-xr-x` | Binaire ou dossier public |

---

⬅️ [Précédent : 01 · Les bases](01_base.md) · 🏠 [Sommaire](README.md) · [Suivant : 02.1 · Utilisateurs ➡️](02.1_user_management.md)
