# 🔧 D3 · Le minimum d'admin qu'un dev utilise tous les jours

*Chapitres [02 · Permissions](../../02_file_permissions.md), [02.1 · Utilisateurs et groupes](../../02.1_user_management.md)
et [04 · Paquets, services et cron](../../04_installation_et_services.md)*

> [!NOTE]
> **Objectifs** : rendre un script exécutable et comprendre pourquoi, savoir qui vous êtes et avec quels droits
> vous tournez, ajouter votre compte à un groupe (celui de Docker, typiquement), installer un paquet, piloter
> un service dont dépend votre appli, lire ses logs, et planifier une tâche.
>
> Ce n'est **pas** le cours d'administration : on ne fait ici que ce qu'un dev fait réellement sur sa machine
> de dev, sa VM ou le serveur de recette. Le reste est dans les jeux d'exercices `Exercices_1_2.md` et
> `Exercices_3_4.md`.

> [!CAUTION]
> VM ou conteneur jetable, **jamais** votre machine principale : on crée des utilisateurs et on touche à des
> services. Les manipulations `systemctl` demandent une vraie VM (un conteneur n'a pas de `systemd`).

---

## Exercice 3.1 — « Permission denied » sur mon script

Vous écrivez `scripts/deploy.sh`, vous le lancez, et le shell répond `Permission denied`.

```bash
mkdir -p ~/ticketflow/scripts
printf '#!/bin/bash\necho "deploiement en cours"\n' > ~/ticketflow/scripts/deploy.sh
```

1. Lancez `./scripts/deploy.sh` et constatez l'erreur. Affichez les permissions du fichier.
2. Traduisez la ligne de permissions obtenue en **notation octale**.
3. Rendez le script exécutable **pour son seul propriétaire**, en notation symbolique, puis relancez-le.
4. Le même script doit maintenant être exécutable par tous les membres de l'équipe (le groupe) mais invisible
   aux autres : quelle est la commande **octale** correspondante ?
5. Pourquoi `bash scripts/deploy.sh` fonctionne-t-il même sans droit `x`, alors que `./scripts/deploy.sh` échoue ?
6. Positionnez `600` sur `api/.env` — expliquez en une phrase pourquoi un fichier de secrets ne doit pas être
   en `644`.

---

## Exercice 3.2 — Droits sur un dossier : le piège du `x`

1. Sur un **fichier**, `r`, `w` et `x` sont clairs. Sur un **dossier**, à quoi servent-ils respectivement ?
   (une phrase chacun)
2. Créez un dossier `scripts/bin`, retirez-lui le droit `x` pour tout le monde, puis essayez d'y entrer et
   de lister son contenu. Que se passe-t-il dans chaque cas ?
3. Remettez des droits corrects, puis appliquez `755` **récursivement** à `scripts/`.
4. Pourquoi `chmod -R 777` sur un projet est-il une très mauvaise réponse à un problème de permissions ?

---

## Exercice 3.3 — Qui suis-je, et avec quels droits ?

1. Affichez votre nom d'utilisateur, votre UID et la liste de vos groupes.
2. Affichez le propriétaire et le groupe de tous les fichiers de `ticketflow/`.
3. Exécutez la seule commande `whoami` **en tant que root**, sans ouvrir de session root.
4. Ouvrez une vraie session root, vérifiez où vous êtes, puis ressortez-en.
5. Vous créez un fichier avec `sudo` dans votre projet : à qui appartient-il ? Rendez-vous-en propriétaire
   (vous **et** votre groupe) avec une seule commande.

> [!TIP]
> C'est **la** cause n°1 des « permission denied » incompréhensibles dans un projet : un `sudo npm install`
> ou un `sudo docker` malheureux qui laisse des fichiers appartenant à root dans votre dépôt.

---

## Exercice 3.4 — Utilisateurs et groupes : le strict nécessaire

Le scénario du dev : ajouter son compte au groupe `docker` pour arrêter de taper `sudo` devant chaque commande.

1. Créez le groupe `ticketflow`.
2. Créez l'utilisateur `deploy`, **avec** sa *home* et le shell `/bin/bash` — c'est le compte technique qui
   fera tourner l'application.
3. Ajoutez `deploy` **et** votre propre utilisateur au groupe `ticketflow`, **sans** les retirer de leurs
   autres groupes. *(L'option qui manque ici est celle qui vide tous les autres groupes : ne vous trompez pas.)*
4. Vérifiez les groupes des deux comptes.
5. Donnez le groupe `ticketflow` à tout le dossier `ticketflow/`, puis des droits `rwxrwxr-x`.
6. Vous venez de vous ajouter à un groupe et `groups` ne le montre toujours pas dans le terminal courant.
   Pourquoi ? Que faut-il faire ?
7. Supprimez l'utilisateur `deploy` **et** sa *home*.

---

## Exercice 3.5 — Installer ce dont on a besoin

1. Mettez à jour l'index des paquets.
2. Installez `git`, `curl`, `jq` et `tree` en une seule commande.
3. Cherchez le paquet qui fournit `nodejs`, puis affichez ses informations détaillées (version, taille,
   description) **sans** l'installer.
4. Quelle version de `git` est réellement installée ? Où est son exécutable ?
5. Désinstallez `tree`, puis désinstallez-le en supprimant **aussi** ses fichiers de configuration.
6. En une phrase : pourquoi la version d'un paquet dans les dépôts Debian est-elle souvent plus ancienne que
   celle du site officiel du projet, et qu'est-ce que ça implique pour installer Node ou Docker ?

---

## Exercice 3.6 — Piloter un service dont dépend votre appli

Installez PostgreSQL (`postgresql`) sur la VM — c'est le service de l'exercice.

1. Affichez l'**état** du service `postgresql` : tourne-t-il ? est-il activé au démarrage ?
2. Arrêtez-le, vérifiez que votre appli ne peut plus s'y connecter (`psql` ou un simple `curl` sur le port),
   puis redémarrez-le.
3. Rechargez sa configuration **sans** le redémarrer. Quelle est la différence entre `restart` et `reload`,
   et pourquoi ça compte en production ?
4. Désactivez-le au démarrage, redémarrez la VM, constatez, puis réactivez-le **et** démarrez-le en une
   seule commande.
5. Listez tous les services en échec sur la machine.

---

## Exercice 3.7 — Lire les logs d'un service

1. Affichez les logs du service `postgresql`.
2. Affichez seulement les **30 dernières** lignes.
3. **Suivez** ses logs en direct pendant que vous le redémarrez dans un autre terminal.
4. Affichez ses logs depuis « il y a 10 minutes », puis ceux d'aujourd'hui uniquement.
5. Affichez uniquement les messages de **niveau erreur** de tout le système.
6. Filtrez les logs du service pour n'afficher que les lignes contenant `connection` — en combinant
   `journalctl` et une commande du chapitre 03.

---

## Exercice 3.8 — Faire tourner *son* application comme un service

Votre API doit survivre à la fermeture de votre session SSH et redémarrer toute seule si elle plante.

```bash
sudo tee /usr/local/bin/ticketflow-api.sh >/dev/null <<'EOF'
#!/bin/bash
while true; do
  echo "$(date '+%F %T') api heartbeat"
  sleep 10
done
EOF
```

1. Rendez le script exécutable avec des droits corrects pour un script système.
2. Écrivez l'unité `/etc/systemd/system/ticketflow-api.service` : type `simple`, exécutée par l'utilisateur
   `deploy` (recréez-le si besoin), redémarrage automatique en cas d'échec, lancée après le réseau.
3. Rechargez la configuration de systemd, puis activez au boot **et** démarrez le service en une commande.
4. Vérifiez son état et lisez ses logs — vos `echo` doivent y apparaître.
5. Tuez brutalement le processus et vérifiez que systemd le relance tout seul.
6. Arrêtez le service, désactivez-le, supprimez l'unité et rechargez systemd (nettoyage).

> [!TIP]
> C'est exactement ce que fait un `docker run --restart=unless-stopped` du [chapitre 07](../../07_docker.md),
> mais sans conteneur. Savoir écrire les deux vous permet de choisir en connaissance de cause.

---

## Exercice 3.9 — Planifier une tâche

1. Écrivez la ligne de crontab qui, **toutes les 5 minutes**, ajoute la date dans `~/ticketflow/logs/cron.log`.
2. Une ligne qui, **du lundi au vendredi à 7 h 30**, lance `~/ticketflow/scripts/deploy.sh` en redirigeant
   la sortie standard **et** les erreurs vers un fichier de log.
3. Une ligne qui, **tous les jours à 3 h**, supprime les fichiers de `logs/` de plus de 7 jours
   *(la commande de recherche vient du chapitre 03)*.
4. Une ligne qui lance votre script **à chaque redémarrage** de la machine.
5. Affichez la liste de vos tâches planifiées, puis videz-la.
6. Votre tâche cron « ne marche pas » alors que la commande fonctionne dans votre terminal.
   Citez les **deux** causes les plus fréquentes. *(Indice : `PATH` et variables d'environnement.)*

---

## ✅ Vérification

- Vos scripts se lancent en `./script.sh` sans que vous ayez à réfléchir, et vous savez traduire un
  `-rwxr-x---` en `750` dans les deux sens.
- Vous savez retrouver le propriétaire d'un fichier récalcitrant et le réparer avec `chown`.
- Vous savez répondre à « le service tourne-t-il ? », « pourquoi a-t-il planté ? » et « comment le relancer
  au boot ? » sans chercher dans le cours.
- Votre unité `ticketflow-api.service` a bien été activée, testée, puis nettoyée.
- Vous savez pourquoi une tâche cron a besoin de chemins absolus.
