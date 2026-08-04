# 05 · Sécurité

> [!NOTE]
> **Objectifs du chapitre**
> - Aller au-delà des permissions POSIX avec les **ACL**
> - Déléguer finement des droits d'administration via **sudoers**
> - Filtrer le trafic réseau avec un **pare-feu** (`ufw`, `firewalld`, `iptables`, `nftables`)
> - Configurer, durcir et diagnostiquer un accès **SSH** par clés
> - Confiner les services avec le contrôle d'accès obligatoire (**AppArmor / SELinux**)

Ce chapitre couvre les quatre couches qui se superposent sur un serveur Linux. Elles ne se remplacent pas, elles s'empilent :

```text
┌──────────────────────────────────────────────────────────────┐
│  MAC        AppArmor / SELinux   → ce qu'un processus peut    │
│                                    faire, même en root        │
├──────────────────────────────────────────────────────────────┤
│  Privilèges sudo / sudoers       → qui peut devenir qui       │
├──────────────────────────────────────────────────────────────┤
│  Fichiers   POSIX + ACL          → qui peut lire quoi         │
├──────────────────────────────────────────────────────────────┤
│  Réseau     ufw / nftables       → qui peut atteindre la      │
│             SSH                    machine, et comment        │
└──────────────────────────────────────────────────────────────┘
```

## Sommaire

