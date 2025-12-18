### Les conditions 

Les conditions (if/else/elif) vont me permettre d'exécuter des parties d'un script sous certaines conditions.

Donc par exemple : 
```shell
# Si la directory du projet existe déjà, j'arrête le script
if [ -d "./$PROJECT_NAME"]; then
  echo "Le projet existe déjà !"
  # Permet d'arrêter le script en renvoyant 0 (pas d'erreur, tout autre valeur sera prise comme code d'erreur)
  exit 0
fi
```

#### Test de vérifications

On peut avoir plusieurs arguments :

| arguments | Signification                          |
|-----------|----------------------------------------|
| -f        | vérifie si un fichier existe           |
| -d        | vérifie si un dossier existe           |
| -e        | existe                                 |
| -r        | Si un fichier/dossier est lisible      |
| -w        | Si un fichier/dossier est modifiable   |
| -x        | Si un fichier/dossier est exécutable   |

#### Test de comparaison

| arguments | Signification                                                      |
|-----------|--------------------------------------------------------------------|
| -eq       | Vérifier si deux choses sont égales                                |
| -ne       | L'inverse de -eq                                                   |
| -gt       | Vérifie si l'argument de gauche est plus grand que celui de droite |
| -lt       | Vérifie si l'argument de gauche est plus petit que celui de droite |
| -ge       | Plus grand ou égale                                                |
| -le       | Plus petit ou égale                                                |
| -n        | Permet de vérifier si un variable n'est pas vide                   |
| =~        | Comparaison avec expression régulière                              |


Exemples : 
```shell
VALUE=5

if ["$VALUE" -gt 10]; then
  echo "VALUE > 10"  
fi

if ["$VALUE" -ge 10]; then
  echo "VALUE >= 10"  
fi

if ["$VALUE" -eq 10]; then
  echo "VALUE == 10"  
fi

if ["$VALUE" -ne 10]; then
  echo "VALUE != 10"  
fi
```

Dans le cas d'une chaine de caractère je pourrai utiliser "="

```shell
read "Entrez votre nom : " NAME

if ["$NAME" = "Philippe"]; then
    echo "Bonjour Admin"
fi
```

#### Else/Elif

```shell
read "confirm drop database (y/n) : " DROP_DB

# Ici j'utilise le =~ pour faire une comparaison avec des expressions régulières
if [ "$DROP_DB" =~ ^[Yy]$ ]; 
then
  echo "Dropping DB"
  # commandes de drop 
  exit 0
else
  # Le code du else ne s'exécutera uniquement si la condition du IF est fausse.
  echo "Exit!"
  exit 1
fi
```

```shell

# Le code qui suit est exécuter dans tous les cas.
DB_USER=$(echo "Une commande qui retournerais les utilisateurs de la DB en filtrant sur le nom d'utilisateur")

if ![ -n "$DB_USER" ];
then
  echo "Creete USER"
# Le elif me permet de rajouter un else avec une condition supplémentaire
# Le elif et le else sont optionel
elif ![ -n "$PASSWORD" ];
then 
  echo "update user password"
fi
```

#### Opérateurs logique

1) Opérateur logique && (et)
```shell
if [ -f "./start.sh"] && [ -x "./start.sh" ] && [ -r "./start.sh"]; then
  echo "Le fichier existe et peut être exécuter et lu"
fi
```

L'opérateur logique && a besoin que les deux parties (à droite et à gauche) soient vraient pour retourner vrai.

2) Opérateur logique || (ou)

L'opérateur OR va me permettre d'exécuter une partie d'un script, si l'une des deux conditions (droits/gauche) est vraie

```shell
read "Enter (Y/y) to continue : " CONFIRM 
if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
  echo "Si CONFIRM est égale à Y ou y j'exécute ce code"
fi
```

3) Opérateur "!" (not)
```shell
if ![ -f "./start.sh" ]; then
  echo "Création du fichier start.sh"
  touch start.sh
  chmod 750 start.sh
fi
```