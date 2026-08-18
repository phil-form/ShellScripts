# 1) Write a restore script to select & restore a PostgreSQL database from a backup in custom format.

The script needs to be able to :
* Backup the current database if needed with --backup option
* select a database from a list of available backups in ./init_db
* pass the password safely (without exposing it in the command line) So use either the prompt or a .env file with `source`
* execute migrations on the restored database if needed with --migrate option

# 2) Manage access 

The script should enable you to : 
* add a new user (check if the user exists before creating it)
* pass the password safely (without exposing it in the command line) So use either the prompt or a .env file with `source`
* Do the same for the new user password (ask via a prompt or read from a .env file)
* Create the user with the specified password and grant them access to the database
* And manage his rights with the following flags :
  * --schema SCHEMA : selected schema to grant access to the user
  * --write : grant write access to the user
  * --read : grant read-only access to the user
  * --admin : grant admin access to the user
  * --view : grant view access to the user
* Bonus : make a picker to select the schema if -S is passed.

**Bonus of the bonus : Check how to use `fzf` as a picker**