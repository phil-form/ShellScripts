# 06.3 · Les boucles

> [!NOTE]
> **Objectifs**
> - Parcourir une liste d'éléments avec `for`
> - Répéter un traitement tant qu'une condition est vraie avec `while`
> - Lire un fichier ligne par ligne
> - Contrôler le déroulement avec `break` et `continue`

## Sommaire

1. [Boucle for](#boucle-for)
2. [Boucle while](#boucle-while)
3. [Lire un fichier ligne par ligne](#lire-un-fichier-ligne-par-ligne)
4. [break et continue](#break-et-continue)
5. [Récapitulatif](#récapitulatif)

---

Les boucles permettent de parcourir chaque élément d'une liste (la plupart du temps, on couple les deux : un tableau et une boucle) et d'exécuter une série d'opérations sur chacun d'eux.

---

## Boucle for

```bash
files=$(ls .)

for file in $files
do
  echo "$file"
done
```

> [!WARNING]
> Parcourir la sortie de `ls` est **fragile** : tout nom de fichier contenant un espace sera découpé en plusieurs éléments.
> La forme robuste utilise le *globbing* du shell :
>
> ```bash
> for file in ./*
> do
>   echo "$file"
> done
> ```

### Parcourir un tableau

```bash
RIGHTS=("ADMIN" "NETWORK" "DEV")

for right in "${RIGHTS[@]}"
do
  echo "Droit : $right"
done
```

### Parcourir une plage de nombres

```bash
for i in {1..5}
do
  echo "Itération $i"
done
```

Ou avec la syntaxe « à la C » :

```bash
for (( i = 0; i < 5; i++ ))
do
  echo "Itération $i"
done
```

### Exemple complet — sauvegarde par rotation

```bash
#!/bin/bash

for file in ./*
do
  echo "backing up $file"
  if [ -f "$file.1" ]; then
    mv "$file.1" "$file.2"
  fi
  cp "$file" "$file.1"
done
```

---

## Boucle while

La boucle `while` répète le bloc **tant que** la condition est vraie.

```bash
compteur=1

while [ $compteur -le 5 ]
do
  echo "Generate file.$compteur"
  touch "file.$compteur"
  compteur=$((compteur + 1))
done
```

> [!IMPORTANT]
> N'oubliez jamais de faire **évoluer** la variable de la condition (ici `compteur=$((compteur + 1))`), sinon la boucle tourne indéfiniment.
> `$(( ... ))` est la syntaxe d'évaluation arithmétique de bash.

### Boucle interactive

```bash
while read -p "Entrez un nom d'utilisateur à ajouter en DB : " line
do
  # Si l'utilisateur n'a rien saisi
  if [ -z "$line" ]; then
    # le break permet de stopper la boucle
    break
  fi
  echo "Ajoute l'utilisateur $line à la database"
done
```

### until — l'inverse de while

`until` répète le bloc **jusqu'à ce que** la condition devienne vraie :

```bash
until systemctl is-active --quiet apache2
do
  echo "En attente du démarrage d'apache2..."
  sleep 1
done
```

---

## Lire un fichier ligne par ligne

C'est le motif le plus utile de tout le chapitre :

```bash
while read line
do
  echo "La ligne contient $line"
done < file.txt
```

Avec `file.txt` :

```text
ligne1
ligne2 asdf
ligne3 aqeqwe
ligne4 asdafasd
```

Sortie :

```text
La ligne contient ligne1
La ligne contient ligne2 asdf
La ligne contient ligne3 aqeqwe
La ligne contient ligne4 asdafasd
```

> [!TIP]
> La forme recommandée est `while IFS= read -r line` :
> - `IFS=` préserve les espaces en début et fin de ligne ;
> - `-r` empêche l'interprétation des `\`.
>
> ```bash
> while IFS= read -r line
> do
>   echo "La ligne contient $line"
> done < file.txt
> ```

---

## break et continue

| Mot-clé | Effet |
|---------|-------|
| `break` | Sort immédiatement de la boucle |
| `continue` | Passe directement à l'itération suivante |

```bash
for file in ./*
do
  # On ignore les dossiers
  if [ -d "$file" ]; then
    continue
  fi

  # On s'arrête si on tombe sur un fichier de verrouillage
  if [ "$file" = "./STOP" ]; then
    echo "Fichier STOP détecté, arrêt."
    break
  fi

  echo "Traitement de $file"
done
```

---

## Récapitulatif

| Boucle | Syntaxe |
|--------|---------|
| Sur une liste | `for x in a b c; do … done` |
| Sur un tableau | `for x in "${ARR[@]}"; do … done` |
| Sur des fichiers | `for f in ./*; do … done` |
| Sur une plage | `for i in {1..5}; do … done` |
| Tant que | `while [ cond ]; do … done` |
| Jusqu'à ce que | `until [ cond ]; do … done` |
| Sur un fichier | `while IFS= read -r l; do … done < f.txt` |

**Fichiers d'exemple de ce dossier :** [`exemple_for.sh`](exemple_for.sh) · [`exemple_while.sh`](exemple_while.sh) · [`file.txt`](file.txt)

---

⬅️ [Précédent : 06.2 · Conditions](../02_operateur_logique/exemple.md) · 🏠 [Sommaire](../../README.md) · [Suivant : 06.4 · Gestion des erreurs ➡️](../04_gestion_des_erreurs/gestion_des_erreurs.md)
