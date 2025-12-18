## TMUX (Terminal Multiplexer)

C'est outils assez intéressent quand on fait de l'administrion système à distance.

Cet outil va nous permettre de gérer des sessions sur le server et de récupérer
celles-ci en cas de déconnexion.

1) Installation
```shell
sudo apt install tmux
```

2) Démarrer une session tmux
```shell
tmux
```

```shell
tmux new -s session-name
```

3) Sortir d'une session (en la gardant active)

ctrl + b (lacher les touches) appyer sur d

pour les raccourci suivant je vais abbrégé par :
ctrl + b => d

4) Lister les sessions actives 
```shell
tmux ls
```
ou dans tmux

ctrl + b => s

5) Rejoindre une session 
```shell
tmux a -t session-name
```
ou 
```shell
tmux attach -t session-name
```

6) Détruire une session

```shell
tmux kill-session -t session-name
```
```shell
tmux kill -t session-name
```
```shell
tmux k -t session-name
```

7) Renommer une session

ctrl + b => shift + $

8) Changer la cwd 

si on ouvre un nouveau terminal dans une session il va se positionner à un CWD
(current working directory) par défaut

ctrl + b => shift + :

on va pouvoir ensuite rentrer la commande

a -c /new/directory

Ici l'idée est de se positionner automatiquement dans le bon dossier en ouvrant des nouveaux
terminaux dans une session tmux (par exemple le dossier de travail d'un projet)

9) Activer le scrolling 

ctrl + b => [

sortir du scrolling :

q

10) Rechercher dans le terminal 

il faut d'abord être en mode scrolling 

ctrl + b => [

ensuite on peut faire :

ctrl + r

et tapper ce que l'on veut chercher

11) Avec oh-my-tmux on peut utiliser la souris

raccourci : 

ctrl + b => m

#### Split

Je vais pouvoir diviser le terminal en plusieurs parties avec : 

Split horizontal :

ctrl + b => % 

Split vertical : 

ctrl + b => "

1) Changer de panneau : 

ctrl + b => flèche directionnelles (celle qui va dans le sense du panneau désiré)

2) Cycle les terminaux (split)

circuler dans le sense des aiguilles d'une montre :

ctrl + b => o

dans le sense inverse : 

ctrl + b => shift + {

3) Passer sur le split le plus utilisé

ctrl + b => ;

#### Fenêtre

1) Création de fenêtre :

ctrl + b => c 

2) Changer le titre d'une fenetre

ctrl + b => ,

3) changer le terminal actuel de fenêtre

ctrl + b => shift + !

4) fermer la fenetre active

ctrl + b => shift + &

5) Changer de fenetre 

pour aller à la fenetre suivante: 

ctrl + b => n

fenetre précédente : 

ctrl + b => p

6) Lister les fenetre

ctrl + b => w

### Oh my tmux (améliorer tmux et ajoute le support de la souris)

https://github.com/gpakosz/.tmux