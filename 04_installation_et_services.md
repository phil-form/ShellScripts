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

Ce fichier doit être créer dans "/etc/systemd/system/servicename.service"
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

Remplacer SERVICE_COMMAND par la commande lancé lar le service 

Les targets disponibles :
| systemd targets     | SystemV runlevel | target aliases       | Description |
|---------------------|------------------|-----------------------|-------------|
| default.target      |                  |                       | This target is always aliased with a symbolic link to either multi-user.target or graphical.target. systemd always uses the default.target to start the system. The default.target should never be aliased to halt.target, poweroff.target, or reboot.target. |
| graphical.target    | 5                | runlevel5.target      | Multi-user.target with a GUI |
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

### CRON