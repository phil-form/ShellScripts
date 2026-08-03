1) Créer un cron qui écrit la date du jours toutes les minutes dans un fichiers (dates.txt) dans votre home directory
```shell
* * * * * /usr/bin/date >> /home/debian/dates.txt
```
2) Créer un second cron copie les données du fichier dates.txt dans dates.txt.bak supprime toutes les données du fichier dates.txt toutes les 10 min
```shell
*/10 * * * * /usr/bin/cat $HOME/dates.txt >> dates.txt.bak && echo "" > $HOME/dates.txt
```
3) Créer un cron qui écrit votre nom d'utilisateur toutes les heures dans /tmp/username.txt
```shell
* */1 * * * /usr/bin/whoami >> /tmp/username.txt
```
4) Faire un cron qui nettoie le fichier /tmp/username.txt et le fichier dates.txt.bak tous les jours à minuit rediriger les erreurs de celui-ci dans un fichier cleanup.txt dans votre home directory
```shell
0 0 * * * /usr/bin/rm /tmp/username.txt $HOME/dates.txt.bak 2>> /tmp/cleanup.txt
```
5) une fois par mois copier les données de cleanup.txt dans cleanup.txt.bak et nettoyer les données de cleanup.txt
```shell
0 0 1 * * /bin/cat /tmp/cleanup.txt >> /tmp/cleanup.txt.bak && echo "" >> /tmp/cleanup.txt
```
6) une fois par ans supprimer cleanup.bak.txt
```shell
@yearly /bin/rm /tmp/cleanup.txt.bak
```