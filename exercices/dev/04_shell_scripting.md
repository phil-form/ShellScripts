# 🐚 D4 · Shell scripting

*Chapitre [06 · Shell scripting](../../06_shellscript/) — les six sous-chapitres*

> [!NOTE]
> **Objectifs** : écrire les scripts d'outillage que l'équipe utilisera tous les jours — variables, conditions,
> boucles, gestion des erreurs, arguments, fonctions. On construit progressivement le contenu de
> `ticketflow/scripts/`.

> [!IMPORTANT]
> Règles du chapitre, valables pour **tous** les scripts qui suivent :
> - shebang `#!/bin/bash` en première ligne, script rendu exécutable ;
> - toute variable est **quotée** (`"$VAR"`) ;
> - chaque script passe [ShellCheck](https://www.shellcheck.net/) sans avertissement avant d'être considéré comme fini.

---

## 1 · Les bases *(chapitre [06.1](../../06_shellscript/01_Base/base.md))*

### Exercice 4.1 — `env-check.sh`

Un script qui affiche le contexte d'exécution, à lancer quand « ça marche chez moi ».

1. Créez `scripts/env-check.sh`, avec shebang, et rendez-le exécutable.
2. Affichez : l'utilisateur courant, le dossier courant, la date, le nom de la machine et la version de bash.
   *(Chaque valeur vient d'une commande dont vous récupérez la sortie dans une variable, avec la syntaxe moderne.)*
3. Affichez le tout sous cette forme :
```text
   === ticketflow · env-check ===
   utilisateur : alice
   dossier     : /home/alice/ticketflow
```
4. Ajoutez une variable `PROJET="ticketflow"` en haut du script et utilisez-la dans l'en-tête.
5. Faites-lui afficher le **nombre de fichiers** du dossier courant (une commande, capturée dans une variable).

### Exercice 4.2 — Variables et quoting

1. Créez une variable contenant `mon dossier de travail` (avec des espaces) et faites-en un dossier.
   Que se passe-t-il **sans** guillemets ? Faites l'essai, puis corrigez.
2. Écrivez un script qui demande à l'utilisateur (`read`) son prénom et le port sur lequel il veut lancer
   l'API, puis affiche `Bonjour <prénom>, l'API tournera sur le port <port>`.
3. Faites en sorte que le port ait la valeur `3000` **si l'utilisateur ne saisit rien**.
   *(Indice : la valeur par défaut d'une variable s'écrit avec `:-`.)*
4. Demandez un mot de passe **sans qu'il s'affiche à l'écran** pendant la saisie.

### Exercice 4.3 — Tableaux

1. Créez un tableau `SERVICES` contenant `api`, `web`, `db` et `redis`.
2. Affichez tous ses éléments, puis uniquement le troisième.
3. Affichez le **nombre** d'éléments.
4. Ajoutez `worker` à la fin, supprimez `redis`, réaffichez le tableau.
5. Remplissez un tableau avec la liste des fichiers `.js` de `api/src` et affichez sa taille.

---

## 2 · Conditions *(chapitre [06.2](../../06_shellscript/02_operateur_logique/exemple.md))*

### Exercice 4.4 — `preflight.sh`

Le script qui vérifie qu'on peut lancer le projet.

1. Vérifiez que le dossier `api/` existe ; sinon, affichez une erreur et sortez avec le code `1`.
2. Vérifiez que le fichier `api/.env` existe ; s'il n'existe pas mais que `api/.env.example` existe,
   copiez l'exemple et prévenez l'utilisateur.
3. Vérifiez que le fichier `scripts/deploy.sh` est **exécutable**.
4. Vérifiez que la commande `docker` est disponible sur la machine. *(Indice : `command -v`.)*
5. Vérifiez que la variable d'environnement `DATABASE_URL` est définie **et non vide**.
6. Terminez par `Tout est prêt ✔` si toutes les vérifications passent.

### Exercice 4.5 — Comparaisons et `elif`

1. Écrivez un script qui reçoit un environnement (`dev`, `staging`, `prod`) dans une variable et affiche le
   port correspondant (3000, 4000, 80) — avec `if` / `elif` / `else`, puis **réécrivez-le avec un `case`**.
   Lequel est le plus lisible ?
2. Écrivez un test qui compare deux **nombres** (le nombre de tests attendus et le nombre de tests passés)
   et affiche `OK` ou `ÉCHEC`.
3. Écrivez un test qui vérifie qu'une chaîne de version correspond au format `x.y.z`
   *(indice : `[[ ]]` et `=~`)*.
4. Expliquez en une phrase la différence entre `[ ]` et `[[ ]]`, et pourquoi on préfère le second en bash.

### Exercice 4.6 — Opérateurs logiques

1. Écrivez, **en une seule ligne**, « crée le dossier `logs` s'il n'existe pas, sans afficher d'erreur s'il existe ».
2. Écrivez, en une ligne, « lance les tests et, seulement s'ils passent, lance le build ».
3. Écrivez, en une ligne, « lance le build et, en cas d'échec, affiche un message d'erreur et sors avec le code 1 ».
4. Combinez deux conditions dans un seul `if` : le fichier `.env` existe **et** la variable `NODE_ENV` vaut `dev`.

---

## 3 · Boucles *(chapitre [06.3](../../06_shellscript/03_boucles/exemple.md))*

### Exercice 4.7 — Parcourir

1. Bouclez sur le tableau `SERVICES` et affichez `→ démarrage de <service>` pour chacun.
2. Bouclez sur tous les fichiers `.js` de `api/src` et affichez, pour chacun, son nom et son nombre de lignes.
3. Bouclez sur les nombres de 1 à 5 et affichez `tentative n°X`.
4. Bouclez sur les nombres de 0 à 100 **par pas de 10**.

### Exercice 4.8 — `while`, `until`, lecture de fichier

1. Écrivez une boucle qui attend qu'un fichier `logs/ready.flag` apparaisse, en affichant un point toutes
   les secondes. *(Créez le fichier depuis un autre terminal pour la débloquer.)*
2. Réécrivez la même attente avec `until`.
3. Lisez `logs/app.log` **ligne par ligne** et affichez uniquement les lignes de niveau `ERROR`, préfixées
   d'un numéro d'ordre.
4. Écrivez une boucle interactive qui redemande un nom d'environnement tant que la réponse n'est pas
   `dev`, `staging` ou `prod`.
5. Dans la boucle de lecture de log, **sautez** les lignes vides (`continue`) et **arrêtez** la lecture
   dès qu'une ligne contient `FATAL` (`break`).

### Exercice 4.9 — Rotation des sauvegardes

1. Écrivez un script qui, pour chaque fichier de `logs/`, crée une copie horodatée dans `archives/`
   (format `nom-AAAAMMJJ-HHMMSS.log`).
2. Complétez-le pour qu'il ne conserve que les **3 archives les plus récentes** de chaque log et supprime
   les autres. *(Indice : `ls -t` et une boucle, ou `find` — comparez les deux approches.)*

---

## 4 · Gestion des erreurs *(chapitre [06.4](../../06_shellscript/04_gestion_des_erreurs/gestion_des_erreurs.md))*

### Exercice 4.10 — Échouer proprement

1. Écrivez un script qui lance `cat fichier-inexistant` puis affiche son **code de retour**.
2. Faites en sorte que le script s'arrête **automatiquement** à la première erreur.
3. Ajoutez le traitement des variables non définies et des erreurs dans un pipe.
   *(La ligne complète est celle que vous mettrez en tête de tous vos scripts.)*
4. Désactivez temporairement l'arrêt automatique pour **une seule** commande dont l'échec est acceptable.
5. Écrivez une fonction `erreur()` qui affiche son message sur la **sortie d'erreur** avec un préfixe
   `[ERREUR]` et sort avec le code `1`. Utilisez-la dans `preflight.sh`.
6. Écrivez le message de succès sur la sortie standard et vérifiez, avec les redirections du chapitre 01,
   que vos deux flux sont bien séparés.

### Exercice 4.11 — Nettoyer avec `trap`

1. Écrivez un script qui crée un dossier temporaire, y travaille, et le **supprime toujours** en sortant —
   que le script réussisse, échoue, ou soit interrompu par `CTRL+C`.
2. Vérifiez les trois cas : succès, erreur provoquée, `CTRL+C`.
3. Ajoutez un message `nettoyage…` dans la fonction de nettoyage pour prouver qu'elle passe bien.
4. Pourquoi `mktemp -d` est-il préférable à un dossier `/tmp/mon-script` codé en dur ?

---

## 5 · Arguments *(chapitre [06.5](../../06_shellscript/05_Arguments/args.md))*

### Exercice 4.12 — Arguments positionnels

1. Écrivez `scripts/logs.sh` qui reçoit un nom de service en argument et affiche `logs du service <nom>`.
2. Si aucun argument n'est fourni, affichez un mode d'emploi et sortez avec le code `1`.
3. Affichez le **nombre** d'arguments reçus, puis **tous** les arguments, un par ligne.
4. Faites que le script accepte plusieurs services d'un coup et boucle dessus.

### Exercice 4.13 — `getopts`

Faites de `scripts/deploy.sh` une vraie commande :

```text
Usage: deploy.sh -e <env> [-t <tag>] [-n] [-v] [-h]
  -e ENV   environnement cible : dev | staging | prod   (obligatoire)
  -t TAG   tag de l'image à déployer                    (défaut : latest)
  -n       dry-run : affiche ce qui serait fait, sans le faire
  -v       mode verbeux
  -h       affiche cette aide
```

1. Implémentez le parsing avec `getopts`.
2. `-h` affiche l'aide et sort avec le code `0`.
3. L'absence de `-e` est une erreur : message sur la sortie d'erreur + code `1`.
4. Une valeur de `-e` autre que `dev`, `staging` ou `prod` est refusée.
5. Une option inconnue affiche l'aide et sort en erreur.
6. En mode `-n`, chaque action est préfixée de `[dry-run]` et n'est pas exécutée réellement.
7. En mode `-v`, le script affiche en plus chaque étape et les valeurs des options reçues.

---

## 6 · Fonctions *(chapitre [06.6](../../06_shellscript/06_fonctions/fonctions.md))*

### Exercice 4.14 — Découper

Reprenez `deploy.sh` et découpez-le en fonctions : `usage()`, `log()`, `erreur()`, `verifier_prerequis()`,
`construire()`, `deployer()`.

1. Le corps du script ne doit plus être qu'une suite d'appels de fonctions.
2. `log()` prend un message et l'affiche horodaté : `[2024-03-01 09:12:00] message`.
3. `verifier_prerequis()` renvoie `0` si tout va bien, `1` sinon — et le script réagit à ce code de retour.
4. Utilisez `local` pour toutes les variables internes. Démontrez, avec un exemple, ce qui se passe si vous
   l'oubliez.
5. Écrivez une fonction qui **renvoie une valeur** (et pas seulement un code) : `taille_du_projet()` qui
   renvoie le poids de `ticketflow/`, récupérée dans une variable par l'appelant.

### Exercice 4.15 — `scripts/lib.sh`, la bibliothèque de l'équipe

1. Créez `scripts/lib.sh` qui contient `log()`, `erreur()`, `confirmer()` (pose une question o/n et renvoie
   `0` ou `1`) et `require_cmd()` (vérifie qu'une commande existe, sinon sort en erreur).
2. `lib.sh` ne doit **rien exécuter** quand on le source : uniquement définir des fonctions.
3. Importez-le depuis `deploy.sh`, `preflight.sh` et `logs.sh`, et supprimez le code dupliqué.
4. Faites en sorte que l'import fonctionne **quel que soit le dossier depuis lequel on lance le script**.
   *(Indice : dériver le chemin du script à partir de `$0` / `BASH_SOURCE`.)*
5. Ajoutez à `lib.sh` une fonction `couleur()` qui affiche un message en vert (succès) ou en rouge (erreur).

---

## ✅ Vérification

`ticketflow/scripts/` contient au minimum `lib.sh`, `env-check.sh`, `preflight.sh`, `logs.sh` et `deploy.sh`, et :

- tous sont exécutables et démarrent par un shebang ;
- tous commencent par la même ligne de robustesse (`set -euo pipefail`) et sourcent `lib.sh` ;
- `deploy.sh -h` affiche une aide utilisable, `deploy.sh` sans argument échoue **avec un code de sortie non nul** ;
- `deploy.sh -e prod -n` ne fait rien d'autre qu'afficher ce qu'il ferait ;
- aucun script ne laisse de fichier temporaire derrière lui, même interrompu par `CTRL+C` ;
- `shellcheck scripts/*.sh` ne renvoie rien.
