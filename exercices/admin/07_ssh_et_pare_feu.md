# 🛡️ A7 · SSH et pare-feu

*Chapitre [05 · Sécurité](../../05_securite.md) — parties **firewall**, **SSH** et **fail2ban***

> [!NOTE]
> **Objectifs** : ne plus jamais se connecter par mot de passe, durcir `sshd` sans se couper l'accès,
> savoir se rebondir et tunneler, fermer tout ce qui n'a pas à être ouvert, et faire taire les robots.

> [!CAUTION]
> **Le chapitre où l'on se verrouille dehors.** La procédure, à chaque modification :
> 1. snapshot de la VM ;
> 2. une session SSH **déjà ouverte** que vous ne fermez sous aucun prétexte ;
> 3. vérification de syntaxe (`sshd -t`, `nft -c -f`) ;
> 4. `reload` (pas `restart`) ;
> 5. test depuis une **troisième** connexion — et seulement ensuite, on referme la session de secours.

---

## Exercice 7.1 — L'état des lieux

1. Le serveur SSH tourne-t-il ? Sur quel port ? Quelle version ?
2. Quels ports sont en écoute sur la machine, et par quels processus ?
   Lesquels écoutent sur **toutes** les interfaces plutôt que sur la boucle locale ?
3. Affichez la configuration `sshd` **effective** telle que le démon la comprend — pas le fichier, la
   configuration résolue.
4. Un pare-feu est-il actif ? Lequel ? Quelles sont ses règles actuelles ?
5. Depuis votre poste, scannez les ports ouverts du serveur. Consignez le résultat : ce sera votre
   « avant / après ».

---

## Exercice 7.2 — Les clés

1. Générez sur votre poste une paire de clés `ed25519` avec un commentaire identifiant et une **passphrase**.
2. Pourquoi `ed25519` plutôt que `rsa` 2048 ? Dans quel cas garde-t-on du RSA ?
3. Déployez la clé publique sur le compte `alice` du serveur — d'abord avec l'outil dédié, puis
   **à la main** (pour comprendre ce qu'il fait).
4. Quels sont les droits **exacts** attendus sur `~/.ssh` et sur `~/.ssh/authorized_keys` ?
   Que se passe-t-il s'ils sont trop larges ? Testez.
5. Connectez-vous par clé, puis vérifiez dans les logs du serveur que l'authentification est bien passée
   par la clé.
6. Ajoutez votre clé à l'agent SSH pour ne plus saisir la passphrase à chaque connexion.
7. Affichez l'empreinte de votre clé publique. À quoi sert-elle dans un inventaire ?

---

## Exercice 7.3 — Durcir `sshd`

Un point à la fois, avec vérification de syntaxe et test entre chaque :

1. Interdire complètement la connexion de `root`.
2. Désactiver l'authentification par **mot de passe** (et l'authentification interactive au clavier).
3. Restreindre la connexion aux seuls membres du groupe `ops`, plus le compte `backup`.
4. Réduire la surface d'attaque : pas de transfert X11, pas d'`AllowAgentForwarding`, pas de
   `PermitEmptyPasswords`, `MaxAuthTries` bas.
5. Déconnecter les sessions inactives au bout de 10 minutes.
6. Passer la journalisation en `VERBOSE` — qu'est-ce que cela ajoute dans les logs, et pourquoi est-ce utile ?
7. Afficher une bannière légale avant la connexion.
8. Changer le port d'écoute pour 2222. Qu'est-ce que cela apporte réellement, et qu'est-ce que cela
   n'apporte pas ? Que faut-il penser à modifier **en même temps** (pare-feu, fail2ban, `~/.ssh/config`,
   SELinux le cas échéant) ?

### Exercice 7.4 — Les blocs `Match`

1. Le compte `backup` ne doit pouvoir lancer **que** `rsync`, sans shell interactif.
2. Les membres de `ops` connectés **depuis le réseau interne** ont droit aux tunnels ; les autres non.
3. Un compte `sftp-client` est confiné à son dossier par un `chroot`, sans accès shell.
4. Vérifiez chaque règle en vous connectant réellement avec le compte concerné.
5. Restreignez, **côté `authorized_keys`**, la clé de déploiement : une seule commande autorisée, depuis une
   IP donnée, sans tunnel ni allocation de terminal. Pourquoi cette restriction est-elle complémentaire de
   celle du `Match` ?

