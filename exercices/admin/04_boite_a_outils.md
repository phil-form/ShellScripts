# 🧰 A4 · La boîte à outils

*Chapitre [03 · Commandes essentielles](../../03_commandes_essentielles.md)*

> [!NOTE]
> **Objectifs** : exploiter les logs et les fichiers système avec `grep`, `sed`, `awk`, `cut`/`sort`/`uniq`,
> retrouver n'importe quoi avec `find` et `xargs`, diagnostiquer un disque plein avec `du` et `df`, archiver
> avec `tar`. C'est l'outillage qu'on utilise toute la journée, tous les jours.

---

## 🧰 Jeu de données

Si votre serveur est trop neuf pour avoir des logs intéressants, posez ce jeu de travail :

```bash
mkdir -p /srv/labo/{logs,conf,archives,web} && cd /srv/labo

cat > logs/auth.log <<'EOF'
Mar  1 08:02:11 srv-tickets sshd[1420]: Accepted publickey for alice from 10.0.0.14 port 51422 ssh2
Mar  1 08:14:02 srv-tickets sshd[1503]: Failed password for root from 203.0.113.9 port 39112 ssh2
Mar  1 08:14:05 srv-tickets sshd[1503]: Failed password for root from 203.0.113.9 port 39112 ssh2
Mar  1 08:14:09 srv-tickets sshd[1503]: Failed password for invalid user admin from 203.0.113.9 port 39118 ssh2
Mar  1 08:21:44 srv-tickets sudo:    alice : TTY=pts/0 ; PWD=/home/alice ; USER=root ; COMMAND=/usr/bin/apt update
Mar  1 09:02:31 srv-tickets sshd[1688]: Failed password for bob from 198.51.100.4 port 44120 ssh2
Mar  1 09:02:35 srv-tickets sshd[1688]: Accepted password for bob from 198.51.100.4 port 44120 ssh2
Mar  1 09:40:00 srv-tickets sudo:      bob : user NOT in sudoers ; TTY=pts/1 ; PWD=/home/bob ; USER=root ; COMMAND=/bin/systemctl restart nginx
Mar  1 10:11:52 srv-tickets sshd[1902]: Failed password for root from 203.0.113.9 port 40122 ssh2
EOF

cat > logs/nginx-access.log <<'EOF'
10.0.0.14 - - [01/Mar/2024:09:01:02] "GET /api/tickets HTTP/1.1" 200 1420
203.0.113.9 - - [01/Mar/2024:09:01:44] "GET /admin.php HTTP/1.1" 404 162
203.0.113.9 - - [01/Mar/2024:09:01:45] "GET /wp-login.php HTTP/1.1" 404 162
10.0.0.14 - - [01/Mar/2024:09:03:10] "POST /api/tickets HTTP/1.1" 201 88
198.51.100.4 - - [01/Mar/2024:09:05:00] "GET /api/tickets HTTP/1.1" 500 512
10.0.0.14 - - [01/Mar/2024:09:07:31] "GET /api/health HTTP/1.1" 200 12
203.0.113.9 - - [01/Mar/2024:09:09:00] "GET /.env HTTP/1.1" 404 162
198.51.100.4 - - [01/Mar/2024:09:12:20] "GET /api/tickets HTTP/1.1" 500 512
EOF

cp /etc/ssh/sshd_config conf/sshd_config.copie
head -c 40M /dev/zero > archives/dump-2023.bin
head -c 12M /dev/zero > logs/vieux.log
touch -d '2 years ago' archives/dump-2023.bin
touch web/index.html web/.env conf/vhost.conf logs/old.tmp
```

---

## Exercice 4.1 — `grep` : chercher dans les logs

Sur `logs/auth.log` :

1. Toutes les tentatives d'authentification **échouées**, avec leur numéro de ligne.
2. Le **nombre** de ces tentatives.
3. Les connexions **réussies**, quelle que soit la casse.
4. Toutes les lignes **sauf** celles concernant `alice`.
5. Les lignes contenant `Failed` **ou** `NOT in sudoers`, en une seule commande *(regex étendue)*.
6. Une recherche **récursive** de `203.0.113.9` dans tout `/srv/labo`, en n'affichant que les noms de fichiers.
7. Sur `/etc/ssh/sshd_config` : toutes les directives actives, c'est-à-dire les lignes qui ne sont
   **ni vides ni commentées**. *(La commande que vous utiliserez toute votre carrière.)*

