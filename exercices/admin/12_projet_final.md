# 🎓 A12 · Projet final — durcir et exploiter `srv-tickets`

*Tout le parcours : chapitres [01](../../01_base.md) à [06](../../06_shellscript/), [08](../../08_docker_administration.md),
[09](../../09_tmux.md), [10](../../10_shell_config.md) et [11](../../11_advanced_config.md)*

> [!NOTE]
> **Objectif** : reprendre une machine laissée à l'abandon et la rendre **tenable** — c'est-à-dire
> documentée, durcie, sauvegardée, supervisée et reproductible. Le livrable n'est pas une commande :
> c'est un serveur dont vous pouvez rendre compte.

> [!CAUTION]
> Repartez d'une **VM neuve** avec l'existant décrit dans le [README du parcours](README.md#-le-fil-rouge--srv-tickets) :
> tout le monde en root, SSH par mot de passe, pas de pare-feu, pas de sauvegarde. Snapshot à chaque étape.

---

## 🎯 Le cahier des charges

Vous avez une semaine (fictive) et un serveur en production que **vous n'avez pas le droit de couper**
plus de quelques secondes. À la fin, un auditeur passe : il doit pouvoir vérifier chaque point ci-dessous
en lisant votre documentation et en lançant vos commandes.

---

## Étape 0 — L'état des lieux *(chapitres [01](../../01_base.md) et [03](../../03_commandes_essentielles.md))*

Produisez `/root/audit-initial.md`, généré autant que possible par des commandes :

1. Système : distribution, noyau, *uptime*, ressources, partitions et taux de remplissage.
2. Comptes : humains, systèmes, ceux qui ont un shell, ceux qui sont dans `sudo`, ceux sans mot de passe.
3. Services actifs, services en échec, services **écoutant sur l'extérieur**.
4. Ports ouverts, vus depuis la machine **et** depuis l'extérieur.
5. Tâches planifiées existantes (crontabs de tous les utilisateurs, `/etc/cron.*`, *timers*).
6. Fichiers SUID, fichiers *world-writable*, fichiers appartenant à des UID inexistants.
7. Ce que Docker fait tourner, avec quels droits et quels ports.
8. Les cinq risques que vous jugez les plus urgents, classés, avec une phrase de justification chacun.

## Étape 1 — Les comptes *(chapitres [02](../../02_file_permissions.md) et [02.1](../../02.1_user_management.md))*

1. Créez un compte nominatif par personne, avec le bon groupe (`ops`, `dev`), la bonne politique
   d'expiration et le bon shell.
2. Créez les comptes techniques `deploy` et `backup`, sans shell de connexion.
3. Posez les droits et la propriété corrects sur `/srv/ticketflow`, `/var/log/ticketflow` et vos scripts —
   dossiers et fichiers ne doivent pas avoir les mêmes.
4. Mettez le SGID et le sticky bit là où ils s'imposent, et justifiez chaque pose dans le journal.
5. Retirez à `root` la possibilité de se connecter directement, une fois — et seulement une fois —
   qu'un compte nominatif fonctionne en `sudo`.

## Étape 2 — La délégation *(chapitre [05](../../05_securite.md), partie sudo)*

1. Un fragment `sudoers.d` par besoin, nommé et commenté : `ops`, `dev`, `deploy`, `backup`.
2. `dev` ne peut que redémarrer et consulter les services applicatifs. `deploy` ne peut lancer qu'un script,
   sans mot de passe, et ce script ne lui appartient pas.
3. Les ACL de `/srv/ticketflow` respectent le tableau de l'exercice [6.4](06_acl_et_sudo.md).
4. `sudo -l` exécuté avec chaque compte prouve que le cahier des charges est respecté — copiez les sorties
   dans le journal.
5. La procédure de secours « `sudoers` cassé » est écrite **avant** d'en avoir besoin.

## Étape 3 — L'accès *(chapitre [05](../../05_securite.md), parties SSH et pare-feu)*

1. Authentification par clé uniquement, `root` interdit, accès restreint aux groupes autorisés,
   sessions inactives coupées, journalisation verbeuse, bannière.
2. Pare-feu : tout fermé en entrée sauf ce qui est justifié, chaque règle **commentée**, PostgreSQL
   uniquement depuis le réseau interne, configuration persistante au redémarrage.
3. `fail2ban` actif sur SSH, avec votre réseau d'administration en liste blanche.
4. Un scan depuis l'extérieur, **avant / après**, dans le journal.
5. La preuve que vous ne vous êtes pas enfermé dehors : un redémarrage complet de la VM, suivi d'une
   connexion réussie.

## Étape 4 — L'exploitation *(chapitre [04](../../04_installation_et_services.md))*

1. L'application tourne sous un compte dédié, dans une unité systemd durcie, redémarrée automatiquement.
2. Les logs sont dans le journal, persistants, limités en taille, et `logrotate` gère les logs applicatifs.
3. Les mises à jour de sécurité sont appliquées, et vous avez une position écrite sur les mises à jour
   automatiques (pour ou contre, et pourquoi).
4. Tout ce qui est planifié est documenté : quoi, quand, pourquoi, où vont les sorties.

## Étape 5 — L'outillage *(chapitre [06](../../06_shellscript/))*

Trois scripts, appuyés sur `lib-admin.sh`, installés dans `/usr/local/bin`, avec `--help` et `--dry-run` :

| Script | Rôle |
|--------|------|
| `srv-audit` | rejoue l'audit de l'étape 0 et signale ce qui a changé depuis la dernière fois |
| `srv-backup` | sauvegarde fichiers + base + volumes Docker, avec rotation et somme de contrôle |
| `srv-check` | contrôle de santé : services, disque, charge, certificats, conteneurs ; code de sortie parlant |

1. Chacun passe ShellCheck sans avertissement.
2. Chacun échoue proprement, avec un code de sortie distinct par cause, et une trace dans le journal système.
3. `srv-backup` interrompu ne laisse aucune archive partielle.
4. `srv-check` est planifié toutes les 5 minutes et **vous alerte** sans que vous ayez à regarder.
5. Une **restauration réelle** a été effectuée depuis une sauvegarde produite par `srv-backup`.

## Étape 6 — Docker *(chapitre [08](../../08_docker_administration.md))*

1. Rotation des logs configurée globalement, aucun conteneur en root ni en `--privileged`.
2. Limites de mémoire, de CPU et de PID sur chaque service ; politique de redémarrage explicite.
3. La stack repart seule après un redémarrage de la machine (unité systemd).
4. Les volumes sont sauvegardés par `srv-backup`, et une restauration a été testée.
5. Un ménage hebdomadaire est planifié, et vous savez exactement ce qu'il supprime.

## Étape 7 — L'environnement et la reproductibilité *(chapitres [10](../../10_shell_config.md) et [11](../../11_advanced_config.md))*

1. `/etc/profile.d` porte le `PATH`, le `umask` et le prompt root distinctif ; `/etc/skel` est complété.
2. Vos dotfiles d'administrateur se déploient en une commande sur une machine neuve.
3. Vos fichiers de configuration modifiés (`/etc/ssh/sshd_config`, `sudoers.d`, unités, `daemon.json`,
   `logrotate.d`) sont **versionnés** quelque part, avec l'historique de vos modifications.
4. Un collègue peut reconstruire ce serveur à partir de votre documentation seule. Faites-le vérifier :
   donnez votre `journal.md` à quelqu'un d'autre et regardez-le essayer, sans l'aider.

---

## 📄 Le livrable

Un dossier `/root/dossier-serveur/` (versionné) contenant :

1. `audit-initial.md` — l'état à votre arrivée.
2. `journal.md` — ce que vous avez changé, quand, et **pourquoi**.
3. `exploitation.md` — les procédures : démarrer, arrêter, déployer, sauvegarder, **restaurer**,
   que faire si le disque est plein, que faire si l'application ne répond plus.
4. `acces.md` — qui a accès à quoi, avec quel droit, et comment on retire un accès quand quelqu'un part.
5. `scripts/` — vos scripts et leur `README.md`.
6. `audit-final.md` — le même audit qu'à l'étape 0, pour comparaison. C'est votre démonstration.

---

## ✅ Critères de réussite

- [ ] Aucune connexion possible en `root` ni par mot de passe ; chaque action est traçable à une personne.
- [ ] Un scan externe ne montre que les ports que vous pouvez justifier un par un.
- [ ] `systemctl --failed` est vide, et l'application repart seule après un redémarrage complet de la VM.
- [ ] Une sauvegarde a été **restaurée** pour de vrai, et la procédure est écrite.
- [ ] `srv-check` détecte une panne que vous provoquez (arrêtez un service, remplissez le disque) et
      vous alerte sans que vous ayez à regarder.
- [ ] `--dry-run` existe et fonctionne sur toutes vos commandes destructives.
- [ ] Aucun secret n'apparaît dans un fichier lisible par tous, ni dans un historique, ni dans une ligne
      de commande, ni dans un dépôt Git.
- [ ] Vous pouvez partir deux semaines en congé : quelqu'un d'autre tient le serveur avec votre dossier.

> [!TIP]
> Ce dernier point est le seul qui compte vraiment. Un serveur qu'un seul humain sait administrer n'est pas
> administré : il est otage.
