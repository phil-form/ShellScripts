# 06.6 · Les fonctions

> [!NOTE]
> **Objectifs**
> - Déclarer et appeler une fonction
> - Lui passer des arguments et récupérer un résultat
> - Maîtriser la portée des variables (`local`)
> - Factoriser du code dans une bibliothèque importée avec `source`

## Sommaire

1. [Déclarer une fonction](#déclarer-une-fonction)
2. [Les arguments des fonctions](#les-arguments-des-fonctions)
3. [Retourner une valeur](#retourner-une-valeur)
4. [Portée des variables](#portée-des-variables)
5. [Importer des fonctions d'un autre script](#importer-des-fonctions-dun-autre-script)
6. [Récapitulatif](#récapitulatif)

---

## Déclarer une fonction

Le but d'une fonction est de pouvoir exécuter une portion de code plusieurs fois dans le script sans avoir à la retaper.

```bash
#!/bin/bash

print_help() {
  echo "Usage :"
  echo "./command_name.sh -u username -p password -v"
  printf "\t-u \t username, suivi du nom d'utilisateur\n"
  printf "\t-p \t password, suivi du mot de passe\n"
  printf "\t-h \t affiche ce message\n"
  printf "\t-v \t active le mode verbose\n"
}

VERBOSE=false
ERRORS=()

while getopts "u:p:hv" OPS
do
  case "${OPS}" in
    u)
      # $OPTARG contient la valeur de l'option
      echo "username $OPTARG"
      USERNAME=${OPTARG}
      ;;
    p)
      echo "password $OPTARG"
      PASSWORD=${OPTARG}
      ;;
    h)
      print_help
      exit 0
      ;;
    v)
      echo "Activer le mode verbose"
      VERBOSE=true
      ;;
    *)
      print_help
      exit 1
      ;;
  esac
done
```

> [!IMPORTANT]
> Une fonction doit être **définie avant d'être appelée** : bash lit le script de haut en bas. En pratique, on regroupe toutes les fonctions en début de fichier.
>
> Notez aussi l'usage de `printf` plutôt que `echo` pour les tabulations : `echo "\t"` affiche littéralement `\t` en bash (il faudrait `echo -e`), alors que `printf` est fiable et portable.

---

## Les arguments des fonctions

Une fonction reçoit ses arguments exactement comme un script : `$1`, `$2`, `$#`, `"$@"`.

```bash
#!/bin/bash

hello_fct() {
  echo "Hello $1"
}

hello_fct "Philippe"
hello_fct "Bob"
```

```text
Hello Philippe
Hello Bob
```

> [!NOTE]
> À l'intérieur d'une fonction, `$1` est le premier argument **de la fonction**, pas du script. Seul `$0` reste le nom du script.

---

## Retourner une valeur

Deux mécanismes, souvent confondus :

### 1. `return` — un code de statut (0-255)

```bash
user_exists() {
  id "$1" > /dev/null 2>&1
}

if user_exists "debian"; then
  echo "L'utilisateur existe"
fi
```

`return` sert à indiquer un **succès ou un échec**, pas à renvoyer une donnée.

### 2. `echo` + `$( )` — une vraie valeur

```bash
get_username() {
  echo "user_$1"
}

NAME=$(get_username "42")
echo "$NAME"   # user_42
```

---

## Portée des variables

Par défaut, toutes les variables sont **globales** en bash — y compris celles créées dans une fonction.

```bash
compteur() {
  local i=0            # visible uniquement dans la fonction
  TOTAL=10             # variable globale : modifie le reste du script !
}
```

> [!TIP]
> Déclarez systématiquement vos variables de travail avec **`local`** dans les fonctions. Sans cela, une fonction peut écraser silencieusement une variable du script principal — un bug particulièrement pénible à diagnostiquer.

---

## Importer des fonctions d'un autre script

```bash
#!/bin/bash

# Importe les fonctions du script fonctions.sh
source ./fonctions.sh
```

`.` est un synonyme de `source` :

```bash
. ./fonctions.sh
```

> [!IMPORTANT]
> `source script.sh` exécute le script **dans le shell courant** (les fonctions et variables restent disponibles ensuite).
> `./script.sh` l'exécute dans un **sous-processus** : rien n'en subsiste au retour.
>
> C'est exactement le même mécanisme qui permet d'appliquer une modification du `.bashrc` sans rouvrir son terminal — voir le [chapitre 10](../../10_shell_config.md).

Structure typique d'un projet de scripts :

```text
mon_projet/
├── lib/
│   └── fonctions.sh     # uniquement des définitions de fonctions
└── deploy.sh            # source lib/fonctions.sh puis les utilise
```

Pour que le `source` fonctionne quel que soit le dossier depuis lequel on lance le script :

```bash
#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/fonctions.sh"
```

---

## Récapitulatif

| Élément | Syntaxe |
|---------|---------|
| Déclaration | `ma_fonction() { … }` |
| Appel | `ma_fonction arg1 arg2` |
| Arguments | `$1`, `$2`, `$#`, `"$@"` |
| Variable locale | `local var=valeur` |
| Code de retour | `return 0` / `return 1` |
| Renvoyer une donnée | `echo "valeur"` + `VAR=$(ma_fonction)` |
| Importer | `source ./fonctions.sh` |

---

⬅️ [Précédent : 06.5 · Arguments](../05_Arguments/args.md) · 🏠 [Sommaire](../../README.md) · [Suivant : 07 · Docker (développeurs) ➡️](../../07_docker.md)
