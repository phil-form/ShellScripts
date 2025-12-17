### Créer un script 

Je crée un fichier (habituellement .sh)

```shell
touch  test.sh
```

après il faut que je rende mon script exécutable : 
```shell
chmod 750 test.sh
```
une autre méthode (à ne pas utiliser sur des script sur des serveurs de prod)
```shell
chmod +x test.sh
```

Editer le script
```shell
vim test.sh
```

Example de script :
```shell
#!/bin/bash

echo "Bonjour !!!!"
```

Lancer le script :
```shell
./test.sh
```

En sois un script n'est qu'un fichier qui va contenir une série de commandes à exécuter l'une après l'autre.

Générelemt on commence un script en définissant son environment d'exécution (#!/bin/bash)

#### Sortie (affichier des données)

```shell
#!/bin/bash

echo "Bonjour !!!!"
```

#### Variables 

1) Création et utilisation d'une variable
```shell
#!/bin/bash

# Création d'une variable
NAME="Philippe"

# Utilisation d'une variable 
echo "Bonjour !!!! $NAME"
```

2) Types de variables :
```shell
#!/bin/bash

# Chaine de caractères
NAME="Philippe"
# Entier
AGE=99
# Boolean (valeur vrais - true - ou fausse - false -)
TRAINER=true

# Utilisation d'une variable 
echo "Bonjour !!!! $NAME"
```

3) Récupérer la sortie d'une commande dans une variable

```shell
#!/bin/bash

OUTPUT=$(ls -la /)
DATE=$(date)

# L'ancienne syntaxe 
EXAMPLE=`date`
```

#### Lecture de données (récupérer des données entrées par l'utilisateur)

```shell
#!/bin/bash

# j'utilise read pour lire ce que m'entrera l'utilisateur lors de l'exécution
# Le contenu entré sera mis dans la variable NAME
read -p "Entrez votre nom : " NAME

echo "Votre nom est : $NAME"
```

Example d'utilisation :
```shell
./enter_name.sh
```
```terminaloutput
Entrez votre nom : Philippe
Votre nom est Philippe
```

#### Tableau 

```shell
RIGHTS=("ADMIN" "NETWORK" "DEV")

echo ${RIGHTS[0]}
echo ${RIGHTS[1]}
echo ${RIGHTS[2]}

RIGHTS[3] = "TESTER"

echo ${RIGHTS[3]}

# Afficher tous les éléments
echo ${RIGHTS[@]}
echo ${RIGHTS[*]}

# Ajouter un élément à la fin
RIGHTS+=("USER")

# Supprimer un élément
unset RIGHTS[3]
echo ${RIGHTS[@]}

# Obtenir la taille d'un tableau 
echo "${#RIGHTS[@]}"
```

#### Arguments

exemple d'arguments
```shell
ls -la /home/dev
```

ici les arguments sont :
- $0 => ls
- $1 => -la
- $2 => /home/dev

```shell
#!/bin/bash

echo "Script name : $0"
echo "Argument 1 : $1"
echo "Argument 2 : $2"
echo "Nombre d'arguments : $#"
echo "Tous les argemts $@"
```



