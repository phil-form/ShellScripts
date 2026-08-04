# 💾 Exercice 13 — Projet fil rouge : `pgbackup`

> Un outil de **sauvegarde de bases PostgreSQL** que l'on construit étape par étape, une étape par chapitre du [module 06 · Shell scripting](../06_shellscript). Chaque étape réutilise et enrichit le script de la précédente : à la fin, on obtient un vrai outil d'administration.
 
---

## 🎯 Scénario

L'ASBL bruxelloise **Delvaux & Fils** héberge plusieurs bases PostgreSQL sur un serveur Debian (une pour la boutique, une pour le blog, une pour la comptabilité). Aujourd'hui, personne ne sauvegarde rien « parce que c'est chiant à taper à la main ». On vous confie l'écriture d'un outil `pgbackup.sh` qui :

- fait un dump horodaté d'une ou plusieurs bases avec `pg_dump` ;
- range les sauvegardes dans un dossier dédié ;
- ne garde que les **N** sauvegardes les plus récentes (rotation) ;
- journalise ce qu'il fait, et échoue proprement quand quelque chose se passe mal ;
- s'utilise en ligne de commande avec des options (`-d`, `-o`, `-k`, `-v`, `-h`).
  On avance **par étape**. À chaque étape, on part du script obtenu à l'étape précédente.

---

## 🚀 Mise en place de l'environnement

On travaille sur la base de démonstration du dépôt (`docker-compose.yml`).

```bash
# À la racine du dépôt, lancer la base PostgreSQL de démo
docker compose up -d
```

Installer le client PostgreSQL sur la machine de travail (il fournit `psql` **et** `pg_dump`) :

```bash
sudo apt update && sudo apt install -y postgresql-client
```

Le conteneur expose PostgreSQL sur le port **5435**. Pour ne pas retaper les paramètres de connexion à chaque commande, on les met dans l'environnement — `psql` et `pg_dump` les lisent automatiquement :

```bash
export PGHOST=localhost
export PGPORT=5435
export PGUSER=postgres
export PGPASSWORD=1234
```

> [!TIP]
> Vérifiez la connexion avant de commencer : `psql -l` doit afficher la liste des bases. Si ça bloque, c'est un problème d'environnement (conteneur éteint, mauvais port), pas de script.

Créez trois bases de démonstration avec un peu de contenu, elles serviront de cibles :

```bash
for db in boutique blog compta; do
  psql -c "CREATE DATABASE $db"
  psql -d "$db" -c "CREATE TABLE clients (id SERIAL PRIMARY KEY, nom TEXT);"
  psql -d "$db" -c "INSERT INTO clients (nom) VALUES ('Dupont'), ('Peeters');"
done
```

> [!CAUTION]
> Comme tout le module, ces exercices se font sur une VM ou un conteneur jetable, **jamais** sur une base de production. Un `pg_dump` est inoffensif, mais on va aussi écrire du code qui **supprime** de vieilles sauvegardes.
 
---

## Étape 1 — Le squelette *(chapitre [06.1 · Les bases](../06_shellscript/01_Base/base.md))*

> [!NOTE]
> **Objectifs** : variables, `printf`, `read`, un tableau, l'argument `$1`.

1. Créez le fichier `pgbackup.sh`, ajoutez le *shebang*, et rendez-le exécutable avec les droits `750`.
2. Définissez trois variables en tête de script :
    - `BACKUP_DIR` : le dossier de destination (`./backups`) ;
    - `TIMESTAMP` : la date et l'heure courantes au format `AAAA-MM-JJ_HH-MM-SS` (indice : `date +%F_%H-%M-%S`) ;
    - `DB_NAME` : le nom de la base à sauvegarder.
3. Le nom de la base doit venir du **premier argument** `$1`. Si l'utilisateur n'a rien passé, demandez-le-lui avec `read`.
4. Construisez le chemin complet du fichier de dump dans une variable `DUMP_FILE`, sous la forme :
   `./backups/<base>_<horodatage>.sql`.
5. Lancez la sauvegarde : `pg_dump "$DB_NAME" > "$DUMP_FILE"`.
6. Affichez un récapitulatif propre avec `printf` (base sauvegardée, fichier produit, horodatage).
7. Déclarez enfin un tableau `DEFAULT_DATABASES=(boutique blog compta)` et affichez son contenu — il servira à l'étape 3.
> [!TIP]
> Testez : `./pgbackup.sh boutique` doit créer un fichier dans `backups/`. Vérifiez qu'il n'est pas vide avec `ls -lh backups/`.
 
---

## Étape 2 — Les vérifications *(chapitre [06.2 · Conditions](../06_shellscript/02_operateur_logique/exemple.md))*

> [!NOTE]
> **Objectifs** : `[[ ]]`, tests de fichiers, `-z`, `=~`, `if/elif/else`, `&&` / `||`.

