# 👥 A3 · Utilisateurs, groupes et comptes

*Chapitre [02.1 · Gestion des utilisateurs et des groupes](../../02.1_user_management.md)*

> [!NOTE]
> **Objectifs** : créer et retirer des comptes proprement, comprendre les fichiers qui les décrivent, séparer
> comptes humains et comptes de service, gérer mots de passe et expirations, et cesser de travailler en `root`.

> [!CAUTION]
> Snapshot de la VM **avant** de commencer. On verrouille des comptes et on touche à `sudo` :
> gardez en permanence une session privilégiée ouverte que vous ne fermez pas.

---

## Exercice 3.1 — L'existant

1. Listez tous les comptes de la machine. Combien y en a-t-il ?
2. Distinguez les comptes **humains** des comptes **système** : quel critère utilisez-vous ?
   Produisez la liste des seuls comptes humains *(chapitre [03](../../03_commandes_essentielles.md) :
   `awk` sur `/etc/passwd`)*.
3. Que contient chacun des sept champs d'une ligne de `/etc/passwd` ?
4. Pourquoi le mot de passe n'y est-il plus, et où est-il ? Qui peut lire ce fichier, et avec quels droits ?
5. Listez tous les groupes, puis ceux auxquels appartient votre utilisateur.
6. Quels comptes ont un shell de connexion valide ? Lesquels ont `/usr/sbin/nologin`, et pourquoi ?

---

## Exercice 3.2 — Créer les comptes de l'équipe

L'équipe : `alice` (administratrice), `bob` et `carine` (développeurs), plus deux comptes techniques.

1. Créez le groupe `ops` et le groupe `dev`.
2. Créez `alice`, `bob` et `carine` **avec** leur *home*, le shell `/bin/bash` et un commentaire
   (nom complet) renseigné.
3. Mettez `alice` dans `ops`, `bob` et `carine` dans `dev` — **sans** les retirer de leur groupe principal.
4. Ajoutez `alice` au groupe qui donne le droit à `sudo` sur Debian. Vérifiez avec elle.
5. Créez le compte technique `deploy` : **pas de *home* interactif nécessaire**, shell `/usr/sbin/nologin`,
   groupe `ops`. Pourquoi un compte de service ne doit-il pas avoir de shell de connexion ?
6. Créez le compte `backup`, sans mot de passe utilisable, destiné à être utilisé **uniquement** par clé SSH.
7. Affichez, pour chaque compte créé, son UID, son GID et ses groupes secondaires.

---

## Exercice 3.3 — Mots de passe et expiration

1. Définissez un mot de passe pour `bob`.
2. Forcez `bob` à changer son mot de passe **à sa prochaine connexion**.
3. Affichez la politique d'expiration du compte de `bob` (dernière modification, expiration, avertissement).
4. Imposez : mot de passe valable 90 jours, avertissement 7 jours avant, minimum 1 jour entre deux changements.
5. Fixez une **date d'expiration du compte** de `carine` au dernier jour du mois prochain
   (une stagiaire, on n'oubliera pas de fermer le compte).
6. **Verrouillez** le compte de `bob`, essayez de vous y connecter, puis déverrouillez-le.
   Quelle est la différence entre verrouiller le mot de passe et désactiver le shell ?
7. Où se règle la politique de mots de passe **par défaut** pour les nouveaux comptes ?

---

## Exercice 3.4 — Modifier et supprimer

1. Renommez `carine` en `carine.dupont`, en renommant aussi son *home*.
2. Changez le shell par défaut de `bob` pour `/bin/sh`, puis remettez `/bin/bash`.
3. Déplacez le *home* de `bob` vers `/srv/home/bob` en conservant ses fichiers.
4. Retirez `bob` du groupe `dev` sans toucher à ses autres groupes.
5. Supprimez le compte `carine.dupont` **avec** son *home* et sa file de courrier.
6. Après la suppression, des fichiers lui appartenant subsistent ailleurs sur le disque.
   Comment les retrouver *(chapitre [03](../../03_commandes_essentielles.md))* ? Que se passe-t-il si vous
   créez un nouveau compte qui récupère le même UID ?

---

## Exercice 3.5 — Le squelette des nouveaux comptes

1. Que contient `/etc/skel` sur votre machine ?
2. Ajoutez-y un fichier `README-serveur.txt` rappelant les règles internes, et un `.bashrc` complété d'un
   alias maison.
3. Créez un nouveau compte de test et vérifiez qu'il hérite bien de ces fichiers.
4. Les comptes **déjà existants** en héritent-ils ? Comment leur appliquer la modification ?
   *(Voir le chapitre [10](../../10_shell_config.md) et l'exercice [A11](11_environnement_utilisateurs.md).)*
5. Où se configure le *home* par défaut, le shell par défaut et la plage d'UID des nouveaux comptes ?

---

## Exercice 3.6 — Changer d'identité proprement

1. Exécutez **une seule** commande en tant que root, sans ouvrir de session root.
2. Ouvrez une session root complète, avec un environnement propre. Quelle différence avec `su root` sans tiret ?
3. Ouvrez une session en tant que `deploy` alors qu'il n'a pas de shell de connexion.
   *(Indice : une option de `su` permet de forcer le shell.)* Dans quel cas d'exploitation en a-t-on besoin ?
4. Vérifiez « qui vous êtes vraiment » dans une session `sudo -i` : `whoami`, `logname`, `id`.
   Laquelle de ces commandes trace l'utilisateur d'origine ?
5. Retrouvez dans `/var/log/auth.log` toutes les élévations de privilèges de la journée
   *(chapitre [03](../../03_commandes_essentielles.md))*.
6. Pourquoi laisse-t-on `root` sans mot de passe utilisable sur un serveur bien tenu, et par quoi le
   remplace-t-on ? *(La suite est en [A6](06_acl_et_sudo.md).)*

---

## ✅ Vérification

- `alice`, `bob`, `deploy` et `backup` existent avec le bon shell, les bons groupes et la bonne politique
  d'expiration.
- Aucun compte de service n'a de shell de connexion.
- Vous savez produire, en une ligne, la liste des comptes humains de la machine.
- Vous savez répondre à « qui a fait ça, et quand ? » en lisant `/var/log/auth.log`.
- Votre `journal.md` documente chaque compte créé : à qui il appartient, pourquoi il existe,
  et quand il devra être fermé.
