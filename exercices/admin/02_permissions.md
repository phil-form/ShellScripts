# 🔐 A2 · Permissions et propriété

*Chapitre [02 · Les permissions de fichiers](../../02_file_permissions.md)*

> [!NOTE]
> **Objectifs** : lire une ligne de `ls -l` sans réfléchir, poser des droits justes en octal comme en
> symbolique, comprendre ce que `r`, `w` et `x` signifient sur un dossier, maîtriser SUID / SGID / sticky bit,
> et réparer une propriété cassée.

---

## Exercice 2.1 — Lire

Voici un extrait de `ls -l` pris sur `srv-tickets` :

```text
-rwxr-x---  1 root   ops     2048  /usr/local/bin/backup.sh
-rw-r--r--  1 root   root     742  /etc/ticketflow/app.conf
drwxrws---  4 root   dev     4096  /srv/projet/
-rw-------  1 alice  alice   1675  /home/alice/.ssh/id_ed25519
-rwsr-xr-x  1 root   root   68208  /usr/bin/passwd
drwxrwxrwt  8 root   root    4096  /tmp
lrwxrwxrwx  1 root   root      21  /root/conf -> /srv/ticketflow/conf
```

Pour **chaque ligne** : quel est le type d'objet ? que peuvent faire le propriétaire, le groupe, les autres ?
quelle est la notation **octale** correspondante ? Et pour les trois dernières, **quel bit spécial** est posé,
et à quoi sert-il ici concrètement ?

---

## Exercice 2.2 — Poser des droits

Donnez la commande `chmod` **octale** pour chacun de ces besoins, puis la version **symbolique** équivalente :

| Chemin | Besoin |
|--------|--------|
| `/root/.ssh/id_ed25519` | clé privée : le propriétaire seul, en lecture / écriture |
| `/etc/ticketflow/app.conf` | lisible par tous, modifiable par root seul |
| `/usr/local/bin/backup.sh` | exécutable par root et par le groupe `ops`, invisible aux autres |
| `/srv/ticketflow/backups` | traversable et listable par le groupe, interdit aux autres |
| `/var/log/ticketflow` | le service écrit dedans, les admins lisent, personne d'autre n'entre |

Puis **dans l'autre sens** : traduisez en `rwx` les droits `640`, `750`, `775`, `1777` et `4755`.

---

## Exercice 2.3 — Le cas des dossiers

1. Sur un fichier `r`, `w` et `x` sont clairs. Sur un **dossier**, que permet chacun exactement ?
2. Créez `/srv/test-droits`, mettez-y un fichier, puis retirez `x` au dossier pour votre utilisateur de test.
   Peut-il encore **lister** le dossier ? **lire** le fichier dont il connaît le nom ? Expliquez.
3. Refaites l'essai en retirant `r` mais en laissant `x`. Que peut-il faire cette fois ?
4. Un utilisateur peut supprimer un fichier dont il n'est **pas** propriétaire et sur lequel il n'a **aucun**
   droit d'écriture. Comment est-ce possible ? Comment l'empêcher ?

---

## Exercice 2.4 — Appliquer en masse

1. Appliquez `750` récursivement à `/srv/ticketflow`.
2. Problème : cela rend aussi les **fichiers** exécutables, ce qu'on ne veut pas. Écrivez les deux commandes
   qui posent `750` sur les **dossiers** et `640` sur les **fichiers**, en utilisant `find`
   *(chapitre [03](../../03_commandes_essentielles.md))*.
3. Refaites la même chose avec la notation symbolique `X` majuscule. Que fait-elle exactement ?
4. Pourquoi `chmod -R 777` est-il presque toujours la mauvaise réponse ? Donnez deux conséquences concrètes.

---

## Exercice 2.5 — Les bits spéciaux

1. **SGID sur un dossier** : faites en sorte que tout fichier créé dans `/srv/projet` appartienne
   automatiquement au groupe `dev`, quel que soit son créateur. Vérifiez avec deux comptes différents.
2. **Sticky bit** : faites en sorte que, dans ce dossier partagé, chacun ne puisse supprimer que **ses propres**
   fichiers. Vérifiez en essayant de supprimer le fichier d'un autre.
3. **SUID** : pourquoi `/usr/bin/passwd` en a-t-il besoin ? Que se passerait-il sans ?
4. Recherchez sur tout le système les fichiers portant le bit **SUID** *(indice : `find / -perm`)* et
   expliquez pourquoi cette liste est un **point d'audit** de sécurité.
5. Posez le SUID sur une copie de `/bin/bash` dans `/tmp`, constatez le danger, puis **supprimez-la
   immédiatement**. Qu'auriez-vous fait si vous aviez trouvé ce fichier sur un serveur en production ?

---

## Exercice 2.6 — Propriétaire et groupe

1. Donnez `/srv/ticketflow` à l'utilisateur `deploy` et au groupe `ops`, récursivement, en une commande.
2. Changez **uniquement le groupe** de `/var/log/ticketflow` en `adm`.
3. Un `git pull` lancé avec `sudo` a laissé des fichiers appartenant à root dans le *home* d'un développeur.
   Écrivez la commande qui répare la propriété de tout son *home*.
4. Copiez un fichier avec `cp` puis avec `cp -a` : que deviennent propriétaire, groupe, droits et dates ?
   Quelle option utilise-t-on pour une sauvegarde ?
5. Un utilisateur non privilégié peut-il donner un de ses fichiers à quelqu'un d'autre ? Pourquoi ?

---

## Exercice 2.7 — `umask`

1. Affichez votre `umask` courant. Quels droits obtient un **fichier** nouvellement créé ? Un **dossier** ?
2. Vérifiez-le en créant les deux et en lisant leurs droits.
3. Passez le `umask` à `027` et refaites l'essai. Qu'est-ce que ça change pour « les autres » ?
4. Où faut-il écrire cette valeur pour qu'elle s'applique **à tous les utilisateurs** à chaque connexion ?
   *(Voir aussi le chapitre [10](../../10_shell_config.md).)*
5. Pourquoi un `umask` à `002` est-il fréquent sur un serveur de travail collaboratif, et dangereux ailleurs ?

---

## ✅ Vérification

- Vous traduisez `rwxr-x---` ↔ `750` dans les deux sens, sans table de correspondance.
- `/srv/projet` a le SGID **et** le sticky bit, et vous l'avez prouvé avec deux comptes.
- `/srv/ticketflow` a des dossiers en `750` et des fichiers en `640` — pas l'inverse.
- Vous savez produire la liste des binaires SUID de la machine et dire pourquoi on la surveille.
- Aucune copie de shell SUID ne traîne dans `/tmp`.
