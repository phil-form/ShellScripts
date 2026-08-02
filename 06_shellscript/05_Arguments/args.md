# 06.5 · Les arguments

> [!NOTE]
> **Objectifs**
> - Récupérer les arguments positionnels d'un script
> - Compter et parcourir les arguments
> - Parser des options (`-h`, `-v`, `-u valeur`) avec `getopts`

## Sommaire

1. [Les arguments positionnels](#les-arguments-positionnels)
2. [Nombre d'arguments](#nombre-darguments)
3. [Le tableau des arguments](#le-tableau-des-arguments)
4. [Parsing d'arguments avec getopts](#parsing-darguments-avec-getopts)
5. [Syntaxe des options](#syntaxe-des-options)
6. [Vérifier la présence d'un argument avec un if](#vérifier-la-présence-dun-argument-avec-un-if)
7. [Récapitulatif](#récapitulatif)

---

## Les arguments positionnels

Les arguments sont ce qui suit la commande qu'on exécute :

```bash
ls -la /dev
```

Ici les arguments sont :

| Argument | Variable |
|----------|----------|
| `ls`   | `$0` |
| `-la`  | `$1` |
| `/dev` | `$2` |

Les récupérer dans un script :

```bash
#!/bin/bash

echo "Nom du script : $0"
echo "Argument 1 : $1"
echo "Argument 2 : $2"
echo "Argument 3 : $3"
echo "Argument 4 : $4"
echo "Argument 5 : $5"
echo "Argument 6 : $6"
echo "etc"
```

> [!NOTE]
> Au-delà de `$9`, il faut utiliser des accolades : `${10}`, `${11}`… Sinon `$10` est interprété comme `$1` suivi du caractère `0`.

---

## Nombre d'arguments

```bash
#!/bin/bash

echo $#
```

C'est la base de toute vérification d'usage :

```bash
#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage : $0 <source> <destination>" >&2
  exit 2
fi
```

---

## Le tableau des arguments

Récupérer **le tableau** des arguments :

```bash
#!/bin/bash

echo "$@"
```

Récupérer **la chaîne de caractères** contenant tous les arguments :

```bash
#!/bin/bash

echo "$*"
```

> [!IMPORTANT]
> La différence entre les deux n'apparaît qu'entre guillemets, et elle est essentielle :
>
> | Forme | Résultat avec les arguments `a` `b c` |
> |-------|----------------------------------------|
> | `"$@"` | Deux éléments distincts : `a` et `b c` ✅ |
> | `"$*"` | Un seul élément : `a b c` |
>
> Dans une boucle, utilisez **toujours** `"$@"` :
>
> ```bash
> for arg in "$@"; do
>   echo "Argument : $arg"
> done
> ```

---

## Parsing d'arguments avec getopts

```bash
#!/bin/bash

# Syntaxe
# while getopts "options" NOM_VARIABLE;
# do
#   case "$NOM_VARIABLE" in
#   ....
#   esac
# done

while getopts "hv" OPS
do
  case "$OPS" in
    h)
      echo "afficher l'aide"
      exit 0
      ;;
    v)
      echo "Activer le mode verbose"
      ;;
    *)
      echo "Option inconnue ! $OPS" >&2
      exit 1
      ;;
  esac
done
```

> [!WARNING]
> Le `case` doit impérativement être refermé par un **`esac`** avant le `done`, sinon bash s'arrête sur une erreur de syntaxe.

Exemples d'exécution :

```bash
./script.sh -h
```

```text
afficher l'aide
```

```bash
./script.sh -v
```

```text
Activer le mode verbose
```

```bash
./script.sh -r
```

```text
Option inconnue ! -r
```

---

## Syntaxe des options

```bash
# Je précise les options -h et -v
getopts "hv"

# Ici je précise que -u et -p seront suivis d'une valeur (l'argument suivant)
getopts "u:p:hv"
```

Le `:` après une lettre signifie : « cette option attend une valeur ».

```bash
#!/bin/bash

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
      echo "afficher l'aide"
      exit 0
      ;;
    v)
      echo "Activer le mode verbose"
      VERBOSE=true
      ;;
    *)
      echo "Option inconnue '$OPS' !" >&2
      exit 1
      ;;
  esac
done
```

| Variable | Contenu |
|----------|---------|
| `$OPTARG` | La valeur associée à l'option courante |
| `$OPTIND` | L'index du prochain argument à traiter |

> [!TIP]
> Après la boucle, `shift $((OPTIND - 1))` retire toutes les options traitées, de sorte que `"$@"` ne contienne plus que les arguments positionnels restants (les fichiers à traiter, par exemple).
>
> Ne passez **jamais** un mot de passe en argument de ligne de commande sur une vraie machine : il est visible par tous dans `ps aux` et reste dans l'historique du shell. Préférez `read -s`, une variable d'environnement ou un fichier protégé.

---

## Vérifier la présence d'un argument avec un if

```bash
# Ici je regarde si la chaîne d'arguments contient -v
if [[ "$*" == *-v* ]]; then
  VERBOSE=true
fi
```

> [!NOTE]
> Cette forme nécessite `[[ ]]` : la comparaison avec un joker (`*-v*`) n'est pas supportée par `[ ]`.
> Elle est pratique pour un cas simple, mais `getopts` reste préférable dès que le script accepte plusieurs options.

---

## Récapitulatif

| Variable | Contenu |
|----------|---------|
| `$0` | Nom du script |
| `$1` … `$9`, `${10}` | Arguments positionnels |
| `$#` | Nombre d'arguments |
| `"$@"` | Tous les arguments, comme éléments distincts ✅ |
| `"$*"` | Tous les arguments, en une seule chaîne |
| `$OPTARG` | Valeur de l'option courante (`getopts`) |
| `shift` | Décale les arguments d'un cran |

---

⬅️ [Précédent : 06.4 · Gestion des erreurs](../04_gestion_des_erreurs/gestion_des_erreurs.md) · 🏠 [Sommaire](../../README.md) · [Suivant : 06.6 · Fonctions ➡️](../06_fonctions/fonctions.md)
