# 📜 A9 · Scripts d'administration

*Chapitre [06 · Shell scripting](../../06_shellscript/) — les six sous-chapitres*

> [!NOTE]
> **Objectifs** : automatiser ce que vous faites deux fois. Auditer les comptes, sauvegarder avec rotation,
> surveiller la machine, créer des comptes en série — avec des scripts qui échouent proprement, s'expliquent
> et ne laissent rien derrière eux.

> [!IMPORTANT]
> Règles valables pour tous les scripts du chapitre :
> - shebang, exécutable, dans `/usr/local/bin` ou `/srv/ticketflow/scripts` ;
> - `set -euo pipefail` en tête ;
> - toute variable quotée ;
> - un script d'administration **ne détruit rien** sans un `--dry-run` disponible et une confirmation ;
> - il passe [ShellCheck](https://www.shellcheck.net/) sans avertissement.

---

## 1 · Les bases *(chapitre [06.1](../../06_shellscript/01_Base/base.md))*

### Exercice 9.1 — `sysinfo.sh`

Le script que vous lancerez en arrivant sur une machine inconnue.

1. Affichez, proprement présentés : nom de la machine, distribution, noyau, *uptime*, charge moyenne,
   mémoire libre, occupation de `/`, nombre d'utilisateurs connectés, nombre de services en échec.
2. Chaque valeur vient d'une commande dont vous capturez la sortie dans une variable.
3. Ajoutez un en-tête avec la date et le nom du serveur, et un séparateur.
4. Faites-le écrire son rapport **à l'écran et** dans `/var/log/ticketflow/sysinfo-<date>.txt`.
5. Stockez les seuils d'alerte (disque, charge) dans des variables en haut du fichier, pour qu'ils se
   modifient sans relire le code.

### Exercice 9.2 — Tableaux

1. Créez un tableau `SERVICES_CRITIQUES` contenant `ssh`, `nginx`, `postgresql` et `ticketflow-api`.
2. Affichez le nombre d'éléments, puis chaque élément.
3. Remplissez un tableau avec la liste des utilisateurs humains de la machine
   *(chapitre [03](../../03_commandes_essentielles.md))* et affichez-le.
4. Ajoutez un service au tableau, retirez-en un, réaffichez.

---

## 2 · Conditions *(chapitre [06.2](../../06_shellscript/02_operateur_logique/exemple.md))*

### Exercice 9.3 — `check-server.sh`

1. Le script doit refuser de s'exécuter s'il n'est **pas** lancé en root. Comment teste-t-on cela ?
2. Vérifiez que `/srv/ticketflow` existe et est un dossier.
3. Vérifiez que le fichier de configuration existe et est **lisible**.
4. Vérifiez que la commande `pg_dump` est disponible.
5. Vérifiez que l'occupation de `/` est sous le seuil défini ; sinon, affichez une alerte.
6. Vérifiez qu'une variable d'environnement obligatoire est définie **et non vide**.
7. Écrivez un test qui compare deux nombres (l'espace libre et le seuil) et un test qui compare deux chaînes
   (l'environnement). Pourquoi les opérateurs ne sont-ils pas les mêmes ?
8. Écrivez, en une seule ligne, « crée le dossier de sauvegarde s'il n'existe pas », puis
   « lance la sauvegarde, et si elle échoue, écris une alerte et sors en erreur ».

---

## 3 · Boucles *(chapitre [06.3](../../06_shellscript/03_boucles/exemple.md))*

### Exercice 9.4 — Parcourir

1. Bouclez sur `SERVICES_CRITIQUES` et affichez, pour chacun, `✔` ou `✘` selon qu'il est actif.
2. Bouclez sur les *homes* des utilisateurs et affichez, pour chacun, son poids
   *(chapitre [03](../../03_commandes_essentielles.md))*.
3. Bouclez sur les fichiers de `/etc/sudoers.d` et affichez le nom de chacun avec ses droits.
4. Bouclez sur une liste d'adresses IP et testez si chacune répond au ping, avec un résumé final.

### Exercice 9.5 — Lire un fichier, attendre

1. Lisez `/etc/passwd` **ligne par ligne** et affichez, pour les seuls comptes humains, le nom et le shell.
2. Lisez un fichier `utilisateurs.csv` (`nom;groupe;commentaire`) et créez les comptes correspondants.
   Sautez les lignes vides et les commentaires (`continue`), arrêtez-vous si une ligne est malformée (`break`).
3. Écrivez une boucle qui attend qu'un service soit réellement `active`, avec un **délai maximal** et un
   message d'échec au-delà. Pourquoi une attente sans borne est-elle inacceptable dans un script d'exploitation ?
4. Réécrivez cette attente avec `until`.

### Exercice 9.6 — `backup.sh` et la rotation

1. Écrivez un script qui archive `/srv/ticketflow` et `/etc` dans
   `/srv/ticketflow/backups/backup-AAAAMMJJ-HHMMSS.tar.gz`, **en préservant droits et ACL**.
2. Ajoutez un dump de la base PostgreSQL, **sans jamais faire apparaître le mot de passe dans la ligne
   de commande** *(indice : un fichier d'environnement sourcé, ou `~/.pgpass`)*.
3. Ne conservez que les **7 dernières** sauvegardes, supprimez les autres.
4. Écrivez la taille et la durée de chaque sauvegarde dans un fichier de log.
5. Produisez une somme de contrôle par archive, et une commande de vérification.

---

## 4 · Gestion des erreurs *(chapitre [06.4](../../06_shellscript/04_gestion_des_erreurs/gestion_des_erreurs.md))*

### Exercice 9.7 — Échouer proprement

1. Ajoutez `set -euo pipefail` à `backup.sh` et constatez ce qui casse — corrigez ce qui doit l'être.
2. Désactivez temporairement l'arrêt automatique pour **une seule** commande dont l'échec est acceptable.
3. Écrivez `erreur()` : message préfixé `[ERREUR]` sur la **sortie d'erreur**, code de sortie non nul.
4. Faites en sorte que le script sorte avec un code **différent** selon la cause : 1 (arguments),
   2 (prérequis manquant), 3 (sauvegarde échouée). Pourquoi est-ce utile quand le script est appelé par
   cron ou par un *timer* systemd ?
5. Une sauvegarde interrompue ne doit **jamais** laisser d'archive incomplète : écrivez dans un fichier
   temporaire renommé seulement en cas de succès.
6. Avec `trap`, garantissez la suppression du dossier temporaire en fin de script, en cas d'erreur,
   et sur `CTRL+C`. Vérifiez les trois cas.
7. Faites en sorte qu'une erreur envoie une ligne dans le journal système *(indice : `logger`)*.
   Où la retrouvez-vous ensuite ?

---

## 5 · Arguments *(chapitre [06.5](../../06_shellscript/05_Arguments/args.md))*

### Exercice 9.8 — `backup.sh` en vraie commande

```text
Usage: backup.sh -d <destination> [-k <nombre>] [-t full|db|conf] [-n] [-v] [-h]
  -d DEST   dossier de destination                      (obligatoire)
  -k N      nombre de sauvegardes conservées            (défaut : 7)
  -t TYPE   ce qu'on sauvegarde : full | db | conf      (défaut : full)
  -n        dry-run : affiche ce qui serait fait
  -v        mode verbeux
  -h        aide
```

1. Implémentez le parsing avec `getopts`.
2. `-h` affiche l'aide et sort avec le code `0` ; l'absence de `-d` est une erreur.
3. Une valeur de `-t` inconnue est refusée avec un message explicite.
4. `-k` doit être un **entier positif** : validez-le.
5. En mode `-n`, aucune écriture ni suppression n'a lieu — chaque action est annoncée, préfixée `[dry-run]`.
6. Testez : `-n -t db`, `-k abc`, `-t plop`, aucune option, `-h`.

### Exercice 9.9 — `useradd-batch.sh`

1. Un script qui reçoit un fichier CSV en argument et crée les comptes qu'il décrit.
2. Il vérifie **avant** de créer : le compte n'existe pas déjà, le groupe existe, le nom est valide.
3. Il génère un mot de passe aléatoire par compte, force son changement à la première connexion,
   et écrit les identifiants dans un fichier lisible **par root seul**.
4. Il produit un compte rendu final : créés, ignorés, en erreur.
5. Il dispose d'un `--dry-run`.

---

## 6 · Fonctions *(chapitre [06.6](../../06_shellscript/06_fonctions/fonctions.md))*

### Exercice 9.10 — Découper et partager

1. Découpez `backup.sh` en fonctions : `usage`, `log`, `erreur`, `verifier_prerequis`, `sauver_fichiers`,
   `sauver_base`, `rotation`, `nettoyage`.
2. Le corps du script n'est plus qu'une suite d'appels.
3. `log()` horodate ses messages et écrit à la fois à l'écran et dans le fichier de log.
4. `verifier_prerequis()` renvoie un **code** que le script exploite.
5. Écrivez une fonction qui **renvoie une valeur** : `espace_libre()` renvoie le pourcentage d'occupation
   de la partition passée en argument.
6. Utilisez `local` partout ; montrez, par un exemple, ce qui casse quand on l'oublie.

### Exercice 9.11 — `lib-admin.sh`

1. Créez `/usr/local/lib/lib-admin.sh` avec `log`, `erreur`, `confirmer`, `require_root`, `require_cmd`,
   `service_actif`, `alerte` (envoi d'une ligne dans le journal système).
2. Le fichier ne doit **rien exécuter** quand on le source.
3. Sourcez-le depuis `backup.sh`, `check-server.sh` et `useradd-batch.sh`, et supprimez tout le code dupliqué.
4. Faites en sorte que l'import fonctionne quel que soit le dossier depuis lequel le script est lancé.
5. Ajoutez la couleur — désactivée automatiquement quand la sortie n'est pas un terminal.
   Pourquoi est-ce indispensable pour un script appelé par cron ?

### Exercice 9.12 — Mise en production

1. Installez `backup.sh` dans `/usr/local/bin` avec le propriétaire et les droits corrects
   *(chapitre [02](../../02_file_permissions.md))*.
2. Planifiez-le quotidiennement — en cron **ou** en *timer* systemd *(chapitre [04](../../04_installation_et_services.md))*.
3. Vérifiez le lendemain que la tâche est passée : où regardez-vous ?
4. Provoquez un échec (destination inexistante) et vérifiez que vous en êtes **averti** sans avoir à
   aller regarder.
5. Écrivez la procédure de **restauration** dans `journal.md`, et testez-la réellement.
   Une sauvegarde qu'on n'a jamais restaurée n'est pas une sauvegarde.

---

## ✅ Vérification

- `/usr/local/bin` contient `sysinfo.sh`, `check-server.sh`, `backup.sh`, `useradd-batch.sh`, et
  `/usr/local/lib/lib-admin.sh` porte tout le code commun.
- `shellcheck` ne renvoie rien sur aucun d'eux.
- `backup.sh -h` s'explique tout seul ; `backup.sh` sans argument échoue avec un code non nul.
- `backup.sh -n` ne modifie rien du tout.
- Un `CTRL+C` en pleine sauvegarde ne laisse ni archive partielle ni dossier temporaire.
- La sauvegarde tourne toute seule, échoue bruyamment, et vous avez **restauré** au moins une fois.