---

## Exercice 4.2 — `sed` : modifier des configurations

Sur `conf/sshd_config.copie` — **jamais sur le vrai fichier tant que la commande n'est pas validée** :

1. Affichez le fichier avec `#PermitRootLogin` décommenté et mis à `no`, **sans** modifier le fichier.
2. Faites réellement la modification, en gardant une sauvegarde.
3. Changez le port de `22` à `2222`, en ne touchant qu'à la directive `Port`.
4. Commentez toutes les lignes commençant par `PasswordAuthentication`.
5. Supprimez d'un coup les lignes vides **et** les lignes commentées, et écrivez le résultat dans
   `conf/sshd_config.propre`.
6. Affichez uniquement les lignes 10 à 25 du fichier d'origine.
7. Pourquoi le changement de séparateur (`s|…|…|`) est-il indispensable dès qu'on manipule des chemins ?

> [!CAUTION]
> `sed -i` écrase sans confirmation et sans `undo`. Sur un fichier de `/etc`, on lance **toujours** la commande
> sans `-i` d'abord, et on garde un `.bak` jusqu'à ce que le service ait redémarré sans erreur.

---

## Exercice 4.3 — `awk` : analyser

1. Sur `/etc/passwd` : le nom et l'UID de tous les comptes dont l'**UID ≥ 1000**.
2. Sur `/etc/passwd` : les comptes ayant un shell **autre que** `/usr/sbin/nologin` ou `/bin/false`.
3. Sur `logs/auth.log` : le **top des IP** à l'origine d'échecs d'authentification, la plus insistante d'abord.
4. Sur `logs/auth.log` : la liste des utilisateurs visés par ces échecs.
5. Sur `logs/nginx-access.log` : le nombre de requêtes **par code HTTP**, dans un bloc `END`.
6. Sur `logs/nginx-access.log` : les IP ayant provoqué au moins une erreur `500`.
7. Sur `logs/nginx-access.log` : le **volume total** d'octets servis (dernière colonne), affiché en Mo.
8. Sur la sortie de `ps aux` : la mémoire totale consommée par les processus d'un utilisateur donné.

---

## Exercice 4.4 — `cut`, `sort`, `uniq`, `wc`, `tr`

1. La liste des noms d'utilisateurs de `/etc/passwd`, avec `cut`.
2. Le nombre de comptes de la machine, en une commande.
3. La liste triée et dédoublonnée des IP présentes dans `nginx-access.log`, avec leur nombre d'occurrences.
4. Les shells utilisés sur la machine, dédoublonnés et comptés — combien de comptes par shell ?
5. Sur la sortie de `df -h`, extrayez le point de montage et le pourcentage d'occupation, alignés,
   en compressant les espaces avec `tr -s` puis `cut`. Pourquoi `awk` fait-il ça plus proprement ?

---

## Exercice 4.5 — `find` : retrouver

