#!/bin/bash

PROJECT_NAME=$1

# Ici je vérifie si l'utilisateur a rentrer un nom de projet.
#if [ -z ${PROJECT_NAME} ]
#then
#  read -p "Entrez le nom du projet : " PROJECT_NAME
#fi

# Le problème c'est que si l'utilisateur fait directement enter dans le read, le nom de projet restera vide
# Donc il est intéresent de mettre les entrées utilisateurs dans des boucles while.
while [ -z ${PROJECT_NAME} ]
do
  read -p "Entrez le nom du projet : " PROJECT_NAME
done

mkdir -p $PROJECT_NAME/src $PROJECT_NAME/data
touch $PROJECT_NAME/src/start.sh
chmod 750 $PROJECT_NAME/src/start.sh