# 🧰 Point 03 — Commandes essentielles

*Chapitre [03 · Commandes essentielles](../03_commandes_essentielles.md)*

> [!NOTE]
> **Objectifs** : `tree`, `grep`, `sed`, `awk`, le trio `cut`/`sort`/`uniq`/`wc`/`tr`, `find`, `xargs`, `du`/`df`, `tar`, et les utilitaires du quotidien (`tee`, `diff`, `stat`, `file`, `watch`, `which`/`type`).

> [!TIP]
> **Jeu de données de départ** — exécutez ceci pour avoir de quoi travailler :
> ```bash
> mkdir -p labo/{app,logs,archives,conf} && cd labo
> seq 1 200 | sed 's/^/ligne /' > logs/app.log
> printf 'INFO ok\nERROR db down\nwarning cache\nERROR timeout\nINFO ok\n' > logs/server.log
> cat > logs/access.log <<'EOF'
> 192.168.1.24 - GET /index 200
> 10.0.0.8 - GET /health 200
> 192.168.1.24 - POST /login 200
> 192.168.1.24 - GET /tickets 500
> 203.0.113.7 - GET /index 404
> 10.0.0.8 - GET /index 200
> 192.168.1.24 - GET /index 200
> EOF
> cat > conf/app.conf <<'EOF'
> host = localhost
> #PermitRootLogin yes
> DEBUG verbose
>
> port = 8080
> EOF
> head -c 2M /dev/zero > archives/dump.bin
> gzip -c logs/access.log > archives/masque.bin   # un gzip déguisé en .bin
> touch app/main.py app/utils.py app/README.md logs/old.tmp
> ```

### Exercice 3.1 — Visualiser avec `tree`

1. Affichez l'arborescence de `labo/` limitée à **2 niveaux**.
2. Affichez **uniquement les dossiers**.
3. Affichez l'arborescence avec la **taille** de chaque fichier.
### Exercice 3.2 — Chercher du texte avec `grep`

Sur `logs/server.log` :

1. Affichez les lignes contenant `ERROR`, avec leur **numéro de ligne**.
2. Comptez combien de lignes contiennent `ERROR`.
3. Affichez les lignes contenant `info`, **sans tenir compte de la casse**.
4. Affichez toutes les lignes qui **ne** contiennent **pas** `INFO`.
5. Cherchez `ERROR` **récursivement** dans `logs/`, en n'affichant que le **nom des fichiers** concernés.
### Exercice 3.3 — Remplacer du texte avec `sed`

Sur `conf/app.conf` :