1. Tous les fichiers `.conf` sous `/etc`, sans les erreurs de permission à l'écran
   *(indice : rediriger la sortie d'erreur)*.
2. Tous les fichiers de plus de **10 Mo** sous `/srv` et `/var`.
3. Les fichiers **non modifiés depuis plus d'un an** dans `/srv/labo/archives`.
4. Les fichiers modifiés il y a **moins de 60 minutes** sous `/etc` — utile après une intervention.
5. Les fichiers appartenant à un utilisateur donné, hors de son *home*.
6. Les fichiers **world-writable** (droits en écriture pour tout le monde) sous `/srv` : pourquoi est-ce un
   point d'audit ?
7. Les fichiers `.tmp` de `/srv/labo`, listés puis supprimés.
8. Le détail (`ls -lh`) de chaque `.log` trouvé, via `-exec`.

---

## Exercice 4.6 — `xargs` : enchaîner

1. Cherchez `PermitRootLogin` **uniquement dans les fichiers `.conf`** de `/etc/ssh/`, en combinant
   `find` et `xargs grep`.
2. Copiez tous les `.conf` de `/srv/labo/conf` vers `/srv/labo/archives/conf/` avec `xargs -I {}`.
3. Comptez le nombre total de lignes de tous les logs de `/srv/labo/logs`.
4. Un fichier `mon rapport final.log` casse un `find … | xargs rm` naïf : créez-le, constatez, puis écrivez
   la version **robuste**.
5. Écrivez la commande qui compresse tous les `.log` de plus de 7 jours — d'abord avec `-exec`,
   puis avec `xargs`. Quelle différence de performance, et pourquoi ?

---

## Exercice 4.7 — Le disque est plein

C'est l'appel du vendredi soir. `/` est à 98 %.

1. Affichez l'occupation de toutes les partitions, en lisible.
2. Affichez le poids de chaque dossier de premier niveau de `/`, sans descendre plus bas.
3. Descendez : trouvez les **10 plus gros dossiers** de `/var`.
4. Trouvez les **10 plus gros fichiers** de la machine.
5. `df` dit que le disque est plein mais la somme des `du` ne le retrouve pas. Citez **deux** causes classiques
   *(indice : un fichier supprimé mais toujours ouvert par un processus ; les inodes)*.
6. Combien reste-t-il d'**inodes** libres ?
7. Écrivez la ligne qui compresse tous les logs de plus de 30 jours de `/var/log/ticketflow` — et expliquez
   pourquoi `logrotate` fait mieux que votre ligne. *(À revoir en [A5](05_paquets_services_cron.md).)*

---

## Exercice 4.8 — `tar` : sauvegarder

1. Archivez `/etc` en `/srv/ticketflow/backups/etc-<date>.tar.gz`.
2. Listez le contenu de l'archive sans l'extraire.
3. Extrayez-en **un seul fichier** dans un dossier de restauration.
4. Créez une archive de `/srv/labo` **en excluant** `archives/` et les `.tmp`.
5. Créez une archive contenant exactement les fichiers renvoyés par un `find` *(indice : `-T -`)*.
6. Quelle option préserve propriétaires, droits et ACL ? Pourquoi est-ce vital pour une sauvegarde système ?
7. Vérifiez l'intégrité d'une archive existante et produisez sa somme de contrôle.

---

## Exercice 4.9 — Les utilitaires du diagnostic

1. Écrivez la sortie d'un audit à l'écran **et** dans un fichier, en une commande.
2. Comparez `conf/sshd_config.copie` et le `sshd_config` d'origine, en version lisible.
3. Affichez le vrai type de `archives/dump-2023.bin` — l'extension dit-elle la vérité ?
4. Affichez toutes les métadonnées de `/etc/shadow` : droits, propriétaire, dates, inode.
5. `systemctl` est-il un binaire, un alias, une fonction ? Où se trouve-t-il ?
6. Quelle commande réafficherait `df -h` toutes les 5 secondes en surlignant les changements ?

---

## Exercice 4.10 — Le rapport d'incident

Une seule ligne de commande par question.

1. Le **top 5 des IP** ayant échoué à s'authentifier, avec leur nombre de tentatives.
2. La liste des utilisateurs qui ont utilisé `sudo` aujourd'hui, dédoublonnée.
3. Les IP ayant demandé des chemins suspects (`.env`, `wp-login`, `admin.php`) dans le log nginx.
4. Le nombre de requêtes en erreur `5xx` par IP, trié.
5. Une archive `/srv/ticketflow/backups/incident-<date>.tar.gz` contenant tous les fichiers de `logs/`
   qui mentionnent l'IP fautive.
6. Un fichier `/root/rapport-incident.txt` rassemblant les résultats des cinq points précédents,
   chacun précédé d'un titre.

---

## ✅ Vérification

- Vous produisez le top des IP attaquantes d'un `auth.log` sans hésiter sur l'ordre des commandes.
- Vous savez répondre à « pourquoi le disque est plein ? » en moins de cinq commandes.
- `/srv/ticketflow/backups/` contient une archive de `/etc` restaurable **avec ses droits**.
- `/root/rapport-incident.txt` existe et se lit tout seul.
- Vous savez expliquer chaque étage de chacun de vos pipes.
