# 💾 Exercice 13 — `pgbackup` · Corrections

> Correction du [projet fil rouge `pgbackup`](Exercice13_pgbackup_enonces.md). On donne, pour chaque étape, **les ajouts** par rapport à l'étape précédente, avec les points pédagogiques. Les deux scripts finaux complets et vérifiés (`bash -n` + ShellCheck) sont en fin de document.

---

## Étape 1 — Le squelette

```bash
#!/bin/bash

# If it runs inside a cron then always use ABSOLUTE paths, never relative ones.
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%F_%H-%M-%S)
DB_NAME="$1"

if [ -z "$DB_NAME" ]; then
  read -p "Nom de la base à sauvegarder : " DB_NAME
fi

DUMP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

mkdir -p "$BACKUP_DIR"
pg_dump "$DB_NAME" > "$DUMP_FILE"

printf "%-12s : %s\n" "Base" "$DB_NAME"
printf "%-12s : %s\n" "Fichier" "$DUMP_FILE"
printf "%-12s : %s\n" "Horodatage" "$TIMESTAMP"

DEFAULT_DATABASES=(boutique blog compta)
echo "Bases par défaut : ${DEFAULT_DATABASES[*]}"
```

**Points clés**

- `date +%F_%H-%M-%S` donne `2025-01-30_14-22-05`. On évite `:` dans un nom de fichier (réservé sur d'autres systèmes) — d'où les `-`.
- `${DB_NAME}_${TIMESTAMP}` : les accolades délimitent le nom de variable pour le coller à `_` sans ambiguïté.
- Le `read` n'est atteint **que** si `$1` est vide : le script reste utilisable des deux façons.
- On affiche le tableau avec `"${DEFAULT_DATABASES[*]}"` (tous les éléments en une chaîne) — l'important c'est de manipuler un tableau, il servira vraiment à l'étape 3.

> [!NOTE]
> `mkdir -p` est déjà là par nécessité (`>` échoue si le dossier n'existe pas). L'étape 2 en fait une vraie vérification raisonnée.

---

## Étape 2 — Les vérifications

On insère les gardes **avant** de dumper, dans l'ordre où elles protègent le plus tôt.

```bash
# 1. Nom non vide
if [ -z "$DB_NAME" ]; then
  echo "Aucun nom de base fourni." >&2
  exit 1
fi

# 2. Nom syntaxiquement valide
if ! [[ "$DB_NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
  echo "Nom de base invalide : $DB_NAME" >&2
  exit 1
fi

# 3. Dossier de destination utilisable
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
elif [ ! -w "$BACKUP_DIR" ]; then
  echo "Dossier non modifiable : $BACKUP_DIR" >&2
  exit 1
fi

# 4. La base existe côté serveur
exists=$(psql -t -A -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")
if [ "$exists" = "1" ]; then
  pg_dump "$DB_NAME" > "$DUMP_FILE"
else
  echo "La base '$DB_NAME' n'existe pas." >&2
  exit 1
fi

# 5. Le dump n'est pas vide
if [ ! -s "$DUMP_FILE" ]; then
  echo "Sauvegarde suspecte (fichier vide) : $DUMP_FILE" >&2
fi
```

**Points clés**

- `[[ ... =~ ... ]]` : la regex **exige** les doubles crochets (bash), impossible en `[ ]` POSIX.
- `^[a-zA-Z_][a-zA-Z0-9_]*$` : premier caractère lettre ou `_`, puis lettres/chiffres/`_`. C'est la règle des identifiants PostgreSQL non entre guillemets.
- `psql -t -A` : `-t` enlève l'en-tête et le pied, `-A` le formatage aligné → on récupère juste `1` ou une chaîne vide, facile à tester.
- `-s` teste « existe **et** non vide » : parfait pour valider un dump.

> [!WARNING]
> Injecter `$DB_NAME` dans une requête SQL est acceptable **ici** parce qu'on a validé le nom par regex juste avant. Sans cette validation, ce serait une injection SQL. L'ordre des vérifications n'est pas cosmétique.

---

## Étape 3 — Boucles et rotation

**Boucle sur le tableau** — le corps « vérifier + dumper » de l'étape 2 est déplacé dans la boucle :

```bash
for db in "${DEFAULT_DATABASES[@]}"; do
  # … toutes les vérifications de l'étape 2, appliquées à $db …
  pg_dump "$db" > "$BACKUP_DIR/${db}_${TIMESTAMP}.sql"
done
```

**Lecture d'un fichier** avec filtrage des commentaires et lignes vides :

```bash
while IFS= read -r line; do
  [ -z "$line" ] && continue                 # ligne vide
  [[ "$line" =~ ^[[:space:]]*# ]] && continue # commentaire
  echo "Traitement de : $line"
  # … dump de $line …
done < databases.txt
```

**Rotation** — on garde les `keep` plus récents, on jette le reste :

```bash
keep=3
count=0
for f in $(ls -t "$BACKUP_DIR/${db}_"*.sql 2>/dev/null); do
  count=$((count + 1))
  if [ "$count" -gt "$keep" ]; then
    echo "rm $f"      # d'abord on VÉRIFIE, puis on remplace par : rm -f "$f"
  fi
done
```

if it is a daily backup, you can also use `find` with `-mtime` to delete files older than a certain number of days, but here we are keeping the last N backups regardless of age.

```shell
find "$BACKUP_DIR" -name "${db}_*.sql" -type f -mtime +3 -exec rm -f {} \;
```

**Points clés**

- `IFS= read -r` : `IFS=` empêche le rognage des espaces en début/fin, `-r` empêche l'interprétation des `\`. C'est **la** façon correcte de lire un fichier ligne par ligne.
- `ls -t` trie du plus récent au plus ancien ; un compteur suffit alors à couper après le `keep`-ième.
- `2>/dev/null` sur le `ls` : à la toute première sauvegarde d'une base, le motif `*.sql` ne correspond à rien et `ls` râle — on tait ce cas normal.
- On **affiche** le `rm` avant de l'activer : réflexe de survie sur toute boucle destructrice.

> [!NOTE]
> **ShellCheck (SC2045 / SC2012)** signalera l'itération sur `ls`. Ici les noms de fichiers sont entièrement contrôlés par le script (`base_horodatage.sql`, sans espace), donc c'est sûr. La version finale l'assume avec une directive `# shellcheck disable=…` commentée — c'est la bonne pratique : on ne masque un avertissement qu'en connaissance de cause.

---

## Étape 4 — Gestion des erreurs

```bash
set -euo pipefail

CURRENT_DUMP=""
cleanup() {
  if [ -n "$CURRENT_DUMP" ] && [ -f "$CURRENT_DUMP" ]; then
    rm -f "$CURRENT_DUMP"
    echo "Interrompu : dump partiel supprimé ($CURRENT_DUMP)" >&2
  fi
}
trap cleanup INT TERM

# … dans la boucle, pour chaque base :
CURRENT_DUMP="$DUMP_FILE"
if pg_dump "$db" > "$DUMP_FILE"; then
  CURRENT_DUMP=""        # succès : plus rien à nettoyer
else
  rm -f "$DUMP_FILE"
  echo "Échec du dump de $db" >&2
  continue               # on passe à la base suivante
fi
```

**Points clés**

- `set -e` (arrêt sur erreur), `set -u` (variable non définie = erreur), `pipefail` (un pipe échoue si **n'importe quel** maillon échoue). Le trio de rigueur.
- **Le piège `set -u`** : toute variable potentiellement vide doit être initialisée (`DB_NAME=""`, `VERBOSE=false`) ou lue en `${VAR:-défaut}`. Sinon le script meurt à la première lecture.
- **`pg_dump` dans un `if`** : mettre une commande faillible en condition **neutralise** `set -e` pour elle — c'est ainsi qu'on gère une erreur au lieu de la subir.
- **`trap` + variable témoin** : `CURRENT_DUMP` pointe le dump en cours ; on la vide dès le succès. Si l'on fait `CTRL + C` pendant le `pg_dump`, le `trap` trouve un fichier à supprimer et nettoie. Après succès, il n'y a plus rien à nettoyer.
- Le `rm` de rotation qui ne trouve rien ne doit pas tuer le script : on le protège (voir la version finale), sans masquer les vraies erreurs.

> [!TIP]
> Codes de sortie retenus : `0` succès · `2` mauvais usage (arguments) · `3` connexion PostgreSQL impossible · `99` erreur critique (via `print_critical`).

---

## Étape 5 — `getopts`

```bash
DB_NAME=""
DB_FILE=""
BACKUP_DIR="./backups"
KEEP=3
VERBOSE=false

while getopts "d:f:o:k:vh" flag; do
  case "$flag" in
    d) DB_NAME="$OPTARG" ;;
    f) DB_FILE="$OPTARG" ;;
    o) BACKUP_DIR="$OPTARG" ;;
    k) KEEP="$OPTARG" ;;
    v) VERBOSE=true ;;
    h) print_help; exit 0 ;;
    *) print_help; exit 2 ;;
  esac
done

if [ -z "$DB_NAME" ] && [ -z "$DB_FILE" ]; then
  print_help
  echo "Précisez une base (-d) ou un fichier (-f)." >&2
  exit 2
fi
if [ -n "$DB_FILE" ] && [ ! -f "$DB_FILE" ]; then
  echo "Fichier introuvable : $DB_FILE" >&2
  exit 2
fi
```

**Points clés**

- Dans `"d:f:o:k:vh"`, le `:` après une lettre signifie « cette option attend une valeur », récupérée dans `$OPTARG`. `v` et `h` n'en attendent pas.
- Le `*)` attrape toute option inconnue **et** les options mal formées → on affiche l'aide et on sort en `2`.
- On garde des **valeurs par défaut** (`BACKUP_DIR`, `KEEP`) que l'utilisateur peut écraser : `-o`/`-k` remplacent simplement les variables.
- La logique métier ne change pas : on a juste remplacé la source des paramètres (`read`/tableau codé en dur → options).

---

## Étape 6 — Fonctions et bibliothèque

C'est l'aboutissement : le script est découpé en fonctions courtes, et les logs sont sortis dans `lib_log.sh` importée par `source`. Voir les **scripts finaux** ci-dessous.

**Points clés**

- `source "$(dirname "$0")/lib_log.sh"` : `dirname "$0"` permet de trouver la bibliothèque **à côté** du script, quel que soit le dossier courant d'où on le lance.
- `db_exists` renvoie un **code** (`return` implicite du dernier test) → on l'utilise directement dans un `if db_exists "$db"`.
- `latest_dump` renvoie une **valeur** via `echo`, capturée par `LAST=$(latest_dump …)`. C'est la distinction du chapitre 06.6 : `return` pour un statut, `echo` + `$( )` pour une donnée.
- Toutes les variables internes sont `local` → pas de fuite entre fonctions.
- **Piège `set -e` + `&&`** : `print_info` n'affiche qu'en mode verbeux. Écrite en `[ "$VERBOSE" = true ] && echo …`, elle **renvoie 1** quand `VERBOSE=false`, ce qui tue le script sous `set -e`. On l'écrit donc avec un `if` et un `return 0` explicite (voir `lib_log.sh`).

---

## 📄 Script final — `lib_log.sh`

```bash
#!/bin/bash

print_ok()       { echo -e "\e[1;37m[\e[1;32m  OK  \e[1;37m] $1\e[0m"; }
print_info() {
  if [ "${VERBOSE:-false}" = true ]; then
    echo -e "\e[1;37m[\e[1;37m INFO \e[1;37m] $1\e[0m"
  fi
  return 0   # ne jamais renvoyer 1 : casserait set -e chez l'appelant
}
print_warning()  { echo -e "\e[1;37m[\e[1;33m WARN \e[1;37m] $1\e[0m" >&2; }
print_error()    { echo -e "\e[1;37m[\e[1;91m ERROR \e[1;37m] $1\e[0m" >&2; }
print_critical() { echo -e "\e[1;37m[\e[1;31m CRIT \e[1;37m] $1\e[0m" >&2; exit 99; }
```

## 📄 Script final — `pgbackup.sh`

```bash
#!/bin/bash
set -euo pipefail

# If I put an absolute path here, it will break if the script is moved. 
# So we use dirname to find the library next to this script.
source "$(dirname "$0")/lib_log.sh"

DB_NAME=""
DB_FILE=""
BACKUP_DIR="./backups"
KEEP=3
VERBOSE=false
CURRENT_DUMP=""

print_help() {
  echo "Usage : ./pgbackup.sh (-d base | -f fichier) [-o dossier] [-k n] [-v] [-h]"
  echo -e "\t-d <base>\tbase à sauvegarder"
  echo -e "\t-f <fichier>\tfichier listant les bases (une par ligne)"
  echo -e "\t-o <dossier>\tdossier de destination (défaut : ./backups)"
  echo -e "\t-k <n>\t\tnombre de sauvegardes à conserver (défaut : 3)"
  echo -e "\t-v\t\tmode verbeux"
  echo -e "\t-h\t\taffiche cette aide"
}

cleanup() {
  if [ -n "$CURRENT_DUMP" ] && [ -f "$CURRENT_DUMP" ]; then
    rm -f "$CURRENT_DUMP"
    print_error "Interrompu : dump partiel supprimé ($CURRENT_DUMP)"
  fi
}
trap cleanup INT TERM

check_dependencies() {
  local cmd
  for cmd in pg_dump psql; do
    if ! command -v "$cmd" > /dev/null; then
      print_critical "Commande requise introuvable : $cmd"
    fi
  done
}

db_exists() {
  local db="$1" found
  found=$(psql -t -A -c "SELECT 1 FROM pg_database WHERE datname='$db'")
  [ "$found" = "1" ]
}

valid_name() {
  local db="$1"
  [[ "$db" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}

latest_dump() {
  local db="$1" dir="$2"
  # shellcheck disable=SC2012  # noms de fichiers contrôlés (pas d'espaces)
  ls -t "$dir/${db}_"*.sql 2>/dev/null | head -n 1
}

dump_db() {
  local db="$1" dir="$2" stamp file
  stamp=$(date +%F_%H-%M-%S)
  file="$dir/${db}_${stamp}.sql"
  print_info "Sauvegarde de $db -> $file"
  CURRENT_DUMP="$file"
  if pg_dump "$db" > "$file"; then
    CURRENT_DUMP=""
  else
    rm -f "$file"
    print_error "Échec du dump de $db"
    return 1
  fi
  [ -s "$file" ] || print_warning "Dump vide pour $db"
  print_ok "$db sauvegardée"
}

rotate() {
  local db="$1" dir="$2" keep="$3" count=0 f
  # shellcheck disable=SC2045,SC2012  # noms de fichiers contrôlés (pas d'espaces)
  for f in $(ls -t "$dir/${db}_"*.sql 2>/dev/null); do
    count=$((count + 1))
    if [ "$count" -gt "$keep" ]; then
      print_info "Rotation : suppression de $f"
      rm -f "$f"
    fi
  done
}

backup_one() {
  local db="$1"
  valid_name "$db" || { print_error "Nom invalide, ignoré : $db"; return 1; }
  db_exists "$db"  || { print_error "Base inexistante, ignorée : $db"; return 1; }
  dump_db "$db" "$BACKUP_DIR" || return 1
  rotate "$db" "$BACKUP_DIR" "$KEEP"
}

main() {
  check_dependencies

  if ! psql -c '\q' > /dev/null 2>&1; then
    print_error "Connexion à PostgreSQL impossible."
    exit 3
  fi

  if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
  elif [ ! -w "$BACKUP_DIR" ]; then
    print_critical "Dossier de destination non modifiable : $BACKUP_DIR"
  fi

  [ -n "$DB_NAME" ] && { backup_one "$DB_NAME" || true; }

  if [ -n "$DB_FILE" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      backup_one "$line" || true
    done < "$DB_FILE"
  fi

  if [ -n "$DB_NAME" ]; then
    local last
    last=$(latest_dump "$DB_NAME" "$BACKUP_DIR")
    [ -n "$last" ] && print_ok "Dernier dump : $last"
  fi
  return 0
}

while getopts "d:f:o:k:vh" flag; do
  case "$flag" in
    d) DB_NAME="$OPTARG" ;;
    f) DB_FILE="$OPTARG" ;;
    o) BACKUP_DIR="$OPTARG" ;;
    k) KEEP="$OPTARG" ;;
    v) VERBOSE=true ;;
    h) print_help; exit 0 ;;
    *) print_help; exit 2 ;;
  esac
done

if [ -z "$DB_NAME" ] && [ -z "$DB_FILE" ]; then
  print_help
  print_error "Précisez une base (-d) ou un fichier (-f)."
  exit 2
fi
if [ -n "$DB_FILE" ] && [ ! -f "$DB_FILE" ]; then
  print_critical "Fichier introuvable : $DB_FILE"
fi

# Store database variables inside a .env file for easier configuration
# Even safer, in real production -> use a vault (hashicorp vault, AWS secrets manager, etc.) to store credentials and sensitive information.
source .env
main
```

> [!NOTE]
> Ces deux scripts passent `bash -n` et `shellcheck` **sans avertissement**, et la rotation a été vérifiée (5 sauvegardes successives avec `-k 3` ne laissent bien que les 3 plus récentes).

---

## 🎁 Bonus — restauration (`-r`)

Ajouter la lettre `r:` à `getopts`, une variable `RESTORE_FILE`, et cette fonction :

```bash
restore_db() {
  local db="$1" file="$2"
  [ -f "$file" ] || print_critical "Dump introuvable : $file"
  print_info "Restauration de $db depuis $file"
  psql "$db" < "$file"
  print_ok "$db restaurée"
}
```

Dans le parsing : `r) RESTORE_FILE="$OPTARG" ;;`, puis en tête de `main`, si `RESTORE_FILE` est défini, appeler `restore_db "$DB_NAME" "$RESTORE_FILE"` et sortir avant la logique de sauvegarde.

> [!CAUTION]
> Une restauration **écrase** des données. En production, on restaure toujours dans une base neuve ou de test d'abord — jamais directement sur la base vivante.