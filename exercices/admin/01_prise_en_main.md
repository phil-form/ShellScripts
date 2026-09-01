# 🖥️ A1 · Prise en main du serveur

*Chapitres [01 · Les bases du terminal](../../01_base.md) et [09 · tmux](../../09_tmux.md)*

> [!NOTE]
> **Objectifs** : savoir où on a atterri. Reconnaître l'arborescence d'un système Linux, retrouver les
> fichiers de configuration et les logs, lire ce qui tourne, rediriger et archiver ses constats — et
> travailler dans une session qui survit à une coupure SSH.

---

## Exercice 1.1 — L'état des lieux

Connectez-vous à `srv-tickets` et répondez, **commande à l'appui**, aux questions qu'on vous posera
en réunion :

1. Quelle distribution et quelle version exactement ?
2. Quelle version du noyau ? Quelle architecture ?
3. Quel est le nom de la machine ? Depuis combien de temps tourne-t-elle ?
4. Combien de processeurs, combien de mémoire vive, combien reste-t-il de libre ?
5. Quelles partitions sont montées, et laquelle est la plus remplie ?
6. Quelle est l'adresse IP du serveur, et sur quelle interface ?
7. Qui est connecté sur la machine en ce moment ? Qui s'y est connecté récemment ?
8. Consignez toutes ces réponses dans `/root/journal.md` — c'est le début de votre documentation.

---

## Exercice 1.2 — L'arborescence d'un système

Sans rien modifier, répondez en une phrase pour chacun :

1. Que trouve-t-on dans `/etc`, `/var`, `/opt`, `/srv`, `/usr/local/bin` et `/tmp` ?
2. Quelle différence entre `/bin` et `/usr/local/bin` ? Où mettez-vous **vos** scripts ?
3. Où sont les logs du système ? Quel est le plus gros fichier de `/var/log` ?
4. Où sont stockées les unités systemd fournies par les paquets ? Et **les vôtres** ?
5. `/proc` et `/sys` occupent-ils de la place sur le disque ? Pourquoi ?
6. Listez le contenu de `/etc` en format détaillé, trié par **date de modification** — qu'est-ce qui a été
   touché en dernier sur ce serveur ?

---

## Exercice 1.3 — Lire les logs

1. Affichez les 50 dernières lignes de `/var/log/syslog`.
2. Suivez `/var/log/auth.log` **en direct** et, depuis un autre terminal, ouvrez une session : que voyez-vous ?
3. Affichez `/var/log/auth.log` page par page, en pouvant remonter.
4. Combien de lignes contient `/var/log/auth.log` ? Quelle est sa taille sur le disque ?
5. Affichez les 100 premières lignes du fichier, puis les lignes 200 à 220.
   *(Deux commandes du chapitre 01 combinées par un pipe suffisent.)*

---

## Exercice 1.4 — Créer et remplir des fichiers de configuration

1. Créez l'arborescence de travail de l'administrateur :
```text
   /srv/ticketflow/
   ├── backups/
   ├── scripts/
   └── conf/
   /var/log/ticketflow/
```
   en **une seule commande** pour la première.
2. Avec un **heredoc**, écrivez `/srv/ticketflow/conf/serveur.conf` :
```ini
   [serveur]
   nom  = srv-tickets
   role = production
   admin = alice
```
3. Ajoutez la ligne `derniere_revue = <la date du jour>` à la fin du fichier, **sans l'écraser**, en insérant
   la date produite par une commande.
4. Copiez ce fichier en `.bak` — prenez l'habitude, elle vous servira à tous les chapitres suivants.
5. Créez un lien symbolique `/root/conf` vers `/srv/ticketflow/conf`, et vérifiez-le.

---

## Exercice 1.5 — Redirections : garder une trace

1. Lancez un inventaire des paquets installés et écrivez-le dans `/root/inventaire-paquets.txt`.
2. Lancez une commande qui échoue (par exemple sur un dossier inexistant) et envoyez **uniquement l'erreur**
   dans `/root/erreurs.log`.
3. Relancez-la en envoyant les **deux flux** dans le même fichier, **sans écraser** son contenu.
4. Lancez une commande longue en jetant complètement sa sortie.
5. Écrivez la sortie de `df -h` à l'écran **et** dans un fichier, en une seule commande.
6. Expliquez, en une phrase, pourquoi `commande > fichier 2>&1` et `commande 2>&1 > fichier` ne font pas
   la même chose.

---

## Exercice 1.6 — Les processus

1. Affichez tous les processus de la machine, puis uniquement ceux de l'utilisateur `root`.
2. Affichez les 5 processus qui consomment le plus de **mémoire**, puis le plus de **CPU**.
3. Retrouvez le PID du serveur SSH, puis affichez l'arborescence des processus.
4. Lancez un processus en arrière-plan, retrouvez-le, arrêtez-le proprement.
5. Un processus ne répond plus : quelle est la différence entre le signal par défaut et `kill -9` ?
   Dans quel ordre les essaie-t-on, et pourquoi ?
6. Quel processus écoute sur le port 22 ? Et sur le port 5432 ? *(Indice : `ss -tulpn`.)*
7. Un utilisateur se plaint que « le serveur rame ». Donnez les **quatre** commandes que vous lancez dans
   la minute, et ce que vous regardez dans chacune.

---

## Exercice 1.7 — Travailler dans une session qui survit *(chapitre [09](../../09_tmux.md))*

1. Installez tmux et ouvrez une session nommée `admin`.
2. Détachez-vous, vérifiez qu'elle tourne toujours, rejoignez-la.
3. Découpez l'écran en trois panneaux : un shell, un `journalctl -f`, un `htop`.
4. Passez le panneau de logs en plein écran, puis revenez à la disposition normale.
5. Créez une seconde fenêtre nommée `backup`, basculez entre les deux, renommez la première `travail`.
6. Lancez une mise à jour longue dans un panneau, **coupez brutalement votre connexion SSH**, reconnectez-vous
   et retrouvez la mise à jour. Que se serait-il passé sans tmux ?
7. Remontez dans l'historique d'un panneau et recherchez-y un mot. Comment sort-on du mode copie ?
8. Écrivez dans votre `journal.md` la liste des raccourcis que vous utiliserez tous les jours.

> [!TIP]
> Sur un serveur distant, `tmux` (ou `screen`) n'est pas un confort : c'est ce qui empêche une coupure réseau
> d'interrompre un `apt upgrade` ou une migration de base au milieu.

---

## ✅ Vérification

- `/root/journal.md` contient l'état des lieux complet de l'exercice 1.1.
- `/srv/ticketflow/` et `/var/log/ticketflow/` existent, avec `serveur.conf` et sa sauvegarde.
- Vous savez retrouver, sans hésiter : la configuration d'un service, ses logs, son unité systemd, son PID
  et le port qu'il écoute.
- Vous pouvez perdre votre connexion SSH sans perdre votre travail en cours.
