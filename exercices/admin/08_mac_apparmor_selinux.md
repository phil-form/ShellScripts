# 🧱 A8 · AppArmor / SELinux

*Chapitre [05 · Sécurité](../../05_securite.md) — partie **AppArmor / SELinux***

> [!NOTE]
> **Objectifs** : comprendre ce qu'ajoute un contrôle d'accès obligatoire (MAC) par-dessus les droits POSIX,
> savoir dans quel mode tourne la machine, lire un refus dans les logs, ajuster un profil ou un contexte —
> et surtout **ne pas désactiver la protection à la première difficulté**.

> [!IMPORTANT]
> Debian / Ubuntu utilisent **AppArmor**, RHEL / Fedora / Rocky utilisent **SELinux**. Faites la partie qui
> correspond à votre VM, puis **lisez** l'autre : vous tomberez sur les deux dans votre carrière.

---

## Exercice 8.1 — Le principe

1. En une phrase chacun : qu'est-ce que le **DAC** (les droits POSIX du chapitre 02) et qu'est-ce que le **MAC** ?
2. Un processus tourne en `root`. Le DAC lui permet de tout lire. Que peut encore l'en empêcher ?
3. Donnez un exemple concret de compromission qu'un MAC bloque et qu'un `chmod` correct n'aurait pas bloquée.
4. Sur votre machine : AppArmor est-il présent ? actif ? Et SELinux ? Quelles commandes vous le disent ?

---

## Partie AppArmor *(Debian, Ubuntu, SUSE)*

### Exercice 8.2 — État et modes

1. Affichez l'état d'AppArmor : combien de profils chargés, combien en `enforce`, combien en `complain` ?
2. Quelle est la différence entre `enforce`, `complain` et `disabled` ? Dans quel ordre les utilise-t-on
   quand on construit un profil ?
3. Listez les profils chargés et repérez celui de votre serveur web ou de votre client de base de données.
4. Passez un profil existant en `complain`, vérifiez le changement, puis remettez-le en `enforce`.

### Exercice 8.3 — Lire un refus

1. Provoquez un refus : faites lire à un programme confiné un fichier auquel son profil ne lui donne pas accès
   (par exemple, faites servir par nginx un dossier hors de son profil).
2. Retrouvez le refus dans les logs. Quel mot-clé cherchez-vous ?
   *(Chapitre [03](../../03_commandes_essentielles.md) pour le filtrage.)*
3. Décodez la ligne : quel programme, quelle opération, quel chemin, quel profil ?
4. Un utilisateur vous dit « ça marche en root mais pas depuis le service » alors que les droits POSIX sont
   corrects. Quelle est votre première hypothèse, et comment la vérifiez-vous en trente secondes ?

### Exercice 8.4 — Écrire et ajuster un profil

1. Écrivez `/usr/local/bin/backup.sh`, un script qui lit `/srv/ticketflow` et écrit dans
   `/srv/ticketflow/backups`.
2. Créez un profil pour ce script : lecture seule sur les sources, écriture sur la destination,
   exécution des binaires dont il a besoin, et **rien d'autre**.
3. Chargez-le en mode `complain`, exercez le script sur **tous** ses cas d'usage (y compris les cas d'erreur),
   puis récoltez ce qui a manqué.
4. Passez en `enforce` et vérifiez que le script fonctionne toujours.
5. Vérifiez qu'il **ne peut pas** lire `/etc/shadow` ni écrire ailleurs que dans son dossier de destination.
6. Modifiez le profil d'un paquet (nginx, par exemple) pour autoriser un docroot personnalisé —
   **sans** éditer le fichier fourni par le paquet. Où écrit-on cette surcharge ?
7. Vérifiez la syntaxe d'un profil sans le charger, puis rechargez-le, puis rechargez l'ensemble.

---

## Partie SELinux *(RHEL, Fedora, Rocky)*

### Exercice 8.5 — État et modes

1. Affichez le mode courant et le mode configuré au démarrage. Où se règle ce dernier ?
2. Passez temporairement en `permissive`, vérifiez, revenez en `enforcing`.
   Pourquoi ne fait-on **jamais** un `SELINUX=disabled` définitif pour « régler » un problème ?
3. Quelle est la différence entre `permissive` et `disabled` du point de vue du diagnostic ?

### Exercice 8.6 — Contextes

1. Affichez le contexte de sécurité de `/var/www/html`, d'un processus `httpd` et de votre propre shell.
2. Que signifient les quatre champs d'un contexte ?
3. Déplacez un fichier depuis votre *home* vers `/var/www/html` avec `mv`, puis avec `cp`.
   Comparez les contextes obtenus et expliquez le piège classique.
4. Réparez le contexte du fichier déplacé — d'abord ponctuellement, puis **durablement** en déclarant
   la règle pour le chemin et en la réappliquant.
5. Faites servir à votre serveur web un docroot dans `/srv/web` : quel type faut-il déclarer, et comment ?

### Exercice 8.7 — Booléens, ports et diagnostic

1. Listez les booléens actifs concernant votre serveur web. Que fait `httpd_can_network_connect` ?
2. Activez-en un de façon **permanente**, et expliquez ce que change l'option de persistance.
3. Faites écouter `sshd` sur le port 2222 : quel type de port faut-il déclarer, et avec quelle commande ?
   *(Le lien avec l'exercice [7.3](07_ssh_et_pare_feu.md) est direct.)*
4. Provoquez un refus, retrouvez-le dans les logs d'audit, et faites-vous expliquer la cause.
5. Générez le module de politique qui autoriserait ce refus — **et lisez-le avant de l'installer**.
   Pourquoi ne l'installe-t-on jamais sans le lire ?

---

## Exercice 8.8 — La méthode de diagnostic

Un service refuse d'accéder à un fichier. Écrivez, dans `journal.md`, votre **arbre de décision** en
partant de la question « est-ce un problème de droits ? » :

1. Que vérifiez-vous en premier (DAC : propriétaire, droits, ACL, chemin traversable) ?
2. Comment savez-vous, en une commande, si le MAC est en cause ?
3. Comment le confirmez-vous **sans** désactiver la protection ?
4. Comment le corrigez-vous proprement — et pourquoi la correction « je mets tout en 777 » ou
   « je désactive SELinux » est-elle un aveu d'échec ?
5. Qu'écrivez-vous dans le journal une fois le problème résolu ?

---

## ✅ Vérification

- Vous savez dire, sur n'importe quelle machine, si un MAC tourne et dans quel mode.
- Votre script de sauvegarde tourne sous un profil / un contexte restreint, **et** vous avez prouvé qu'il ne
  peut pas lire `/etc/shadow`.
- Vous avez lu et décodé au moins un refus dans les logs, et corrigé la cause plutôt que désactivé la protection.
- Votre arbre de décision de l'exercice 8.8 tient sur une page et se lit par quelqu'un d'autre.
