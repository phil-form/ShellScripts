# 📦 A5 · Paquets, services et tâches planifiées

*Chapitre [04 · Installation de paquets, services et tâches planifiées](../../04_installation_et_services.md)*

> [!NOTE]
> **Objectifs** : maîtriser le cycle de vie des paquets, piloter et diagnostiquer les services, écrire une
> unité systemd propre pour l'application maison, exploiter `journalctl`, et planifier ce qui doit l'être —
> avec `cron` comme avec les *timers* systemd.

> [!IMPORTANT]
> Une **vraie VM** est indispensable : un conteneur ne fait pas tourner `systemd`.

---

## Exercice 5.1 — Paquets

1. Mettez à jour l'index des paquets, puis affichez la liste des paquets **pouvant** être mis à jour,
   sans rien installer.
2. Appliquez les mises à jour de sécurité. Quelle différence entre `upgrade`, `full-upgrade` et
   `dist-upgrade` ?
3. Installez `nginx`, `postgresql-client`, `ufw`, `fail2ban` et `acl` en une commande.
4. Recherchez le paquet qui fournit la commande `ss`, puis affichez ses informations détaillées.
5. Listez les fichiers installés par le paquet `nginx`. À quel paquet appartient `/usr/bin/systemctl` ?
6. Supprimez `nginx` en gardant sa configuration, puis supprimez-le **avec** sa configuration.
   Quelle est la différence, et laquelle utilise-t-on quand on veut repartir de zéro ?
7. Faites le ménage des dépendances devenues inutiles et du cache de téléchargement.
8. Un paquet a été installé manuellement : comment retrouver la liste des paquets **installés
   explicitement** par un humain, par opposition aux dépendances ?
9. Empêchez la mise à jour automatique d'un paquet précis *(indice : `apt-mark hold`)*. Dans quel cas
   fait-on ça, et quel est le risque ?

---

## Exercice 5.2 — Piloter les services

1. Listez tous les services **actifs**, puis tous ceux qui sont **en échec**.
2. Affichez l'état de `ssh` : tourne-t-il ? est-il activé au démarrage ? depuis quand ? quel est son PID ?
3. Arrêtez, démarrez, redémarrez `nginx`. Rechargez sa configuration **sans** couper les connexions en cours.
4. Quelle différence exacte entre `restart` et `reload` ? Et entre `enable` et `start` ?
5. Activez `nginx` au démarrage **et** lancez-le en une seule commande.
6. Masquez un service pour empêcher toute activation, même par dépendance. Puis démasquez-le.
   Dans quel cas utilise-t-on `mask` plutôt que `disable` ?
7. Affichez la liste des dépendances de `nginx.service`, puis ce qui dépend de lui.
8. Combien de temps a pris le dernier démarrage de la machine, et quels services sont les plus lents ?
   *(Indice : `systemd-analyze`.)*

---

## Exercice 5.3 — Une unité pour l'application maison

L'API `ticketflow` doit tourner en permanence, sous un compte dédié, et redémarrer si elle plante.

```bash
sudo tee /usr/local/bin/ticketflow-api >/dev/null <<'EOF'
#!/bin/bash
echo "démarrage de l'API ticketflow (pid $$)"
trap 'echo "arrêt demandé"; exit 0' TERM INT
while true; do
  echo "$(date '+%F %T') api ok"
  sleep 15
done
EOF
```

1. Posez sur ce script le propriétaire et les droits corrects pour un exécutable système.
2. Écrivez `/etc/systemd/system/ticketflow-api.service` avec :
   - une description claire ;
   - un démarrage **après le réseau** et après `postgresql.service` ;
   - `Type=simple`, exécution sous l'utilisateur `deploy` et le groupe `ops` ;
   - un redémarrage automatique en cas d'échec, avec un délai de 5 secondes ;
   - le dossier de travail `/srv/ticketflow` ;
   - une variable d'environnement `NODE_ENV=production` ;
   - une installation dans `multi-user.target`.
3. Rechargez la configuration de systemd, activez le service au boot **et** démarrez-le en une commande.
4. Vérifiez son état et lisez ses logs.
5. Tuez brutalement le processus : systemd le relance-t-il ? Au bout de combien de temps ?
6. Ajoutez trois directives de durcissement (`NoNewPrivileges`, `PrivateTmp`, `ProtectSystem`) et vérifiez
   que le service redémarre toujours. Que fait chacune ?
