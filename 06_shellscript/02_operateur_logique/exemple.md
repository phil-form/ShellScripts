# 06.2 · Conditions et opérateurs logiques

> [!NOTE]
> **Objectifs**
> - Écrire des conditions `if` / `elif` / `else`
> - Tester l'existence et les droits d'un fichier
> - Comparer des nombres et des chaînes
> - Combiner des conditions avec `&&`, `||` et `!`

## Sommaire

1. [Les conditions](#les-conditions)
2. [Tests de vérification (fichiers)](#tests-de-vérification-fichiers)
3. [Tests de comparaison](#tests-de-comparaison)
4. [Else / Elif](#else--elif)
5. [Opérateurs logiques](#opérateurs-logiques)
6. [Récapitulatif](#récapitulatif)

---

## Les conditions

Les conditions (`if` / `else` / `elif`) permettent d'exécuter des parties d'un script sous certaines conditions.

Par exemple :

```bash
# Si le dossier du projet existe déjà, j'arrête le script
if [ -d "./$PROJECT_NAME" ]; then
  echo "Le projet existe déjà !"
  # Arrête le script en renvoyant 0 (pas d'erreur ; toute autre valeur = code d'erreur)
  exit 0
fi
```

> [!CAUTION]
> **Les espaces à l'intérieur des crochets sont obligatoires.**
> `[` n'est pas de la syntaxe : c'est une **commande**, et ses arguments doivent être séparés par des espaces.
>
> ```bash
> if [ -d "$DIR" ]; then   # ✅
> if [-d "$DIR"]; then     # ❌ "[-d: command not found"
> ```

### `[ ]` ou `[[ ]]` ?

| Syntaxe | Quand l'utiliser |
|---------|------------------|
| `[ ... ]` | Test POSIX, fonctionne partout (y compris `sh`) |
| `[[ ... ]]` | Spécifique à bash — **obligatoire** pour `=~` (regex) et les jokers, et plus tolérant sur les variables vides |
| `(( ... ))` | Comparaisons **arithmétiques** : `if (( VALUE > 10 ))` |

---

## Tests de vérification (fichiers)

| Argument | Signification |
|----------|---------------|
| `-f` | Vérifie qu'un **fichier** existe |
| `-d` | Vérifie qu'un **dossier** existe |
| `-e` | Vérifie qu'un élément existe (fichier ou dossier) |
| `-r` | Le fichier/dossier est **lisible** |
| `-w` | Le fichier/dossier est **modifiable** |
| `-x` | Le fichier/dossier est **exécutable** |
| `-s` | Le fichier existe et n'est **pas vide** |
| `-L` | L'élément est un **lien symbolique** |

---

## Tests de comparaison

| Argument | Signification |
|----------|---------------|
| `-eq` | Vérifie que deux nombres sont **égaux** |
| `-ne` | L'inverse de `-eq` |
| `-gt` | Le membre de gauche est **plus grand que** celui de droite |
| `-lt` | Le membre de gauche est **plus petit que** celui de droite |
| `-ge` | Plus grand **ou égal** |
| `-le` | Plus petit **ou égal** |
| `-z` | La variable est **vide** |
| `-n` | La variable n'est **pas vide** |
| `=` / `!=` | Comparaison de **chaînes** |
| `=~` | Comparaison avec une **expression régulière** (nécessite `[[ ]]`) |

> [!IMPORTANT]
> `-eq`, `-gt`, `-lt`… sont réservés aux **nombres**.
> Pour les **chaînes**, on utilise `=` et `!=`. Comparer `"abc" -eq "abd"` produit une erreur.

Exemples :

```bash
VALUE=5

if [ "$VALUE" -gt 10 ]; then
  echo "VALUE > 10"
fi

if [ "$VALUE" -ge 10 ]; then
  echo "VALUE >= 10"
fi

if [ "$VALUE" -eq 10 ]; then
  echo "VALUE == 10"
fi

if [ "$VALUE" -ne 10 ]; then
  echo "VALUE != 10"
fi
```

Dans le cas d'une chaîne de caractères, j'utilise `=` :

```bash
read -p "Entrez votre nom : " NAME

if [ "$NAME" = "Philippe" ]; then
  echo "Bonjour Admin"
fi
```

---

## Else / Elif

```bash
read -p "Confirmer le drop de la database (y/n) : " DROP_DB

# J'utilise [[ ]] et =~ pour comparer avec une expression régulière
if [[ "$DROP_DB" =~ ^[Yy]$ ]]; then
  echo "Dropping DB"
  # commandes de drop
  exit 0
else
  # Le code du else s'exécute uniquement si la condition du if est fausse
  echo "Exit!"
  exit 1
fi
```

```bash
# Le code qui suit s'exécute dans tous les cas
DB_USER=$(echo "Une commande qui retournerait les utilisateurs de la DB en filtrant sur le nom")

if [ -z "$DB_USER" ]; then
  echo "Create USER"
# Le elif permet d'ajouter un else avec une condition supplémentaire
# Le elif et le else sont optionnels
elif [ -z "$PASSWORD" ]; then
  echo "Update user password"
fi
```

> [!TIP]
> `[ -z "$VAR" ]` (« la variable est vide ») est plus lisible que `! [ -n "$VAR" ]`, et évite un piège classique : `[ ! -n $VAR ]` **sans guillemets** se comporte de manière imprévisible quand la variable est vide.

---

## Opérateurs logiques

### 1. `&&` — ET

```bash
if [ -f "./start.sh" ] && [ -x "./start.sh" ] && [ -r "./start.sh" ]; then
  echo "Le fichier existe, et peut être exécuté et lu"
fi
```

L'opérateur `&&` exige que **les deux** parties (gauche et droite) soient vraies pour retourner vrai.

### 2. `||` — OU

L'opérateur `||` permet d'exécuter une partie du script si **au moins une** des deux conditions est vraie.

```bash
read -p "Entrez (Y/y) pour continuer : " CONFIRM

if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
  echo "Si CONFIRM vaut Y ou y, j'exécute ce code"
fi
```

### 3. `!` — NON

```bash
if [ ! -f "./start.sh" ]; then
  echo "Création du fichier start.sh"
  touch start.sh
  chmod 750 start.sh
fi
```

> [!NOTE]
> Le `!` se place **à l'intérieur** des crochets (`[ ! -f … ]`) ou **avant** la commande de test séparé par un espace (`! [ -f … ]`), mais jamais collé à `[`.

### Enchaîner des commandes avec `&&` et `||`

En dehors d'un `if`, ces opérateurs servent aussi à enchaîner des commandes selon leur réussite :

```bash
mkdir /tmp/build && cd /tmp/build     # cd seulement si mkdir a réussi
cd /tmp/build || exit 1               # quitte si le cd échoue
```

C'est la base de la gestion d'erreurs vue au [chapitre 06.4](../04_gestion_des_erreurs/gestion_des_erreurs.md).

---

## Récapitulatif

```bash
if [ condition ]; then
  # ...
elif [ autre_condition ]; then
  # ...
else
  # ...
fi
```

| À retenir | |
|-----------|---|
| Espaces obligatoires | `[ "$A" = "$B" ]` |
| Nombres | `-eq -ne -gt -lt -ge -le` |
| Chaînes | `=` `!=` `-z` `-n` |
| Fichiers | `-f -d -e -r -w -x` |
| Regex | `[[ "$V" =~ ^[Yy]$ ]]` |
| Logique | `&&` `\|\|` `!` |

---

⬅️ [Précédent : 06.1 · Bases](../01_Base/base.md) · 🏠 [Sommaire](../../README.md) · [Suivant : 06.3 · Boucles ➡️](../03_boucles/exemple.md)
