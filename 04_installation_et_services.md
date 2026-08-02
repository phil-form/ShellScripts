# 04 · Installation de paquets, services et tâches planifiées

> [!NOTE]
> **Objectifs du chapitre**
> - Installer, mettre à jour, rechercher et supprimer des paquets (Debian et RedHat)
> - Piloter des services avec `systemctl`
> - Écrire son propre service `systemd`
> - Consulter les logs avec `journalctl`
> - Planifier des tâches récurrentes avec `cron`

## Sommaire

1. [Gestion des paquets](#gestion-des-paquets)
2. [Gestion des services](#gestion-des-services)
3. [Création d'un service custom](#création-dun-service-custom)
4. [Journald](#journald)
5. [CRON](#cron)
6. [Récapitulatif](#récapitulatif)

---

## Gestion des paquets

Deux grandes familles de distributions, deux gestionnaires de paquets :

| Famille | Distributions | Gestionnaire |
|---------|---------------|--------------|
| **Debian** | Debian, Ubuntu, Mint, Raspberry Pi OS | `apt` |
| **RedHat** | RHEL, CentOS, Fedora, Rocky, Alma | `yum` (ancien) / `dnf` (actuel) |

### Préinstallation / mise à jour de l'index

Avant d'installer un paquet, on met à jour la base de données **locale** des paquets, pour récupérer les dernières versions disponibles.

Sur Debian :

```bash
sudo apt update
```

Sur RedHat, cette opération est intégrée à l'installation.

> [!IMPORTANT]
> `apt update` met à jour la **liste** des paquets disponibles ; il n'installe rien.
> `apt upgrade` installe effectivement les nouvelles versions. Les deux vont toujours ensemble.

### Installer

Sur base Debian :

```bash
sudo apt install nom_du_paquet1 nom_paquet2 ...
```

Sur base RedHat :

```bash
sudo yum install nom_paquet ...
```

```bash
sudo dnf install paquet1 ...
```

### Mettre à jour

Sur Debian (doit impérativement être précédé d'un `apt update`) :

```bash
sudo apt upgrade
```

```bash
sudo apt upgrade nom_paquet
```

Sur RedHat :

```bash
sudo yum update
```

```bash
sudo dnf update
```

### Supprimer

Sur Debian :

```bash
sudo apt remove nom_paquet
```

Sur RedHat :

```bash
sudo yum remove nom_paquet
```

```bash
sudo dnf remove nom_paquet
```

> [!TIP]
> `apt remove` laisse les fichiers de configuration en place ; `apt purge` les supprime aussi.
> `sudo apt autoremove` nettoie les dépendances devenues inutiles.

### Rechercher

Opération équivalente à chercher une application dans un store.

Sur Debian :

```bash
apt search nom_paquet
```

Sur RedHat :

```bash
yum search nom_paquet
```

```bash
dnf search nom_paquet
```

### Tableau de correspondance

| Action | Debian (`apt`) | RedHat (`dnf`) |
|--------|----------------|----------------|
| Mettre à jour l'index | `apt update` | *(automatique)* |
| Installer | `apt install pkg` | `dnf install pkg` |
| Mettre à jour | `apt upgrade` | `dnf update` |
| Supprimer | `apt remove pkg` | `dnf remove pkg` |
| Rechercher | `apt search pkg` | `dnf search pkg` |
| Info sur un paquet | `apt show pkg` | `dnf info pkg` |
| Lister les installés | `apt list --installed` | `dnf list installed` |

---

## Gestion des services

Les services sont des programmes qui tournent en arrière-plan sur la machine (le serveur).

Quelques exemples :

- serveur HTTP/HTTPS
- serveur SSH
- serveur de base de données
- …

### Les commandes systemctl

| Commande | Effet |
|----------|-------|
| `sudo systemctl enable nom` | **Activer** : démarrer le service au boot de la machine |
| `sudo systemctl disable nom` | Désactiver le démarrage automatique |
| `sudo systemctl start nom` | Démarrer le service **maintenant** |
| `sudo systemctl stop nom` | Arrêter le service |
| `sudo systemctl restart nom` | Redémarrer le service |
| `sudo systemctl reload nom` | Recharger sa configuration **sans** couper le service |
| `sudo systemctl status nom` | Inspecter l'état actuel du service |

```bash
sudo systemctl enable service_name
```

```bash
sudo systemctl start service_name
```

```bash
sudo systemctl status service_name
```

> [!IMPORTANT]
> `enable` ≠ `start`. `enable` programme le démarrage **au prochain boot**, `start` démarre **tout de suite**.
> Pour faire les deux d'un coup : `sudo systemctl enable --now service_name`.

### Lister les services

```bash
systemctl list-units --type=service
```

```bash
systemctl list-units --type=service --state=running
```

```bash
systemctl list-units --type=service --state=active
```

Lister tous les services en échec :

```bash
systemctl list-units --type=service --state=failed
```

---

## Création d'un service custom

Il faut créer un fichier pour ce service (habituellement nommé `nom_du_service.service`), dans `/etc/systemd/system/SERVICENAME.service` :

```ini
[Unit]
Description=Exemple de service
After=multi-user.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=SERVICE_USERNAME
ExecStart=SERVICE_COMMAND

[Install]
WantedBy=multi-user.target
```

- Remplacer `SERVICE_USERNAME` par le nom de l'utilisateur auquel le service sera lié.
- Remplacer `SERVICE_COMMAND` par la commande lancée par le service.

> [!WARNING]
> **Toujours mettre le chemin absolu** des commandes et des fichiers utilisés : `systemd` n'a pas le même `PATH` que votre shell.
> Vérifiez aussi que l'utilisateur du service a bien le droit d'exécuter cette commande et d'accéder aux fichiers concernés.

Trouver le chemin absolu d'une commande :

```bash
type -a COMMAND
```

### Les targets disponibles

| systemd target | Runlevel SystemV | Alias | Description |
|----------------|------------------|-------|-------------|
| `default.target` | | | Toujours un lien symbolique vers `multi-user.target` ou `graphical.target`. C'est ce que systemd utilise pour démarrer le système. Ne jamais l'aliaser vers `halt`, `poweroff` ou `reboot`. |
| `graphical.target` | 5 | `runlevel5.target` | `multi-user.target` avec une interface graphique |
| | 4 | `runlevel4.target` | Inutilisé. Identique au runlevel 3 sous SystemV. Peut être créé et personnalisé pour démarrer des services locaux sans modifier `multi-user.target`. |
| `multi-user.target` | 3 | `runlevel3.target` | Tous les services démarrés, en ligne de commande uniquement |
| | 2 | `runlevel2.target` | Multi-utilisateur, sans NFS, tous les autres services non graphiques démarrés |
| `rescue.target` | 1 | `runlevel1.target` | Système de base : systèmes de fichiers montés, services minimaux et shell de secours sur la console |
| `emergency.target` | S | | Mode mono-utilisateur — aucun service, aucun système de fichiers monté. Le niveau le plus basique, avec uniquement un shell d'urgence. |
| `halt.target` | | | Arrête le système sans couper l'alimentation |
| `reboot.target` | 6 | `runlevel6.target` | Redémarrage |
| `poweroff.target` | 0 | `runlevel0.target` | Arrête le système et coupe l'alimentation |

### Exemple complet

```ini
[Unit]
Description=Exemple de service
After=multi-user.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=debian
ExecStart=/usr/bin/node /home/debian/test.js

[Install]
WantedBy=multi-user.target
```

Il reste ensuite à recharger systemd, puis à activer et démarrer le service :

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now mon_service
```

> [!IMPORTANT]
> Le `daemon-reload` est indispensable après **toute** création ou modification d'un fichier `.service` : sans lui, systemd continue d'utiliser l'ancienne version en mémoire.

---

## Journald

`journald` est l'outil de journalisation de Linux sous systemd. Son utilisation est relativement simple :

```bash
journalctl -u service_name
```

Exemple :

```bash
journalctl -u apache2
```

| Option | Effet |
|--------|-------|
| `-u nom` | Filtrer sur une **unité** systemd (le cas le plus courant) |
| `-t nom` | Filtrer sur un *syslog identifier* (le nom que le programme donne à ses logs) |
| `-f` | Suivre les logs en direct |
| `-n 50` | Afficher les 50 dernières lignes |
| `--since "1 hour ago"` | Filtrer par date |
| `-p err` | Ne garder que les messages d'un niveau de priorité donné |

---

## CRON

Cron permet de lancer des tâches automatiquement à des moments précis.

Peut nécessiter une installation :

```bash
sudo apt install cron
```

Cron est lui-même un service :

```bash
# Debian
systemctl status cron

# RedHat
systemctl status crond
```

### Gérer son crontab

| Commande | Effet |
|----------|-------|
| `crontab -e` | Éditer ses tâches planifiées |
| `crontab -l` | Lister ses tâches planifiées |
| `crontab -r` | **Supprimer** tout son crontab |

> [!CAUTION]
> `crontab -r` supprime l'intégralité du crontab sans demander confirmation — et `-r` est juste à côté de `-e` sur le clavier. Gardez une copie de vos crontabs : `crontab -l > ~/crontab.bak`.

### Syntaxe d'un crontab

```text
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * command to be executed
```

Par exemple, pour exécuter la commande `ls` toutes les minutes :

```text
* * * * * /usr/bin/ls
```

Toutes les heures (à XXh00) :

```text
0 * * * * /usr/bin/ls
```

### Expressions courantes

| Expression CRON | Signification |
|-----------------|---------------|
| `* * * * *`   | Toutes les minutes |
| `0 * * * *`   | Toutes les heures (XXh00) |
| `30 2 * * *`  | Tous les jours à 2h30 |
| `0 8 * * 1-5` | Du lundi au vendredi à 8h00 |
| `*/5 * * * *` | Toutes les 5 minutes |
| `0 */2 * * *` | Toutes les 2 heures |
| `0 0 1 1 *`   | Tous les 1er janvier |
| `@reboot`     | À chaque démarrage |
| `@yearly`     | ⇒ `0 0 1 1 *` |
| `@monthly`    | Tous les mois |
| `@weekly`     | Toutes les semaines |
| `@daily`      | Tous les jours |
| `@hourly`     | Toutes les heures |

### Le crontab système

Il existe aussi un crontab système, dans `/etc/crontab` (à ne pas modifier en principe : les crontabs par utilisateur suffisent).

Celui-ci a un **champ supplémentaire** : l'utilisateur qui exécutera la tâche.

```bash
cat /etc/crontab
```

```text
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
17 *	* * *	root	cd / && run-parts --report /etc/cron.hourly
25 6	* * *	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
47 6	* * 7	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.weekly; }
52 6	1 * *	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.monthly; }
#
```

### Gérer les sorties des tâches cron

Par défaut, sur certains systèmes (RedHat notamment), cron envoie la sortie des tâches **par mail** (si un MTA est disponible). Il est donc intéressant de rediriger explicitement la sortie des commandes lancées via cron :

```text
* * * * * /bin/ls > /dev/null 2>&1
```

Dans cet exemple, je redirige la sortie vers `/dev/null` et je redirige les erreurs vers la sortie standard (donc, elle aussi, vers `/dev/null`).

Dans la plupart des cas, on redirige plutôt vers un fichier de log :

```text
* * * * * /bin/ls >> /tmp/customlog
```

```text
* * * * * /bin/ls >> /home/debian/cronlogs/customlog
```

### Voir les logs de cron

```bash
sudo journalctl -t CRON
```

Ou via syslog (**nécessite `rsyslog`**) :

```bash
sudo apt install rsyslog
```

```bash
cat /var/log/syslog | grep CRON
```

```text
2025-12-12T09:31:01.451982+00:00 balrog-c2-srv CRON[2708800]: (debian) CMD (/usr/bin/echo "Hello" >> /home/debian/hello.txt)
2025-12-12T09:32:01.459068+00:00 balrog-c2-srv CRON[2708812]: (debian) CMD (/usr/bin/echo "Hello" >> /home/debian/hello.txt)
2025-12-12T09:33:01.465445+00:00 balrog-c2-srv CRON[2708824]: (debian) CMD (/usr/bin/echo "Hello" >> /home/debian/hello.txt)
```

> [!IMPORTANT]
> Ces logs montrent que la commande **a été lancée**, mais pas ce qu'elle a produit. Il faut donc gérer soi-même les logs de sortie de ses scripts.

### Bonnes pratiques

> [!TIP]
> - Toujours utiliser des **chemins absolus** (cron a un `PATH` minimal et n'exécute pas votre `.bashrc`).
> - Toujours **tester le script manuellement** avant de le mettre dans un cron.
> - **Rediriger les sorties** pour faciliter le debugging.
> - **Documenter** ses crons (un commentaire au-dessus de chaque ligne).
> - **Vérifier régulièrement** les logs d'exécution de ses crons.

---

## Récapitulatif

| Commande | Rôle |
|----------|------|
| `apt update` / `apt upgrade` | Mettre à jour l'index / les paquets |
| `apt install` / `apt remove` | Installer / supprimer un paquet |
| `systemctl start` / `stop` / `restart` | Piloter un service |
| `systemctl enable --now` | Activer au boot **et** démarrer |
| `systemctl status` | État d'un service |
| `systemctl daemon-reload` | Recharger après modification d'un `.service` |
| `journalctl -u nom -f` | Suivre les logs d'un service |
| `crontab -e` / `-l` | Éditer / lister ses tâches planifiées |

---

⬅️ [Précédent : 03 · Commandes essentielles](03_commandes_essentielles.md) · 🏠 [Sommaire](README.md) · [Suivant : 05 · Sécurité ➡️](05_securite.md)