1. Affichez à l'écran le fichier avec `localhost` remplacé par `127.0.0.1` — **sans** modifier le fichier.
2. Faites réellement ce remplacement dans le fichier, en gardant une **sauvegarde** de l'original.
3. En une seule commande, supprimez les lignes contenant `DEBUG` **et** les lignes vides.
4. Commentez (préfixez d'un `#`) la ligne qui **commence** par `port`.
5. Affichez uniquement les **lignes 1 à 2** du fichier.
> [!CAUTION]
> Avant tout `sed -i`, lancez la commande **sans** `-i` pour vérifier le résultat à l'écran. `sed -i` écrase sans confirmation.

### Exercice 3.4 — Traiter des colonnes avec `awk`

Sur `logs/access.log` (colonnes : IP, `-`, méthode, chemin, code) :

1. Affichez uniquement la **1re colonne** (les adresses IP).
2. Affichez l'**IP et le chemin** des requêtes dont le **code vaut 500**.
3. Sur `/etc/passwd` (séparateur `:`), affichez le **nom et l'UID** des comptes dont l'**UID ≥ 1000**.
4. Produisez le **classement des IP les plus actives** du log (IP + nombre de requêtes, du plus fréquent au moins fréquent).
5. Comptez le **nombre de requêtes par méthode HTTP** (`GET`, `POST`…), avec un bloc `END`.
### Exercice 3.5 — Découper, trier, compter (`cut`, `sort`, `uniq`, `wc`, `tr`)

1. Avec `cut`, affichez la **liste des noms d'utilisateurs** de `/etc/passwd`.
2. Combien de comptes contient `/etc/passwd` ? (une seule commande)
3. Affichez la liste **triée et dédoublonnée** des méthodes HTTP présentes dans `access.log`.
4. Mettez la chaîne `helpdesk` en **majuscules** avec `tr`.
5. `ps aux` aligne ses colonnes avec des espaces multiples. En vous servant de `tr -s`, réduisez ces espaces puis extrayez avec `cut` la **1re** et la **11e** colonne (utilisateur + commande). *(Pourquoi `awk` serait ici plus simple ?)*
### Exercice 3.6 — Trouver des fichiers avec `find`

Depuis `labo/` :

1. Trouvez tous les fichiers `.py`.
2. Trouvez tous les **dossiers**.
3. Trouvez les fichiers de plus de **1 Mo**.
4. Trouvez les fichiers modifiés il y a **moins de 24 h**.
5. Listez le détail (`ls -lh`) de chaque `.log` trouvé, via `-exec`.
6. Supprimez tous les fichiers `.tmp` trouvés.
### Exercice 3.7 — Passer les résultats à `xargs`

1. Cherchez, **uniquement dans les fichiers `.conf`** de `labo/`, ceux qui contiennent le mot `port` — en combinant `find` et `xargs grep -l`.
2. Copiez tous les fichiers `.py` de `labo/` vers un dossier `/tmp/sauvegarde/` (à créer), avec `xargs -I {}`.
3. Un fichier nommé `mon rapport.tmp` (avec une espace) casse un `find … | xargs rm` naïf. Écrivez la version **robuste** qui gère les espaces.
### Exercice 3.8 — Espace disque : `du` et `df`

1. Poids de chaque sous-dossier de `labo/`, en lisible, sur **un seul niveau**.
2. Classez-les **du plus léger au plus lourd**.
3. Affichez l'espace **disponible** sur vos partitions, en lisible.
### Exercice 3.9 — Archiver avec `tar`

1. Créez une archive **non compressée** `app.tar` du dossier `app/`.
2. Créez une archive **compressée gzip** `logs.tar.gz` du dossier `logs/`.
3. **Listez** le contenu de `logs.tar.gz` sans l'extraire.
4. Extrayez `logs.tar.gz` dans un dossier `restore/` (à créer).
### Exercice 3.10 — Les utilitaires du quotidien

1. Affichez le **vrai type** du fichier `archives/masque.bin`. L'extension dit-elle la vérité ?
2. Ajoutez la ligne `127.0.0.1 helpdesk.local` à `/etc/hosts` — fichier qui demande les droits root — en utilisant `tee` (et non `>`). Pourquoi `sudo echo … > /etc/hosts` ne marche-t-il pas ?
3. Comparez `conf/app.conf` et sa sauvegarde `.bak` (exercice 3.3) avec `diff`.
4. Où se trouve l'exécutable `python3` ? La commande `ll` est-elle un binaire, un alias ou une fonction ?
5. *(À décrire, pas à laisser tourner)* : quelle commande réafficherait `df -h` toutes les 5 secondes en surlignant les changements ?
### Exercice 3.11 — Tout combiner

1. Comptez, en une ligne, le nombre de fichiers `.py` sous `labo/` (`find … | wc -l`).
2. Créez une archive `code.tar.gz` contenant **exactement** les fichiers `.py` trouvés par `find` (`find … | tar … -T -`).
3. À partir de `access.log`, produisez en une seule ligne le **top 3 des IP** ayant provoqué une erreur (code `500` ou `404`). *(Indice : `awk` pour filtrer + extraire, puis `sort | uniq -c | sort -rn | head`.)*
---
---

# 📦 Point 04 — Paquets, services & cron

*Chapitre [04 · Paquets, services et tâches planifiées](../04_installation_et_services.md)*

> [!NOTE]
> **Objectifs** : `apt`, `systemctl`, un service `.service` custom, `journalctl`, `cron`.

> [!IMPORTANT]
> Les manipulations `systemctl` demandent une vraie VM (un conteneur ne fait pas tourner `systemd` par défaut).

### Exercice 4.1 — Gestion des paquets (`apt`)

1. Mettez à jour l'index des paquets.
2. Installez `htop`, `tree` et `cron` en une commande.
3. Recherchez le paquet `ncdu`, puis affichez ses informations détaillées.
4. Listez les paquets installés et comptez-les (avec un pipe).
5. Supprimez `htop`.
### Exercice 4.2 — Piloter un service existant

Sur le service `cron` :

1. Affichez son **état**.
2. Redémarrez-le.
3. Vérifiez qu'il est bien **activé au démarrage** ; sinon, activez-le au boot **et** démarrez-le en une seule commande.
### Exercice 4.3 — Créer un service custom

L'ASBL veut un petit service « battement de cœur » qui écrit l'heure dans un log toutes les 10 secondes.

1. Créez le script `/usr/local/bin/heartbeat.sh` :
```bash
   #!/bin/bash
   while true; do
     echo "$(date '+%F %T') heartbeat" >> /var/log/heartbeat.log
     sleep 10
   done
```
Rendez-le exécutable avec des droits corrects pour un script système.
2. Écrivez l'unité `heartbeat.service` (Type `simple`, redémarrage automatique, lancée après `multi-user.target`, exécutant votre script), installez-la dans `/etc/systemd/system/`.
3. Rechargez la configuration de systemd, puis **activez au boot et démarrez** le service en une commande.
4. Vérifiez son état.

### Exercice 4.4 — Lire les logs (`journalctl`)

1. Affichez les logs du service `heartbeat`.
2. Affichez seulement les **20 dernières** lignes.
3. **Suivez** ses logs en direct.
4. Affichez les logs du service depuis **« il y a 5 minutes »**.
### Exercice 4.5 — Tâches planifiées (`cron`)

Écrivez les lignes de crontab (via `crontab -e`) qui réalisent :

1. Toutes les minutes, écrire la date dans `/home/debian/tick.txt`.
2. Toutes les 5 minutes, sauvegarder `tick.txt` en `tick.txt.bak` puis le vider.
3. Du lundi au vendredi à 8h00, écrire `bonjour` dans `/tmp/matin.txt`.
4. Tous les jours à minuit, supprimer `/tmp/matin.txt`, en **redirigeant les erreurs** vers `/home/debian/cron-erreurs.log`.
5. À chaque **redémarrage** de la machine, lancer votre `heartbeat.sh`.
6. Affichez enfin la liste de vos tâches planifiées.
> [!TIP]
> Bonnes pratiques cron : toujours des **chemins absolus** (`/usr/bin/date`, pas `date`), et rediriger les sorties, car cron n'a pas votre environnement de shell habituel.