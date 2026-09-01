# 🎛️ A6 · ACL et délégation `sudo`

*Chapitre [05 · Sécurité](../../05_securite.md) — parties **ACL** et **sudo / sudoers***

> [!NOTE]
> **Objectifs** : dépasser les limites des droits POSIX avec les ACL (masque, héritage, sauvegarde), et
> déléguer des droits d'administration précis sans distribuer `ALL=(ALL) ALL` à toute l'équipe.

> [!CAUTION]
> `sudoers` est le fichier qui peut vous enfermer dehors le plus vite. **Snapshot avant**, une session root
> ouverte en permanence dans un second terminal, et jamais d'édition sans `visudo`.

---

## Partie 1 — ACL

### Exercice 6.1 — Prérequis

1. Vérifiez que le paquet `acl` est installé.
2. Vérifiez que le système de fichiers qui porte `/srv` est monté avec le support des ACL.
   Comment le rendre permanent si ce n'est pas le cas ?
3. Créez `/srv/projet` et repérez, dans un `ls -l`, le signe qui indique qu'un fichier porte des ACL.

### Exercice 6.2 — Lire et poser

1. Affichez l'ACL complète de `/srv/projet`. Que signifie chaque ligne quand aucune ACL étendue n'est posée ?
2. Donnez à `bob` le droit de **lire et écrire** dans `/srv/projet`, sans le mettre dans le groupe propriétaire.
3. Donnez au groupe `dev` un droit de **lecture seule** sur ce même dossier.
4. Relisez l'ACL : que vaut le `mask` ? Que se passe-t-il si vous le passez à `r--` ?
5. Retirez l'entrée de `bob`, puis supprimez **toutes** les ACL étendues du dossier.

### Exercice 6.3 — Héritage

1. Posez une ACL **par défaut** sur `/srv/projet` : tout nouveau fichier doit être lisible et modifiable
   par le groupe `dev`.
2. Créez un fichier avec le compte `alice` et un autre avec `bob` : vérifiez que les deux portent bien
   l'ACL héritée.
3. Ajoutez le **SGID** sur le dossier pour que le groupe propriétaire soit conservé, et expliquez la
   différence entre ce que fait le SGID et ce que fait l'ACL par défaut.
4. Un fichier **copié** dans le dossier hérite-t-il de l'ACL ? Et un fichier **déplacé** ?
   Testez les deux cas et expliquez.

### Exercice 6.4 — Le cas pratique complet

Cahier des charges pour `/srv/projet` :

| Qui | Droit attendu |
|-----|---------------|
| `alice` (ops) | tout, y compris administrer le dossier |
| groupe `dev` | lecture / écriture sur les fichiers, création de fichiers |
| `deploy` | lecture seule |
| tous les autres | rien, pas même lister |

1. Écrivez la suite de commandes qui met cela en place, ACL d'accès **et** ACL par défaut.
2. Vérifiez chaque ligne du tableau en vous connectant avec les comptes concernés.
3. **Sauvegardez** les ACL du dossier dans un fichier, supprimez-les toutes, puis **restaurez-les**
   depuis la sauvegarde.
4. Copiez l'arborescence vers `/srv/projet-copie` **en conservant les ACL** : quelle option de `cp` (ou
   quelle autre commande) faut-il ?
5. Pourquoi les ACL doivent-elles apparaître dans votre procédure de sauvegarde ? Que se passe-t-il si vous
   restaurez un `tar` fait sans l'option adéquate ?

---

## Partie 2 — `sudo`

### Exercice 6.5 — L'état des lieux

1. Affichez ce que **vous** avez le droit de faire avec `sudo`.
2. Qui est membre du groupe `sudo` sur cette machine ?
3. Où sont définies les règles ? Quel est l'ordre de lecture, et pourquoi la ligne d'inclusion des fragments
   doit-elle être **en dernier** ?
4. Produisez la liste de **toutes** les règles effectives, tous fichiers confondus, puis celle des règles
   `NOPASSWD` — ce sont vos points d'audit prioritaires.

### Exercice 6.6 — Éditer sans se verrouiller

1. Pourquoi n'édite-t-on jamais `/etc/sudoers` avec `nano` directement ?
2. Créez le fragment `/etc/sudoers.d/ops` **avec l'outil dédié**, et posez-lui les droits corrects
   (quels sont-ils, et que se passe-t-il s'ils sont trop larges ?).
3. Vérifiez la syntaxe de l'ensemble de la configuration **sans** l'appliquer.
4. Introduisez volontairement une faute de syntaxe dans un fragment, constatez ce que dit la vérification,
   et corrigez-la.

### Exercice 6.7 — Déléguer précisément

Écrivez les règles correspondant à chacun de ces besoins, chacune dans son propre fragment nommé :

1. Le groupe `ops` peut tout faire, avec mot de passe.
2. Le groupe `dev` peut **uniquement** redémarrer et consulter l'état de `nginx` et `ticketflow-api`,
   et lire leurs logs — rien d'autre.
3. Le compte `deploy` peut lancer **un seul** script de déploiement, **sans mot de passe** (il est appelé
   par la CI, sans terminal).
4. Le compte `backup` peut lancer `rsync` et `tar` en lecture, sans mot de passe.
5. `bob` peut éditer les fichiers de configuration de son application — **avec `sudoedit`**, pas avec un
   éditeur lancé en root. Expliquez la différence de risque.
6. Définissez un alias de commandes `SERVICES` et un alias d'utilisateurs `ADMINS`, et réécrivez deux des
   règles ci-dessus en les utilisant.
7. Réglez les `Defaults` : cache d'authentification de 5 minutes, journalisation des commandes,
   message d'avertissement personnalisé au premier `sudo`.

### Exercice 6.8 — Les pièges

Pour chacun de ces exemples, expliquez **pourquoi la règle est dangereuse** et proposez une version correcte :

1. `bob ALL=(ALL) NOPASSWD: /usr/bin/vim`
2. `%dev ALL=(ALL) NOPASSWD: /bin/chmod`
3. `deploy ALL=(ALL) NOPASSWD: /usr/local/bin/deploy.sh` — le script étant modifiable par `deploy`.
4. `carine ALL=(ALL) NOPASSWD: /usr/bin/find`
5. `%dev ALL=(ALL) ALL` « en attendant, on affinera plus tard ».

### Exercice 6.9 — Audit et journalisation

1. Retrouvez dans les logs toutes les commandes lancées avec `sudo` aujourd'hui, et par qui
   *(chapitre [03](../../03_commandes_essentielles.md))*.
2. Retrouvez les **tentatives refusées** (utilisateur pas dans `sudoers`, ou commande non autorisée).
3. Activez la journalisation des entrées / sorties d'une session `sudo` pour un compte sensible,
   et relisez une session enregistrée.
4. Écrivez la procédure de secours : **vous venez de casser `sudoers` et vous n'avez plus de session root
   ouverte**. Listez, dans l'ordre, ce que vous essayez.

---

## ✅ Vérification

- `getfacl /srv/projet` reflète exactement le tableau de l'exercice 6.4, et un nouveau fichier créé par
  n'importe quel membre de `dev` hérite des bons droits.
- `visudo -c` est propre, et chaque droit délégué vit dans son propre fragment de `/etc/sudoers.d/`.
- `sudo -l` exécuté avec `bob`, `deploy` et `backup` montre **strictement** ce que le cahier des charges prévoit.
- Aucune règle `NOPASSWD` ne porte sur un éditeur, un interpréteur ou un script modifiable par son appelant.
- Votre procédure de secours est écrite dans `journal.md` **avant** d'en avoir besoin.