On sécurise le script de l'étape 1. Ajoutez, dans l'ordre logique :

1. **Nom de base non vide** : si `DB_NAME` est vide après le `read`, afficher un message et arrêter le script (`exit 1`).
2. **Nom de base valide** : un nom de base PostgreSQL commence par une lettre ou un `_`, puis lettres/chiffres/`_`. Validez `DB_NAME` avec une expression régulière (`[[ "$DB_NAME" =~ ... ]]`). Refusez tout nom invalide.
3. **Dossier de destination** : si `BACKUP_DIR` n'existe pas, créez-le (`mkdir -p`). S'il existe mais n'est **pas modifiable**, arrêtez avec une erreur. (Indice : tests `-d` et `-w`.)
4. **La base existe côté serveur** : interrogez le catalogue PostgreSQL
```bash
   psql -t -A -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'"
```
Selon le résultat, avec un `if/elif/else` :
- la base existe → on continue ;
- la base n'existe pas → message d'erreur clair et `exit`.
5. **Le dump a réussi** : après le `pg_dump`, vérifiez que `DUMP_FILE` existe et **n'est pas vide** (`-s`). Sinon, prévenez que la sauvegarde est suspecte.
> [!TIP]
> Cherchez à écrire les tests dans l'ordre où ils protègent le plus tôt possible : inutile de lancer `pg_dump` si le nom de base est déjà invalide.
 
---

## Étape 3 — Sauvegarder plusieurs bases et faire la rotation *(chapitre [06.3 · Les boucles](../06_shellscript/03_boucles/exemple.md))*

> [!NOTE]
> **Objectifs** : `for` sur un tableau, lecture d'un fichier ligne par ligne, `continue`, rotation.

1. **Boucle sur un tableau** : transformez le script pour qu'il sauvegarde **toutes** les bases du tableau `DEFAULT_DATABASES`, et plus seulement une. Toutes les vérifications de l'étape 2 doivent tourner pour chaque base.
2. **Lecture depuis un fichier** : créez un fichier `databases.txt` contenant une base par ligne :
```text
   boutique
   blog
   # cette ligne est un commentaire
   compta
```
Faites lire ce fichier par le script (`while IFS= read -r line`). Avec `continue`, **ignorez** les lignes vides et celles qui commencent par `#`.

3. **Rotation / rétention** : c'est le cœur de l'outil. Après avoir sauvegardé une base, on ne veut garder que les **3** sauvegardes les plus récentes de cette base et supprimer les plus anciennes.
    - Listez les dumps existants de la base, du plus récent au plus ancien (indice : `ls -t "$BACKUP_DIR/${db}_"*.sql`).
    - Parcourez-les avec un `for` et un compteur ; au-delà du 3ᵉ, supprimez le fichier.
> [!TIP]
> Pour tester la rotation sans attendre, relancez le script plusieurs fois d'affilée : l'horodatage à la seconde crée des fichiers distincts. Vérifiez ensuite avec `ls backups/` qu'il ne reste bien que 3 dumps par base.

> [!WARNING]
> On manipule ici un `rm`. Avant de brancher la suppression, faites d'abord un `echo "rm $fichier"` pour **voir** ce que le script s'apprête à supprimer. On n'active le vrai `rm` qu'une fois la liste vérifiée.
 
---

## Étape 4 — Échouer proprement *(chapitre [06.4 · La gestion des erreurs](../06_shellscript/04_gestion_des_erreurs/gestion_des_erreurs.md))*

> [!NOTE]
> **Objectifs** : `set -euo pipefail`, `$?`, sortie d'erreur `>&2`, `||`, `trap`, codes de sortie.