7. Faites lire la configuration depuis un fichier d'environnement `/etc/default/ticketflow`
   plutôt qu'en dur dans l'unité.
8. Comment surcharger une directive d'une unité **fournie par un paquet** sans modifier son fichier
   d'origine (qui serait écrasé à la prochaine mise à jour) ? *(Indice : `systemctl edit`.)*

---

## Exercice 5.4 — `journalctl`

1. Les logs du service `ticketflow-api`, puis ses 50 dernières lignes, puis en suivi temps réel.
2. Les logs depuis « il y a 15 minutes », puis ceux d'aujourd'hui, puis ceux du **démarrage précédent**.
3. Les seuls messages de niveau `error` et au-delà, pour tout le système.
4. Les logs du noyau uniquement.
5. Les logs d'un utilisateur précis, puis d'un PID précis.
6. Quelle place occupe le journal sur le disque ? Limitez-le à 500 Mo de façon **permanente**.
7. Le journal est-il persistant après un redémarrage sur cette machine ? Comment le rendre persistant ?
8. Purgez les entrées de plus de 30 jours.
9. Exportez les logs du service du jour dans un fichier, pour les joindre à un rapport d'incident.

---

## Exercice 5.5 — `cron`

1. Affichez votre crontab, puis celle de l'utilisateur `deploy`.
2. Écrivez, dans la crontab de `root`, une tâche qui lance `/usr/local/bin/backup.sh`
   **tous les jours à 2 h 30**, en redirigeant sortie standard **et** erreurs vers un fichier de log.
3. Une tâche qui, **toutes les 10 minutes**, écrit l'espace disque restant dans un fichier.
4. Une tâche qui, **du lundi au vendredi, toutes les heures de 8 h à 18 h**, lance un contrôle de santé.
5. Une tâche qui, **le premier de chaque mois**, archive les logs du mois écoulé.
6. Une tâche qui s'exécute **à chaque redémarrage** de la machine.
7. Écrivez la même sauvegarde quotidienne sous forme de fragment `/etc/cron.d/ticketflow-backup` —
   quelle colonne supplémentaire ce format demande-t-il ?
8. À quoi servent `/etc/cron.daily` et compagnie ? Quand les préfère-t-on à une ligne de crontab ?
9. Votre tâche « ne marche pas » alors que la commande fonctionne dans votre terminal.
   Citez les **trois** causes les plus fréquentes et comment vous les vérifiez.
10. Interdisez l'usage de `cron` à tous les utilisateurs sauf `root` et `deploy`
    *(indice : `/etc/cron.allow`)*.

---

## Exercice 5.6 — Les *timers* systemd

1. Listez les *timers* actifs de la machine et la prochaine échéance de chacun.
2. Écrivez le couple `ticketflow-backup.service` + `ticketflow-backup.timer` qui remplace la tâche cron
   de l'exercice 5.5.2 : type `oneshot`, déclenchement quotidien à 2 h 30, avec rattrapage si la machine
   était éteinte *(indice : `Persistent=true`)*.
3. Activez le *timer*, vérifiez sa prochaine exécution, déclenchez le service manuellement pour tester.
4. Citez trois avantages d'un *timer* systemd sur une ligne de crontab.

---

## Exercice 5.7 — `logrotate`

1. Regardez comment `/etc/logrotate.d/` est organisé.
2. Écrivez `/etc/logrotate.d/ticketflow` : rotation quotidienne des logs de `/var/log/ticketflow`,
   7 rotations conservées, compression, pas d'erreur si le fichier est absent, et création du nouveau
   fichier avec les bons droits et le bon propriétaire.
3. Testez votre configuration **à blanc**, sans rien faire tourner *(indice : `-d`)*.
4. Forcez une rotation immédiate pour vérifier le résultat.
5. Pourquoi une application qui garde son fichier de log ouvert peut-elle continuer à écrire dans l'ancien
   fichier après rotation, et quelle directive règle le problème ?

---

## ✅ Vérification

- `systemctl status ticketflow-api` montre un service actif, durci, tournant sous `deploy`, relancé
  automatiquement après un `kill -9`.
- `systemctl --failed` ne renvoie rien.
- La sauvegarde quotidienne existe **soit** en cron, **soit** en *timer*, et vous savez justifier votre choix.
- `journalctl -u ticketflow-api --since today` montre les traces de vos tests.
- `logrotate -d /etc/logrotate.d/ticketflow` ne signale aucune erreur.
- Votre `journal.md` liste tout ce qui est planifié sur la machine, avec l'heure et la raison.