### Exercice 7.5 — Le client, les tunnels et les transferts

1. Écrivez un `~/.ssh/config` sur votre poste : un alias `srv-tickets` avec l'hôte, le port, l'utilisateur
   et la clé ; des valeurs communes à tous les hôtes ; la réutilisation de connexion.
2. Connectez-vous ensuite d'un simple `ssh srv-tickets`.
3. Atteignez une seconde machine **via** le serveur (rebond).
4. Ouvrez un tunnel **local** rendant la base PostgreSQL du serveur (qui n'écoute que sur `127.0.0.1`)
   joignable depuis votre poste sur le port 5433. Vérifiez avec un client.
5. Ouvrez un proxy SOCKS et faites passer un navigateur par le serveur.
6. Transférez un fichier avec `scp`, puis un dossier avec `rsync`. Pourquoi `rsync` dès que l'opération
   se répète ?
7. `known_hosts` : que se passe-t-il si l'empreinte du serveur change ? Comment réagit-on **correctement**
   (et pourquoi supprimer la ligne sans réfléchir est une mauvaise réponse) ?

---

## Exercice 7.6 — Le pare-feu

Choisissez `ufw` **ou** `nftables` et faites tout l'exercice avec le même outil.

1. Affichez les règles actuelles et la politique par défaut.
2. Politique par défaut : **tout refuser en entrée**, tout autoriser en sortie.
3. Autorisez SSH **avant toute chose**. Pourquoi cet ordre est-il non négociable ?
4. Autorisez HTTP et HTTPS depuis n'importe où.
5. Autorisez PostgreSQL **uniquement depuis le sous-réseau interne**.
6. Autorisez le port d'administration uniquement depuis votre IP, avec un **commentaire** sur la règle.
7. Activez le pare-feu, puis vérifiez depuis votre poste ce qui est joignable et ce qui ne l'est plus.
8. Limitez le débit des connexions SSH pour ralentir les robots.
9. Journalisez les paquets rejetés, avec une limite de débit. Où atterrissent ces lignes ?
10. Supprimez une règle devenue inutile, listez les règles **numérotées**, et rendez la configuration
    persistante au redémarrage. Vérifiez-le en redémarrant réellement la VM.
11. Le service tourne mais n'est pas joignable de l'extérieur. Donnez les **quatre** hypothèses à tester,
    dans l'ordre, et la commande pour chacune.

---

## Exercice 7.7 — `fail2ban`

1. Installez et démarrez `fail2ban`, puis affichez la liste des prisons actives.
2. Pourquoi configure-t-on `jail.local` et non `jail.conf` ?
3. Configurez la prison SSH : 5 tentatives, fenêtre de 10 minutes, bannissement d'1 heure,
   en tenant compte de **votre port** SSH.
4. Ajoutez votre réseau d'administration en liste blanche — l'oubli classique.
5. Provoquez volontairement un bannissement depuis une autre machine, constatez-le, puis débannissez l'IP.
6. Affichez les statistiques de la prison : combien de tentatives, combien de bannissements ?
7. Vérifiez comment `fail2ban` s'articule avec votre pare-feu : où sont réellement écrites les règles
   de bannissement ?

---

## ✅ Vérification

- Un `ssh root@srv-tickets` échoue ; un `ssh -o PreferredAuthentications=password alice@…` échoue aussi.
- Vous vous connectez par clé, sur le nouveau port, en tapant `ssh srv-tickets`.
- Un scan de ports depuis l'extérieur ne montre plus que ce que vous avez explicitement ouvert —
  comparez avec le relevé de l'exercice 7.1.
- Le pare-feu survit à un redémarrage complet de la VM.
- Cinq échecs de connexion depuis une IP de test la font bannir, et votre réseau d'admin ne peut pas
  être banni.
- `journal.md` documente : port SSH, comptes autorisés, ports ouverts et pour qui, procédure de secours.