1. Ajoutez `set -euo pipefail` en tête du script. Corrigez ce qui casse à cause de cette rigueur nouvelle (variables potentiellement vides, etc.).
2. **Code de retour de `pg_dump`** : un `pg_dump` peut échouer (base verrouillée, disque plein…). Récupérez son code de retour et, en cas d'échec, écrivez un message **sur la sortie d'erreur** (`>&2`) et passez à la base suivante au lieu de tout arrêter. Introduisez des codes de sortie parlants (`0` succès, `2` mauvais usage, `3` connexion impossible, par exemple).
3. **`trap` de nettoyage** : si le script est interrompu (`CTRL + C`) **pendant** un `pg_dump`, il laisse un fichier `.sql` incomplet. Mettez en place un `trap` sur `INT`/`TERM`/`EXIT` qui supprime le dump en cours s'il n'a pas été mené à terme.
4. **`||` pour les erreurs sans gravité** : la commande de rotation `rm` peut ne rien trouver à supprimer (première sauvegarde d'une base). Assurez-vous que ce cas n'arrête pas le script, sans pour autant masquer les vraies erreurs.
> [!TIP]
> Pour tester le `trap` : lancez le script sur une grosse base et faites `CTRL + C` en plein dump. Aucun `.sql` incomplet ne doit subsister dans `backups/`.
 
---

## Étape 5 — Une vraie ligne de commande *(chapitre [06.5 · Les arguments](../06_shellscript/05_Arguments/args.md))*

> [!NOTE]
> **Objectifs** : `getopts`, `$#`, `$@`, `$OPTARG`.

On remplace le `read` interactif et le fichier codé en dur par de vraies options. Le script doit accepter :

| Option | Rôle | Obligatoire |
|--------|------|-------------|
| `-d <base>` | La base à sauvegarder | oui, **sauf** si `-f` |
| `-f <fichier>` | Un fichier listant les bases (une par ligne) | oui, **sauf** si `-d` |
| `-o <dossier>` | Dossier de destination (défaut : `./backups`) | non |
| `-k <n>` | Nombre de sauvegardes à conserver (défaut : `3`) | non |
| `-v` | Mode verbeux | non |
| `-h` | Affiche l'aide et quitte | non |

1. Écrivez une fonction/section `print_help` qui documente l'usage, sur le modèle de `createUserV3.sh` (exercice 12).
2. Parsez les options avec `getopts`. Rangez les valeurs dans les bonnes variables (`$OPTARG`).
3. Gérez les cas d'erreur :
    - aucune cible (`-d` **et** `-f` absents) → aide + `exit 2` ;
    - option inconnue → aide + erreur ;
    - fichier `-f` introuvable → erreur.
4. Faites en sorte que `-k` remplace le `3` codé en dur de la rotation, et que `-o` remplace `BACKUP_DIR`.
> [!TIP]
> Testez tous les chemins : `./pgbackup.sh -h`, `./pgbackup.sh -d boutique -k 5 -v`, `./pgbackup.sh -f databases.txt`, et un appel volontairement faux pour voir l'aide s'afficher.
 
---

## Étape 6 — Découper en fonctions *(chapitre [06.6 · Les fonctions](../06_shellscript/06_fonctions/fonctions.md))*

> [!NOTE]
> **Objectifs** : fonctions, `local`, `return` vs `echo` + `$( )`, portée, `source`.

Le script commence à être long. On le structure.

1. **Bibliothèque de logs** : reprenez la bibliothèque `fonctions.sh` de l'exercice 12 (les `print_ok`, `print_info`, `print_warning`, `print_error`, `print_critical`) dans un fichier `lib_log.sh`, et importez-la avec `source`. Remplacez vos `echo` par ces fonctions. Le mode verbeux (`-v`) ne doit afficher les `print_info` que s'il est activé.
2. **Découpez le script en fonctions**, chacune avec ses variables `local` :
    - `check_dependencies` — vérifie que `pg_dump` et `psql` sont installés ;
    - `db_exists <base>` — renvoie `0` si la base existe, `1` sinon (utilise `return`) ;
    - `dump_db <base> <dossier>` — fait le dump d'une base et gère son code de retour ;
    - `rotate <base> <dossier> <keep>` — applique la rotation ;
    - `main` — orchestre le tout à partir des options parsées.
3. **`echo` + `$( )`** : écrivez une fonction `latest_dump <base> <dossier>` qui **renvoie** (via `echo`) le chemin du dump le plus récent d'une base, et récupérez-la avec `LATEST=$(latest_dump …)`. Servez-vous-en pour un message de fin.
4. **Bonus** : ajoutez une fonction `restore_db <base> <fichier>` et une option `-r <fichier>` qui restaure une base depuis un dump (`psql "$db" < "$fichier"`).
> [!TIP]
> Une fois découpé, le corps du script doit se lire presque comme un texte : `check_dependencies`, puis parsing des arguments, puis `main`. Si `main` fait plus de 20 lignes, c'est qu'une sous-tâche mérite encore sa propre fonction.
 
```shell
pg_dump -X --no-owner --no-privileges -Fc "$DB_NAME" > "$DUMP_FILE"
```
---

## ✅ Critères de réussite

À la fin des 6 étapes, `pgbackup.sh` doit :

- [ ] se lancer avec `-d`, `-f`, `-o`, `-k`, `-v`, `-h` et afficher une aide correcte ;
- [ ] sauvegarder une ou plusieurs bases dans des fichiers horodatés ;
- [ ] refuser un nom de base invalide ou une base inexistante ;
- [ ] ne conserver que les `-k` dernières sauvegardes de chaque base ;
- [ ] ne jamais laisser de dump incomplet derrière lui ;
- [ ] passer [ShellCheck](https://www.shellcheck.net/) sans avertissement majeur ;
- [ ] être découpé en fonctions lisibles, avec une bibliothèque de logs importée.
> [!TIP]
> Faites analyser votre script final par ShellCheck : `shellcheck pgbackup.sh lib_log.sh`. C'est le meilleur relecteur automatique pour le shell.