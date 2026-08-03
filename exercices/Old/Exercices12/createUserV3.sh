#!/bin/bash

source ./fonctions.sh

print_help() {
  echo -e " Usage : "
  echo -e "./createUser.sh -u username -p password -d database_name"
  echo -e "\t-u \t username followed by the username"
  echo -e "\t-p \t password followed by the user password"
  echo -e "\t-s schema \t select the schema"
  echo -e "\t-d \t name of the targeted database"
  echo -e "\t-r \t give read rights"
  echo -e "\t-w \t give write rights"
  echo -e "\t-h \t prompt this message"
  echo -e "\t-v \t enable verbose mode"
}

READ=false
DELETE=false
WRITE=false
SCHEMA='public'

while getopts u:d:p:s:rwxv flag
do
  case "${flag}" in
    u)
      USER=$OPTARG
      ;;
    p)
      PASSWORD=$OPTARG
      ;;
    s)
      SCHEMA=$OPTARG
      ;;
    r)
      READ=true
      ;;
    w)
      WRITE=true
      ;;
    x)
      DELETE=true
      ;;
    d)
      DATABASE=$OPTARG
      ;;
    h)
      print_help
      ;;
    v)
      VERBOSE=true
      ;;
    *)
      print_help
      print_critical "Unknown argument !"
      exit 99
      ;;
  esac
done

if [ -z ${USER} ];
then
  print_help
  print_critical "username required (-u)"
fi

if [ -z ${DATABASE} ];
then
  print_help
  print_critical "database name required (-d)"
fi

print_info "Look if database exist"
db_result=$(psql -U app -t -A -c "SELECT 1 FROM pg_database WHERE datname='$DATABASE'")

if [ -z ${db_result} ];
then
  print_info "Create Database"
  psql -U app -c "CREATE DATABASE $DATABASE"
  print_ok "Database created"
fi

print_info "Check if user already exist"
result=$(psql -U app -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname='$USER'")

if [ $result -eq 0 ];
then
  if [ -z ${PASSWORD} ];
  then
    print_critical "$USER need a password !"
    exit 1
  fi

  print_info "Create user"
  psql -U app -d $DATABASE -c "CREATE USER $USER WITH ENCRYPTED PASSWORD '$PASSWORD'"
elif ! [ -z ${PASSWORD} ];
then
  print_info "Update user"
  psql -U app -d $DATABASE -c "ALTER USER $USER WITH ENCRYPTED PASSWORD '$PASSWORD'"
fi

if [ $READ = true ];
then
  print_info "Grant READ rights"
  psql -U app -d $DATABASE -c "GRANT Usage ON SCHEMA ${SCHEMA} TO ${USER}"
  print_ok "Usage granted"
  psql -U app -d $DATABASE -c "GRANT SELECT ON ALL TABLES IN SCHEMA ${SCHEMA} TO ${USER}"
  print_ok "Select granted"
  psql -U app -d $DATABASE -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ${SCHEMA} TO ${USER}"
  print_ok "All privileges granted"
fi

if [ $WRITE = true ];
then
  print_info "Grant write rights"
  psql -U app -d $DATABASE -c "GRANT INSERT, UPDATE ON ALL TABLES IN SCHEMA ${SCHEMA} TO ${USER}"
  print_ok "Insert/update granted"
fi

if [ $DELETE = true ];
then
  print_info "Grant delete rights"
  psql -U app -d $DATABASE -c "GRANT DELETE ON ALL TABLES IN SCHEMA ${SCHEMA} TO ${USER}"
  print_ok "Delete granted"
fi
