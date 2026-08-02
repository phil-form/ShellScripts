# 08 · Docker pour l'administrateur système

Le [chapitre 07](07_docker.md) montrait Docker vu du développeur : construire une image, lancer une stack, travailler. Ce chapitre prend l'autre point de vue — celui de la personne qui doit faire **tourner** ces conteneurs sur un serveur, les surveiller, les sécuriser et empêcher le disque de se remplir tout seul un dimanche soir.

> [!NOTE]
> **Objectifs du chapitre**
> - Comprendre l'architecture du démon Docker et savoir le configurer
> - Gérer volumes, réseaux et persistance des données
> - Maîtriser les logs, leur rotation et la consommation de ressources
> - Durcir la configuration : utilisateur non privilégié, capabilities, mode *rootless*
> - Sauvegarder, restaurer, superviser et nettoyer un hôte Docker

## Sommaire

1. [Architecture du démon](#architecture-du-démon)
2. [Configurer le démon](#configurer-le-démon)
3. [Les volumes et la persistance](#les-volumes-et-la-persistance)
4. [Le réseau](#le-réseau)
5. [Les logs](#les-logs)
6. [Limiter les ressources](#limiter-les-ressources)
7. [Sécuriser ses conteneurs](#sécuriser-ses-conteneurs)
8. [Le mode rootless](#le-mode-rootless)
9. [Nettoyage et espace disque](#nettoyage-et-espace-disque)
10. [Sauvegarde et restauration](#sauvegarde-et-restauration)
11. [Docker en production](#docker-en-production)
12. [Supervision et diagnostic](#supervision-et-diagnostic)
13. [Récapitulatif](#récapitulatif)

---

## Architecture du démon

Docker n'est pas un programme, c'est une **architecture client / serveur** :

```text
   docker ps          ┌──────────────────────────────────┐
  (client CLI)  ────► │  dockerd  (démon, tourne en root)│
                      │     └── containerd               │
                      │            └── runc ── conteneur │
                      └──────────────────────────────────┘
                        socket : /var/run/docker.sock
```

| Composant | Rôle |
|-----------|------|
| `docker` | Le client en ligne de commande — ne fait qu'envoyer des requêtes HTTP |
| `dockerd` | Le démon : images, réseaux, volumes, API |
| `containerd` | Le gestionnaire de cycle de vie des conteneurs |
| `runc` | Ce qui crée réellement le conteneur (namespaces + cgroups) |

Le démon est un service `systemd` classique, piloté comme n'importe quel autre service du [chapitre 04](04_installation_et_services.md) :

```bash
systemctl status docker
systemctl restart docker
systemctl enable --now docker
journalctl -u docker -f
```

> [!CAUTION]
> **`/var/run/docker.sock` est la clé du royaume.** Quiconque peut écrire dans cette socket peut lancer un conteneur privilégié montant `/`, donc devenir root sur l'hôte. C'est vrai pour le groupe `docker`, et c'est vrai pour tout conteneur à qui on monte cette socket (`-v /var/run/docker.sock:/var/run/docker.sock`, un grand classique des outils de monitoring). Ne le faites qu'en connaissance de cause.

### Où Docker range ses affaires

```bash
docker info
```

```text
Storage Driver: overlay2
Docker Root Dir: /var/lib/docker
Cgroup Driver: systemd
```

```text
/var/lib/docker/
├── overlay2/     # les couches d'images et conteneurs — c'est ce qui grossit
├── volumes/      # les volumes nommés
├── containers/   # métadonnées et fichiers de logs
└── image/        # index des images
```

> [!WARNING]
> Ne modifiez **jamais** `/var/lib/docker` à la main (ni `rm -rf` sur un sous-dossier). Tout se pilote via les commandes `docker`. Une suppression manuelle laisse le démon avec des métadonnées incohérentes.

> [!TIP]
> Sur un serveur, `/var/lib/docker` mérite sa **propre partition** ou son propre volume LVM. Une image de trop ne doit pas remplir `/` et bloquer tout le système.

---

## Configurer le démon

La configuration se fait dans `/etc/docker/daemon.json` (à créer s'il n'existe pas) :

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "data-root": "/srv/docker",
  "default-address-pools": [
    { "base": "172.30.0.0/16", "size": 24 }
  ],
  "live-restore": true,
  "userland-proxy": false
}
```

| Clé | Effet |
|-----|-------|
| `log-driver` / `log-opts` | Le pilote de logs par défaut et sa rotation |
| `data-root` | Déplacer `/var/lib/docker` ailleurs (disque dédié) |
| `default-address-pools` | Les plages IP utilisées pour les réseaux créés — utile en cas de conflit avec le réseau de l'entreprise |
| `live-restore` | Les conteneurs continuent de tourner pendant un redémarrage du démon |
| `icc: false` | Interdit la communication entre conteneurs du réseau par défaut |

```bash
# Vérifier la syntaxe avant de redémarrer
dockerd --validate --config-file /etc/docker/daemon.json

sudo systemctl restart docker
```

> [!IMPORTANT]
> Un JSON invalide dans `daemon.json` **empêche le démon de démarrer** — et donc tous les conteneurs de remonter. Validez toujours avant de redémarrer, et gardez une copie du fichier précédent.

Pour déplacer les données existantes vers un autre disque :

```bash
sudo systemctl stop docker
sudo rsync -aHAX /var/lib/docker/ /srv/docker/
# puis "data-root": "/srv/docker" dans daemon.json
sudo systemctl start docker
docker info | grep "Docker Root Dir"
```

---

## Les volumes et la persistance

Trois façons de faire persister des données, à ne pas confondre :

| Type | Syntaxe | Usage |
|------|---------|-------|
| **Volume nommé** | `-v pgdata:/var/lib/postgresql/data` | Données applicatives — **le choix par défaut** |
| **Bind mount** | `-v /srv/conf:/etc/app:ro` | Fichiers de configuration, code en développement |
| **tmpfs** | `--tmpfs /tmp` | Données sensibles ou temporaires, en RAM uniquement |

```bash
docker volume create pgdata
docker volume ls
docker volume inspect pgdata
docker volume rm pgdata
docker volume prune            # supprime les volumes non utilisés
```

Un volume nommé vit dans `/var/lib/docker/volumes/<nom>/_data`. On peut donc l'inspecter depuis l'hôte — en lecture, de préférence.

> [!TIP]
> Préférez le **volume nommé** au bind mount pour les données : Docker gère les permissions, la portabilité et le nettoyage. Le bind mount, lui, dépend des UID/GID de l'hôte — et un conteneur qui tourne avec un UID différent de celui du propriétaire du dossier se prend un `Permission denied` immédiat (voir le [chapitre 02](02_file_permissions.md)).

### Monter en lecture seule

```bash
docker run -d \
  -v /srv/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v webdata:/usr/share/nginx/html \
  nginx
```

Le suffixe `:ro` est gratuit et évite qu'un conteneur compromis ne réécrive sa propre configuration.

---

## Le réseau

```bash
docker network ls
```

```text
NETWORK ID     NAME      DRIVER    SCOPE
a1b2c3d4e5f6   bridge    bridge    local
b2c3d4e5f6a1   host      host      local
c3d4e5f6a1b2   none      null      local
```

| Driver | Comportement |
|--------|--------------|
| `bridge` | Réseau virtuel isolé, NAT vers l'extérieur — le mode par défaut |
| `host` | Le conteneur partage la pile réseau de l'hôte, sans isolation |
| `none` | Aucun réseau |
| `overlay` | Réseau multi-hôtes (Swarm / Kubernetes) |
| `macvlan` | Le conteneur obtient sa propre adresse MAC sur le réseau physique |

### Créer un réseau applicatif

```bash
docker network create app-net
docker run -d --name db --network app-net postgres:16-alpine
docker run -d --name api --network app-net -p 3000:3000 mon-api
```

Sur un réseau **créé par l'utilisateur** (contrairement au `bridge` par défaut), Docker fournit une **résolution DNS interne** : `api` joint la base en se connectant simplement à `db:5432`. C'est exactement ce que fait Compose automatiquement.

```bash
docker network inspect app-net      # voir les conteneurs connectés et leurs IP
docker network connect app-net web  # brancher un conteneur existant
docker network disconnect app-net web
```

### Ports publiés et pare-feu

> [!CAUTION]
> **Docker écrit ses propres règles dans `iptables` et court-circuite `ufw`.** Un conteneur lancé avec `-p 5432:5432` est joignable depuis l'extérieur **même si `ufw` bloque le port 5432** — la règle Docker est évaluée avant. Beaucoup de bases de données se retrouvent exposées à Internet de cette façon.
>
> La parade : publier uniquement sur la boucle locale.
>
> ```bash
> docker run -d -p 127.0.0.1:5432:5432 postgres:16-alpine
> ```
>
> Un service qui n'a pas besoin d'être joint depuis l'hôte n'a **aucune raison** d'être publié : sur un réseau Docker, les conteneurs se parlent déjà entre eux sans `-p`. Voir le [chapitre 05 · Sécurité](05_securite.md) pour la configuration du pare-feu.

---

## Les logs

Par défaut, Docker écrit les logs de chaque conteneur dans un fichier JSON :

```text
/var/lib/docker/containers/<id>/<id>-json.log
```

**Sans rotation configurée, ce fichier grossit indéfiniment.** C'est la première cause de disque plein sur un hôte Docker.

### Configurer la rotation globalement

Dans `/etc/docker/daemon.json` :

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

Soit 30 Mo de logs maximum par conteneur.

> [!IMPORTANT]
> Cette configuration ne s'applique qu'aux conteneurs **créés après** le redémarrage du démon. Les conteneurs existants gardent leur réglage : il faut les recréer (`docker compose up -d --force-recreate`).

Par conteneur :

```bash
docker run -d --log-opt max-size=10m --log-opt max-file=3 nginx
```

En Compose :

```yaml
services:
  api:
    image: mon-api
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

### Envoyer les logs à journald

Pour centraliser dans le `journalctl` de l'hôte, vu au [chapitre 04](04_installation_et_services.md#journald) :

```json
{ "log-driver": "journald" }
```

```bash
journalctl CONTAINER_NAME=api -f
```

> [!WARNING]
> Avec le driver `journald` (ou `syslog`, ou `fluentd`), la commande `docker logs` ne fonctionne plus de la même façon : il faut interroger le système de destination.

### Trouver ce qui remplit le disque

```bash
sudo du -sh /var/lib/docker/containers/* | sort -rh | head
```

---

## Limiter les ressources

Par défaut, **un conteneur peut consommer toute la RAM et tout le CPU de l'hôte**. Un processus qui fuit emporte le serveur entier avec lui.

```bash
docker run -d \
  --memory 512m \
  --memory-swap 512m \
  --cpus 1.5 \
  --pids-limit 200 \
  --restart unless-stopped \
  mon-api
```

| Option | Effet |
|--------|-------|
| `--memory 512m` | RAM maximale — au-delà, le conteneur est tué (OOM) |
| `--memory-swap` | RAM + swap ; égal à `--memory` pour interdire le swap |
| `--cpus 1.5` | Équivalent d'un cœur et demi |
| `--cpuset-cpus 0,1` | Épingle le conteneur sur des cœurs précis |
| `--pids-limit 200` | Nombre max de processus (protection anti *fork bomb*) |

En Compose :

```yaml
services:
  api:
    image: mon-api
    deploy:
      resources:
        limits:
          cpus: "1.5"
          memory: 512M
```

### Les politiques de redémarrage

| Politique | Comportement |
|-----------|--------------|
| `no` | Défaut — aucun redémarrage |
| `on-failure[:5]` | Redémarre si le code de sortie ≠ 0, au plus 5 fois |
| `always` | Redémarre toujours, y compris après reboot de l'hôte |
| `unless-stopped` | Comme `always`, mais respecte un arrêt manuel — **le bon choix en production** |

### Le healthcheck

```yaml
services:
  api:
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s
```

```bash
docker ps --format '{{.Names}}\t{{.Status}}'
```

```text
api     Up 4 minutes (healthy)
db      Up 4 minutes (healthy)
```

> [!TIP]
> Un healthcheck n'a de valeur que si quelque chose le regarde : votre supervision, un reverse proxy, ou un `depends_on: condition: service_healthy`. Seul, il ne fait qu'afficher un statut.

---

## Sécuriser ses conteneurs

### Ne pas tourner en root

Par défaut, le processus d'un conteneur tourne en **root** — et l'UID 0 dans le conteneur est l'UID 0 de l'hôte. En cas d'évasion, la casse est maximale.

Dans le `Dockerfile` :

```dockerfile
RUN addgroup -S app && adduser -S -G app app
USER app
```

Ou à l'exécution :

```bash
docker run -d --user 1000:1000 mon-api
```

### Le durcissement standard

```bash
docker run -d \
  --read-only \
  --tmpfs /tmp \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --security-opt no-new-privileges \
  --user 1000:1000 \
  mon-api
```

| Option | Effet |
|--------|-------|
| `--read-only` | Système de fichiers racine en lecture seule |
| `--tmpfs /tmp` | Un espace inscriptible en RAM, puisque tout le reste est en lecture seule |
| `--cap-drop ALL` | Retire **toutes** les capabilities Linux |
| `--cap-add NET_BIND_SERVICE` | …puis ne rend que celle qui est nécessaire (écouter sous le port 1024) |
| `--security-opt no-new-privileges` | Interdit l'escalade via les binaires SUID |

Le même en Compose :

```yaml
services:
  api:
    image: mon-api
    read_only: true
    tmpfs: [/tmp]
    cap_drop: [ALL]
    security_opt: ["no-new-privileges:true"]
    user: "1000:1000"
```

> [!CAUTION]
> **N'utilisez jamais `--privileged`.** Cette option retire quasiment toute l'isolation : le conteneur obtient toutes les capabilities et l'accès aux périphériques de l'hôte. C'est l'équivalent d'un `chmod 777` sur la sécurité de la machine. Si un outil « en a besoin », il a en réalité besoin d'une ou deux capabilities précises — accordez celles-là.

### Les autres réflexes

- **Épingler les versions** d'images, et privilégier les variantes `-alpine` ou `-slim` (moins de code, moins de CVE).
- **Scanner les images** avant déploiement :

  ```bash
  docker scout cves mon-api:1.0
  # ou
  trivy image mon-api:1.0
  ```

- **Reconstruire régulièrement** : une image figée accumule des vulnérabilités dans ses dépendances système.
- **Passer les secrets à l'exécution**, jamais dans l'image (voir chapitre 07). En Compose :

  ```yaml
  services:
    api:
      secrets: [db_password]
  secrets:
    db_password:
      file: /srv/secrets/db_password.txt
  ```

- **AppArmor / SELinux** (chapitre 05) s'appliquent aussi aux conteneurs : Docker charge un profil `docker-default` par défaut.

---

## Le mode rootless

Le démon Docker tourne en root. Le mode **rootless** le fait tourner sous un utilisateur non privilégié, en s'appuyant sur les *user namespaces* : root dans le conteneur correspond à un UID non privilégié sur l'hôte.

```bash
sudo apt install -y uidmap docker-ce-rootless-extras
dockerd-rootless-setuptool.sh install
```

```bash
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
systemctl --user enable --now docker
sudo loginctl enable-linger $USER   # le démon survit à la déconnexion
```

| Avantage | Limite |
|----------|--------|
| Une évasion de conteneur ne donne pas root sur l'hôte | Pas d'écoute sous le port 1024 sans configuration |
| Chaque utilisateur a son propre démon isolé | Certains drivers réseau et de stockage indisponibles |
| Plus besoin du groupe `docker` | Performances réseau légèrement moindres |

> [!TIP]
> C'est le mode par défaut à privilégier sur un serveur mutualisé ou une machine de CI, où plusieurs utilisateurs lancent des conteneurs. Pour un serveur applicatif dédié, le démon classique correctement durci reste courant.

---

## Nettoyage et espace disque

```bash
docker system df
```

```text
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          24        4         8.2GB     6.9GB (84%)
Containers      6         4         120MB     40MB (33%)
Local Volumes   11        3         2.1GB     1.8GB (85%)
Build Cache     142       0         3.4GB     3.4GB
```

```bash
docker container prune          # conteneurs arrêtés
docker image prune              # images sans tag (dangling)
docker image prune -a           # toutes les images non utilisées
docker builder prune            # cache de build
docker volume prune             # volumes non utilisés
docker system prune -a          # tout ce qui précède, sauf les volumes
docker system prune -a --volumes # tout, volumes compris
```

> [!CAUTION]
> `docker system prune -a --volumes` supprime les **volumes non attachés à un conteneur existant**. Une base de données dont le conteneur a été supprimé mais dont le volume devait être conservé disparaît définitivement. Sur un serveur, prunez les images et le cache de build ; touchez aux volumes à la main, en connaissance de cause.

Un nettoyage automatique, sans les volumes, via `cron` (chapitre 04) :

```bash
# /etc/cron.d/docker-prune
0 4 * * 0 root /usr/bin/docker system prune -af --filter "until=168h" >> /var/log/docker-prune.log 2>&1
```

Le filtre `until=168h` épargne tout ce qui a moins de 7 jours.

---

## Sauvegarde et restauration

**Ce qu'il faut sauvegarder, ce sont les volumes et les fichiers de configuration.** Les images se reconstruisent, les conteneurs se recréent ; les données, non.

### Sauvegarder un volume

```bash
docker run --rm \
  -v pgdata:/data:ro \
  -v "$(pwd)":/backup \
  alpine tar czf /backup/pgdata-$(date +%F).tar.gz -C /data .
```

On lance un conteneur jetable qui monte le volume en lecture seule et le dossier courant en écriture, puis on archive (chapitre 03).

### Restaurer

```bash
docker run --rm \
  -v pgdata:/data \
  -v "$(pwd)":/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/pgdata-2026-08-02.tar.gz -C /data"
```

### Le dump applicatif

Pour une base de données, un dump logique est souvent préférable à la copie des fichiers : il est cohérent, portable entre versions et restaurable partiellement.

```bash
docker compose exec -T db pg_dump -U postgres app | gzip > app-$(date +%F).sql.gz
```

### Exporter une image ou un conteneur

```bash
docker save mon-api:1.0 | gzip > mon-api-1.0.tar.gz   # une image, avec ses couches
docker load < mon-api-1.0.tar.gz                      # la réimporter

docker export web > web-fs.tar    # le système de fichiers d'un conteneur, à plat
```

> [!IMPORTANT]
> `save` / `load` travaillent sur des **images** (avec leur historique). `export` / `import` aplatissent un **conteneur** en un système de fichiers sans historique ni métadonnées. Pour transférer une application, c'est `save` qu'il vous faut.

---

## Docker en production

### Le registre d'images

```bash
docker login registry.exemple.be
docker tag mon-api:1.0 registry.exemple.be/equipe/mon-api:1.0
docker push registry.exemple.be/equipe/mon-api:1.0
docker pull registry.exemple.be/equipe/mon-api:1.0
```

> [!TIP]
> Sur un serveur, ne construisez pas les images : votre CI les construit, les scanne, les pousse sur le registre ; le serveur ne fait que `pull` un tag immuable. Le build a besoin d'outils, de sources et de secrets — autant de choses qui n'ont rien à faire en production.

### Lancer une stack Compose au boot

Compose ne gère pas le démarrage au boot. Deux approches :

**1. `restart: unless-stopped`** sur chaque service — le démon Docker (activé via `systemctl enable docker`) relance les conteneurs au démarrage. Simple et suffisant dans la plupart des cas.

**2. Une unité systemd** dédiée, quand on veut maîtriser l'ordre et les dépendances (chapitre 04) :

```ini
# /etc/systemd/system/mon-app.service
[Unit]
Description=Stack applicative mon-app
Requires=docker.service
After=docker.service network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/srv/mon-app
ExecStart=/usr/bin/docker compose up -d --remove-orphans
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose up -d --remove-orphans
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now mon-app
```

### Déployer une nouvelle version

```bash
cd /srv/mon-app
docker compose pull            # récupérer les nouvelles images
docker compose up -d            # recréer uniquement les services modifiés
docker image prune -f           # nettoyer les anciennes images
```

> [!WARNING]
> `docker compose up -d` recrée les conteneurs dont la configuration ou l'image a changé : il y a une **coupure de service** de quelques secondes. Pour du zéro-downtime, il faut un reverse proxy et un déploiement en bleu/vert — ou un orchestrateur (Swarm, Nomad, Kubernetes).

### Les fichiers Compose superposés

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Le second fichier **surcharge** le premier : on garde une base commune et on n'exprime que les différences de la production (pas de bind mount du code, limites de ressources, redémarrage automatique, ports sur `127.0.0.1`).

Un exemple complet des deux fichiers se trouve dans [`07_docker/05_stack_compose/`](07_docker/05_stack_compose/) — comparez `docker-compose.yml` et [`docker-compose.prod.yml`](07_docker/05_stack_compose/docker-compose.prod.yml).

> [!CAUTION]
> **Les listes sont concaténées, pas remplacées.** Redéclarer `ports:` dans le fichier de surcharge **ajoute** l'entrée à celle du fichier de base, et écrire `ports: []` ne supprime rien du tout. Le piège est sérieux : on croit avoir restreint la base à `127.0.0.1`, et elle reste publiée sur `0.0.0.0` — ou le conteneur refuse de démarrer pour conflit de port.
>
> Depuis Compose 2.24, deux marqueurs règlent le problème :
>
> ```yaml
> services:
>   api:
>     ports: !override        # remplace la liste héritée
>       - "127.0.0.1:3000:3000"
>     volumes: !reset []      # efface la liste héritée
> ```

**Vérifiez toujours le résultat de la fusion avant de déployer :**

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml config
```

```bash
# La question qui compte : qu'est-ce qui est réellement publié ?
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps --format '{{.Service}} {{.Ports}}'
```

```text
api    127.0.0.1:3000->3000/tcp
cache  6379/tcp
db     5432/tcp
```

Ici seul l'API est joignable depuis l'hôte, et uniquement en local : `cache` et `db` n'existent que sur le réseau Docker.

---

## Supervision et diagnostic

```bash
docker stats                          # CPU / RAM / réseau / I/O en direct
docker stats --no-stream              # un instantané, exploitable en script
docker events                         # le flux des événements du démon
docker ps --filter "health=unhealthy" # les conteneurs en mauvaise santé
docker inspect --format '{{.State.ExitCode}}' api
```

Un petit script de contrôle, dans l'esprit du [chapitre 06](06_shellscript/01_Base/base.md) :

```bash
#!/usr/bin/env bash
set -euo pipefail

# Signale tout conteneur arrêté ou en mauvaise santé
mapfile -t down < <(docker ps -a --filter "status=exited" --format '{{.Names}}')
mapfile -t sick < <(docker ps --filter "health=unhealthy" --format '{{.Names}}')

if (( ${#down[@]} + ${#sick[@]} > 0 )); then
    printf 'Conteneurs arrêtés : %s\n' "${down[*]:-aucun}"
    printf 'Conteneurs malades : %s\n' "${sick[*]:-aucun}"
    exit 1
fi

echo "Tous les conteneurs sont opérationnels."
```

### Les pannes classiques

| Symptôme | Piste |
|----------|-------|
| Le conteneur redémarre en boucle | `docker logs --tail 100 nom` puis `docker inspect --format '{{.State.ExitCode}}' nom` |
| Code de sortie **137** | Tué par SIGKILL — presque toujours l'OOM killer : `--memory` trop bas ou fuite mémoire |
| Code de sortie **139** | Segfault dans l'application |
| `no space left on device` | `docker system df`, puis prune des images et du cache de build |
| `port is already allocated` | `ss -tulpn \| grep :8080` — un autre service occupe le port |
| Le conteneur ne résout aucun nom | DNS du démon : vérifier `dns` dans `daemon.json` |
| Lenteur générale de l'hôte | `docker stats` — un conteneur sans limite de ressources |

> [!TIP]
> Pour déboguer un conteneur qui s'arrête immédiatement, court-circuitez sa commande de démarrage :
>
> ```bash
> docker run -it --rm --entrypoint sh mon-api:1.0
> ```
>
> Vous obtenez un shell dans l'image, avec exactement son contenu, et vous pouvez lancer la commande à la main pour voir l'erreur.

---

## Récapitulatif

| Commande | Rôle |
|----------|------|
| `systemctl status docker` / `journalctl -u docker` | État et logs du démon |
| `docker info` / `docker system df` | Configuration / occupation disque |
| `docker volume ls` / `inspect` / `prune` | Gérer les volumes |
| `docker network create` / `inspect` | Gérer les réseaux |
| `docker run --memory --cpus --pids-limit` | Limiter les ressources |
| `docker run --cap-drop ALL --read-only --user` | Durcir un conteneur |
| `docker system prune -af --filter "until=168h"` | Nettoyage périodique |
| `docker save` / `load` | Exporter / importer une image |
| `docker stats` / `docker events` | Supervision temps réel |
| `docker compose pull && docker compose up -d` | Déployer une nouvelle version |

### Les fichiers à connaître

| Chemin | Contenu |
|--------|---------|
| `/etc/docker/daemon.json` | Configuration du démon |
| `/var/lib/docker/` | Images, conteneurs, volumes |
| `/var/lib/docker/volumes/<nom>/_data` | Les données d'un volume nommé |
| `/var/run/docker.sock` | La socket de l'API — à protéger |

### Les sept règles à retenir

> [!TIP]
> 1. **Configurer la rotation des logs** dès l'installation — sinon le disque se remplit.
> 2. **Limiter mémoire, CPU et PID** de chaque conteneur.
> 3. **Publier sur `127.0.0.1`** tout ce qui n'a pas à être exposé — Docker contourne `ufw`.
> 4. **Jamais `--privileged`**, jamais la socket Docker montée sans raison.
> 5. **Ne pas tourner en root** dans le conteneur.
> 6. **Sauvegarder les volumes**, pas les conteneurs.
> 7. **Prune régulier des images et du cache**, jamais des volumes en automatique.

---

⬅️ [Précédent : 07 · Docker pour les développeurs](07_docker.md) · 🏠 [Sommaire](README.md) · [Suivant : 09 · tmux ➡️](09_tmux.md)
