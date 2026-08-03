1) Installer un serveur SSH
Depuis le serveur Linux
```shell
sudo apt install ssh
```
2) Configurer le pare-feu

Depuis le serveur Linux
```shell
sudo ufw enable
sudo ufw allow ssh
```
3) connecter vous via votre pc hote à votre VM en ssh.

Depuis windows
```shell
powershell > ssh username@SERVER_IP
```

4) Créer sur votre hote une paire de clés ssh

Depuis windows
```shell
powershell > ssh-keygen
```

5) Copier votre clé publique sur le serveur

Depuis windows
```shell
powershell > ssh username@SERVER_IP
```
Devrait demander le mots de passe de l'utilisateur sur le serveur

une fois connecté sur linux 
```shell
bash $ vim .ssh/authorized_keys
```
et copier/coller le contenu de la clé
```shell
chmod 600 .ssh/authorized_keys
```
ou
```shell
ssh-copy-id username@SERVER_IP
```
6) Tester la connexion avec clé

Depuis windows
```shell
powershell > ssh username@SERVER_IP
```
Devrait demander la passphrase de la clé 

7) Supprimer la possibilité de se connecter en ssh via mots de passe
```shell
sudo vim /etc/ssh/ssh_config
```
```terminaloutput
#   PasswordAuthentication yes
```
```terminaloutput
    PasswordAuthentication no
```