1. [ACL (Access Control Lists)](#acl-access-control-lists)
   - [Prérequis et vérifications](#prérequis-et-vérifications)
   - [Lire une ACL en détail](#lire-une-acl-en-détail)
   - [Modifier les ACL](#modifier-les-acl)
   - [Le mask, en détail](#le-mask-en-détail)
   - [ACL par défaut et héritage](#acl-par-défaut-et-héritage)
   - [Cas pratique : un dossier d'équipe](#cas-pratique--un-dossier-déquipe)
   - [Sauvegarder, copier et migrer des ACL](#sauvegarder-copier-et-migrer-des-acl)
   - [Diagnostic ACL](#diagnostic-acl)
2. [Sudo / sudoers](#sudo--sudoers)
   - [Utilisation quotidienne](#utilisation-quotidienne)
   - [Éditer le sudoers sans se verrouiller](#éditer-le-sudoers-sans-se-verrouiller)
   - [Anatomie du fichier](#anatomie-du-fichier)
   - [La syntaxe d'une règle](#la-syntaxe-dune-règle)
   - [Les tags](#les-tags)
   - [Les Defaults](#les-defaults)
   - [Les alias](#les-alias)
   - [sudoedit — éditer un fichier protégé, proprement](#sudoedit--éditer-un-fichier-protégé-proprement)
   - [Cas pratiques complets](#cas-pratiques-complets)
   - [Les pièges de sécurité](#les-pièges-de-sécurité)
   - [Audit et journalisation](#audit-et-journalisation)
   - [Diagnostic sudo](#diagnostic-sudo)
3. [Firewall](#firewall)
   - [Les concepts communs](#les-concepts-communs)
   - [ufw (Debian, Ubuntu)](#ufw-debian-ubuntu)
   - [firewalld (RHEL, Fedora)](#firewalld-rhel-fedora)
   - [iptables](#iptables)
   - [nftables](#nftables)
   - [Tester et diagnostiquer](#tester-et-diagnostiquer-un-pare-feu)
4. [SSH](#ssh)
   - [Installation et vérification](#installation-et-vérification)
   - [Les deux fichiers de configuration](#les-deux-fichiers-de-configuration)
   - [Gestion des clés](#gestion-des-clés)
   - [Déployer sa clé publique](#déployer-sa-clé-publique)
   - [Durcir le serveur : sshd_config](#durcir-le-serveur--sshd_config)
   - [Les blocs Match](#les-blocs-match)
   - [Restreindre une clé dans authorized_keys](#restreindre-une-clé-dans-authorized_keys)
   - [Configurer le client : ~/.ssh/config](#configurer-le-client--sshconfig)
   - [known_hosts et empreintes](#known_hosts-et-empreintes)
   - [L'agent SSH](#lagent-ssh)
   - [Tunnels et rebonds](#tunnels-et-rebonds)
   - [Transférer des fichiers](#transférer-des-fichiers)
   - [fail2ban](#fail2ban)
   - [Diagnostic SSH](#diagnostic-ssh)
5. [AppArmor / SELinux](#apparmor--selinux)
   - [AppArmor (Debian, Ubuntu, SUSE)](#apparmor-debian-ubuntu-suse)
   - [SELinux (RHEL, Fedora, CentOS, Rocky)](#selinux-rhel-fedora-centos-rocky)
   - [Méthode de diagnostic](#méthode-de-diagnostic)
6. [Récapitulatif](#récapitulatif)

---

## ACL (Access Control Lists)

Les permissions POSIX ne connaissent que trois cibles :

```text
 Owner   Group   Other
 rwx     rwx     rwx
```

Cela suffit tant que les besoins sont simples. Mais dès qu'on veut *« Alice peut écrire, Bob peut seulement lire, l'équipe dev peut lire, et personne d'autre ne voit rien »*, il faudrait créer un groupe par combinaison de droits. C'est exactement le problème que résolvent les **ACL** : accorder des droits à **un utilisateur précis** ou à **un groupe précis**, en plus du propriétaire et du groupe propriétaire.

### Prérequis et vérifications

**1. Les outils** — ils ne sont pas toujours installés :

```bash
sudo apt install acl          # Debian / Ubuntu
sudo dnf install acl          # RHEL / Fedora
```

**2. Le système de fichiers doit supporter les ACL.** C'est le cas par défaut d'ext4 et de XFS sur les distributions modernes, mais cela se vérifie :

```bash
# Pour ext2/3/4
sudo tune2fs -l /dev/sda1 | grep "Default mount options"
```

```text
Default mount options:    user_xattr acl
```

```bash
# Vérifier les options de montage effectives
mount | grep " / "
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS /
```

Si l'option `acl` est absente, il faut l'ajouter dans `/etc/fstab` :

```text
# /etc/fstab
UUID=xxxx-xxxx  /srv  ext4  defaults,acl  0  2
```

```bash
sudo mount -o remount /srv
```

**3. Test rapide** — si le système de fichiers ne supporte pas les ACL, `setfacl` échoue explicitement :

```bash
setfacl -m u:nobody:r /tmp/test.txt
```

```text
setfacl: /tmp/test.txt: Operation not supported
```

### Lire une ACL en détail

```bash
getfacl hello.txt
```

```text
# file: hello.txt              ← le fichier concerné
# owner: debian                ← propriétaire POSIX
# group: debian                ← groupe propriétaire POSIX
user::rw-                      ← droits du propriétaire (= le "u" de ls -l)
user:alice:rw-                 ← ENTRÉE NOMMÉE : droits spécifiques d'alice
group::r--                     ← droits du groupe propriétaire (= le "g" de ls -l)
group:dev:r-x                  ← ENTRÉE NOMMÉE : droits spécifiques du groupe dev
mask::rwx                      ← plafond appliqué aux entrées nommées et au groupe
other::r--                     ← droits des autres (= le "o" de ls -l)
```

| Type de ligne | Sens |
|---------------|------|
| `user::` | Le propriétaire — **jamais** limité par le mask |
| `user:nom:` | Un utilisateur nommé — soumis au mask |
| `group::` | Le groupe propriétaire — soumis au mask |
| `group:nom:` | Un groupe nommé — soumis au mask |
| `mask::` | Le plafond des droits effectifs |
| `other::` | Tous les autres — **jamais** limité par le mask |
| `default:…` | Une ACL héritée par les éléments créés dans le dossier |

### Repérer qu'un fichier porte des ACL

```bash
ls -la hello.txt
```

```text
-rw-r-xr--+ 1 debian debian   378 Dec 12 10:29 hello.txt
```

> [!TIP]
> Le petit **`+`** en fin de permissions signale des droits supplémentaires aux POSIX classiques. C'est le **seul** indice visible dans un `ls` — d'où l'importance de vérifier avec `getfacl` quand un fichier se comporte « bizarrement ».
>
> Piège de lecture supplémentaire : quand une ACL est présente, la colonne des droits du groupe dans `ls -l` n'affiche plus les droits du groupe propriétaire, mais **le mask**. Un `ls` peut donc annoncer `rwx` là où le groupe n'a réellement que `r--`.

Trouver tous les fichiers porteurs d'ACL dans une arborescence :

```bash
getfacl -R -s /srv 2>/dev/null | grep "^# file:"
```

### Modifier les ACL

La syntaxe générale est :

```text
setfacl [-R] -m  <type>:<nom>:<droits>  <cible>
         │    │      │      │      │
         │    │      │      │      └─ rwx, rw, r, ou - pour rien
         │    │      │      └──────── vide pour le propriétaire / groupe propriétaire
         │    │      └─────────────── u (user), g (group), m (mask), o (other)
         │    └────────────────────── -m modifie, -x retire, -b efface tout
         └─────────────────────────── récursif
```

| Commande | Effet |
|----------|-------|
| `setfacl -m u:alice:rw f` | Donner `rw` à l'utilisateur alice |
| `setfacl -m g:dev:rx f` | Donner `rx` au groupe dev |
| `setfacl -m o::--- f` | Retirer tout droit aux autres |
| `setfacl -m m:r f` | Fixer le mask à `r` |
| `setfacl -x u:alice f` | Retirer l'entrée d'alice |
| `setfacl -b f` | Supprimer **toutes** les ACL (retour au POSIX pur) |
| `setfacl -k d/` | Supprimer uniquement les ACL **par défaut** |
| `setfacl -R -m …` | Appliquer récursivement |
| `setfacl -d -m u:alice:rw d/` | Poser une ACL **par défaut** (héritage) |

#### 1. Donner des droits à un utilisateur

```bash
setfacl -m u:test:rw hello.txt
```

```bash
getfacl hello.txt
```

```text
# file: hello.txt
# owner: debian
# group: debian
user::rw-
user:test:rw-
group::r--
mask::rw-
other::r--
```

#### 2. Donner des droits à un groupe

```bash
setfacl -m g:test:rx hello.txt
```

```text
# file: hello.txt
# owner: debian
# group: debian
user::rw-
group::r--
group:test:r-x
mask::r-x
other::r--
```

#### 3. Plusieurs entrées en une commande

Les entrées se séparent par des virgules :

```bash
setfacl -m u:alice:rw,u:bob:r,g:dev:rx rapport.txt
```

#### 4. Appliquer récursivement

```bash
setfacl -R -m u:test:rX dossier/
```

> [!TIP]
> Notez le **`X` majuscule** : il accorde le droit d'exécution **uniquement aux dossiers** (et aux fichiers qui sont déjà exécutables). C'est exactement ce qu'on veut en récursif — sans lui, `-R -m u:test:rx` rendrait exécutables tous les fichiers de données de l'arborescence.

#### 5. Retirer des droits

```bash
setfacl -x u:test hello.txt      # retirer une entrée précise
setfacl -b hello.txt             # tout effacer, retour au POSIX pur
```

### Le mask, en détail

C'est le point qui déroute tout le monde, et la première cause d'ACL « qui ne marchent pas ».

Le `mask` est un **plafond** appliqué à toutes les entrées nommées (`user:nom`, `group:nom`) **et** au groupe propriétaire. Il ne s'applique **ni** au propriétaire (`user::`) **ni** aux autres (`other::`).

```text
Droit effectif  =  droit accordé  ET  mask
```

```bash
setfacl -m u:test:rwx test.sh
setfacl -m m:r test.sh
getfacl test.sh
```

```text
# file: test.sh
# owner: debian
# group: debian
user::rwx
user:test:rwx                   #effective:r--     ← le mask a tranché
group::r-x                      #effective:r--
mask::r--
other::---
```

`getfacl` est explicite : il affiche `#effective:` à côté de chaque entrée bridée par le mask. L'utilisateur `test` a beau avoir `rwx` inscrit, il ne peut que **lire**.

> [!CAUTION]
> **`chmod` recalcule le mask.** C'est le piège classique, et il est silencieux :
>
> ```bash
> setfacl -m u:alice:rwx projet/     # alice a rwx
> chmod g-w projet/                  # on croit ne toucher qu'au groupe...
> getfacl projet/                    # ...mais le mask est passé à r-x
> ```
>
> `chmod` sur les droits du **groupe** modifie en réalité le **mask** quand des ACL sont présentes. Les droits d'alice tombent avec lui. Après tout `chmod` sur un fichier porteur d'ACL, vérifiez le mask :
>
> ```bash
> setfacl -m m:rwx projet/           # rétablir le plafond
> ```

Par défaut, `setfacl` recalcule automatiquement le mask pour qu'il englobe toutes les entrées. Pour l'en empêcher :

```bash
setfacl -n -m u:alice:rwx fichier    # -n : ne pas recalculer le mask
```

### ACL par défaut et héritage

Les ACL par défaut (`default:`, ou l'option `-d`) ne s'appliquent **qu'aux dossiers**. Elles ne donnent aucun droit sur le dossier lui-même : elles définissent les ACL que recevront automatiquement les éléments **créés à l'intérieur**.

```bash
setfacl -d -m u:test:rw shared/
setfacl -d -m g:dev:rwx shared/
```

Ou avec la syntaxe explicite :

```bash
setfacl -m d:u:test:rw shared/
setfacl -m d:g:dev:rwx shared/
```

```bash
getfacl shared/
```

```text
# file: shared
# owner: debian
# group: dev
user::rwx
group::r-x
other::---
default:user::rwx
default:user:test:rw-
default:group::r-x
default:group:dev:rwx
default:mask::rwx
default:other::---
```

Vérifions l'héritage :

```bash
touch shared/nouveau.txt
getfacl shared/nouveau.txt
```

```text
# file: shared/nouveau.txt
# owner: debian
# group: dev
user::rw-
user:test:rw-
group::r-x                      #effective:r--
group:dev:rwx                   #effective:rw-
mask::rw-
other::---
```

> [!IMPORTANT]
> Trois points à connaître sur l'héritage :
> 1. Il ne s'applique **qu'aux nouveaux** fichiers. Les fichiers déjà présents ne sont pas modifiés — il faut un `setfacl -R` pour eux.
> 2. Un **sous-dossier** créé hérite à la fois des ACL d'accès **et** des ACL par défaut : l'héritage se propage en profondeur.
> 3. Un fichier n'obtient jamais le droit `x` par héritage s'il n'est pas créé exécutable ; le mask s'ajuste en conséquence (`rwx` par défaut devient `rw-` effectif ci-dessus).

Supprimer les ACL par défaut d'un dossier :

```bash
setfacl -k shared/
```

### Cas pratique : un dossier d'équipe

C'est *le* cas d'usage des ACL. L'objectif :

> Un dossier `/srv/projet` où l'équipe **dev** travaille à plusieurs. Tout fichier créé par n'importe qui doit être immédiatement modifiable par toute l'équipe. L'équipe **qa** peut lire. Personne d'autre ne voit quoi que ce soit.

```bash
# 1. Les groupes
sudo groupadd dev
sudo groupadd qa
sudo usermod -aG dev alice
sudo usermod -aG dev bob
sudo usermod -aG qa carol

# 2. Le dossier, propriété du groupe dev
sudo mkdir -p /srv/projet
sudo chgrp dev /srv/projet
sudo chmod 2770 /srv/projet
```

Le `2` de `2770` est le **SGID** : tout fichier créé dans le dossier appartiendra au groupe `dev` et non au groupe primaire de son créateur. C'est le complément indispensable des ACL par défaut (voir le [chapitre 02](02_file_permissions.md#sgid-sur-un-dossier)).

```bash
# 3. Les ACL d'accès : ce que chacun peut faire sur le dossier lui-même
sudo setfacl -m g:dev:rwx /srv/projet
sudo setfacl -m g:qa:rx  /srv/projet

# 4. Les ACL par défaut : ce dont hériteront les nouveaux fichiers
sudo setfacl -d -m g:dev:rwx /srv/projet
sudo setfacl -d -m g:qa:rx   /srv/projet
sudo setfacl -d -m o::---    /srv/projet
```

Vérification :

```bash
getfacl /srv/projet
```

```text
# file: srv/projet
# owner: root
# group: dev
# flags: -s-                    ← le SGID est bien posé
user::rwx
group::rwx
group:dev:rwx
group:qa:r-x
mask::rwx
other::---
default:user::rwx
default:group::rwx
default:group:dev:rwx
default:group:qa:r-x
default:mask::rwx
default:other::---
```

Test grandeur nature :

```bash
sudo -u alice touch /srv/projet/fichier_alice.txt
getfacl /srv/projet/fichier_alice.txt
```

```text
# file: srv/projet/fichier_alice.txt
# owner: alice
# group: dev                     ← grâce au SGID
user::rw-
group::rwx                       #effective:rw-
group:dev:rwx                    #effective:rw-   ← bob peut modifier
group:qa:r-x                     #effective:r--   ← carol peut lire
mask::rw-
other::---                       ← personne d'autre
```

### Sauvegarder, copier et migrer des ACL

**Sauvegarder les ACL d'une arborescence** — à faire avant toute manipulation risquée :

```bash
getfacl -R /srv/projet > /root/acl-projet.bak
```

**Restaurer** :

```bash
setfacl --restore=/root/acl-projet.bak
```

**Copier les ACL d'un fichier vers un autre** :

```bash
getfacl source.txt | setfacl --set-file=- destination.txt
```

**Préserver les ACL lors des copies et sauvegardes** — les outils ne le font *pas* par défaut :

| Outil | Option requise |
|-------|----------------|
| `cp` | `cp -p` ou `cp --preserve=all` |
| `rsync` | `rsync -A` (et `-X` pour les attributs étendus) |
| `tar` | `tar --acls` |
| `mv` | Rien à faire — les ACL suivent le fichier sur le même système de fichiers |

```bash
rsync -avAX /srv/projet/ /mnt/backup/projet/
tar --acls -czvf projet.tar.gz /srv/projet
```

> [!WARNING]
> Une sauvegarde faite sans `-A` / `--acls` restaure des fichiers aux permissions POSIX seules. Le jour de la restauration, la structure de droits patiemment construite a disparu — et personne ne s'en aperçoit avant que quelqu'un se plaigne d'un accès refusé.

### Diagnostic ACL

Une ACL qui ne produit pas l'effet attendu vient presque toujours de l'une de ces cinq causes :

| Symptôme | Cause probable | Vérification |
|----------|----------------|--------------|
| `Operation not supported` | Le système de fichiers n'est pas monté avec `acl` | `findmnt -o OPTIONS /srv` |
| L'utilisateur ne peut pas écrire malgré `rw` | Le **mask** plafonne le droit | `getfacl f \| grep effective` |
| Le droit a disparu après un `chmod` | `chmod` a recalculé le mask | `setfacl -m m:rwx f` |
| L'utilisateur ne peut pas **atteindre** le fichier | Il manque le droit `x` sur un **dossier parent** | `namei -l /srv/projet/fichier.txt` |
| Les nouveaux fichiers n'héritent pas | ACL par défaut absente, ou fichiers créés avant | `getfacl d/ \| grep default` |

La commande la plus utile pour le quatrième cas :

```bash
namei -l /srv/projet/docs/rapport.txt
```

```text
f: /srv/projet/docs/rapport.txt
 drwxr-xr-x root  root  /
 drwxr-xr-x root  root  srv
 drwxrws---+ root dev   projet
 drwx------  root root  docs        ← le blocage est ici
 -rw-rw----+ alice dev  rapport.txt
```

`namei -l` déroule le chemin dossier par dossier et montre immédiatement où l'accès casse. Un droit parfait sur le fichier ne sert à rien si un dossier parent interdit la traversée.

### Récapitulatif ACL

| Commande | Effet |
|----------|-------|
| `getfacl f` | Lire les ACL |
| `getfacl -R d/ > f.bak` | Sauvegarder une arborescence |
| `setfacl --restore=f.bak` | Restaurer |
| `setfacl -m u:user:rw f` | Ajouter/modifier une entrée utilisateur |
| `setfacl -m g:group:rx f` | Ajouter/modifier une entrée groupe |
| `setfacl -R -m u:user:rX d/` | Récursif, `X` = exécution sur les dossiers seulement |
| `setfacl -d -m g:dev:rwx d/` | ACL par défaut (héritage) |
| `setfacl -m m:rwx f` | Fixer le mask |
| `setfacl -x u:user f` | Retirer une entrée |
| `setfacl -b f` / `-k d/` | Tout effacer / effacer les ACL par défaut |
| `namei -l /chemin/fichier` | Trouver où un chemin bloque |

---

## Sudo / sudoers

`sudo` (*super user do*) permet d'exécuter une commande en tant qu'un autre utilisateur (`root` par défaut), après authentification avec **son propre** mot de passe.

C'est ce dernier point qui en fait l'outil central de l'administration : contrairement à `su`, personne n'a besoin de connaître le mot de passe root, chaque action est tracée nominativement, et on peut retirer les droits d'une personne sans changer le mot de passe de tout le monde.

### Utilisation quotidienne

```bash
sudo cat /var/log/syslog
```

| Commande | Effet |
|----------|-------|
| `sudo commande` | Exécuter en tant que root |
| `sudo -u alice commande` | Exécuter en tant qu'un autre utilisateur |
| `sudo -g dev commande` | Exécuter avec un autre groupe |
| `sudo -i` | Ouvrir un shell de login root (charge l'environnement de root) |
| `sudo -s` | Ouvrir un shell root en conservant l'environnement courant |
| `sudo -E commande` | Préserver les variables d'environnement |
| `sudo -l` | **Lister ce que j'ai le droit de faire** |
| `sudo -k` | Oublier l'authentification en cache (re-demander le mot de passe) |
| `sudo -v` | Prolonger le cache d'authentification |
| `sudo !!` | Rejouer la commande précédente avec sudo |

La commande la plus utile pour comprendre ses droits :

```bash
sudo -l
```

```text
Matching Defaults entries for alice on serveur:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User alice may run the following commands on serveur:
    (root) /usr/bin/systemctl restart apache2
    (root) NOPASSWD: /usr/local/bin/deploy.sh
```

```bash
sudo -l -U bob        # en tant qu'admin : lister les droits d'un autre utilisateur
```

> [!NOTE]
> Si `/var/log/syslog` n'existe pas, c'est que `rsyslog` n'est pas installé :
> ```bash
> sudo apt install rsyslog
> ```

Par défaut, il faut appartenir au groupe `sudo` (Debian/Ubuntu) ou `wheel` (RHEL/Fedora) pour pouvoir utiliser `sudo`.

```bash
sudo usermod -aG sudo alice        # Debian
sudo usermod -aG wheel alice       # RHEL
```

> [!IMPORTANT]
> L'ajout à un groupe ne prend effet qu'à la **prochaine session**. Alice doit se déconnecter et se reconnecter — ou lancer `newgrp sudo` — avant que `sudo` fonctionne pour elle.

### Éditer le sudoers sans se verrouiller

> [!CAUTION]
> **N'éditez jamais `/etc/sudoers` directement avec un éditeur.** Une erreur de syntaxe dans ce fichier rend `sudo` totalement inutilisable, et vous verrouille hors de tout accès administrateur sur une machine où root n'a pas de mot de passe (cas par défaut d'Ubuntu).
>
> ```bash
> sudo visudo
> ```
>
> `visudo` verrouille le fichier contre les éditions concurrentes et **valide la syntaxe avant d'enregistrer**. En cas d'erreur, il propose de rééditer plutôt que d'écrire un fichier cassé.

Choisir son éditeur :

```bash
sudo EDITOR=nano visudo
sudo update-alternatives --config editor    # changer le défaut sur Debian
```

Vérifier un fichier sans l'éditer :

```bash
sudo visudo -c
```

```text
/etc/sudoers: parsed OK
/etc/sudoers.d/deploiement: parsed OK
```

**La bonne pratique : ne touchez pas à `/etc/sudoers`.** Déposez vos règles dans un fichier dédié sous `/etc/sudoers.d/`, ce qui les rend lisibles, réversibles et déployables par configuration management :

```bash
sudo visudo -f /etc/sudoers.d/equipe_web
```

```text
# /etc/sudoers.d/equipe_web
# Géré par Ansible — ne pas éditer à la main
%webops ALL=(root) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx
```

```bash
sudo chmod 0440 /etc/sudoers.d/equipe_web
```

> [!WARNING]
> Deux règles sur `/etc/sudoers.d/` :
> - Le fichier doit être en **0440** et appartenir à root, sinon sudo l'ignore silencieusement.
> - Les fichiers dont le nom contient un `.` ou se termine par `~` sont **ignorés**. Nommez `equipe_web`, pas `equipe_web.conf`.

### Anatomie du fichier

```text
# /etc/sudoers

# ── Defaults : le comportement global de sudo ──────────────────────
Defaults        env_reset
Defaults        mail_badpass
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ── Alias : des raccourcis nommés ─────────────────────────────────
User_Alias      ADMINS = alice, bob
Cmnd_Alias      SERVICES = /usr/bin/systemctl

# ── Règles utilisateurs ───────────────────────────────────────────
root            ALL=(ALL:ALL) ALL

# ── Règles de groupes (préfixés par %) ────────────────────────────
%sudo           ALL=(ALL:ALL) ALL
%admin          ALL=(ALL) ALL

# ── Inclusion du dossier de fragments — TOUJOURS EN DERNIER ───────
@includedir /etc/sudoers.d
```

> [!IMPORTANT]
> **L'ordre compte : la dernière règle qui correspond l'emporte.** Si un utilisateur est couvert par plusieurs règles, c'est la plus basse dans le fichier qui s'applique. C'est pour cela que `@includedir /etc/sudoers.d` est en dernière ligne : vos fragments peuvent ainsi surcharger les règles générales.
>
> (Sur les versions plus anciennes, la directive s'écrit `#includedir /etc/sudoers.d` — et le `#` n'est **pas** un commentaire ici.)

### La syntaxe d'une règle

```text
alice    serveur1 = (root:web) NOPASSWD: /usr/bin/systemctl restart nginx
  │         │         │   │        │                    │
  │         │         │   │        │                    └─ COMMANDES autorisées
  │         │         │   │        └─────────────────────── TAGS (optionnels)
  │         │         │   └──────────────────────────────── groupe cible (optionnel)
  │         │         └──────────────────────────────────── utilisateur cible
  │         └────────────────────────────────────────────── HÔTES où la règle s'applique
  └──────────────────────────────────────────────────────── QUI (% = un groupe)
```

La règle canonique, celle du groupe `sudo` :

```text
%sudo   ALL=(ALL:ALL)   ALL
```

Elle se lit : *« les membres du groupe `sudo`, depuis n'importe quel hôte, peuvent devenir n'importe quel utilisateur et n'importe quel groupe, pour exécuter n'importe quelle commande »*.

#### Restreindre l'identité empruntable

```text
test  ALL=(debian)    ALL
```

`test` peut tout faire, mais uniquement sous l'identité de `debian` — pas de root :

```bash
sudo -u debian commande     # ✅ autorisé
sudo commande               # ❌ refusé (cible = root)
```

#### Restreindre les commandes

```text
test ALL=(root)   /usr/bin/systemctl
```

`test` ne peut utiliser que `systemctl` en tant que root — mais **avec n'importe quel argument**, y compris `systemctl stop firewalld`.

```text
test ALL=(root)   /usr/bin/systemctl restart apache2
```

Ici, la commande est figée **avec ses arguments** : il ne peut que redémarrer apache2.

```text
test ALL=(root)   /usr/bin/systemctl restart apache2, /usr/bin/systemctl status apache2
```

Plusieurs commandes se séparent par des virgules.

#### Interdire une commande

```text
test ALL=(devops) ALL, !/bin/rm
```

`test` peut emprunter l'identité de `devops` pour toutes les commandes, sauf `rm`.

> [!CAUTION]
> **Les listes noires ne fonctionnent pas.** `!/bin/rm` se contourne en trois secondes :
>
> ```bash
> sudo -u devops cp /bin/rm /tmp/r && sudo -u devops /tmp/r fichier
> sudo -u devops vim -c ':!rm fichier'
> sudo -u devops find . -exec rm {} \;
> ```
>
> Toute commande capable de lancer un shell, de copier un binaire ou d'exécuter un programme arbitraire annule la restriction. **Utilisez toujours une liste blanche** de commandes explicites, et vérifiez qu'aucune ne permet d'évasion.

### Les tags

Les tags modifient le comportement pour les commandes qui suivent, jusqu'à la fin de la règle.

| Tag | Effet |
|-----|-------|
| `NOPASSWD:` | Pas de mot de passe demandé |
| `PASSWD:` | Redemander le mot de passe (annule un `NOPASSWD:` précédent) |
| `NOEXEC:` | Empêcher la commande de lancer d'autres programmes |
| `SETENV:` | Autoriser à passer des variables d'environnement |
| `LOG_OUTPUT:` | Enregistrer la sortie de la commande |

```text
# Le déploiement est automatisé : pas de mot de passe pour ce script précis,
# mais le reste des droits reste protégé
deploy ALL=(root) NOPASSWD: /usr/local/bin/deploy.sh
deploy ALL=(root) PASSWD:   /usr/bin/systemctl restart nginx
```

> [!CAUTION]
> **`NOPASSWD` est à utiliser avec parcimonie.** Chaque entrée est une porte ouverte si le compte est compromis : plus besoin de connaître le mot de passe pour élever ses privilèges.
> Réservez-le à des commandes précises, non détournables, et typiquement à des comptes de service non interactifs. Un `NOPASSWD: ALL` équivaut à donner le mot de passe root.

Le tag `NOEXEC` mérite d'être connu — il neutralise les évasions de shell sur les commandes qui en permettent :

```text
alice ALL=(root) NOEXEC: /usr/bin/less /var/log/secure
```

Sans lui, `less` permettrait `!sh` et donnerait un shell root.

### Les Defaults

Les lignes `Defaults` pilotent le comportement de sudo lui-même.

```text
# Comportement de base
Defaults    env_reset                       # repartir d'un environnement propre
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults    mail_badpass                    # mail à l'admin en cas de mauvais mot de passe

# Durée du cache d'authentification, en minutes
Defaults    timestamp_timeout=15            # 0 = demander à chaque fois, -1 = jamais
Defaults    passwd_tries=3                  # nombre d'essais

# Journalisation
Defaults    logfile="/var/log/sudo.log"
Defaults    log_input, log_output           # enregistrement complet des sessions
Defaults    iolog_dir="/var/log/sudo-io"

# Confort
Defaults    pwfeedback                      # afficher des astérisques à la saisie
Defaults    editor="/usr/bin/vim"           # éditeur utilisé par sudoedit
Defaults    !visiblepw                      # refuser si le mot de passe s'afficherait en clair
```

Les `Defaults` peuvent être ciblés :

```text
Defaults:alice          timestamp_timeout=60      # pour l'utilisatrice alice
Defaults>root           !set_logname              # quand la cible est root
Defaults!/usr/bin/vim   NOEXEC                    # pour cette commande
Defaults@serveur-web    log_output                # sur cet hôte
```

> [!IMPORTANT]
> `env_reset` et `secure_path` sont des protections **essentielles** : elles empêchent un utilisateur de détourner une commande sudo en manipulant `PATH` ou `LD_PRELOAD`. Ne les désactivez pas pour « faire marcher » un script — passez plutôt le chemin absolu de la commande.

### Les alias

Les alias rendent le fichier lisible et maintenable quand le nombre de règles augmente.

**1. Les utilisateurs**

```text
User_Alias  ADMINS  = debian, bob
User_Alias  JUNIORS = carol, dave, %stagiaires
```

**2. Les hôtes**

```text
Host_Alias  SERVER_WEB = server1name, server2name
Host_Alias  SERVER_DB  = 192.168.1.20, 192.168.1.21
```

**3. Les commandes**

```text
Cmnd_Alias  MAINTENANCE = /usr/bin/apt, /usr/bin/systemctl
Cmnd_Alias  LECTURE_LOG = /usr/bin/journalctl, /usr/bin/less /var/log/*
Cmnd_Alias  RESEAU      = /usr/sbin/ip, /usr/bin/ss, /usr/sbin/tcpdump
```

**4. Les identités cibles**

```text
Runas_Alias  SERVICES = www-data, postgres, redis
```

Assemblés :

```text
ADMINS   SERVER_WEB = (root)     MAINTENANCE
JUNIORS  SERVER_WEB = (root)     LECTURE_LOG
ADMINS   SERVER_DB  = (SERVICES) ALL
```

### sudoedit — éditer un fichier protégé, proprement

C'est la fonctionnalité la plus sous-utilisée de sudo, et pourtant la bonne réponse à un besoin très courant : *modifier un fichier appartenant à root, avec **mon** éditeur et **ma** configuration, sans donner les droits root à cet éditeur.*

```bash
sudoedit /etc/nginx/nginx.conf
```

```bash
sudo -e /etc/nginx/nginx.conf      # syntaxe équivalente
```

**Ce qui se passe réellement :**

```text
1. sudo copie /etc/nginx/nginx.conf vers un fichier temporaire
2. Il vous en donne la propriété
3. Il lance VOTRE éditeur, avec VOTRE utilisateur et VOTRE configuration
   → pas de droits root sur l'éditeur, ni sur ses plugins
4. À la fermeture, si le fichier a changé, sudo recopie le temporaire
   à sa place d'origine, avec les droits et le propriétaire d'origine
5. Toute l'opération est journalisée
```

**Pourquoi c'est important**, comparé à `sudo vim /etc/nginx/nginx.conf` :

| | `sudo vim fichier` | `sudoedit fichier` |
|---|---|---|
| Utilisateur de l'éditeur | **root** | vous |
| Configuration chargée | celle de **root** (`/root/.vimrc`) — pas la vôtre | **la vôtre** (`~/.vimrc`, `~/.config/nvim/`) |
| Plugins exécutés | en root | avec vos droits |
| Fichier temporaire d'échange (`.swp`) | écrit en root, parfois là où il ne faut pas | dans votre espace |
| Droit sudo nécessaire | `ALL` ou l'éditeur entier | `sudoedit /chemin/precis` |

> [!IMPORTANT]
> **Le cas de la configuration personnalisée.** Si vous utilisez Neovim avec une configuration élaborée (LSP, plugins, thème), `sudo nvim` ne la charge pas : root a son propre `$HOME`, donc sa propre configuration — le plus souvent inexistante. Vous vous retrouvez dans un vi nu au pire moment.
>
> La tentation est alors de faire `sudo -E nvim` pour conserver `$HOME`, ou pire, de rendre `/root/.config` symlink vers le vôtre. **C'est exactement ce qu'il ne faut pas faire** : vous faites alors exécuter **en root** des dizaines de milliers de lignes de plugins tiers, téléchargés depuis GitHub et mis à jour automatiquement. Un seul plugin compromis, et la machine l'est aussi.
>
> `sudoedit` résout le problème proprement : votre configuration complète, vos plugins, votre LSP — tout tourne sous votre utilisateur, et seule la recopie finale du fichier est privilégiée.

**Configurer l'éditeur utilisé** — `sudoedit` regarde, dans l'ordre, `$SUDO_EDITOR`, `$VISUAL`, `$EDITOR`, puis le `Defaults editor` du sudoers :

```bash
export SUDO_EDITOR=nvim        # dans ~/.bashrc ou ~/.zshrc
```

Côté sudoers, il faut autoriser explicitement les variables d'environnement de l'utilisateur, sinon `env_reset` les efface :

```text
Defaults  env_keep += "SUDO_EDITOR VISUAL EDITOR"
```

**Déléguer l'édition de fichiers précis** — c'est là que `sudoedit` prend tout son sens dans le sudoers. On donne le droit de modifier un fichier, pas le droit de lancer un éditeur en root :

```text
# L'équipe web peut modifier les vhosts, et rien d'autre
%webops ALL=(root) sudoedit /etc/nginx/sites-available/*

# Un développeur peut ajuster la configuration de son application
alice ALL=(root) sudoedit /etc/monapp/config.yml
```

```bash
sudo -l -U alice
```

```text
User alice may run the following commands on serveur:
    (root) sudoedit /etc/monapp/config.yml
```

> [!WARNING]
> Dans une règle sudoers, écrivez `sudoedit` **sans chemin** — c'est une pseudo-commande interne à sudo, pas un binaire à part entière. `/usr/bin/sudoedit` dans une règle ne fonctionne pas comme attendu.
>
> Attention aussi aux jokers : `sudoedit /etc/nginx/*` autorise `sudoedit /etc/nginx/../shadow` sur les versions anciennes de sudo. Restez sur des chemins précis, et maintenez sudo à jour.

### Cas pratiques complets

#### 1. Un opérateur qui ne gère que des services

```text
# /etc/sudoers.d/ops_services
Cmnd_Alias SVC_WEB = /usr/bin/systemctl start nginx,   \
                     /usr/bin/systemctl stop nginx,    \
                     /usr/bin/systemctl restart nginx, \
                     /usr/bin/systemctl reload nginx,  \
                     /usr/bin/systemctl status nginx

Cmnd_Alias SVC_LOG = /usr/bin/journalctl -u nginx *

%ops ALL=(root) SVC_WEB, SVC_LOG
```

#### 2. Un compte de déploiement automatisé

```text
# /etc/sudoers.d/deploy
# Compte non interactif utilisé par la CI — clé SSH restreinte côté authorized_keys
deploy ALL=(root) NOPASSWD: /usr/local/bin/deploy.sh
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart monapp

Defaults:deploy !requiretty
Defaults:deploy log_output
```

> [!CAUTION]
> Le script `/usr/local/bin/deploy.sh` doit impérativement appartenir à **root** et n'être modifiable que par root (`chown root:root`, `chmod 755`). S'il est modifiable par l'utilisateur `deploy`, celui-ci peut y écrire n'importe quoi et obtenir un shell root — la règle sudo devient un `NOPASSWD: ALL` déguisé.
>
> ```bash
> sudo chown root:root /usr/local/bin/deploy.sh
> sudo chmod 755 /usr/local/bin/deploy.sh
> ```

#### 3. Une équipe qui gère ses propres configurations

```text
# /etc/sudoers.d/equipe_app
%devs ALL=(root) sudoedit /etc/monapp/*.yml
%devs ALL=(root) /usr/bin/systemctl restart monapp
%devs ALL=(monapp) /bin/bash          # shell sous l'identité du service, pas root
```

#### 4. Un compte de sauvegarde

```text
# /etc/sudoers.d/backup
backup ALL=(root) NOPASSWD: /usr/bin/rsync --server --sender *
backup ALL=(root) NOPASSWD: /usr/bin/tar --acls -czf * /srv/data
```

### Les pièges de sécurité

> [!CAUTION]
> **1. Les jokers trop larges.** Un `*` dans une commande couvre bien plus que ce qu'on imagine :
>
> ```text
> alice ALL=(root) /usr/bin/chown * /var/www
> ```
>
> Cette règle autorise `sudo chown alice /etc /var/www` — le joker absorbe des arguments supplémentaires.


> [!CAUTION]
> **2. Les scripts modifiables.** Toute commande autorisée en sudo doit appartenir à root et n'être modifiable que par root — le binaire comme tous les dossiers de son chemin.

> [!CAUTION]
> **3. Les chemins relatifs.** Une règle doit toujours utiliser un chemin absolu. `alice ALL=(root) systemctl` (sans chemin) ne fonctionne pas et n'apporte aucune garantie.

Audit rapide des droits accordés sur une machine :

```bash
# Toutes les règles effectives, tous fichiers confondus
sudo grep -rvE '^\s*($|#)' /etc/sudoers /etc/sudoers.d/

# Les NOPASSWD, à revoir en priorité
sudo grep -rn "NOPASSWD" /etc/sudoers /etc/sudoers.d/

# Qui est dans le groupe sudo ?
getent group sudo wheel
```

### Audit et journalisation

Chaque utilisation de sudo est journalisée, réussie ou non.

```bash
sudo cat /var/log/auth.log            # Debian / Ubuntu
sudo cat /var/log/secure              # RHEL / Fedora
sudo journalctl -t sudo
sudo journalctl _COMM=sudo --since today
```

```text
Dec 12 09:31:01 serveur sudo:    alice : TTY=pts/0 ; PWD=/home/alice ;
  USER=root ; COMMAND=/usr/bin/systemctl restart nginx
Dec 12 09:33:22 serveur sudo:      bob : user NOT in sudoers ; TTY=pts/1 ;
  PWD=/home/bob ; USER=root ; COMMAND=/usr/bin/apt install htop
```

**L'enregistrement de session** est la fonctionnalité d'audit avancée : sudo peut enregistrer **tout ce qui a été tapé et affiché** pendant une commande, et le rejouer.

```text
Defaults  log_input, log_output
Defaults  iolog_dir="/var/log/sudo-io"
```

```bash
sudo sudoreplay -l                    # lister les sessions enregistrées
```

```text
Dec 12 10:15:03 2025 : alice : TTY=/dev/pts/0 ; CWD=/home/alice ;
  USER=root ; TSID=000001 ; COMMAND=/bin/bash
```

```bash
sudo sudoreplay 000001                # rejouer la session, en temps réel
sudo sudoreplay -s 10 000001          # rejouer 10× plus vite
```

> [!TIP]
> C'est extrêmement utile en formation et en post-mortem d'incident : on voit exactement ce qui a été fait, dans l'ordre, y compris les fautes de frappe. À déployer au moins sur les comptes disposant d'un shell root.

### Diagnostic sudo

| Message / symptôme | Cause | Correction |
|--------------------|-------|------------|
| `alice is not in the sudoers file` | Pas membre de `sudo`/`wheel`, aucune règle | `usermod -aG sudo alice` puis reconnexion |
| `Sorry, user alice is not allowed to execute …` | La commande ne correspond à aucune règle | `sudo -l` pour voir ce qui est autorisé ; vérifier le chemin absolu et les arguments |
| `sudo: no tty present and no askpass program` | Exécution non interactive (cron, CI) sans `NOPASSWD` | Ajouter `NOPASSWD:` pour cette commande précise |
| `sudo: /etc/sudoers.d/xxx is mode 0644, should be 0440` | Mauvaises permissions — le fichier est **ignoré** | `chmod 0440` et `chown root:root` |
| La commande marche à la main mais pas via sudo | `secure_path` remplace votre `PATH` | Utiliser le chemin absolu de la commande |
| `sudo: unable to resolve host serveur` | Le nom d'hôte n'est pas dans `/etc/hosts` | Ajouter `127.0.1.1 serveur` dans `/etc/hosts` |

**Se sortir d'un sudoers cassé** — par ordre de préférence :

```bash
# 1. Une session root est encore ouverte quelque part : réparer immédiatement
visudo -c && visudo

# 2. pkexec, s'il est installé (PolicyKit, indépendant de sudo)
pkexec visudo

# 3. Le compte root a un mot de passe
su -

# 4. Dernier recours : redémarrer en mode rescue depuis GRUB
#    (ajouter "init=/bin/bash" aux paramètres du noyau, puis remonter / en rw)
mount -o remount,rw /
visudo
```

> [!TIP]
> **Le réflexe qui évite tout cela :** avant de modifier un sudoers sur une machine distante, ouvrez une **seconde session SSH en root** et laissez-la ouverte. Si vous cassez quelque chose, vous avez encore un accès pour réparer. C'est le même réflexe que pour SSH et le pare-feu — on y revient dans les sections suivantes.

### Récapitulatif sudo

| Commande | Rôle |
|----------|------|
| `sudo -l` | Lister ses propres droits |
| `sudo -l -U bob` | Lister les droits d'un autre |
| `sudo -u alice cmd` | Exécuter sous une autre identité |
| `sudo -i` / `sudo -s` | Shell root (login / non-login) |
| `sudoedit fichier` | Éditer un fichier protégé avec **son propre** éditeur |
| `visudo` | Éditer `/etc/sudoers` en sécurité |
| `visudo -c` | Valider la syntaxe |
| `visudo -f /etc/sudoers.d/x` | Créer un fragment de règles |
| `sudoreplay -l` / `sudoreplay ID` | Lister / rejouer une session enregistrée |
| `journalctl -t sudo` | Consulter les logs |

---

## Firewall

Un pare-feu filtre le trafic réseau en définissant des règles qui déterminent ce qui peut passer ou non.

Sous Linux, quatre outils cohabitent — mais ils ne sont pas au même niveau :

| Outil | Rôle |
|-------|------|
| **netfilter** | Le moteur de filtrage, **dans le noyau**. Aucun des outils ci-dessous ne le remplace : ils le pilotent. |
| **iptables** | L'interface historique de netfilter |
| **nftables** | La nouvelle interface officielle, qui remplace iptables |
| **ufw** | Une surcouche simplifiée à iptables/nftables, sur les systèmes Debian |
| **firewalld** | L'équivalent d'ufw sur les systèmes RedHat, avec la notion de zones |

> [!TIP]
> En pratique : on utilise `ufw` (Debian) ou `firewalld` (RHEL) au quotidien, et on ne descend au niveau `nftables` que pour des règles que la surcouche ne sait pas exprimer. Il faut néanmoins savoir lire une règle `iptables` : c'est ce que produisent la plupart des documentations, des scripts anciens et de Docker.

### Les concepts communs

Quel que soit l'outil, quatre notions reviennent.

**1. Le sens du trafic** — trois chaînes principales :

```text
                    ┌──────────────┐
   Internet ──────► │    INPUT     │ ──► processus locaux
                    ├──────────────┤
   processus ─────► │   OUTPUT     │ ──► Internet
                    ├──────────────┤
   Internet ──────► │   FORWARD    │ ──► autre machine (routage, Docker, VPN)
                    └──────────────┘
```

Sur un serveur classique, **c'est `INPUT` qui compte** : c'est là qu'on décide qui peut atteindre la machine.

**2. La politique par défaut** — ce qui arrive à un paquet qui ne correspond à aucune règle :

| Politique | Signification |
|-----------|---------------|
| `ACCEPT` / `allow` | Tout ce qui n'est pas interdit est autorisé — **liste noire**, à proscrire |
| `DROP` / `deny` | Le paquet est jeté silencieusement — **liste blanche**, la bonne approche |
| `REJECT` | Le paquet est refusé avec un message d'erreur ICMP |

> [!IMPORTANT]
> `DROP` ou `REJECT` ? `DROP` ne répond rien : le client attend jusqu'au timeout, ce qui ralentit les scanners mais aussi vos propres diagnostics. `REJECT` répond immédiatement « connexion refusée », ce qui est plus courtois et plus lisible.
> Convention courante : `DROP` vers Internet, `REJECT` sur le réseau interne.

**3. L'ordre des règles.** Les règles sont évaluées **de haut en bas**, et la **première** qui correspond décide. Une règle d'autorisation placée après un `DROP` général ne sera jamais atteinte.

**4. Le suivi de connexion (*stateful*).** Le noyau garde la trace des connexions établies. C'est ce qui permet de n'autoriser que les connexions **entrantes initiales** tout en laissant revenir les réponses au trafic que vous avez initié.

```text
ESTABLISHED  → paquet appartenant à une connexion déjà acceptée
RELATED      → connexion liée à une autre (ex. le canal de données FTP)
NEW          → première tentative de connexion — c'est celle qu'on filtre
```

---

### ufw (Debian, Ubuntu)

#### Voir le statut

```bash
sudo ufw status verbose
```

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80,443/tcp (WWW Full)      ALLOW IN    Anywhere
3306/tcp                   ALLOW IN    192.168.1.0/24
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80,443/tcp (WWW Full (v6)) ALLOW IN    Anywhere (v6)
```

Chaque règle apparaît deux fois : une pour IPv4 et une pour IPv6.

Pour supprimer des règles, il faut leur numéro :

```bash
sudo ufw status numbered
```

```text
     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere
[ 2] 80,443/tcp (WWW Full)      ALLOW IN    Anywhere
[ 3] 3306/tcp                   ALLOW IN    192.168.1.0/24
```

#### La bonne séquence de mise en place

> [!CAUTION]
> **Sur un serveur distant, l'ordre de ces commandes n'est pas négociable.** Activer ufw avant d'avoir autorisé SSH vous coupe l'accès à la machine, instantanément et définitivement (sauf accès console).

```bash
# 1. Politique par défaut : tout fermer en entrée, tout autoriser en sortie
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 2. SSH EN PREMIER — avant toute chose
sudo ufw allow ssh

# 3. Les services réellement nécessaires
sudo ufw allow http
sudo ufw allow https

# 4. Seulement maintenant, activer
sudo ufw enable
```

```text
Command may disrupt existing ssh connections. Proceed with operation (y|n)?
```

#### Créer des règles

```bash
# Par nom de service (lu dans /etc/services)
sudo ufw allow ssh
sudo ufw allow http

# Par numéro de port
sudo ufw allow 22
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp

# Une plage de ports
sudo ufw allow 6000:6010/tcp

# Depuis une IP précise
sudo ufw allow from 203.0.113.42

# Depuis un sous-réseau, vers un port précis — la forme la plus utile
sudo ufw allow from 192.168.1.0/24 to any port 3306 proto tcp

# Sur une interface donnée
sudo ufw allow in on eth1 to any port 5432

# Avec un commentaire — à faire systématiquement
sudo ufw allow from 192.168.1.0/24 to any port 3306 comment 'MySQL LAN uniquement'
```

#### Bloquer et supprimer

```bash
sudo ufw deny 3306                          # bloquer (silencieux)
sudo ufw reject 3306                        # refuser (avec message d'erreur)
sudo ufw deny from 203.0.113.66             # bannir une IP

sudo ufw delete allow 22                    # par description
sudo ufw status numbered && sudo ufw delete 3   # par numéro
```

> [!WARNING]
> Supprimer par numéro **renumérote** les règles suivantes. Pour en supprimer plusieurs, commencez par la plus grande, ou relisez `ufw status numbered` entre chaque suppression.

#### Insérer une règle à une position précise

L'ordre compte : `ufw insert` place la règle avant les autres.

```bash
sudo ufw insert 1 deny from 203.0.113.66
```

#### Limiter les connexions (anti-bruteforce)

```bash
sudo ufw limit ssh
```

Bloque une IP qui tente plus de 6 connexions en 30 secondes. C'est un filet minimal, utile mais moins fin que [fail2ban](#fail2ban).

#### Les profils d'applications

```bash
sudo ufw app list
```

```text
Available applications:
  Apache Full
  Nginx Full
  Nginx HTTP
  OpenSSH
```

```bash
sudo ufw app info 'Nginx Full'
sudo ufw allow 'Nginx Full'
```

Les profils sont de simples fichiers dans `/etc/ufw/applications.d/` :

```text
[Nginx Full]
title=Web Server (Nginx, HTTP + HTTPS)
description=Small, but very powerful and efficient web server
ports=80,443/tcp
```

#### Journalisation

```bash
sudo ufw logging on
sudo ufw logging medium        # off | low | medium | high | full
```

```bash
sudo tail -f /var/log/ufw.log
```

```text
[UFW BLOCK] IN=eth0 OUT= SRC=203.0.113.66 DST=192.168.1.10
  PROTO=TCP SPT=54321 DPT=3306 WINDOW=1024 SYN
```

| Champ | Sens |
|-------|------|
| `UFW BLOCK` | La règle appliquée |
| `SRC` / `DST` | IP source / destination |
| `SPT` / `DPT` | Port source / **port destination** — c'est celui qui vous intéresse |
| `PROTO` | Protocole |

#### Réinitialiser

```bash
sudo ufw reset          # désactive et supprime toutes les règles
```

Les fichiers de configuration se trouvent dans `/etc/ufw/` et `/etc/default/ufw`.

---

### firewalld (RHEL, Fedora)

firewalld introduit une notion absente d'ufw : les **zones**. Chaque interface réseau est rattachée à une zone, et chaque zone a son propre jeu de règles. C'est pensé pour les machines à plusieurs interfaces (un serveur avec une patte publique et une patte LAN).

```bash
sudo firewall-cmd --get-zones
```

| Zone | Niveau de confiance |
|------|---------------------|
| `drop` | Tout est jeté, sans réponse |
| `block` | Tout est refusé avec un message ICMP |
| `public` | **Zone par défaut** — réseau non fiable, quelques services autorisés |
| `external` | Réseau externe, avec masquerading (NAT) |
| `dmz` | Machines exposées, accès interne limité |
| `work` / `home` | Réseaux relativement fiables |
| `internal` | Réseau interne |
| `trusted` | **Tout** est accepté |

#### État et inspection

```bash
sudo firewall-cmd --state
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --list-all
```

```text
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0
  sources:
  services: dhcpv6-client ssh http https
  ports: 8080/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

#### Runtime contre permanent

> [!IMPORTANT]
> C'est **la** particularité de firewalld, et la source de la plupart des erreurs : il maintient deux configurations distinctes.
>
> | | Effet | Survit au reboot |
> |---|---|---|
> | Sans `--permanent` | Immédiat | ❌ Non |
> | Avec `--permanent` | **Aucun** effet immédiat | ✅ Oui |
>
> La séquence correcte est donc systématiquement :
>
> ```bash
> sudo firewall-cmd --permanent --add-service=http
> sudo firewall-cmd --reload
> ```
>
> Astuce de test sécurisée : appliquer d'abord en runtime seul, vérifier que tout fonctionne, **puis** rendre permanent. Si vous vous coupez l'accès, un simple reboot rétablit la situation.

#### Gérer les services et les ports

```bash
# Par nom de service (défini dans /usr/lib/firewalld/services/)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --remove-service=cockpit

# Par port
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=6000-6010/udp
sudo firewall-cmd --permanent --remove-port=3306/tcp

# Lister les services disponibles
sudo firewall-cmd --get-services

sudo firewall-cmd --reload
```

#### Travailler avec les zones

```bash
# Rattacher une interface à une zone
sudo firewall-cmd --permanent --zone=internal --change-interface=eth1

# Rattacher une source (sous-réseau) à une zone de confiance
sudo firewall-cmd --permanent --zone=internal --add-source=192.168.1.0/24

# Ouvrir un service uniquement dans cette zone
sudo firewall-cmd --permanent --zone=internal --add-service=mysql

sudo firewall-cmd --reload
```

Résultat : MySQL n'est accessible que depuis le LAN, et pas depuis l'interface publique — sans avoir écrit la moindre règle d'IP.

#### Les rich rules

Pour ce que les services et les zones ne couvrent pas :

```bash
# Autoriser une IP précise sur un port précis
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4" source address="203.0.113.42" port port="5432" protocol="tcp" accept'

# Bannir une IP
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4" source address="203.0.113.66" reject'

# Limiter le débit de connexion et journaliser
sudo firewall-cmd --permanent --add-rich-rule='
  rule service name="ssh" log prefix="SSH " level="info" limit value="3/m" accept'

sudo firewall-cmd --reload
sudo firewall-cmd --list-rich-rules
```

#### Le mode panique

```bash
sudo firewall-cmd --panic-on       # coupe TOUT le trafic, immédiatement
sudo firewall-cmd --panic-off
sudo firewall-cmd --query-panic
```

> [!CAUTION]
> `--panic-on` coupe aussi votre session SSH. À réserver à une intervention depuis la console physique ou une console virtuelle du fournisseur cloud.

---

### iptables

iptables organise les règles en **tables**, elles-mêmes composées de **chaînes**.

| Table | Usage |
|-------|-------|
| `filter` | **Table par défaut** — accepter ou rejeter (chaînes INPUT, OUTPUT, FORWARD) |
| `nat` | Traduction d'adresses : redirection de ports, masquerading |
| `mangle` | Modification des en-têtes de paquets |
| `raw` | Exclusion du suivi de connexion |

#### Lire les règles

```bash
sudo iptables -L -v -n --line-numbers
```

| Option | Effet |
|--------|-------|
| `-L` | Lister |
| `-v` | Verbeux (compteurs de paquets et d'octets) |
| `-n` | Ne pas résoudre les noms — beaucoup plus rapide |
| `--line-numbers` | Numéroter, pour pouvoir supprimer par index |

```text
Chain INPUT (policy DROP 12 packets, 720 bytes)
num  pkts bytes target  prot opt in   out  source      destination
1    1523  128K ACCEPT  all  --  lo   *    0.0.0.0/0   0.0.0.0/0
2   84021   42M ACCEPT  all  --  *    *    0.0.0.0/0   0.0.0.0/0   ctstate RELATED,ESTABLISHED
3      42  2520 ACCEPT  tcp  --  *    *    0.0.0.0/0   0.0.0.0/0   tcp dpt:22
```

> [!TIP]
> Les colonnes `pkts` et `bytes` sont précieuses en diagnostic : une règle dont le compteur reste à zéro n'est jamais atteinte. C'est souvent le signe qu'une règle placée plus haut intercepte le trafic.
> `sudo iptables -Z` remet les compteurs à zéro avant un test.

#### Construire un jeu de règles minimal

Voici un ensemble complet et commenté, pour un serveur web avec SSH :

```bash
#!/bin/bash
set -euo pipefail

# 1. Vider les règles existantes
iptables -F
iptables -X

# 2. Politique par défaut : tout refuser en entrée
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

# 3. Autoriser l'interface de bouclage (indispensable — beaucoup de services
#    communiquent entre eux via 127.0.0.1)
iptables -A INPUT -i lo -j ACCEPT

# 4. Autoriser les réponses au trafic qu'on a initié (stateful)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 5. Jeter les paquets invalides
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# 6. SSH — en premier parmi les services
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# 7. HTTP / HTTPS
iptables -A INPUT -p tcp --dport 80  -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

# 8. PostgreSQL, uniquement depuis le LAN
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 5432 -j ACCEPT

# 9. Autoriser le ping (utile pour la supervision)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# 10. Journaliser ce qui est jeté, avec limite de débit
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPT-DROP: " --log-level 4
```

> [!IMPORTANT]
> Les étapes 3 et 4 sont celles qu'on oublie, et leurs symptômes sont déroutants :
> - sans `-i lo -j ACCEPT`, des services locaux cessent de fonctionner sans raison apparente ;
> - sans la règle `ESTABLISHED,RELATED`, la machine ne peut plus rien télécharger : les paquets partent, mais les réponses sont bloquées à l'entrée.

#### Ajouter, insérer, supprimer

```bash
iptables -A INPUT -p tcp --dport 80 -j ACCEPT     # -A : Ajouter à la FIN
iptables -I INPUT 1 -s 203.0.113.66 -j DROP       # -I : Insérer en position 1
iptables -D INPUT 3                               # -D : supprimer la règle n° 3
iptables -R INPUT 2 -p tcp --dport 8080 -j ACCEPT # -R : remplacer
```

> [!WARNING]
> `-A` ajoute **après** toutes les règles existantes. Sur une chaîne qui se termine par un `DROP` explicite, la nouvelle règle ne sera jamais évaluée. Dans le doute, utilisez `-I` avec une position, et vérifiez avec `-L --line-numbers`.

#### Persistance

> [!CAUTION]
> **Les règles iptables sont perdues au redémarrage.** C'est la propriété qui surprend le plus — et qui sauve, aussi : en cas d'erreur de manipulation qui vous coupe l'accès, un reboot rétablit la situation.

```bash
sudo apt install iptables-persistent          # Debian/Ubuntu
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6
```

```bash
sudo iptables-restore < /etc/iptables/rules.v4
```

---

### nftables

`nftables` remplace iptables, ip6tables, arptables et ebtables par un outil unique et une syntaxe cohérente. C'est le moteur par défaut de Debian 10+ et RHEL 8+.

#### Inspecter

```bash
sudo nft list ruleset
```

#### La structure

```text
table  <famille>  <nom>        famille : ip, ip6, inet (les deux), arp, bridge
  └─ chain <nom> { type … hook … priority … ; policy … ; }
       └─ règles
```

#### Un ruleset complet et commenté

```bash
#!/usr/sbin/nft -f
# /etc/nftables.conf

flush ruleset

table inet filter {
    chain input {
        # hook input : on filtre ce qui entre ; policy drop : liste blanche
        type filter hook input priority 0; policy drop;

        # Bouclage
        iif lo accept

        # Connexions déjà établies
        ct state established,related accept
        ct state invalid drop

        # ICMP (ping, découverte de MTU)
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        # SSH, avec limitation anti-bruteforce
        tcp dport 22 ct state new limit rate 6/minute accept

        # Web
        tcp dport { 80, 443 } accept

        # PostgreSQL depuis le LAN uniquement
        ip saddr 192.168.1.0/24 tcp dport 5432 accept

        # Journaliser le reste avant de le jeter
        limit rate 5/minute log prefix "NFT-DROP: " level info
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}
```

> [!TIP]
> La syntaxe est nettement plus lisible qu'iptables : les **ensembles** (`{ 80, 443 }`) évitent de répéter les règles, et la famille `inet` couvre IPv4 **et** IPv6 d'un seul jeu de règles — là où iptables imposait de tout écrire deux fois.

#### Charger, tester et rendre persistant

```bash
# Vérifier la syntaxe sans appliquer
sudo nft -c -f /etc/nftables.conf

# Appliquer
sudo nft -f /etc/nftables.conf

# Rendre persistant (le service recharge /etc/nftables.conf au boot)
sudo systemctl enable --now nftables
```

Commandes ponctuelles :

```bash
sudo nft add rule inet filter input tcp dport 8080 accept
sudo nft list ruleset -a                  # -a affiche les handles
sudo nft delete rule inet filter input handle 12
sudo nft flush ruleset                    # tout effacer
```

---

### Tester et diagnostiquer un pare-feu

#### 1. Le service écoute-t-il vraiment ?

Avant d'accuser le pare-feu, vérifiez que quelque chose écoute sur le port :

```bash
sudo ss -tulpn
```

```text
Netid State  Local Address:Port   Process
tcp   LISTEN 0.0.0.0:22           users:(("sshd",pid=812,fd=3))
tcp   LISTEN 127.0.0.1:5432       users:(("postgres",pid=1043,fd=5))
tcp   LISTEN 0.0.0.0:80           users:(("nginx",pid=1201,fd=6))
```

> [!IMPORTANT]
> Regardez l'**adresse d'écoute**, pas seulement le port. Ci-dessus, PostgreSQL écoute sur `127.0.0.1:5432` : il est inaccessible depuis l'extérieur, et **aucune règle de pare-feu n'y changera quoi que ce soit**. C'est la configuration du service qu'il faut modifier (`listen_addresses` pour PostgreSQL).
>
> `0.0.0.0` = toutes les interfaces · `127.0.0.1` = machine locale uniquement · `::` = toutes, en IPv6.

#### 2. Tester depuis l'extérieur

Depuis **une autre machine** — tester depuis la machine elle-même ne prouve rien, le trafic local ne traverse pas les mêmes chaînes :

```bash
nc -zv 192.168.1.10 22            # test d'un port
nmap -Pn -p 22,80,443 192.168.1.10
curl -v telnet://192.168.1.10:80
```

#### 3. Lire les journaux

```bash
sudo tail -f /var/log/ufw.log                    # ufw
sudo journalctl -f -k | grep -E "DROP|REJECT"    # iptables / nftables
sudo firewall-cmd --get-log-denied               # firewalld
sudo firewall-cmd --set-log-denied=all
```

#### 4. La checklist

| Symptôme | Vérifier |
|----------|----------|
| Connexion refusée immédiatement | Aucun service n'écoute (`ss -tulpn`), ou règle `REJECT` |
| Connexion qui pend jusqu'au timeout | Règle `DROP`, ou pare-feu intermédiaire (cloud, routeur) |
| Ça marche en local, pas à distance | Le service écoute sur `127.0.0.1` uniquement |
| Ça marche en IPv4, pas en IPv6 | Règles IPv6 oubliées (`ip6tables`, ou famille `inet` en nftables) |
| La règle existe mais n'a aucun effet | Une règle antérieure intercepte — vérifier l'ordre et les compteurs |
| Tout casse après un reboot | Règles non persistées, ou `--permanent` oublié |
| Docker ignore mon pare-feu | Docker écrit ses propres règles dans la chaîne `DOCKER-USER` |

> [!WARNING]
> **Docker contourne ufw.** Un conteneur lancé avec `-p 3306:3306` ouvre le port sur toutes les interfaces en insérant ses règles **avant** celles d'ufw. Votre `ufw deny 3306` ne s'applique pas.
> Deux solutions : publier sur la boucle locale (`-p 127.0.0.1:3306:3306`), ou écrire vos règles dans la chaîne `DOCKER-USER`, qui est évaluée avant celles de Docker.

#### Le filet de sécurité anti-verrouillage

> [!TIP]
> Avant toute manipulation de pare-feu sur une machine distante, programmez une remise à zéro automatique. Si vous vous coupez l'accès, elle vous rouvre la porte cinq minutes plus tard.
>
> ```bash
> # Debian / ufw
> echo "ufw --force reset && ufw --force enable" | sudo at now + 5 minutes
>
> # iptables
> echo "iptables -P INPUT ACCEPT && iptables -F" | sudo at now + 5 minutes
> ```
>
> Si tout se passe bien, on annule le travail programmé :
>
> ```bash
> sudo atq              # lister
> sudo atrm 1           # annuler
> ```
>
> Et bien sûr, la règle universelle de ce chapitre : **gardez une seconde session SSH ouverte** pendant toute l'intervention.

### Récapitulatif firewall

| Action | ufw | firewalld | nftables |
|--------|-----|-----------|----------|
| État | `ufw status verbose` | `firewall-cmd --list-all` | `nft list ruleset` |
| Activer | `ufw enable` | `systemctl enable --now firewalld` | `systemctl enable --now nftables` |
| Ouvrir un port | `ufw allow 80/tcp` | `firewall-cmd --permanent --add-port=80/tcp` | `tcp dport 80 accept` |
| Ouvrir un service | `ufw allow http` | `firewall-cmd --permanent --add-service=http` | — |
| Restreindre à un LAN | `ufw allow from 192.168.1.0/24 to any port 3306` | `--zone=internal --add-source=…` | `ip saddr 192.168.1.0/24 … accept` |
| Supprimer | `ufw delete 3` | `--permanent --remove-port=80/tcp` | `nft delete rule … handle N` |
| Appliquer | immédiat | `firewall-cmd --reload` | `nft -f /etc/nftables.conf` |
| Persistance | automatique | `--permanent` | `/etc/nftables.conf` |

---

## SSH

SSH (*Secure Shell*) est un protocole de connexion à distance à un serveur (Linux comme Windows), qui fonctionne en ligne de commande. C'est l'outil central de l'administration à distance : tout le reste — transfert de fichiers, tunnels, déploiement, sauvegarde — passe par lui.

### Installation et vérification

```bash
sudo apt install openssh-server        # le serveur (pour accepter des connexions)
sudo apt install openssh-client        # le client (pour se connecter ailleurs)
```

```bash
systemctl status ssh                   # Debian/Ubuntu : le service s'appelle "ssh"
systemctl status sshd                  # RHEL/Fedora   : il s'appelle "sshd"
```

```bash
ss -tulpn | grep sshd                  # sur quel port et quelle interface écoute-t-il ?
```

### Les deux fichiers de configuration

> [!IMPORTANT]
> Ne pas confondre les deux fichiers — c'est l'erreur la plus courante avec SSH, et elle fait perdre des heures :
>
> | Fichier | Concerne | Utilisé pour |
> |---------|----------|--------------|
> | `/etc/ssh/ssh_config` | Le **client** | Les options utilisées quand *je me connecte* à d'autres machines |
> | `~/.ssh/config` | Le **client**, pour un utilisateur | Idem, prioritaire sur le fichier système |
> | `/etc/ssh/sshd_config` | Le **serveur** (démon `sshd`) | Les règles imposées à ceux qui *se connectent à ma machine* |
>
> Le `d` de `sshd_config` est celui de *daemon*. Une directive `PasswordAuthentication no` placée dans `ssh_config` ne sécurise **rien** : elle empêche seulement votre client de proposer un mot de passe aux serveurs distants.

### Gestion des clés

#### Générer une paire de clés

```bash
ssh-keygen -t ed25519 -C "alice@portable-2026"
```

```text
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/alice/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/alice/.ssh/id_ed25519
Your public key has been saved in /home/alice/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:2Xk9…Qw8 alice@portable-2026
```

| Option | Rôle |
|--------|------|
| `-t ed25519` | Type de clé |
| `-C "commentaire"` | Commentaire — mettez-y **qui** et **quelle machine**, c'est ce qui permettra plus tard d'identifier une clé dans un `authorized_keys` |
| `-f ~/.ssh/id_deploy` | Chemin du fichier (pour avoir plusieurs clés) |
| `-a 100` | Nombre de tours de dérivation de la passphrase |

La commande génère **deux** fichiers :

| Fichier | Nature | Règle |
|---------|--------|-------|
| `id_ed25519` | Clé **privée** | Reste sur votre machine, ne se partage **jamais** |
| `id_ed25519.pub` | Clé **publique** | Se dépose sur les serveurs |

#### Quel type de clé choisir ?

| Type | Verdict |
|------|---------|
| **ed25519** | ✅ **Le choix par défaut** — court, rapide, sûr, supporté partout depuis OpenSSH 6.5 (2014) |
| `rsa` (4096 bits) | Acceptable si vous devez parler à un équipement ancien : `ssh-keygen -t rsa -b 4096` |
| `ecdsa` | À éviter — pas de bénéfice sur ed25519 |
| `dsa` | ❌ Obsolète et désactivé par défaut |

#### La passphrase

> [!IMPORTANT]
> **Mettez une passphrase sur vos clés personnelles.** Une clé privée sans passphrase est un mot de passe en clair dans un fichier : quiconque copie ce fichier — vol de portable, sauvegarde mal protégée, malware — obtient tous vos accès.
>
> L'objection habituelle (« je vais devoir la taper tout le temps ») est résolue par l'[agent SSH](#lagent-ssh) : on la saisit une fois par session.
>
> Les clés **de service** (CI/CD, sauvegardes automatisées) sont l'exception : elles ne peuvent pas avoir de passphrase, puisque personne n'est là pour la taper. On les compense par des restrictions dans `authorized_keys` — voir [plus bas](#restreindre-une-clé-dans-authorized_keys).

Ajouter, changer ou retirer une passphrase sur une clé existante :

```bash
ssh-keygen -p -f ~/.ssh/id_ed25519
```

#### Inspecter une clé

```bash
ssh-keygen -l -f ~/.ssh/id_ed25519.pub          # empreinte
ssh-keygen -lv -f ~/.ssh/id_ed25519.pub         # empreinte + art ASCII
```

```text
256 SHA256:2Xk9…Qw8 alice@portable-2026 (ED25519)
```

Exemple de clé publique (format : `type` `clé` `commentaire`) :

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8kQ2vXn5R7T9pM3wYqZ1cD4eF6gH8jK0lN2oP4rS6t alice@portable-2026
```

> [!TIP]
> **La rotation de clés.** Il est conseillé de changer ses clés SSH tous les six mois environ.
> Lors d'une rotation, déployez la nouvelle clé **avant** de retirer l'ancienne, et vérifiez que la nouvelle fonctionne sur chaque serveur avant de nettoyer. Le commentaire `-C` avec la date rend l'inventaire beaucoup plus simple.

### Déployer sa clé publique

La clé publique se dépose sur le serveur, dans `~/.ssh/authorized_keys` de l'utilisateur cible. Ce fichier peut contenir plusieurs clés, une par ligne.

**La méthode automatique :**

```bash
ssh-copy-id username@server
ssh-copy-id -i ~/.ssh/id_deploy.pub deploy@server      # une clé précise
```

**La méthode manuelle**, quand `ssh-copy-id` n'est pas disponible :

```bash
cat ~/.ssh/id_ed25519.pub | ssh username@server \
  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

#### Les permissions, cause n° 1 des échecs

> [!CAUTION]
> `sshd` **refuse silencieusement** toute clé dont les permissions sont trop larges — c'est une protection, mais le message d'erreur côté client (`Permission denied (publickey)`) n'en dit rien.

| Élément | Permissions | Propriétaire |
|---------|-------------|--------------|
| `~` (le home) | Pas de `w` pour groupe/autres — `755` ou moins | l'utilisateur |
| `~/.ssh/` | `700` | l'utilisateur |
| `~/.ssh/authorized_keys` | `600` | l'utilisateur |
| `~/.ssh/id_ed25519` (privée) | `600` | l'utilisateur |
| `~/.ssh/id_ed25519.pub` | `644` | l'utilisateur |
| `~/.ssh/config` | `600` | l'utilisateur |

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys ~/.ssh/id_ed25519 ~/.ssh/config
chmod 644 ~/.ssh/id_ed25519.pub
chown -R $USER:$USER ~/.ssh
```

### Durcir le serveur : `sshd_config`

Voici une configuration de production commentée. Chaque ligne se place dans `/etc/ssh/sshd_config`.

```text
# ── Écoute ────────────────────────────────────────────────────────
Port 22
AddressFamily inet                    # IPv4 seulement, si IPv6 n'est pas utilisé
ListenAddress 0.0.0.0

# ── Authentification ──────────────────────────────────────────────
PermitRootLogin no                    # jamais de connexion root directe
PubkeyAuthentication yes
PasswordAuthentication no             # clés uniquement
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes

MaxAuthTries 3                        # 3 essais puis déconnexion
MaxSessions 5
LoginGraceTime 30                     # 30 s pour s'authentifier

# ── Qui a le droit de se connecter ────────────────────────────────
AllowGroups sshusers                  # liste blanche par groupe

# ── Réduction de la surface d'attaque ─────────────────────────────
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no                 # à laisser à "yes" si vous utilisez des tunnels
PermitTunnel no
PermitUserEnvironment no

# ── Sessions inactives ────────────────────────────────────────────
ClientAliveInterval 300               # sonde toutes les 5 min
ClientAliveCountMax 2                 # déconnecte après 2 sondes sans réponse

# ── Journalisation ────────────────────────────────────────────────
LogLevel VERBOSE                      # journalise les empreintes de clés utilisées

# ── Bannière légale (obligatoire dans certains contextes) ─────────
Banner /etc/issue.net
```

Les directives les plus importantes, résumées :

| Directive | Valeur | Pourquoi |
|-----------|--------|----------|
| `PermitRootLogin` | `no` | Force le passage par un compte nominatif puis `sudo` — traçabilité |
| `PasswordAuthentication` | `no` | Élimine d'un coup le bruteforce de mots de passe |
| `AllowGroups` / `AllowUsers` | liste blanche | Un nouveau compte système ne devient pas accessible par accident |
| `MaxAuthTries` | `3` | Limite les tentatives par connexion |
| `LoginGraceTime` | `30` | Limite les connexions à moitié ouvertes |
| `LogLevel` | `VERBOSE` | Journalise **quelle clé** a servi — indispensable en audit |

#### La procédure de modification, sans se verrouiller

> [!CAUTION]
> **La règle absolue : gardez une seconde session SSH ouverte pendant toute la manipulation.** Tant que cette session est active, elle n'est pas affectée par le rechargement de la configuration : elle reste votre porte de secours.

```bash
# 1. Sauvegarder
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 2. Modifier
sudo vim /etc/ssh/sshd_config

# 3. VÉRIFIER LA SYNTAXE — avant tout rechargement
sudo sshd -t
```

Aucune sortie signifie que tout est correct. Sinon :

```text
/etc/ssh/sshd_config line 42: Bad configuration option: PermitRootLgin
```

```bash
# 4. Voir la configuration effective, telle que sshd la comprend
sudo sshd -T | grep -iE "permitrootlogin|passwordauth|allowgroups"

# 5. Appliquer (reload, pas restart : les sessions en cours sont préservées)
sudo systemctl reload ssh

# 6. DEPUIS UN TROISIÈME TERMINAL, tester une nouvelle connexion
ssh -v username@serveur
```

Ne fermez la session de secours qu'après avoir confirmé que la nouvelle connexion fonctionne.

> [!TIP]
> `sshd -T` est très utile : il affiche la configuration **résolue**, valeurs par défaut comprises. C'est la seule façon de savoir avec certitude ce que fait le serveur, sans avoir à lire les fichiers inclus et les blocs `Match`.
>
> Sur les distributions récentes, `sshd_config` se termine par `Include /etc/ssh/sshd_config.d/*.conf`. Comme la **première** valeur rencontrée l'emporte en SSH, les fichiers de ce dossier surchargent le reste : vérifiez-y en cas de comportement inattendu.

### Les blocs Match

`Match` applique des directives à un sous-ensemble de connexions. C'est ce qui permet des politiques différenciées.

```text
# Configuration globale : verrouillée
PasswordAuthentication no
AllowTcpForwarding no
PermitRootLogin no

# Le compte de sauvegarde n'a droit qu'à rsync, sans shell interactif
Match User backup
    ForceCommand /usr/bin/rrsync -ro /srv/data
    AllowTcpForwarding no
    X11Forwarding no

# Les administrateurs, depuis le réseau interne, peuvent utiliser des tunnels
Match Group admins Address 192.168.1.0/24
    AllowTcpForwarding yes
    AllowAgentForwarding yes

# Un compte SFTP confiné à son dossier (chroot)
Match Group sftponly
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    PermitTunnel no
```

| Critère | Exemple |
|---------|---------|
| `Match User alice,bob` | Par utilisateur |
| `Match Group admins` | Par groupe |
| `Match Address 192.168.1.0/24` | Par IP source |
| `Match LocalPort 2222` | Par port d'écoute |

> [!IMPORTANT]
> Un bloc `Match` s'étend **jusqu'au prochain `Match`** ou la fin du fichier. Toutes les directives globales doivent donc être écrites **avant** le premier `Match` — sinon elles se retrouvent capturées par un bloc et ne s'appliquent qu'à lui.
>
> Pour le chroot SFTP, `ChrootDirectory` exige que le dossier et **tous ses parents** appartiennent à root et ne soient pas modifiables par le groupe ou les autres.

### Restreindre une clé dans `authorized_keys`

Chaque ligne d'`authorized_keys` peut être préfixée par des options. C'est le bon endroit pour encadrer les clés d'automatisation, qui n'ont pas de passphrase.

```text
# Une clé de déploiement : ne peut lancer qu'une commande, depuis une IP donnée
command="/usr/local/bin/deploy.sh",from="203.0.113.10",no-agent-forwarding,no-port-forwarding,no-pty,no-X11-forwarding ssh-ed25519 AAAAC3Nz… ci@gitlab

# Une clé de sauvegarde : rsync en lecture seule
command="/usr/bin/rrsync -ro /srv/data",no-pty,no-port-forwarding ssh-ed25519 AAAAC3Nz… backup@nas

# Une clé d'administration normale, restreinte au réseau interne
from="192.168.1.0/24" ssh-ed25519 AAAAC3Nz… alice@portable
```

| Option | Effet |
|--------|-------|
| `command="…"` | **Force** l'exécution de cette commande, quoi que demande le client |
| `from="192.168.1.0/24,10.0.0.5"` | N'accepte cette clé que depuis ces adresses |
| `no-pty` | Interdit l'allocation d'un terminal — pas de shell interactif |
| `no-port-forwarding` | Interdit les tunnels |
| `no-agent-forwarding` | Interdit le transfert d'agent |
| `no-X11-forwarding` | Interdit le transfert graphique |
| `expiry-time="20261231"` | Date d'expiration de la clé |
| `restrict` | **Tout interdire**, puis rouvrir explicitement — la forme recommandée |

```text
restrict,command="/usr/local/bin/backup.sh" ssh-ed25519 AAAAC3Nz… backup@nas
```

> [!TIP]
> `restrict` est apparu avec OpenSSH 7.2 et vaut mieux que d'énumérer les `no-*` : il désactive tout, y compris les fonctionnalités ajoutées dans les versions futures. On rouvre ensuite au cas par cas avec `pty`, `port-forwarding`, etc.

**Auditer les clés déployées sur un serveur :**

```bash
sudo find /home /root -name authorized_keys -exec echo "── {}" \; -exec cat {} \;
```

```bash
# Avec les empreintes, pour comparer à un inventaire
sudo ssh-keygen -l -f /home/alice/.ssh/authorized_keys
```

### Configurer le client : `~/.ssh/config`

C'est le fichier qui transforme l'usage quotidien de SSH. Il évite de retenir des IP, des ports et des noms d'utilisateur.

```text
# ~/.ssh/config

# ── Valeurs communes à tous les hôtes ─────────────────────────────
Host *
    ServerAliveInterval 60            # garder la connexion vivante
    ServerAliveCountMax 3
    AddKeysToAgent yes                # ajouter la clé à l'agent au 1er usage
    HashKnownHosts yes
    Compression yes

# ── Un serveur simple ─────────────────────────────────────────────
Host web
    HostName 203.0.113.10
    User debian
    Port 22
    IdentityFile ~/.ssh/id_ed25519

# ── Un serveur sur un port non standard ───────────────────────────
Host prod-db
    HostName db.exemple.be
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_prod
    IdentitiesOnly yes                # n'essayer QUE cette clé

# ── Un serveur accessible uniquement via un rebond ────────────────
Host interne
    HostName 10.0.0.42
    User debian
    ProxyJump web                     # passe par l'hôte "web" défini plus haut

# ── Un motif : tous les serveurs d'un domaine ─────────────────────
Host *.exemple.be
    User admin
    IdentityFile ~/.ssh/id_pro

# ── Réutiliser une connexion existante (accélère beaucoup) ────────
Host lent
    HostName lent.exemple.be
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 10m
```

La connexion devient :

```bash
ssh web
ssh interne          # traverse automatiquement le rebond
scp fichier.txt web:/tmp/
```

| Directive | Rôle |
|-----------|------|
| `HostName` | L'adresse réelle |
| `User` | Le compte distant |
| `Port` | Le port |
| `IdentityFile` | La clé à présenter |
| `IdentitiesOnly yes` | Ne pas essayer toutes les clés de l'agent (évite le `MaxAuthTries exceeded`) |
| `ProxyJump` | Rebond par une machine intermédiaire |
| `ServerAliveInterval` | Empêche les coupures de sessions inactives |
| `ControlMaster` / `ControlPersist` | Multiplexage : les connexions suivantes réutilisent la première, instantanément |

> [!IMPORTANT]
> Contrairement à la plupart des fichiers de configuration Linux, **SSH retient la première valeur rencontrée**, pas la dernière. Les blocs les plus spécifiques doivent donc être placés **en haut** du fichier, et le `Host *` **en bas**.

Pour créer le dossier des sockets de multiplexage :

```bash
mkdir -p ~/.ssh/sockets && chmod 700 ~/.ssh/sockets
```

### `known_hosts` et empreintes

À la première connexion :

```text
The authenticity of host '203.0.113.10 (203.0.113.10)' can't be established.
ED25519 key fingerprint is SHA256:2Xk9pQr7…Qw8.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

> [!IMPORTANT]
> Cette question n'est pas une formalité : c'est **la** protection contre l'attaque de l'homme du milieu. Répondre `yes` sans vérifier revient à accepter n'importe quel serveur qui se présenterait à cette adresse.
>
> La bonne pratique : récupérer l'empreinte par un canal indépendant (console du fournisseur cloud, documentation interne, sortie de l'installation) et la comparer. Sur le serveur :
>
> ```bash
> sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
> ```

L'empreinte acceptée est enregistrée dans `~/.ssh/known_hosts`. Si elle change ensuite :

```text
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

Deux explications possibles : le serveur a été réinstallé (cas fréquent et bénin), ou quelqu'un s'interpose (cas grave). **Ne supprimez la ligne qu'après avoir déterminé laquelle.**

```bash
ssh-keygen -R 203.0.113.10                  # retirer l'entrée d'un hôte
ssh-keygen -F 203.0.113.10                  # chercher une entrée
ssh-keyscan -t ed25519 203.0.113.10         # récupérer la clé d'hôte
```

### L'agent SSH

L'agent garde vos clés déverrouillées en mémoire : la passphrase n'est demandée qu'une fois par session.

```bash
eval "$(ssh-agent -s)"          # démarrer l'agent (souvent déjà lancé par le bureau)
ssh-add ~/.ssh/id_ed25519       # ajouter une clé
ssh-add -l                      # lister les clés chargées
ssh-add -t 3600 ~/.ssh/id_prod  # charger pour 1 heure seulement
ssh-add -D                      # décharger toutes les clés
```

Pour que les clés soient ajoutées automatiquement, dans `~/.ssh/config` :

```text
Host *
    AddKeysToAgent yes
```

#### Le transfert d'agent

```bash
ssh -A serveur                  # transférer l'agent vers le serveur
```

Cela permet, depuis le serveur, de rebondir vers une troisième machine avec vos clés locales — sans jamais y copier de clé privée.

> [!CAUTION]
> **Le transfert d'agent est risqué.** Tant que votre session est ouverte, l'administrateur (ou tout attaquant ayant obtenu root) sur la machine intermédiaire peut utiliser le socket de votre agent pour s'authentifier **partout où vos clés donnent accès**.
>
> Ne l'activez jamais globalement (`ForwardAgent yes` sous `Host *`). Préférez **`ProxyJump`**, qui atteint le même résultat sans jamais exposer l'agent sur la machine de rebond :
>
> ```bash
> ssh -J rebond destination
> ```

### Tunnels et rebonds

```bash
# Rebond : atteindre une machine via une autre
ssh -J rebond@bastion admin@10.0.0.42

# Tunnel LOCAL : exposer un service distant sur ma machine
# Ici, la base distante (accessible seulement en local sur le serveur)
# devient joignable sur localhost:5433
ssh -L 5433:localhost:5432 admin@serveur

# Tunnel DISTANT : exposer un service local sur le serveur
ssh -R 8080:localhost:3000 admin@serveur

# Proxy SOCKS : faire passer un navigateur par le serveur
ssh -D 1080 admin@serveur
```

```text
Tunnel local  (-L)    ma machine:5433  ──►  serveur  ──►  db:5432
Tunnel distant (-R)   serveur:8080     ──►  ma machine:3000
Proxy SOCKS   (-D)    ma machine:1080  ──►  serveur  ──►  Internet
```

| Option utile | Effet |
|--------------|-------|
| `-N` | Ne pas exécuter de commande — tunnel seul |
| `-f` | Passer en arrière-plan |
| `-T` | Ne pas allouer de terminal |

```bash
ssh -fNT -L 5433:localhost:5432 admin@serveur      # tunnel en arrière-plan
```

Le cas d'usage type : accéder à une base de données qui n'écoute que sur `127.0.0.1` du serveur, depuis son client graphique local — sans jamais l'exposer sur le réseau.

### Transférer des fichiers

```bash
# scp — simple, adapté aux transferts ponctuels
scp fichier.txt admin@serveur:/srv/data/
scp -r dossier/ admin@serveur:/srv/
scp admin@serveur:/var/log/app.log ./

# rsync — incrémental, reprend là où il s'est arrêté : le bon choix dès que ça se répète
rsync -avz --progress dossier/ admin@serveur:/srv/dossier/
rsync -avzAX --delete /srv/data/ admin@serveur:/backup/data/

# sftp — session interactive
sftp admin@serveur
```

`rsync` bénéficie de votre `~/.ssh/config` : `rsync -av dossier/ web:/srv/` fonctionne avec l'alias `web`.

> [!TIP]
> Options `rsync` à connaître : `-a` (archive : permissions, dates, liens), `-v` (verbeux), `-z` (compression), `-A` (**ACL**), `-X` (attributs étendus), `--delete` (miroir exact — **destructif**, à tester d'abord avec `--dry-run`).

### fail2ban

`fail2ban` lit les journaux, détecte les tentatives d'authentification répétées et bannit temporairement les IP fautives au niveau du pare-feu.

```bash
sudo apt install fail2ban
```

La configuration ne se modifie **jamais** dans `jail.conf` (écrasé aux mises à jour) mais dans `jail.local` :

```text
# /etc/fail2ban/jail.local

[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd
ignoreip = 127.0.0.1/8 192.168.1.0/24      # ne jamais se bannir soi-même

[sshd]
enabled  = true
port     = ssh
maxretry = 3
bantime  = 24h
```

```bash
sudo systemctl enable --now fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

```text
Status for the jail: sshd
|- Filter
|  |- Currently failed: 2
|  |- Total failed:     1847
|  `- Journal matches:  _SYSTEMD_UNIT=sshd.service
`- Actions
   |- Currently banned: 5
   |- Total banned:     213
   `- Banned IP list:   203.0.113.66 198.51.100.4 …
```

```bash
sudo fail2ban-client set sshd unbanip 203.0.113.66     # débannir
```

> [!IMPORTANT]
> Renseignez `ignoreip` avec vos propres réseaux **avant** d'activer le service. Se faire bannir de son propre serveur par fail2ban après trois erreurs de frappe est un grand classique.
>
> À noter : si `PasswordAuthentication` est déjà à `no`, l'essentiel du bruteforce est déjà neutralisé. fail2ban reste utile pour réduire le bruit dans les logs et la charge.

### Diagnostic SSH

#### Côté client : le mode verbeux

```bash
ssh -v username@serveur          # verbeux
ssh -vvv username@serveur        # très verbeux
```

Les lignes à chercher dans la sortie :

```text
debug1: Offering public key: /home/alice/.ssh/id_ed25519 ED25519 SHA256:2Xk9…
debug1: Authentications that can continue: publickey,password
debug1: Server accepts key: /home/alice/.ssh/id_ed25519
```

#### Côté serveur : les journaux

```bash
sudo journalctl -u ssh -f              # Debian
sudo journalctl -u sshd -f             # RHEL
sudo tail -f /var/log/auth.log
```

```text
sshd[1234]: Accepted publickey for alice from 203.0.113.5 port 51234 ssh2:
  ED25519 SHA256:2Xk9pQr7…Qw8
sshd[1235]: Failed password for invalid user admin from 198.51.100.4 port 40122 ssh2
sshd[1236]: Authentication refused: bad ownership or modes for file /home/bob/.ssh/authorized_keys
```

Pour un diagnostic vraiment détaillé, on peut lancer un second `sshd` en mode debug sur un autre port, sans toucher au service en production :

```bash
sudo /usr/sbin/sshd -d -p 2223          # affiche tout, une connexion puis s'arrête
ssh -p 2223 username@serveur            # depuis un autre terminal
```

#### La checklist `Permission denied (publickey)`

C'est l'erreur la plus fréquente. Dans l'ordre :

| # | Vérification | Commande |
|---|--------------|----------|
| 1 | La clé est-elle proposée ? | `ssh -v` → chercher `Offering public key` |
| 2 | La bonne clé est-elle utilisée ? | `ssh -i ~/.ssh/id_ed25519 user@serveur` |
| 3 | La clé publique est-elle sur le serveur ? | `grep "$(cut -d' ' -f2 ~/.ssh/id_ed25519.pub)" ~/.ssh/authorized_keys` |
| 4 | Les permissions sont-elles correctes ? | `ls -ld ~ ~/.ssh ~/.ssh/authorized_keys` |
| 5 | Le home est-il accessible en écriture au groupe ? | `chmod g-w ~` |
| 6 | L'utilisateur est-il autorisé ? | `sudo sshd -T \| grep -i allow` |
| 7 | Un bloc `Match` interfère-t-il ? | `sudo sshd -T -C user=alice,host=…,addr=…` |
| 8 | SELinux a-t-il mal étiqueté `.ssh` ? | `restorecon -Rv ~/.ssh` |
| 9 | Le compte est-il verrouillé ou expiré ? | `sudo passwd -S alice` · `sudo chage -l alice` |

> [!TIP]
> Le point 8 est un grand classique sur RHEL : un `~/.ssh` créé par un script ou copié depuis ailleurs porte un mauvais contexte SELinux, et `sshd` ne peut pas le lire — alors que les permissions POSIX sont parfaites. `restorecon -Rv ~/.ssh` règle le problème en une seconde. Voir la section [SELinux](#selinux-rhel-fedora-centos-rocky).

#### Autres symptômes

| Message | Cause probable |
|---------|----------------|
| `Connection refused` | `sshd` n'écoute pas sur ce port, ou pare-feu en `REJECT` |
| `Connection timed out` | Pare-feu en `DROP`, mauvaise IP, ou groupe de sécurité cloud |
| `Too many authentication failures` | L'agent propose trop de clés → `IdentitiesOnly yes` |
| `Host key verification failed` | Clé d'hôte changée → vérifier, puis `ssh-keygen -R` |
| `no matching host key type found` | Serveur ancien, algorithmes obsolètes → `-o HostKeyAlgorithms=+ssh-rsa` |
| `Broken pipe` après inactivité | Absence de keepalive → `ServerAliveInterval 60` |

### Noms de domaine personnalisés — le fichier hosts

On peut créer des noms de domaine locaux dans le fichier hosts :

| OS | Chemin |
|----|--------|
| Linux / macOS | `/etc/hosts` |
| Windows | `C:\Windows\System32\drivers\etc\hosts` |

```text
192.168.1.42      bf.devops25
```

```bash
ssh username@bf.devops25
```

> [!CAUTION]
> **Le fichier hosts a priorité sur le DNS.** Si vous mettez :
> ```text
> 127.0.0.1      www.google.com
> ```
> chaque tentative de connexion à Google sera redirigée vers votre propre machine.
> Faites donc bien attention aux noms de domaine que vous attribuez à vos serveurs.
>
> Pour un usage courant, `~/.ssh/config` est préférable à `/etc/hosts` : il ne modifie pas la résolution de noms du système entier et ne demande pas les droits root.

### Récapitulatif SSH

| Commande | Rôle |
|----------|------|
| `ssh-keygen -t ed25519 -C "qui@machine"` | Générer une paire de clés |
| `ssh-copy-id user@serveur` | Déployer sa clé publique |
| `ssh-keygen -l -f cle.pub` | Empreinte d'une clé |
| `ssh-keygen -R hote` | Retirer un hôte de `known_hosts` |
| `ssh-add -l` / `ssh-add -t 3600` | Gérer l'agent |
| `sshd -t` | **Valider `sshd_config` avant de recharger** |
| `sshd -T` | Afficher la configuration effective |
| `ssh -v` | Diagnostiquer une connexion |
| `ssh -J rebond destination` | Rebond (préférable à `-A`) |
| `ssh -fNT -L 5433:localhost:5432 srv` | Tunnel local en arrière-plan |
| `rsync -avzAX src/ srv:/dst/` | Synchroniser en préservant les ACL |
| `fail2ban-client status sshd` | Voir les bannissements |

**Les six réglages qui comptent dans `sshd_config` :**

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowGroups sshusers
MaxAuthTries 3
LogLevel VERBOSE
```

---
## AppArmor / SELinux

### DAC contre MAC : pourquoi une couche de plus ?

Tout ce qu'on a vu jusqu'ici — permissions POSIX, ACL, sudoers — relève du contrôle d'accès **discrétionnaire** (DAC, *Discretionary Access Control*) : c'est le **propriétaire** d'un fichier qui décide qui peut y accéder. Et au-dessus de tout ça, root peut tout.

AppArmor et SELinux ajoutent un contrôle d'accès **obligatoire** (MAC, *Mandatory Access Control*) : une politique définie au niveau du système, appliquée par le **noyau**, que ni le propriétaire d'un fichier ni root ne peuvent contourner à la volée.

**Le scénario concret :**

> Une faille est découverte dans votre serveur web. Un attaquant obtient l'exécution de code arbitraire dans le processus `nginx`.
>
> - **Sans MAC** : le processus tourne sous l'utilisateur `www-data`. L'attaquant peut lire tout ce que `www-data` peut lire — donc `/etc/passwd`, les fichiers d'autres sites, les sauvegardes lisibles par tous, et il peut ouvrir des connexions réseau sortantes.
> - **Avec MAC** : le noyau n'autorise le processus `nginx` qu'à lire `/var/www/`, écrire dans `/var/log/nginx/` et écouter sur les ports 80 et 443. Toute autre tentative est refusée **même si les permissions POSIX l'autorisaient**. La compromission reste confinée.

C'est une défense en profondeur : elle ne remplace pas les permissions, elle plafonne les dégâts quand tout le reste a échoué.

| | AppArmor | SELinux |
|---|---|---|
| **Distributions** | Debian, Ubuntu, SUSE | RHEL, Fedora, CentOS, Rocky, Alma |
| **Approche** | Profils par **chemin** de binaire | **Étiquettes** (*labels*) sur chaque fichier et processus |
| **Unité de politique** | Un fichier de profil par exécutable | Une politique globale + contextes |
| **Si le fichier est déplacé** | Le profil ne s'applique plus | L'étiquette suit le fichier |
| **Complexité** | Lisible, rapide à prendre en main | Beaucoup plus fin, mais plus abrupt |
| **Fichiers de config** | `/etc/apparmor.d/` | `/etc/selinux/`, étiquettes dans le système de fichiers |

### Savoir ce qui tourne sur la machine

```bash
# AppArmor présent et actif ?
sudo aa-status
cat /sys/module/apparmor/parameters/enabled       # Y ou N

# SELinux présent et actif ?
sestatus
getenforce
```

---

## AppArmor (Debian, Ubuntu, SUSE)

### 1. Vérifier l'état

```bash
sudo aa-status
```

```text
apparmor module is loaded.
32 profiles are loaded.
29 profiles are in enforce mode.
   /usr/bin/man
   /usr/sbin/nginx
   /usr/sbin/tcpdump
   ...
3 profiles are in complain mode.
   /usr/local/bin/backup.sh
   ...
2 processes have profiles defined.
2 processes are in enforce mode.
   /usr/sbin/nginx (1234)
   /usr/sbin/nginx (1235)
0 processes are in complain mode.
0 processes are unconfined but have a profile defined.
```

### 2. Les trois modes

| Mode | Comportement | Commande |
|------|--------------|----------|
| **enforce** | Bloque tout ce qui n'est pas explicitement autorisé, et le journalise | `sudo aa-enforce /usr/sbin/nginx` |
| **complain** | N'empêche rien, mais **journalise** tout ce qui aurait été bloqué | `sudo aa-complain /usr/sbin/nginx` |
| **disabled** | Le profil est ignoré | `sudo aa-disable /usr/sbin/nginx` |

> [!TIP]
> Le mode **complain** est l'outil central du travail avec AppArmor : on met un profil en complain, on fait tourner l'application normalement pendant quelques jours, on collecte tout ce qu'elle a réellement essayé de faire, puis on bascule en enforce. On ne devine jamais un profil, on l'observe.

Ces commandes viennent du paquet :

```bash
sudo apt install apparmor-utils apparmor-profiles
```

### 3. Anatomie d'un profil

Les profils vivent dans `/etc/apparmor.d/`. Le nom du fichier reprend le chemin du binaire, avec les `/` remplacés par des `.` :

| Binaire | Fichier de profil |
|---------|-------------------|
| `/usr/sbin/nginx` | `/etc/apparmor.d/usr.sbin.nginx` |
| `/usr/local/bin/backup.sh` | `/etc/apparmor.d/usr.local.bin.backup.sh` |

Voici un profil complet et commenté, qui confine un script de sauvegarde maison :

```text
# /etc/apparmor.d/usr.local.bin.backup.sh

abi <abi/3.0>,
include <tunables/global>

# Le chemin du programme confiné, suivi du bloc de règles
/usr/local/bin/backup.sh {

  # ── Abstractions : des blocs de règles réutilisables fournis par le système
  include <abstractions/base>          # le minimum vital (libc, /dev/null, locales…)
  include <abstractions/bash>          # ce dont un script bash a besoin

  # ── Capabilities : les privilèges root fins dont le programme a besoin
  capability dac_read_search,          # lire des fichiers malgré les permissions
  capability chown,

  # ── Le script lui-même et ses interpréteurs
  /usr/local/bin/backup.sh r,
  /bin/bash                ix,         # exécuté DANS ce même profil
  /usr/bin/tar             mrix,
  /usr/bin/gzip            mrix,
  /usr/bin/find            mrix,

  # ── Les données : lecture seule sur la source
  /srv/data/           r,
  /srv/data/**         r,

  # ── La destination : lecture et écriture
  /var/backups/        rw,
  /var/backups/**      rw,

  # ── Le journal
  /var/log/backup.log  w,

  # ── Interdictions explicites (prioritaires sur toute autorisation)
  deny /etc/shadow        rwklx,
  deny /home/*/.ssh/**    rwklx,
  deny /root/**           rwklx,
}
```

**Les lettres de permission**, qui constituent l'essentiel de la syntaxe :

| Lettre | Signification |
|--------|---------------|
| `r` | Lecture |
| `w` | Écriture |
| `a` | Ajout en fin de fichier (*append*) uniquement |
| `k` | Verrouillage du fichier |
| `l` | Création de liens |
| `m` | Projection en mémoire exécutable (*mmap* — nécessaire pour les binaires et bibliothèques) |
| `ix` | Exécuter en **héritant** du profil courant |
| `Px` | Exécuter sous **son propre** profil (qui doit exister), avec nettoyage de l'environnement |
| `Cx` | Exécuter sous un sous-profil défini dans ce fichier |
| `Ux` | Exécuter **sans confinement** — à éviter, c'est un trou dans la politique |

**Les jokers de chemin :**

| Motif | Correspond à |
|-------|--------------|
| `/srv/data/*` | Les fichiers **directement** dans `/srv/data/` |
| `/srv/data/**` | Tout, **récursivement**, sous `/srv/data/` |
| `/home/*/.config/` | Le `.config` de n'importe quel utilisateur |
| `/var/log/app-[0-9].log` | Une classe de caractères |

> [!IMPORTANT]
> **Chaque règle se termine par une virgule.** C'est l'erreur de syntaxe n° 1 dans les profils AppArmor, et `apparmor_parser` la signale avec un numéro de ligne peu bavard.
>
> Sur les versions antérieures à AppArmor 3, la syntaxe d'inclusion est `#include <abstractions/base>` (avec le `#`, qui n'est **pas** un commentaire ici). La forme moderne `include <…>` est équivalente.

Les abstractions disponibles se trouvent dans `/etc/apparmor.d/abstractions/` — il y en a pour presque tout :

```bash
ls /etc/apparmor.d/abstractions/
```

```text
apache2-common  base  bash  consoles  dbus  fonts  nameservice
nis  openssl  perl  php  python  ssl_certs  user-tmp  wutmp  ...
```

### 4. Lire un refus dans les logs

C'est le réflexe à acquérir : quand une application confinée se comporte étrangement, la réponse est dans les logs du noyau.

```bash
sudo dmesg | grep -i apparmor
```

```bash
sudo journalctl -k | grep -i "apparmor=\"DENIED\""
```

Ou, si `auditd` est installé :

```bash
sudo grep apparmor /var/log/audit/audit.log
```

Un refus se lit ainsi :

```text
audit: type=1400 audit(1765108800.123:456): apparmor="DENIED" operation="open"
  profile="/usr/sbin/nginx" name="/srv/www/index.html" pid=1234 comm="nginx"
  requested_mask="r" denied_mask="r" fsuid=33 ouid=0
```

| Champ | Ce qu'il vous dit |
|-------|-------------------|
| `apparmor="DENIED"` | L'accès a été **bloqué** (`ALLOWED` en mode complain) |
| `operation="open"` | Ce que le programme tentait de faire |
| `profile="/usr/sbin/nginx"` | **Quel profil** a bloqué |
| `name="/srv/www/index.html"` | **Quelle ressource** était visée |
| `requested_mask="r"` | Le droit demandé — ici la lecture |

La règle manquante se déduit directement des deux dernières colonnes : `/srv/www/** r,`.

### 5. Créer un profil, méthode complète

C'est le workflow standard, en cinq temps.

```bash
# 1. Générer un squelette de profil et lancer l'application sous surveillance
sudo aa-genprof /usr/local/bin/backup.sh
```

`aa-genprof` reste en attente. Dans **un second terminal**, on fait tourner l'application dans toutes ses conditions d'usage :

```bash
# 2. Exercer l'application : tous les cas d'usage, y compris les cas d'erreur
/usr/local/bin/backup.sh
/usr/local/bin/backup.sh --full
```

```bash
# 3. Revenir au premier terminal et appuyer sur "S" (Scan).
#    aa-genprof propose chaque accès observé : Allow / Deny / Glob / Abort.
#    On répond une fois par accès, puis "F" (Finish) pour enregistrer.
```

```bash
# 4. Laisser tourner en complain quelques jours, puis récolter ce qui manque
sudo aa-logprof
```

```bash
# 5. Passer en enforce quand plus aucun refus n'apparaît
sudo aa-enforce /usr/local/bin/backup.sh
```

> [!TIP]
> `aa-logprof` est la commande à relancer périodiquement : elle relit les logs, présente chaque nouvel accès observé et met le profil à jour. C'est elle qui fait le gros du travail — on écrit rarement un profil entièrement à la main.

### 6. Modifier un profil fourni par un paquet

Éditer directement `/etc/apparmor.d/usr.sbin.nginx` fonctionne, mais vos modifications entreront en conflit à la prochaine mise à jour du paquet. Le mécanisme prévu pour cela est le dossier `local/` :

```bash
sudo nano /etc/apparmor.d/local/usr.sbin.nginx
```

```text
# Autoriser nginx à servir un docroot personnalisé
/srv/monsite/** r,
/var/log/monsite/*.log w,
```

Le profil principal contient déjà, en fin de bloc, la ligne `include <local/usr.sbin.nginx>` qui charge ce fichier.

### 7. Recharger

```bash
# Recharger un profil précis
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx

# Vérifier la syntaxe sans charger
sudo apparmor_parser -Q /etc/apparmor.d/usr.sbin.nginx

# Recharger l'ensemble
sudo systemctl reload apparmor
```

> [!CAUTION]
> Un profil AppArmor ne s'applique à un processus qu'**au moment de son exécution**. Recharger le profil d'un service déjà démarré ne reconfine pas le processus en cours : il faut redémarrer le service.
>
> ```bash
> sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx
> sudo systemctl restart nginx
> ```

---

## SELinux (RHEL, Fedora, CentOS, Rocky)

### 1. Les modes et l'état

```bash
sestatus
```

```text
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      33
```

| Mode | Comportement |
|------|--------------|
| **Enforcing** | Applique la politique et bloque |
| **Permissive** | N'empêche rien, mais journalise tout ce qui aurait été bloqué |
| **Disabled** | SELinux est complètement désactivé |

```bash
getenforce                  # mode actuel
sudo setenforce 0           # passer en permissif — TEMPORAIRE, perdu au reboot
sudo setenforce 1           # repasser en enforcing
```

Le mode permanent est dans `/etc/selinux/config` :

```text
# /etc/selinux/config
SELINUX=enforcing
# SELINUX peut valoir : enforcing | permissive | disabled
SELINUXTYPE=targeted
```

> [!CAUTION]
> **Ne mettez jamais `SELINUX=disabled` pour « faire marcher » une application.** C'est la mauvaise réponse à un problème réel, et elle a un coût caché : pendant que SELinux est désactivé, les nouveaux fichiers ne reçoivent pas d'étiquette. Le jour où vous le réactivez, plus rien ne démarre, et il faut réétiqueter tout le système :
>
> ```bash
> sudo touch /.autorelabel && sudo reboot     # peut prendre de longues minutes
> ```
>
> Si vous devez déboguer, utilisez **`permissive`** : la politique continue de journaliser tout ce qu'elle aurait bloqué, sans casser la production, et le retour en `enforcing` est immédiat.

### 2. Le contexte de sécurité

SELinux étiquette **tout** : fichiers, processus, ports, utilisateurs. Une étiquette a quatre champs :

```text
system_u : object_r : httpd_sys_content_t : s0
   │          │              │              │
 user      role           TYPE           niveau MLS
```

> [!IMPORTANT]
> Dans la politique `targeted` (celle de toutes les distributions par défaut), **seul le `type` compte** en pratique. Les autres champs n'entrent en jeu que dans les configurations multi-niveaux (MLS), très rares. Concentrez-vous sur le champ qui finit par `_t`.

On lit les contextes avec l'option `-Z`, présente dans la plupart des commandes :

```bash
ls -Z /var/www/html
```

```text
unconfined_u:object_r:httpd_sys_content_t:s0 index.html
```

```bash
ps -eZ | grep nginx
```

```text
system_u:system_r:httpd_t:s0    1234 ?  00:00:00 nginx
```

```bash
id -Z                      # mon propre contexte
netstat -Z / ss -Z         # contexte des sockets
```

### 3. Le principe du Type Enforcement

La politique est une liste de règles de la forme : *un processus de type A peut faire telle action sur un objet de type B*.

```text
Processus nginx  →  httpd_t
Fichier servi    →  httpd_sys_content_t
Règle            →  allow httpd_t httpd_sys_content_t : file { read getattr open };
```

Conséquence directe, et cause de 90 % des problèmes rencontrés : **un fichier créé au mauvais endroit ou déplacé avec `mv` porte la mauvaise étiquette**, et le service ne peut pas le lire — même en `chmod 777`.

```bash
# Le piège classique : cp respecte le contexte de destination, mv conserve celui d'origine
cp fichier.html /var/www/html/      # ✅ prend httpd_sys_content_t
mv ~/fichier.html /var/www/html/    # ❌ garde user_home_t → 403 Forbidden
```

### 4. Changer un contexte

**Temporairement** — perdu au prochain réétiquetage :

```bash
sudo chcon -t httpd_sys_content_t /var/www/html/index.html
sudo chcon -R -t httpd_sys_content_t /var/www/html/
```

**Définitivement** — on enregistre la règle dans la politique, puis on l'applique :

```bash
# 1. Déclarer la règle pour ce chemin (et tout ce qu'il contient)
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/monsite(/.*)?"

# 2. Appliquer la règle aux fichiers déjà présents
sudo restorecon -Rv /srv/monsite
```

| Commande | Portée |
|----------|--------|
| `chcon` | Change l'étiquette **maintenant**, sans mémoire — un `restorecon` l'écrase |
| `semanage fcontext -a` | Enregistre la règle **dans la politique** — c'est la source de vérité |
| `restorecon` | Réapplique aux fichiers ce que dit la politique |

> [!TIP]
> **Le réflexe à retenir : `semanage fcontext` puis `restorecon`.** `chcon` est pratique pour tester une hypothèse en trente secondes, mais ne doit jamais rester dans une procédure d'installation.
>
> `semanage` vient du paquet `policycoreutils-python-utils` (`sudo dnf install policycoreutils-python-utils`).

Consulter les règles enregistrées :

```bash
sudo semanage fcontext -l | grep monsite
```

### 5. Les booléens

Beaucoup de comportements courants sont déjà prévus par la politique et pilotés par de simples interrupteurs. C'est la solution la plus propre à un très grand nombre de blocages.

```bash
getsebool -a | grep httpd
```

```text
httpd_can_network_connect --> off
httpd_can_network_connect_db --> off
httpd_can_sendmail --> off
httpd_enable_homedirs --> off
httpd_use_nfs --> off
```

```bash
# -P rend le changement permanent (persistant au reboot)
sudo setsebool -P httpd_can_network_connect on
```

Quelques booléens que l'on rencontre très souvent :

| Booléen | À activer quand… |
|---------|------------------|
| `httpd_can_network_connect` | Le serveur web doit appeler une API ou un backend (reverse proxy) |
| `httpd_can_network_connect_db` | Le serveur web se connecte à une base de données distante |
| `httpd_enable_homedirs` | Le serveur web sert des fichiers depuis les `/home` |
| `ftpd_full_access` | Le serveur FTP doit accéder à tout le système de fichiers |
| `nis_enabled` | Authentification via NIS/LDAP dans certains cas |

### 6. Les ports

SELinux étiquette aussi les ports. Faire écouter un service sur un port non standard demande donc de le déclarer.

```bash
# Quels ports sont autorisés pour le type ssh_port_t ?
sudo semanage port -l | grep ssh
```

```text
ssh_port_t                     tcp      22
```

```bash
# Autoriser sshd à écouter sur le port 2222
sudo semanage port -a -t ssh_port_t -p tcp 2222
```

```bash
# Idem pour un serveur web sur le port 8080
sudo semanage port -a -t http_port_t -p tcp 8080
```

> [!IMPORTANT]
> Changer le port d'un service demande **trois** actions cohérentes, et il est facile d'en oublier une :
> 1. modifier la configuration du service (`Port 2222` dans `sshd_config`) ;
> 2. ouvrir le port dans le pare-feu (`firewall-cmd --permanent --add-port=2222/tcp`) ;
> 3. déclarer le port à SELinux (`semanage port -a`).

### 7. Diagnostiquer un refus

Les refus SELinux s'appellent des **AVC denials** (*Access Vector Cache*).

```bash
sudo ausearch -m AVC -ts recent
```

```text
type=AVC msg=audit(1765108800.123:456): avc:  denied  { read } for  pid=1234
  comm="nginx" name="index.html" dev="sda1" ino=12345
  scontext=system_u:system_r:httpd_t:s0
  tcontext=unconfined_u:object_r:user_home_t:s0
  tclass=file permissive=0
```

Le message se lit comme une phrase :

| Champ | Lecture |
|-------|---------|
| `denied { read }` | L'action refusée |
| `comm="nginx"` | Le programme concerné |
| `scontext=…httpd_t` | **Source** : le type du processus |
| `tcontext=…user_home_t` | **Cible** : le type de l'objet visé — voilà l'anomalie |
| `tclass=file` | La classe d'objet |
| `permissive=0` | 0 = réellement bloqué ; 1 = seulement journalisé |

Ici, tout est dit : un processus `httpd_t` a tenté de lire un fichier resté étiqueté `user_home_t`. La correction est un `restorecon`.

**Une aide plus lisible** est fournie par `setroubleshoot` :

```bash
sudo dnf install setroubleshoot-server
sudo sealert -a /var/log/audit/audit.log
```

`sealert` traduit chaque refus en français courant et propose la ou les commandes correctives — souvent le bon booléen ou le bon `semanage fcontext`.

**En dernier recours**, quand aucun booléen ni aucune étiquette existante ne convient, on génère un module de politique sur mesure :

```bash
# Examiner ce que la règle générée autoriserait — À LIRE avant d'appliquer
sudo ausearch -m AVC -ts recent | audit2allow -m monapp

# Générer et installer le module
sudo ausearch -m AVC -ts recent | audit2allow -M monapp
sudo semodule -i monapp.pp
```

> [!WARNING]
> `audit2allow` autorise **exactement** ce qui a été refusé, sans jugement. Si un refus provient d'une réelle tentative d'intrusion ou d'une application mal configurée, vous venez d'inscrire la faille dans la politique.
> Lisez toujours la sortie de `audit2allow -m` avant d'installer le module, et n'y recourez qu'après avoir écarté les booléens et le réétiquetage.

---

## Méthode de diagnostic

Face à un service qui refuse d'accéder à une ressource alors que les permissions POSIX semblent correctes :

| Étape | AppArmor | SELinux |
|-------|----------|---------|
| **1. Confirmer que c'est bien le MAC** | `sudo aa-complain /usr/sbin/nginx` puis retester | `sudo setenforce 0` puis retester |
| **2. Lire le refus** | `sudo dmesg \| grep DENIED` | `sudo ausearch -m AVC -ts recent` |
| **3. Corriger proprement** | Ajouter la règle dans `/etc/apparmor.d/local/…` | Booléen (`setsebool -P`), étiquette (`semanage fcontext` + `restorecon`) ou port (`semanage port -a`) |
| **4. Refermer** | `sudo aa-enforce /usr/sbin/nginx` | `sudo setenforce 1` |

> [!CAUTION]
> L'étape 4 n'est pas optionnelle. Un `setenforce 0` « le temps de voir » qui n'est jamais annulé est le mode de défaillance le plus courant de SELinux en production — la machine tourne des mois sans aucune protection, et personne ne s'en aperçoit.
>
> Vérification à intégrer à vos contrôles réguliers :
> ```bash
> getenforce                      # doit répondre Enforcing
> sudo aa-status | head -3        # doit annoncer des profils en enforce mode
> ```

> [!TIP]
> Quand un service refuse obstinément d'accéder à un fichier alors que les permissions POSIX sont correctes, pensez à AppArmor/SELinux **avant** de chercher ailleurs. Le mode *permissive* / *complain* permet de confirmer le diagnostic en trente secondes, sans désactiver la protection.

---

## Récapitulatif

| Domaine | Commandes clés |
|---------|----------------|
| **ACL** | `getfacl`, `setfacl -m`, `setfacl -d -m`, `setfacl -x`, `setfacl -b`, `namei -l` |
| **Sudo** | `sudo -l`, `sudoedit`, `visudo`, `visudo -c`, `/etc/sudoers.d/`, `sudoreplay` |
| **Firewall** | `ufw allow/deny/limit`, `firewall-cmd --permanent`, `iptables -L -v -n`, `nft list ruleset`, `ss -tulpn` |
| **SSH** | `ssh-keygen -t ed25519`, `ssh-copy-id`, `sshd -t`, `sshd -T`, `ssh -v`, `~/.ssh/config` |
| **AppArmor** | `aa-status`, `aa-complain`, `aa-enforce`, `aa-genprof`, `aa-logprof`, `apparmor_parser -r` |
| **SELinux** | `sestatus`, `getenforce`, `ls -Z`, `semanage fcontext`, `restorecon`, `setsebool -P`, `ausearch`, `sealert` |

### Les réflexes de base sur un serveur exposé

1. **SSH** : pas de connexion root directe, pas d'authentification par mot de passe, clés `ed25519` avec passphrase.
2. **Pare-feu** : actif, en liste blanche — tout fermé sauf ce qui est strictement nécessaire.
3. **Sudo** : droits explicites et nominatifs, liste blanche de commandes, jamais de `NOPASSWD: ALL`, `sudoedit` plutôt que `sudo vim`.
4. **Fichiers** : les ACL pour les cas fins, jamais de `chmod 777` — et un `namei -l` avant de conclure qu'une permission est cassée.
5. **MAC** : AppArmor ou SELinux laissé en *enforcing*, jamais désactivé pour contourner un problème.
6. **Mises à jour** de sécurité appliquées régulièrement.
7. **Logs** consultés — `auth.log`, `journalctl -t sudo`, `fail2ban-client status` — et pas seulement écrits.

### Le réflexe qui traverse tout le chapitre

> [!TIP]
> **Gardez toujours une seconde session ouverte.**
>
> Que vous modifiiez `sshd_config`, le pare-feu ou le sudoers, la manipulation peut vous couper l'accès à la machine. Une session déjà authentifiée, laissée ouverte en parallèle, n'est affectée par aucun de ces changements : c'est votre porte de secours, et elle coûte dix secondes à ouvrir.
>
> Complétez-la, sur les opérations réseau, par une remise à zéro programmée :
>
> ```bash
> echo "ufw --force reset" | sudo at now + 5 minutes
> ```
>
> Et vérifiez **avant** de recharger, à chaque fois qu'un outil le permet :
>
> ```bash
> sudo sshd -t              # SSH
> sudo visudo -c            # sudoers
> sudo nft -c -f /etc/nftables.conf   # nftables
> sudo apparmor_parser -Q /etc/apparmor.d/monprofil
> ```

---

⬅️ [Précédent : 04 · Paquets et services](04_installation_et_services.md) · 🏠 [Sommaire](README.md) · [Suivant : 06 · Shell scripting ➡️](06_shellscript/01_Base/base.md)
