### Installation

#### Préinstallation/Mise à jours

Généralement  avant d'installer des packets, on va mettre à jours la base de données des packets local.

L'idée est de récupéré les dernières versions disponible des packets avant d'en installer un.

Sur Debian :
```shell
sudo apt update
```

Sur redhat cette opération est intégrée à l'installation.

#### Installation

Sur basé debian 
```shell
sudo apt install nom_du_packet1 nom_packet2 ...
```

sur basé redhat
```shell
sudo yum install nom_packet ...
```
```shell
sudo dnf install package1 ...
```

#### Mettre à jours un ou des packets 

Sur debian (doit impérativement être précédé d'un "apt update") :
```shell
sudo apt upgrade
```
```shell
sudo apt upgrade package_name
```

Sur redhat :
```shell
sudo yum update
```
```shell
sudo dnf update
```

### Supprimer un packet

Sur debian :
```shell
sudo apt remove package_name
```

Sur redhat :
```shell
sudo yum remove package_name
```
```shell
sudo dnf remove package_name
```

#### Rechercher un packet

Opération similaire à rechercher une application dans l'app store ou le play store

Sur debian :
```shell
sudo apt search package_name
```

Sur redhat : 
```shell
sudo yum search package_name
```
```shell
sudo dnf search package_name
```

### Services Management

Les services sont des programmes qui vont tourner en background sur la machine (serveur)

Quelques exemples de services : 
- serveur http/https
- serveur ssh
- serveur de base de données
- ...

#### Activer un service 

Activer le service revient à démarrer ce service au démarrage de la machine 
```shell
sudo systemctl enable service_name
```

#### Désactiver un service
```shell
sudo systemctl disable service_name
```

#### Démarrer un service

Permet de démarrer un service 
```shell
sudo systemctl start service_name
```

#### Arrêter un service
```shell
sudo systemctl stop service_name
```

#### Redémarrer un service
```shell
sudo systemctl restart service_name
```

#### Recharger un service (mettre à jour ses configurations)
```shell
sudo systemctl reload service_name
```

#### Inspecter l'état actuel d'un service
```shell
sudo systemctl status service_name
```

#### Lister les services
```shell
systemctl list-units --type=service
```

```shell
systemctl list-units --type=service --state=running
```

```shell
systemctl list-units --type=service --state=active
```

Lister tous les services qui ont un problème
```shell
systemctl list-units --type=service --state=failed
```

### Création d'un service Custom

Il faudra créer un fichier pour ce service (habituellement appellé nom_du_service.service)

Ce fichier doit être créer dans "/etc/systemd/system/SERVICENAME.service"
```txt
[Unit]
Description=Example de service
After=multi-user.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=SERVICE_USERNAME
ExecStart=SERVICE_COMMAND

[Install]
RequiredBy=multi-user.target
```

Remplacer SERVICE_USERNAME par le username de l'utilisateur à qui le service sera lié

Remplacer SERVICE_COMMAND par la commande lancé lar le service !!! Toujours mettre le chemin absolu des commandes 
et des fichiers utilisé. Il faut aussi faire attention à ce que l'uitilisateur du service, ai le droit 
d'executer cette commande.

Trouver le chemin absolu d'une commande :
```shell
type -a COMMAND
```

Les targets disponibles :

| systemd targets     | SystemV runlevel | target aliases        | Description |
|---------------------|------------------|-----------------------|-------------|
| default.target      |                  |                       | This target is always aliased with a symbolic link to either multi-user.target or graphical.target. systemd always uses the default.target to start the system. The default.target should never be aliased to halt.target, poweroff.target, or reboot.target. |
| graphical.target    | 5                | runlevel5.target      | Multi-user.target with a GUI                                                                                                         |
|                     | 4                | runlevel4.target      | Unused. Runlevel 4 was identical to runlevel 3 in the SystemV world. This target could be created and customized to start local services without changing the default multi-user.target. |
| multi-user.target   | 3                | runlevel3.target      | All services running, but command-line interface (CLI) only |
|                     | 2                | runlevel2.target      | Multi-user, without NFS, but all other non-GUI services running |
| rescue.target       | 1                | runlevel1.target      | A basic system, including mounting the filesystems with only the most basic services running and a rescue shell on the main console |
| emergency.target    | S                |                       | Single-user mode—no services are running; filesystems are not mounted. This is the most basic level of operation with only an emergency shell running on the main console for the user to interact with the system. |
| halt.target         |                  |                       | Halts the system without powering it down |
| reboot.target       | 6                | runlevel6.target      | Reboot |
| poweroff.target     | 0                | runlevel0.target      | Halts the system and turns the power off |

Example
```txt
[Unit]
Description=Example de service
After=multi-user.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=debian
ExecStart=/usr/bin/node /home/debian/test.js

[Install]
RequiredBy=multi-user.target
```

Après il faut activer le service et le démarrer.

### Journald

JournalD est l'outils de journalisation de linux sous systemd, son utilisation est relativement simple : 
```shell
journalctl -t service_name
```

exemple :
```shell
journalctl -t apache2
```

### CRON

Cron permet de lancer des tâches automatiquement à des moments précis

Peut nécéssité une installation : 
```shell
sudo apt install cron
```

Cron est service : 
```shell
# Debian 
systemctl status cron

# Redhat 
systemctl status crond
```

Pour pouvoir paramètrer les crons il faut utiliser la commande crontab -e
```shell
crontab -e
```

Lister les cron de l'utilisateur 
```shell
crontab -l
```

Supprimer le crontab de l'utilisateur :
```shell
crontab -r
```

Configuration d'un fichier crontab personnel
```txt
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * command to be executed
```

Par exemple si je veux excuter toutes les minutes la commande ls 
```txt
* * * * * /usr/bin/ls
```

Toutes les heures (XXh00) : 
```txt
0 * * * * /usr/bin/ls
```

| expression CRON   | Signification                 |
|-------------------|-------------------------------|
| * * * * *         | Toutes les minutes            |
| 0 * * * *         | Toutes les heures (XXh00)     |
| 30 2 * * *        | Tous les jours à 2h30         |
| 0 8 * * 1-5       | Du Lundi au vendredi à 8h00   |
| */5 * * * *       | Toutes les 5 min              |
| * */2 * * *       | Toutes les 2h                 |
| 0 0 1 1 *         | Tous les 1er janvier          |
| @reboot           | Tous les reboot               |
| @yearly           | => 0 0 1 1 *                  |
| @monthly          | Tous les mois                 |
| @weekly           | Toutes les semaines           |
| @daily            | Tous les jours                |
| @hourly           | Toutes les heures             |

On a aussi le crontab du système (à ne pas modifier normalement les crontab par utilisateurs suffiront)

Il se trouve dans /etc/crontab

Celui-ci à un champ supplémentaire qui est l'utilisateur qui sera utilisé pour lancer le cron.

```shell
sudo journalctl -t cron
```
```shell
cat /etc/crontab
```
```terminaloutput
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

Par défaut sur certain système (redhat) cron envoie les sorties des cron par mail (si disponible), 
il peut être donc intéressent de rediriger la sortie des commandes lancées via cron : 

```shell
* * * * * /bin/ls > /dev/null 2>&1
```
Dans cet exemple je redirige la sortie vers /dev/null et je redirige les erreurs vers la stdout (donc /dev/null)

Dans la plus part des cas on redirige la sortie vers un fichier de log : 
```shell
* * * * * /bin/ls >> /tmp/customlog
```

```shell
* * * * * /bin/ls >> /home/debian/cronlogs/customlog
```

Pour voir les logs de cron (!!! nécéssite rsyslog !!!):
```shell
sudo apt install rsyslog
```
```shell
cat /var/log/syslog | grep CRON
```
```terminaloutput
2025-12-12T09:31:01.451982+00:00 balrog-c2-srv CRON[2708800]: (debian) CMD (/usr/bin/echo "Hello" >> /home/debian/hello.txt)
2025-12-12T09:32:01.459068+00:00 balrog-c2-srv CRON[2708812]: (debian) CMD (/usr/bin/echo "Hello" >> /home/debian/hello.txt)
2025-12-12T09:33:01.465445+00:00 balrog-c2-srv CRON[2708824]: (debian) CMD (/usr/bin/echo "Hello" >> /home/debian/hello.txt)
```

Ces logs ne montrent pas les sorties des commandes, il faut donc bien gérer les logs de celles-ci sois-même.

#### Bonnes pratiques
- Toujours utiliser les chemin absolu 
- Toujours tester les scripts manuellement avant de les utiliser dans un cron
- Rediriger les sortie pour faciliter le debugging
- Documenter vos cron
- Vérifier régulèrement les logs des exécutions de vos crons
