# 🎓 D8 · Projet final — `tf`, la CLI de l'équipe

*Tout le parcours : chapitres [01](../../01_base.md), [02](../../02_file_permissions.md),
[03](../../03_commandes_essentielles.md), [04](../../04_installation_et_services.md),
[06](../../06_shellscript/), [07](../../07_docker.md), [09](../../09_tmux.md), [10](../../10_shell_config.md)*

> [!NOTE]
> **Objectif** : écrire `tf`, la commande unique que toute l'équipe `ticketflow` tape à la place de retenir
> vingt lignes de `docker compose`, de `psql` et de `tail`. C'est le livrable du parcours : un vrai outil,
> pas un exercice.

> [!IMPORTANT]
> Aucun corrigé. Les **critères de réussite** en fin de document font office de cahier des charges :
> si votre outil les remplit, il est bon.

---

## 🎯 Le cahier des charges

```text
Usage: tf <commande> [options]

Commandes :
  up                démarre la stack de développement (API + base + cache)
  down              arrête la stack
  restart [service] redémarre toute la stack, ou un seul service
  status            affiche l'état des services et leur santé
  logs [service]    suit les logs (tous les services, ou un seul)
  shell [service]   ouvre un shell dans un service (défaut : api)
  db                ouvre un client psql sur la base
  backup            sauvegarde la base dans backups/, avec rotation
  restore <fichier> restaure une sauvegarde (avec confirmation)
  test              lance les tests dans un conteneur jetable
  clean             supprime conteneurs, volumes et fichiers temporaires
  doctor            vérifie que la machine est prête à travailler
  help              affiche cette aide

Options globales :
  -v, --verbose     affiche chaque commande exécutée
  -n, --dry-run     affiche ce qui serait fait, sans le faire
  -h, --help        affiche cette aide
```

---

## Étape 1 — Le squelette *(chapitres [06.1](../../06_shellscript/01_Base/base.md) et [06.5](../../06_shellscript/05_Arguments/args.md))*

1. Créez `scripts/tf`, exécutable, avec shebang et la ligne de robustesse habituelle.
2. Parsez la **commande** (premier argument) et ses options. `help` et l'absence d'argument affichent l'aide.
3. Une commande inconnue affiche l'aide **sur la sortie d'erreur** et sort avec un code non nul.
4. Le script doit fonctionner **depuis n'importe quel dossier** : dérivez la racine du projet du chemin du
   script, pas du dossier courant.
5. Rendez `tf` appelable sans chemin depuis tout le système *(exercice [7.4](07_environnement_de_travail.md))*.

## Étape 2 — `doctor` *(chapitres [06.2](../../06_shellscript/02_operateur_logique/exemple.md) et [03](../../03_commandes_essentielles.md))*

Vérifiez, en affichant une ligne `✔` / `✘` par point :

1. `docker` et `docker compose` sont installés et le démon répond ;
2. l'utilisateur courant peut lancer Docker **sans `sudo`** — sinon, indiquez le groupe à rejoindre
   *(exercice [3.4](03_admin_minimal.md))* ;
