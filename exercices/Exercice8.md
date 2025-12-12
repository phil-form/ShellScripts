1) Exercice 1 — Gestion de groupe sudo
```shell
sudo useradd dev1 alice bob
```
```shell
sudo usermod -aG sudo dev1
```
```shell
sudo su dev1 -
```
```shell
sudo ls /root
```

2) Exercice 2 — Sudoers de base
```shell
sudo visudo
```
```terminaloutput
alice   ALL=(ALL:ALL) ALL
bob     ALL=(root) /bin/systemctl restart apache2
```
3) Exercice 3 — NOPASSWD
```shell
sudo visudo
```
```terminaloutput
dev1    ALL=(root)  NOPASSWD: /bin/mount
dev1    ALL=(ALL:ALL) !/bin/rm
```

4) Exercice 4 — Alias
```shell
sudo visudo
```
```terminaloutput
# Cmnds aliases
Cmnd_Alias WEB = /bin/systemctl restart apache2, /bin/systemctl restart nginx

# Users aliases
User_Alias  OPS = bob, alice

# Rules
OPS     ALL=(ALL:ALL)   NOPASSWD: WEB
```