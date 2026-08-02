# 06.1 · Les bases du shell script

> [!NOTE]
> **Objectifs**
> - Créer, rendre exécutable et lancer un script
> - Afficher du texte et lire une saisie utilisateur
> - Manipuler des variables et des tableaux
> - Récupérer les arguments passés au script

## Sommaire

1. [Créer un script](#créer-un-script)
2. [Sortie — afficher des données](#sortie--afficher-des-données)
3. [Variables](#variables)
4. [Lecture de données](#lecture-de-données)
5. [Tableaux](#tableaux)
6. [Arguments](#arguments)
7. [Récapitulatif](#récapitulatif)

---

## Créer un script

Je crée un fichier (habituellement avec l'extension `.sh`) :

```bash
touch test.sh
```

Il faut ensuite le rendre exécutable :

```bash
chmod 750 test.sh
```

Une autre méthode, à ne pas utiliser sur des scripts de serveurs de production :

```bash
chmod +x test.sh
```

> [!TIP]
> `chmod +x` donne le droit d'exécution à **tout le monde**, y compris aux « autres ». `chmod 750` le réserve au propriétaire et à son groupe — c'est ce que l'on veut sur un serveur.

Éditer le script :

```bash
vim test.sh
```

Exemple de script :

```bash
#!/bin/bash

echo "Bonjour !!!!"
```

Le lancer :

```bash
./test.sh
```

En soi, un script n'est **qu'un fichier contenant une série de commandes** à exécuter l'une après l'autre.

### Le shebang

On commence généralement un script en définissant son environnement d'exécution : c'est la ligne `#!/bin/bash`, appelée *shebang*.

```bash
#!/bin/bash
```

| Shebang | Interpréteur |
|---------|--------------|
| `#!/bin/bash` | Bash (le plus courant) |
| `#!/bin/sh` | Shell POSIX — plus portable, mais moins de fonctionnalités |
| `#!/usr/bin/env bash` | Le bash trouvé dans le `PATH` — le plus portable des deux mondes |

> [!IMPORTANT]
> Sans shebang, le script est interprété par le shell courant, qui n'est pas forcément bash. Un script écrit en bash mais lancé par `sh` échouera sur les tableaux, `[[ ]]`, etc.

---

## Sortie — afficher des données

```bash
#!/bin/bash

echo "Bonjour !!!!"
```

> [!TIP]
> `echo -e "ligne1\nligne2"` interprète les caractères d'échappement (`\n`, `\t`).
> Pour un formatage fiable et portable, `printf` est préférable : `printf "%-10s %s\n" "Nom" "$NAME"`.

---

## Variables

### 1. Création et utilisation

```bash
#!/bin/bash

# Création d'une variable
NAME="Philippe"

# Utilisation d'une variable
echo "Bonjour !!!! $NAME"
```

> [!WARNING]
> **Pas d'espace autour du `=`** lors d'une affectation. `NAME = "Philippe"` est interprété comme l'exécution d'une commande nommée `NAME`.

### 2. Types de variables

```bash
#!/bin/bash

# Chaîne de caractères
NAME="Philippe"
# Entier
AGE=99
# Booléen (valeur vraie - true - ou fausse - false -)
TRAINER=true

# Utilisation d'une variable
echo "Bonjour !!!! $NAME"
```

### 3. Récupérer la sortie d'une commande dans une variable

```bash
#!/bin/bash

OUTPUT=$(ls -la /)
DATE=$(date)

# L'ancienne syntaxe
EXAMPLE=`date`
```

> [!TIP]
> Préférez `$( )` aux backticks : la syntaxe est lisible et surtout **imbricable** — `$(dirname "$(readlink -f "$0")")`.

### 4. Quoter ses variables

```bash
FICHIER="mon rapport.txt"

rm $FICHIER      # ❌ tente de supprimer "mon" ET "rapport.txt"
rm "$FICHIER"    # ✅ supprime bien le fichier
```

> [!IMPORTANT]
> **Entourez toujours vos variables de guillemets doubles**, sauf raison explicite. C'est la source n°1 de bugs en shell scripting.

---

## Lecture de données

Récupérer des données saisies par l'utilisateur :

```bash
#!/bin/bash

# j'utilise read pour lire ce que l'utilisateur entrera lors de l'exécution
# Le contenu saisi sera mis dans la variable NAME
read -p "Entrez votre nom : " NAME

echo "Votre nom est : $NAME"
```

Exemple d'utilisation :

```bash
./enter_name.sh
```

```text
Entrez votre nom : Philippe
Votre nom est : Philippe
```

| Option de `read` | Effet |
|------------------|-------|
| `-p "texte"` | Afficher une invite |
| `-s` | Saisie masquée (mots de passe) |
| `-t 10` | Délai d'attente de 10 secondes |
| `-r` | Ne pas interpréter les `\` (recommandé par défaut) |

---

## Tableaux

```bash
RIGHTS=("ADMIN" "NETWORK" "DEV")

echo "${RIGHTS[0]}"
echo "${RIGHTS[1]}"
echo "${RIGHTS[2]}"

RIGHTS[3]="TESTER"

echo "${RIGHTS[3]}"

# Afficher tous les éléments
echo "${RIGHTS[@]}"
echo "${RIGHTS[*]}"

# Ajouter un élément à la fin
RIGHTS+=("USER")

# Supprimer un élément
unset 'RIGHTS[3]'
echo "${RIGHTS[@]}"

# Obtenir la taille d'un tableau
echo "${#RIGHTS[@]}"
```

> [!NOTE]
> Les index commencent à **0**.
> `"${RIGHTS[@]}"` produit un élément par entrée (c'est ce qu'on veut dans une boucle `for`) ; `"${RIGHTS[*]}"` produit **une seule** chaîne où les éléments sont collés.

---

## Arguments

Exemple d'arguments :

```bash
ls -la /home/dev
```

Ici les arguments sont :

| Position | Valeur |
|----------|--------|
| `$0` | `ls` |
| `$1` | `-la` |
| `$2` | `/home/dev` |

```bash
#!/bin/bash

echo "Script name : $0"
echo "Argument 1 : $1"
echo "Argument 2 : $2"
echo "Nombre d'arguments : $#"
echo "Tous les arguments : $@"
```

Le sujet est approfondi dans le [chapitre 06.5 · Les arguments](../05_Arguments/args.md).

---

## Récapitulatif

| Élément | Syntaxe |
|---------|---------|
| Shebang | `#!/bin/bash` |
| Variable | `NAME="valeur"` puis `"$NAME"` |
| Sortie de commande | `VAR=$(commande)` |
| Saisie utilisateur | `read -p "invite : " VAR` |
| Tableau | `ARR=("a" "b")`, `"${ARR[@]}"`, `"${#ARR[@]}"` |
| Arguments | `$0`, `$1`, `$#`, `"$@"` |
| Rendre exécutable | `chmod 750 script.sh` |

---

⬅️ [Précédent : 05 · Sécurité](../../05_securite.md) · 🏠 [Sommaire](../../README.md) · [Suivant : 06.2 · Conditions ➡️](../02_operateur_logique/exemple.md)
