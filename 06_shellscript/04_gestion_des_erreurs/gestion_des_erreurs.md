# 06.4 · La gestion des erreurs

> [!NOTE]
> **Objectifs**
> - Récupérer et tester le code de retour d'une commande
> - Interrompre automatiquement un script en cas d'erreur
> - Écrire sur la sortie d'erreur
> - Rattraper une erreur avec `||` et nettoyer avec `trap`

## Sommaire

1. [Récupérer le code de retour](#récupérer-le-code-de-retour)
2. [Arrêter le script automatiquement](#arrêter-le-script-automatiquement)
3. [Désactiver temporairement set -e](#désactiver-temporairement-set--e)
4. [Écrire sur la sortie d'erreur](#écrire-sur-la-sortie-derreur)
5. [Gestion simple avec ||](#gestion-simple-avec-)
6. [Nettoyer avec trap](#nettoyer-avec-trap)
7. [Récapitulatif](#récapitulatif)

---

## Récupérer le code de retour

Toute commande renvoie un **code de retour** : `0` si tout s'est bien passé, une valeur différente de zéro en cas d'erreur. On le récupère avec `$?`.

```bash
#!/bin/bash

# En imaginant que fichier1 n'existe pas
cp fichier1 fichier2

# Je peux récupérer le code d'erreur de la dernière commande lancée via $?
if [ $? -ne 0 ]; then
  echo "Erreur lors de la copie"
  exit 1
fi
```

> [!IMPORTANT]
> `$?` est **écrasé par chaque commande**, y compris par un `echo`. Testez-le immédiatement, ou stockez-le : `STATUS=$?`.

Convention des codes de sortie :

| Code | Signification |
|------|---------------|
| `0` | Succès |
| `1` | Erreur générique |
| `2` | Mauvais usage (arguments invalides) |
| `126` | Commande trouvée mais non exécutable |
| `127` | Commande introuvable |
| `130` | Interrompu par `CTRL + C` |

---

## Arrêter le script automatiquement

```bash
#!/bin/bash

# Via set -e, je demande d'arrêter le script en cas d'erreur
set -e
```

> [!TIP]
> **Le trio recommandé en début de script :**
>
> ```bash
> #!/bin/bash
> set -euo pipefail
> ```
>
> | Option | Effet |
> |--------|-------|
> | `-e` | Arrêter dès qu'une commande échoue |
> | `-u` | Arrêter si une variable non définie est utilisée |
> | `-o pipefail` | Faire échouer un pipe si **n'importe quelle** commande du pipe échoue (sans lui, seul le code de la dernière compte) |

---

## Désactiver temporairement `set -e`

Certaines commandes peuvent légitimement échouer. On désactive alors l'arrêt automatique avec **`set +e`**, puis on le réactive avec `set -e`.

```bash
#!/bin/bash
set -e

set +e          # je désactive l'arrêt en cas d'erreur
commande_qui_peut_echouer
STATUS=$?
set -e          # je le réactive

if [ $STATUS -ne 0 ]; then
  echo "La commande a échoué, mais je gère moi-même"
fi
```

Ou en isolant la portion dans un sous-shell :

```bash
#!/bin/bash
set -e

touch one
# Je désactive l'arrêt en cas d'erreur uniquement pour l'instruction touch two
(
  set +e
  touch two
)
touch three
```

> [!CAUTION]
> **Ne confondez pas `set +e` et `set -x`.**
>
> | Option | Rôle |
> |--------|------|
> | `set -e` / `set +e` | **Activer / désactiver** l'arrêt automatique en cas d'erreur |
> | `set -x` / `set +x` | **Activer / désactiver** le mode trace : chaque commande est affichée avant son exécution |
>
> `set -x` est extrêmement utile pour déboguer un script, mais il n'a **aucun effet** sur la gestion des erreurs.

---

## Écrire sur la sortie d'erreur

```bash
#!/bin/bash

echo "Un message normal d'information"
echo "Un message d'erreur" >&2
```

> [!NOTE]
> Envoyer les erreurs sur `stderr` (`>&2`) permet à l'appelant de séparer les deux flux :
> `./script.sh > rapport.log 2> erreurs.log`.
> C'est indispensable pour un script destiné à tourner en cron ou dans une CI.

---

## Gestion simple avec `||`

```bash
# Si je sais qu'une commande peut échouer sans impact pour la suite.
# Typiquement, on fait ça avec mkdir.

# Si le dossier existe déjà, cette commande échoue.
mkdir ./new_directory

# Ici, même si le dossier existe déjà, le script continue de s'exécuter.
mkdir ./new_directory || true

# Je peux aussi faire l'inverse : exécuter quelque chose en cas d'erreur.
mkdir ./new_directory || {
  echo "Impossible de créer le dossier !" >&2
  exit 1
}
```

> [!TIP]
> Pour ce cas précis, `mkdir -p ./new_directory` ne renvoie pas d'erreur si le dossier existe déjà (et crée au besoin les dossiers parents). C'est la solution la plus propre.

---

## Nettoyer avec `trap`

`trap` permet d'exécuter du code lorsque le script se termine — quelle qu'en soit la raison. C'est le moyen de garantir le nettoyage des fichiers temporaires.

```bash
#!/bin/bash
set -euo pipefail

TMPDIR=$(mktemp -d)

cleanup() {
  echo "Nettoyage de $TMPDIR"
  rm -rf "$TMPDIR"
}

# EXIT  : à la fin du script, succès ou erreur
# INT   : CTRL + C
# TERM  : kill
trap cleanup EXIT INT TERM

# ... le travail du script, qui peut échouer sans laisser de traces
```

---

## Récapitulatif

| Élément | Rôle |
|---------|------|
| `$?` | Code de retour de la dernière commande |
| `exit 0` / `exit 1` | Terminer le script avec un code |
| `set -e` | Arrêter en cas d'erreur |
| `set -u` | Arrêter si variable non définie |
| `set -o pipefail` | Propager l'erreur dans un pipe |
| `set +e` | Désactiver temporairement `-e` |
| `set -x` | Mode trace (debug) |
| `commande >&2` | Écrire sur la sortie d'erreur |
| `commande \|\| { … }` | Rattraper une erreur |
| `trap cleanup EXIT` | Nettoyer à la sortie |

> [!TIP]
> **Outil recommandé :** [ShellCheck](https://www.shellcheck.net/) analyse un script et signale la majorité des pièges vus dans ce chapitre.
>
> ```bash
> sudo apt install shellcheck
> shellcheck mon_script.sh
> ```

---

⬅️ [Précédent : 06.3 · Boucles](../03_boucles/exemple.md) · 🏠 [Sommaire](../../README.md) · [Suivant : 06.5 · Arguments ➡️](../05_Arguments/args.md)
