#!/bin/bash

if [ -z ${1} ]
then
  read -p "Entrez le nom du serveur db : " SERVER_NAME
else
  SERVER_NAME=$1
fi

USERS_TO_ADD=()
USER="tmp"

while ! [ -z ${USER} ];
do
  read -p "Entrez un nom d'utilisateur (ou rien pour continuer) : " USER

  if ! [ -z ${USER} ];
  then
    USERS_TO_ADD+=($USER)
  fi
done

DBS=()
DB="tmp"

while ! [ -z ${DB} ];
do
  read -p "Entrez le nom de la db (ou rien pour continuer) : " DB

  if ! [ -z ${DB} ];
  then
    DBS+=($DB)
  fi
done

echo "${DBS[@]}"
echo "${USERS_TO_ADD[@]}"

for user in "${USERS_TO_ADD[@]}";
do
  for db in "${DBS[@]}";
  do
    sudo -u postgres psql -d $db -c "CREATE USER $USER WITH ENCRYPTED PASSWORD '$PASSWORD'"
  done
done