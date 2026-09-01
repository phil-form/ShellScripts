# 🐳 A10 · Docker pour l'administrateur

*Chapitre [08 · Docker pour l'administrateur système](../../08_docker_administration.md)*

> [!NOTE]
> **Objectifs** : exploiter un hôte Docker sans qu'il devienne une zone de non-droit — configurer le démon,
> maîtriser volumes, réseaux et logs, limiter les ressources, durcir les conteneurs, sauvegarder, nettoyer
> et lancer une stack au boot.

> [!IMPORTANT]
> On ne construit pas d'images ici : l'écriture des `Dockerfile` est traitée au
> [chapitre 07](../../07_docker.md) et dans le [parcours développeur](../dev/05_docker.md).
> Ici, on exploite ce que les développeurs livrent.

---

## Exercice 10.1 — L'hôte

1. Où Docker range-t-il ses données sur cette machine ? Quelle place occupe-t-il ?
2. Quel pilote de stockage, quel pilote de logs, quel pilote réseau par défaut ?
3. Quelle version du démon, quelle version du client ? Le démon tourne-t-il en `root` ?
4. Quel service systemd le pilote ? Où sont ses logs ?
5. Qui, sur cette machine, peut parler au démon Docker ? Pourquoi appartenir au groupe `docker`
   équivaut-il **de fait** à être root sur l'hôte ? Démontrez-le en une commande — puis réfléchissez à ce que
   cela implique pour la règle `sudo` de vos développeurs *(chapitre [A6](06_acl_et_sudo.md))*.

---

## Exercice 10.2 — Configurer le démon

1. Créez `/etc/docker/daemon.json` avec : rotation des logs (10 Mo, 3 fichiers), `live-restore`,
   et les adresses de vos réseaux par défaut.
2. **Vérifiez la syntaxe avant de redémarrer** le démon. Que se passe-t-il si le fichier est invalide ?
3. Redémarrez le démon et vérifiez que les nouvelles valeurs sont bien prises en compte.
4. Déplacez le `data-root` vers `/srv/docker` (une partition dédiée) : quelle est la procédure complète,
   dans quel ordre, et qu'arrive-t-il aux conteneurs existants ?
5. Que fait `live-restore`, et dans quel cas est-ce précieux en production ?

---

## Exercice 10.3 — Volumes et persistance

1. Listez les volumes de la machine, avec leur taille.
2. Lancez un PostgreSQL sur un volume **nommé**, créez-y une table, détruisez le conteneur, relancez-en un
   sur le même volume : les données sont-elles là ?
3. Inspectez le volume : où sont réellement les fichiers sur l'hôte ? Qui en est propriétaire ?
4. Montez un fichier de configuration de l'hôte **en lecture seule** dans un conteneur. Vérifiez qu'une
   écriture est refusée depuis l'intérieur.
5. Quelle différence entre un volume nommé et un *bind mount* du point de vue des droits, des sauvegardes
   et de SELinux/AppArmor ?
6. Trouvez les volumes **orphelins** (plus rattachés à aucun conteneur) et leur poids total.

---

## Exercice 10.4 — Réseau

1. Listez les réseaux Docker et leur pilote.
2. Créez un réseau applicatif `ticketflow-net` et attachez-y deux conteneurs. Vérifiez qu'ils se joignent
   **par leur nom**.
3. Un conteneur sur le réseau `bridge` par défaut peut-il joindre un conteneur du réseau applicatif ?
   Pourquoi cette différence est-elle une fonctionnalité de sécurité ?
4. Publiez un port, puis vérifiez ce qui est **réellement exposé** sur l'hôte, et sur quelles interfaces.
5. Publiez un port **uniquement sur la boucle locale**. Dans quel cas est-ce le bon réflexe ?
6. Le piège du chapitre : votre `ufw` interdit le port 8080, et pourtant le conteneur est joignable de
   l'extérieur. Expliquez pourquoi, et donnez **deux** façons de régler le problème.
7. Depuis un conteneur, résolvez le nom d'un autre service et testez la connexion — sans installer d'outils
   dans l'image applicative *(indice : un conteneur jetable attaché au même réseau)*.

---

## Exercice 10.5 — Les logs

1. Affichez les logs d'un conteneur, puis les 50 dernières lignes, puis en suivi, puis depuis 10 minutes.
2. Où sont physiquement stockés ces logs sur l'hôte ? Quelle taille font-ils ?
3. Trouvez le conteneur dont les logs occupent le plus de place.
4. Configurez la rotation **globalement** dans `daemon.json`, puis **par conteneur** dans un fichier Compose.
   Laquelle s'applique aux conteneurs déjà créés ?
5. Envoyez les logs d'un service vers `journald` et retrouvez-les avec `journalctl`
   *(chapitre [04](../../04_installation_et_services.md))*.
6. Un conteneur a rempli `/var/log` — ou plutôt `/var/lib/docker`. Quelle est la marche à suivre immédiate,
   et la correction durable ?

---

## Exercice 10.6 — Ressources

1. Affichez la consommation temps réel de tous les conteneurs.
2. Lancez un conteneur limité à **512 Mo** de mémoire et **0,5 CPU**. Vérifiez la limite depuis l'hôte.
3. Provoquez un dépassement de mémoire : que fait Docker ? Où le voyez-vous ?
4. Limitez le nombre de processus (`--pids-limit`) et expliquez contre quoi cela protège.
5. Appliquez ces limites dans un fichier Compose plutôt qu'en ligne de commande.
6. Configurez la politique de redémarrage `unless-stopped` sur un service, redémarrez la machine,
   vérifiez. Quelle différence avec `always` ?
7. Ajoutez un `HEALTHCHECK` en ligne de commande à un conteneur et retrouvez son état de santé.
   Que fait Docker d'un conteneur `unhealthy` — et que **ne fait-il pas** ?

---

## Exercice 10.7 — Durcir

1. Vérifiez sous quel utilisateur tourne le processus principal de chacun de vos conteneurs.
   Combien tournent en root ?
2. Lancez un conteneur avec un utilisateur non privilégié imposé depuis l'extérieur de l'image.
3. Lancez un conteneur en **système de fichiers racine en lecture seule**, avec un `tmpfs` pour ce qui doit
   être écrit.
4. Appliquez le durcissement standard : `--cap-drop=ALL` puis les seules capacités nécessaires,
   `--security-opt=no-new-privileges`.
5. Quelles conséquences a `--privileged` ? Donnez un cas où c'est légitime et trois où c'est de la paresse.
6. Un conteneur qui monte `/var/run/docker.sock` : expliquez précisément le risque.
7. Auditez vos conteneurs : écrivez une ligne de commande qui liste, pour chacun, son utilisateur, sa
   politique de redémarrage et ses ports publiés *(indice : `docker inspect --format`)*.
8. *(Bonus)* Testez le mode **rootless** : que gagne-t-on, que perd-on ?

---

## Exercice 10.8 — Sauvegarde et restauration

1. Sauvegardez un **volume** entier dans une archive `.tar.gz` sur l'hôte, en passant par un conteneur jetable.
2. Restaurez cette archive dans un volume neuf et vérifiez les données.
3. Faites un **dump applicatif** de la base (`pg_dump`) depuis le conteneur, sans exposer le mot de passe.
   Pourquoi un dump applicatif vaut-il mieux qu'une copie du volume pour une base de données ?
4. Exportez une image dans un fichier, supprimez l'image, réimportez-la.
5. Quelle différence entre `docker save`/`load` et `docker export`/`import` ?
6. Intégrez la sauvegarde des volumes à votre `backup.sh` du chapitre [A9](09_scripts_administration.md).

---

## Exercice 10.9 — Nettoyage et espace disque

1. Affichez ce que Docker consomme, réparti par images, conteneurs, volumes et cache de build.
2. Supprimez les conteneurs arrêtés, puis les images sans étiquette.
3. Quelle différence exacte entre `docker system prune` et `docker system prune -a` ? Laquelle est
   dangereuse sur un hôte de production, et pourquoi ?
4. Écrivez une tâche planifiée qui fait le ménage chaque semaine — en excluant explicitement ce qui ne doit
   jamais être supprimé. Où l'installez-vous *(chapitre [04](../../04_installation_et_services.md))* ?
5. Testez votre commande de ménage **à blanc** avant de la planifier : comment fait-on ?

---

## Exercice 10.10 — Une stack en production

1. Récupérez la stack `05_stack_compose` du dépôt *(voir [`07_docker/05_stack_compose/`](../../07_docker/05_stack_compose/))*
   et déployez-la dans `/srv/ticketflow`.
2. Écrivez l'unité systemd qui lance cette stack **au démarrage de la machine** et l'arrête proprement à
   l'extinction. Testez avec un redémarrage réel.
3. Superposez le fichier de production : quelles différences avec le fichier de développement, et comment
   vérifiez-vous **ce qui est réellement appliqué** ?
4. Déployez une nouvelle version d'image sans interruption perceptible : quelle est la séquence ?
5. Mettez en place une supervision minimale : un script qui signale tout conteneur arrêté ou `unhealthy`,
   planifié toutes les 5 minutes, qui écrit dans le journal système
   *(chapitre [A9](09_scripts_administration.md))*.
6. Les pannes classiques — pour chacune, la commande de diagnostic **et** la correction :
   - le conteneur redémarre en boucle ;
   - il ne joint pas la base ;
   - le port est déjà utilisé sur l'hôte ;
   - le volume est monté mais vide ;
   - « ça marchait avant la mise à jour de l'image ».

---

## ✅ Vérification

- `docker info` montre la rotation des logs configurée, et aucun conteneur n'a de fichier de log de plusieurs Go.
- Aucun conteneur applicatif ne tourne en root ni en `--privileged`, et vous pouvez le prouver en une commande.
- La stack repart toute seule après un redémarrage complet de la VM.
- Un volume a été sauvegardé **et restauré** pour de vrai.
- Le ménage hebdomadaire est planifié et vous savez exactement ce qu'il supprime.
- `journal.md` documente : où sont les données, ce qui est sauvegardé, comment on restaure.