3. les fichiers `docker/docker-compose.yml` et `api/.env` existent (proposez de créer `.env` depuis
   `.env.example` s'il manque) ;
4. les ports 3000 et 5432 sont libres, ou occupés par **nos** conteneurs ;
5. `git`, `curl` et `jq` sont présents — sinon, affichez la commande d'installation exacte à copier-coller ;
6. `doctor` sort avec le code `0` si tout va bien, `1` sinon.

## Étape 3 — Le cycle de vie *(chapitre [07](../../07_docker.md))*

1. `up` démarre la stack en arrière-plan, puis **attend** que l'API réponde sur `/health` avant de rendre
   la main (avec un délai maximal et un message clair en cas d'échec).
2. `down`, `restart [service]`, `status` : `status` affiche l'état de chaque service **et** son état de santé.
3. `logs [service]` suit les logs en direct ; sans argument, ceux de tous les services.
4. `shell [service]` ouvre un shell dans le service demandé — en gérant le cas où le service ne tourne pas.
5. `db` ouvre un `psql` sur la base, **sans jamais faire apparaître le mot de passe dans la ligne de commande**
   ni dans l'historique. *(Indice : un `.env` sourcé, ou la variable attendue par `psql`.)*

## Étape 4 — Sauvegarde et restauration *(chapitres [06.3](../../06_shellscript/03_boucles/exemple.md) et [06.4](../../06_shellscript/04_gestion_des_erreurs/gestion_des_erreurs.md))*

1. `backup` produit `backups/ticketflow-AAAAMMJJ-HHMMSS.dump` depuis le conteneur de base de données.
2. Il ne conserve que les **7 sauvegardes les plus récentes** et supprime les autres.
3. Une sauvegarde interrompue (`CTRL+C`) ne doit **jamais** laisser de fichier `.dump` incomplet
   *(indice : `trap`, et écrire dans un fichier temporaire renommé à la fin)*.
4. `restore <fichier>` demande une **confirmation explicite** avant d'écraser la base, refuse un fichier
   inexistant, et propose de faire un `backup` juste avant.
5. Affichez la taille et la date de chaque sauvegarde existante quand `restore` est appelé sans argument.

## Étape 5 — Découpage et bibliothèque *(chapitre [06.6](../../06_shellscript/06_fonctions/fonctions.md))*

1. Une fonction par commande : `cmd_up`, `cmd_down`, `cmd_backup`… et un `case` central qui aiguille.
2. Toutes les fonctions transverses (`log`, `erreur`, `confirmer`, `require_cmd`, `run`) vivent dans
   `scripts/lib.sh`, sourcé par `tf`.
3. `run()` est la fonction clé : elle exécute une commande, l'affiche si `--verbose`, et **ne l'exécute pas**
   si `--dry-run`. Toutes les commandes externes passent par elle.
4. Toutes les variables internes sont `local`.
5. `tf --dry-run up`, `tf --dry-run backup` et `tf --dry-run clean` ne doivent **rien** modifier sur la machine.

## Étape 6 — Finitions

1. Les messages de succès vont sur la sortie standard, les erreurs sur la sortie d'erreur, avec des couleurs
   *(désactivées automatiquement si la sortie n'est pas un terminal — cherchez pourquoi et comment)*.
2. Chaque commande renvoie un **code de sortie** juste : `tf status && echo ok` doit se comporter correctement.
3. `clean` demande confirmation, et `tf --dry-run clean` liste précisément ce qui serait supprimé.
4. Écrivez un `scripts/README.md` : installation, les commandes, un exemple par commande.
5. *(Bonus)* Une commande `tf dev` qui ouvre la session tmux de travail *(exercice [6.5](06_tmux.md))*.
6. *(Bonus)* La complétion des commandes de `tf` par `TAB` dans votre shell.
7. *(Bonus)* Un `tf logs --errors` qui n'affiche que les lignes d'erreur, analysées avec `awk`
   *(chapitre [03](../../03_commandes_essentielles.md))*.

---

## ✅ Critères de réussite

Votre `tf` est terminé quand, sur une machine neuve, un nouveau membre de l'équipe peut :

```bash
git clone <votre-dépôt> && cd ticketflow
./scripts/tf doctor     # lui dit exactement ce qui manque, et comment l'installer
./scripts/tf up         # et l'API répond sur http://localhost:3000/health
```

Et que, pour vous :

- [ ] `shellcheck scripts/tf scripts/lib.sh` ne renvoie **rien** ;
- [ ] aucune commande n'écrit de mot de passe dans la ligne de commande ni dans l'historique ;
- [ ] `--dry-run` fonctionne sur **toutes** les commandes destructives ;
- [ ] `CTRL+C` pendant un `backup` ne laisse aucun fichier partiel ni dossier temporaire ;
- [ ] chaque commande a un code de sortie correct et un message d'erreur qui dit **quoi faire** ;
- [ ] le script fonctionne depuis n'importe quel dossier de la machine ;
- [ ] le tout tient dans deux fichiers lisibles, sans code dupliqué.

> [!TIP]
> C'est exactement le genre de script qu'on retrouve à la racine des vrais dépôts, sous le nom de `Makefile`,
> de `taskfile` ou de `bin/dev`. Vous venez d'écrire le vôtre — et vous savez maintenant le lire chez les autres.
