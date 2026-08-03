#!/bin/bash

while read line
do
  echo "$line"
  USER=$(echo "$line" | awk -F : '{ print $1 }')
  PASSWORD=$(echo "$line" | awk -F : '{ print $2 }')
  DATABASE=$(echo "$line" | awk -F : '{ print $3 }')

  result=$(psql -U app -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname='$USER'")
  db_result=$(psql -U app -t -A -c "SELECT 1 FROM pg_database WHERE datname='$DATABASE'")
  echo "$db_result"

  if [ -z ${db_result} ];
  then
    echo "Create Database"
    psql -U app -c "CREATE DATABASE $DATABASE"
  fi

  if [ $result -eq 0 ];
  then
    if [ -z ${PASSWORD} ];
    then
      echo "$USER need a password !"
      exit 1
    fi
    echo "Create user"
    psql -U app -d $DATABASE -c "CREATE USER $USER WITH ENCRYPTED PASSWORD '$PASSWORD'"
  elif ! [ -z ${PASSWORD} ];
  then
    echo "Update user"
    psql -U app -d $DATABASE -c "ALTER USER $USER WITH ENCRYPTED PASSWORD '$PASSWORD'"
  fi
done < file.txt