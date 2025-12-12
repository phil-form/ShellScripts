# Securité

## ACLs (Access Control Lists)

C'est une méthode qui va permettre d'aller plus loin que les règles standard posix
 Owner  Gr  Other
-rwx    rwx rwx

Récupérer les ACLs d'un fichier/dossier
```shell
getfacl hello.txt
```
```terminaloutput
# file: hello.txt
# owner: debian
# group: debian
user::rw-
group::r--
other::r--
```
```shell
ls -la hello.txt
```
```terminaloutput
-rw-r--r-- 1 debian debian 378 Dec 12 10:29 hello.txt
```

Voir si des ACLs sont appliquées avec ls :
```shell
ls -la hello.txt
```
```terminaloutput
-rw-r-xr--+ 1 debian debian   378 Dec 12 10:29 hello.txt
```
Le petit "+" signifie qu'il y a des droits supplémentaires aux POSIX classiques

#### Pour modifier des ACLs

1) Modifier un user : 
```shell
setfacl -m u:test:rw hello.txt 
```
```shell
getfacl hello.txt 
```
```terminaloutput
# file: hello.txt
# owner: debian
# group: debian
user::rw-
user:test:r--
group::r--
group:test:r-x
mask::r-x
other::r--
```

2) Modifier un groupe :
```shell
setfacl -m g:test:r hello.txt 
```
```shell
getfacl hello.txt
```
```terminaloutput
# file: hello.txt
# owner: debian
# group: debian
user::rw-
group::r--
group:test:r--
mask::r--
other::r--
```

```shell
setfacl -m g:test:rx hello.txt 
```
```shell
getfacl hello.txt
```
```terminaloutput
# file: hello.txt
# owner: debian
# group: debian
user::rw-
group::r--
group:test:r-x
mask::r-x
other::r--
```

3) Comme pour chmod, je peux appliquer une règles de manière récursive sur un dossier :
```shell
setfacl -R u:test:r dossier/
```

4) Retirer des droits :
```shell
setfacl -x u:test hello.txt
```
```shell
getfacl hello.txt 
```
```terminaloutput
# file: hello.txt
# owner: debian
# group: debian
user::rw-
group::r--
group:test:r-x
mask::r-x
other::---
```

```shell
setfacl -x g:test hello.txt
```
```shell
getfacl hello.txt 
```
```terminaloutput
# file: hello.txt
# owner: debian
# group: debian
user::rw-
group::r--
mask::r--
other::---
```

5) Droits par défaut :
Les droits par défaut sont applicable uniquement sur les dossier, ceux-ci vont permettre d'appliquer ces ACLs
comme valeur par défaut pour tout élément créé à l'intérieur du dossier.

```shell
setfacl -m d:u:test:rw shared/
```
```shell
setfacl -m d:g:dev:rw shared/
```

6) Mask
```shell
setfacl -m u:test:rwx test.sh
```
```shell
setfacl -m m:r test.sh
```
Ici l'utilisateur test aura les droits rwx, mais ne pourra qu'uniquement lire le fichier car le mask l'empêche d'avoir les droits write et execute.

## Sudo/Sudoers

Sudo (super user do) va me permettre d'exectuer une commande en tant qu'un autre utilisateur (root par défaut)
```shell
sudo cat /var/log/syslog 
```

Par défaut on doit rajouter les utilisateurs au groupe sudo pour pouvoir utiliser sudo (sauf si on configure le sudoers)

En général on garde le groupe sudo pour les administrateur system

Je peux aussi préciser l'utilisalteur que je utiliser :
```shell
sudo -u USERNAME cat /home/USERNAME/private.txt
```

Préserver les variables d'environment (intéressent dans certains cas particulier dans un script) : 
```shell
sudo -E cat /var/log/syslog
```

Passer en tant qu'admin
```shell
sudo su -
```

```terminaloutput
root    ALL=(ALL:ALL)   ALL
```
Sigification

USER    HOSTS=(UTILISTEUR DONT ON PEUT PRENDRE L'IDENTITÉ)  COMMANDE_QUE_L'ON_PEUT_EXECUTER     

Si précédé d'un % alors la règle s'applique aux groupes

```shell
%sudo   ALL=(ALL:ALL)   ALL
```

Je peux préciser l'utilisateur qui pourra être utilisé en sudo : 

```shell
test  ALL=(debian)    ALL
```

Ici test ne peux qu'impersonner debian

```shell
test ALL=(root)   /usr/sbin/systemctl
```

Ici je précise que test ne peux utiliser que systemctl en tant que root.

```shell
test ALL=(root)   /usr/sbin/systemctl restart apache2
```

Ici je précise qu'il ne peux que faire un restart d'apache2 en tant que root.

```shell
test ALL=(devops) ALL,!/bin/rm
```

Ici test peux impersonner devops pour toutes les commandes sauf rm.

#### NOPASSWD

L'argument NOPASSWD va permettre de dire que l'on pourra executer sudo sans utiliser de mots de passe pour faire une ou plusieurs actions

!!! Éviter d'en abuser celà peut vite entrainer des problèmes de sécurité !!!

```shell
test ALL=(root)  NOPASSWD: /usr/sbin/systemctl restart apache2
```

Ici je précise que l'utilisateur test pourra executer la commade sans connaître le mots de passe du root.

#### Alias 

Je vais pouvoir faire des alias pour :

1) Les hotes
```terminaloutput
Host_Alias  SERVER_WEB=server1name,server2name
```
```terminaloutput
root    SERVER_WEB=(root)   ALL
```

2) les utilisateurs 
```terminaloutput
User_Alias  ADMINS = debian, bob
```
```terminaloutput
ADMINS    SERVER_WEB=(root)   ALL
```

3) les commandes
```terminaloutput
Cmnd_Alias  MAINTENANCE = /usr/bin/apt, /usr/sbin/systemctl
```
```terminaloutput
ADMINS    SERVER_WEB=(root)   MAINTENANCE,TEST
```

#### Voir les logs

```shell
sudo cat /var/log/auth.log
```
```shell
sudo journalctl -t sudo
```

## Firewall

## SSH

## AppArmor/SELinux
