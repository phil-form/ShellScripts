# 07 · Docker pour les développeurs

Docker permet d'empaqueter une application **avec tout ce dont elle a besoin pour tourner** (runtime, bibliothèques, fichiers de configuration) dans une unité isolée et reproductible : le **conteneur**.

La promesse : le fameux *« ça marche sur ma machine »* devient *« ça marche partout, de la même façon »*.

> [!NOTE]
> **Objectifs du chapitre**
> - Comprendre la différence entre une image, un conteneur et un volume
> - Lancer, inspecter, arrêter et supprimer des conteneurs
> - Écrire un `Dockerfile` et construire sa propre image
> - Orchestrer plusieurs services avec `docker compose`
> - Mettre en place un environnement de développement complet et jetable

## Sommaire

1. [Conteneur ou machine virtuelle ?](#conteneur-ou-machine-virtuelle-)
2. [Installation](#installation)
3. [Les trois concepts de base](#les-trois-concepts-de-base)
4. [Manipuler des conteneurs](#manipuler-des-conteneurs)
5. [Manipuler des images](#manipuler-des-images)
6. [Écrire un Dockerfile](#écrire-un-dockerfile)
7. [Le build multi-étapes](#le-build-multi-étapes)
8. [Construire son image](#construire-son-image)
9. [Docker Compose](#docker-compose)
10. [Un environnement de développement complet](#un-environnement-de-développement-complet)
11. [Les exemples du dépôt](#les-exemples-du-dépôt)
12. [Récapitulatif](#récapitulatif)

---

## Conteneur ou machine virtuelle ?

Une **machine virtuelle** émule un ordinateur complet : elle embarque son propre noyau et son propre système d'exploitation. Un **conteneur** partage le noyau de la machine hôte et n'isole que ce qui est nécessaire (processus, réseau, système de fichiers).

```text
   Machines virtuelles                   Conteneurs

  ┌──────┐ ┌──────┐ ┌──────┐          ┌──────┐ ┌──────┐ ┌──────┐
  │ App  │ │ App  │ │ App  │          │ App  │ │ App  │ │ App  │
  ├──────┤ ├──────┤ ├──────┤          ├──────┴─┴──────┴─┴──────┤
  │ OS   │ │ OS   │ │ OS   │          │    Docker Engine       │
  ├──────┴─┴──────┴─┴──────┤          ├────────────────────────┤
  │      Hyperviseur       │          │   Noyau Linux (hôte)   │
  ├────────────────────────┤          ├────────────────────────┤
  │   Noyau Linux (hôte)   │          │       Matériel         │
  └────────────────────────┘          └────────────────────────┘
```

| | Machine virtuelle | Conteneur |
|---|---|---|
| Démarrage | Dizaines de secondes | Quelques dizaines de ms |
| Poids | Plusieurs Go | Quelques Mo à quelques centaines de Mo |
| Isolation | Forte (noyau séparé) | Bonne, mais noyau **partagé** |
| Usage typique | Héberger des OS différents | Empaqueter une application |

> [!IMPORTANT]
> Un conteneur **n'est pas une petite VM**. C'est un ou plusieurs processus de l'hôte, isolés par deux mécanismes du noyau Linux vus indirectement au [chapitre 05](05_securite.md) : les **namespaces** (ce que le processus voit) et les **cgroups** (ce qu'il a le droit de consommer).
>
> Conséquence directe : sur macOS et Windows, Docker fait tourner une **VM Linux** en arrière-plan, parce qu'il faut bien un noyau Linux quelque part.

---

## Installation

Sur Debian / Ubuntu, via le dépôt officiel :

```bash
# Prérequis
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Clé GPG du dépôt Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Ajout du dépôt
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Vérification :

```bash
docker --version
docker compose version
docker run --rm hello-world
```

### Utiliser Docker sans `sudo`

```bash
sudo usermod -aG docker $USER
```

Il faut ensuite **se déconnecter et se reconnecter** pour que le nouveau groupe soit pris en compte (voir le [chapitre 02.1](02.1_user_management.md)).

> [!CAUTION]
> Le groupe `docker` équivaut à un accès **root** sur la machine : n'importe quel membre peut monter `/` dans un conteneur et modifier tout le système. Ne l'accordez qu'à des utilisateurs à qui vous donneriez déjà `sudo` sans mot de passe. Le [chapitre 08](08_docker_administration.md#le-mode-rootless) présente le mode *rootless*, qui règle ce problème.

> [!NOTE]
> `docker compose` (avec un espace) est le plugin actuel. `docker-compose` (avec un tiret) est l'ancien script Python, encore présent sur beaucoup de machines mais déprécié. Les fichiers `docker-compose.yml`, eux, restent identiques.

---

## Les trois concepts de base

| Concept | Analogie | Description |
|---------|----------|-------------|
| **Image** | Une classe | Un modèle en lecture seule : un système de fichiers + une commande de démarrage |
| **Conteneur** | Une instance | Une exécution d'une image, avec une couche d'écriture par-dessus |
| **Volume** | Un disque externe | Un espace de stockage qui **survit** à la suppression du conteneur |

```text
  Image  ──── docker run ───►  Conteneur  ──── docker commit / build ───►  Image
 (modèle)                      (instance)
```

> [!IMPORTANT]
> **Un conteneur est jetable.** Tout ce qui est écrit dans son système de fichiers disparaît avec lui. Toute donnée à conserver (base de données, fichiers uploadés, logs) doit vivre dans un **volume**.

Une image est identifiée par un **nom** et un **tag** :

```text
postgres:16-alpine
│        │
│        └── tag : la version (par défaut `latest`)
└── nom du dépôt (ici sur Docker Hub)
```

> [!WARNING]
> Le tag `latest` n'a rien de magique : c'est juste le tag par défaut, et il **change** dans le temps. Une image `node:latest` aujourd'hui et dans six mois, ce n'est pas la même chose. En projet, on épingle toujours une version : `node:22-alpine`.

---

## Manipuler des conteneurs

### Lancer un conteneur

```bash
docker run nginx
```

Le terminal reste bloqué : le conteneur tourne au premier plan.

Les options qui reviennent tout le temps :

| Option | Effet |
|--------|-------|
| `-d` | *detached* — tourne en arrière-plan |
| `--name mon-nginx` | Donne un nom au conteneur (sinon Docker en génère un aléatoire) |
| `-p 8080:80` | Publie le port **80 du conteneur** sur le port **8080 de l'hôte** |
| `-v $(pwd):/app` | Monte un dossier de l'hôte dans le conteneur |
| `-e VAR=valeur` | Définit une variable d'environnement |
| `--rm` | Supprime automatiquement le conteneur à l'arrêt |
| `-it` | Mode interactif avec un terminal (pour un shell) |

En pratique :

```bash
docker run -d --name web -p 8080:80 nginx
```

L'application est disponible sur <http://localhost:8080>.

> [!TIP]
> **Le sens du `-p` :** `-p HÔTE:CONTENEUR`. On lit toujours de gauche à droite, de l'extérieur vers l'intérieur. Même logique pour `-v SOURCE_HÔTE:CIBLE_CONTENEUR`.

### Un shell jetable

```bash
docker run -it --rm debian:12 bash
```

C'est exactement l'environnement de bac à sable proposé dans le [README](README.md#-mise-en-place-de-lenvironnement) pour les manipulations de la formation.

### Lister

```bash
# Les conteneurs qui tournent
docker ps

# Tous, y compris ceux qui sont arrêtés
docker ps -a
```

```text
CONTAINER ID   IMAGE     COMMAND                  STATUS         PORTS                  NAMES
a1b2c3d4e5f6   nginx     "/docker-entrypoint.…"   Up 2 minutes   0.0.0.0:8080->80/tcp   web
```

### Piloter

```bash
docker stop web        # arrêt propre (SIGTERM, puis SIGKILL après 10 s)
docker start web       # redémarrage
docker restart web
docker rm web          # suppression (le conteneur doit être arrêté)
docker rm -f web       # arrêt + suppression
```

### Entrer dans un conteneur qui tourne

```bash
docker exec -it web bash
```

Si l'image est basée sur Alpine, `bash` n'existe pas :

```bash
docker exec -it web sh
```

> [!TIP]
> `docker exec` lance un **nouveau** processus dans un conteneur existant. `docker run` crée un **nouveau conteneur**. C'est la confusion n° 1 des débutants.

### Voir ce qui se passe

```bash
docker logs web            # les logs (stdout / stderr du processus principal)
docker logs -f web         # en continu, comme un tail -f
docker logs --tail 50 web  # les 50 dernières lignes
docker stats               # consommation CPU / RAM en temps réel
docker inspect web         # toute la configuration, en JSON
docker top web             # les processus du conteneur
```

> [!IMPORTANT]
> Dans un conteneur, une application ne doit **pas** écrire ses logs dans un fichier : elle les écrit sur la **sortie standard**, et Docker s'occupe du reste. C'est ce qui rend `docker logs` (et tous les outils de centralisation) possibles.

### Copier des fichiers

```bash
docker cp web:/etc/nginx/nginx.conf ./nginx.conf
docker cp ./nginx.conf web:/etc/nginx/nginx.conf
```

---

## Manipuler des images

```bash
docker pull node:22-alpine   # télécharger une image
docker images                # lister les images locales
docker rmi node:22-alpine    # supprimer une image
docker history nginx         # voir les couches d'une image
```

### Les couches (*layers*)

Une image est un **empilement de couches** en lecture seule. Chaque instruction d'un `Dockerfile` crée une couche, et les couches sont **partagées** entre images et mises en cache.

```text
┌──────────────────────────┐  ← couche d'écriture (le conteneur, éphémère)
├──────────────────────────┤
│ CMD ["node", "app.js"]   │  ┐
│ COPY . .                 │  │
│ RUN npm ci               │  ├── l'image (lecture seule)
│ COPY package*.json ./    │  │
│ FROM node:22-alpine      │  ┘
└──────────────────────────┘
```

C'est pour cela que le deuxième `docker build` est quasi instantané : Docker réutilise les couches inchangées. Et c'est aussi pour cela que l'**ordre des instructions compte** — on y revient plus bas.

---

## Écrire un Dockerfile

Le `Dockerfile` est la recette de fabrication de l'image : une suite d'**étapes**, exécutées de haut en bas, dont chacune produit une couche.

> [!TIP]
> Tous les `Dockerfile` de ce chapitre existent en version complète, commentée ligne par ligne et **réellement constructible** dans le dossier [`07_docker/`](07_docker/) du dépôt. Le premier, [`01_simple/Dockerfile`](07_docker/01_simple/Dockerfile), reprend exactement les étapes ci-dessous.

Un exemple pour une petite application Node :

```dockerfile
# --- ÉTAPE 1 · l'image de départ ---
FROM node:22-alpine

# --- ÉTAPE 2 · le dossier de travail (créé s'il n'existe pas) ---
WORKDIR /app

# --- ÉTAPE 3 · les manifestes de dépendances, seuls ---
COPY package.json package-lock.json ./

# --- ÉTAPE 4 · l'installation : cette couche n'est reconstruite
#     que si package.json ou package-lock.json changent ---
RUN npm ci --omit=dev

# --- ÉTAPE 5 · le code source, qui change à chaque commit ---
COPY src/ ./src/

# --- ÉTAPE 6 · la configuration d'exécution ---
ENV NODE_ENV=production
EXPOSE 3000

# --- ÉTAPE 7 · l'utilisateur non privilégié ---
USER node

# --- ÉTAPE 8 · le contrôle de santé ---
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3000/health || exit 1

# --- ÉTAPE 9 · la commande de démarrage ---
CMD ["node", "src/server.js"]
```

Chaque étape produit une couche, visible après le build :

```bash
docker history mon-app:1.0
```

```text
IMAGE          CREATED BY                                      SIZE
a1b2c3d4e5f6   CMD ["node" "src/server.js"]                    0B
<missing>      HEALTHCHECK &{["CMD-SHELL" "wget -qO- http:…     0B
<missing>      USER node                                       0B
<missing>      EXPOSE map[3000/tcp:{}]                         0B
<missing>      ENV NODE_ENV=production                         0B
<missing>      COPY src/ ./src/                                12.4kB
<missing>      RUN npm ci --omit=dev                           4.21MB
<missing>      COPY package.json package-lock.json ./          1.02kB
<missing>      WORKDIR /app                                    0B
<missing>      /bin/sh -c #(nop) ADD file:… in /               142MB
```

Les instructions de **métadonnées** (`ENV`, `EXPOSE`, `USER`, `CMD`, `HEALTHCHECK`) pèsent 0 octet : elles ne font qu'annoter l'image. Seules celles qui **écrivent des fichiers** (`COPY`, `RUN`, `ADD`) coûtent de la place.

### Les instructions à connaître

| Instruction | Rôle |
|-------------|------|
| `FROM` | L'image de base — toujours la première instruction |
| `WORKDIR` | Le répertoire de travail des instructions suivantes |
| `COPY src dst` | Copie depuis le contexte de build vers l'image |
| `ADD` | Comme `COPY`, mais gère les URL et décompresse les archives — **préférez `COPY`** |
| `RUN` | Exécute une commande **pendant la construction** |
| `ENV VAR=valeur` | Variable d'environnement présente dans l'image |
| `ARG VAR` | Variable disponible **uniquement pendant le build** |
| `EXPOSE` | Documente un port (ne le publie pas — c'est `-p` qui le fait) |
| `USER` | L'utilisateur qui exécute la suite |
| `VOLUME` | Déclare un point de montage persistant |
| `CMD` | La commande par défaut, **remplaçable** en ligne de commande |
| `ENTRYPOINT` | L'exécutable du conteneur, **non remplaçable** par défaut |
| `HEALTHCHECK` | La commande qui dit si le conteneur est en bonne santé |

> [!NOTE]
> **`CMD` ou `ENTRYPOINT` ?** Avec `ENTRYPOINT ["ping"]` et `CMD ["localhost"]`, `docker run mon-image google.com` exécute `ping google.com`. `ENTRYPOINT` fixe le programme, `CMD` fournit les arguments par défaut. Pour une application classique, `CMD` seul suffit.

### `.dockerignore`

Comme `.gitignore`, mais pour le contexte de build. Sans lui, tout le dossier est envoyé au démon Docker — y compris `node_modules` et `.git`.

```text
.git
node_modules
dist
*.log
.env
```

> [!WARNING]
> Ne copiez **jamais** de secret (`.env`, clé privée, token) dans une image. Même supprimé par une instruction ultérieure, il reste lisible dans la couche où il a été ajouté. Les secrets se passent à l'exécution, via des variables d'environnement ou un fichier monté.

### L'ordre des instructions

C'est la principale source de builds lents :

```dockerfile
# ❌ Mauvais : le moindre changement dans le code réinstalle toutes les dépendances
COPY . .
RUN npm ci

# ✅ Bon : les dépendances ne sont réinstallées que si package.json change
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
```

**Règle :** du plus stable au plus volatil.

---

## Le build multi-étapes

**Construire** une application et la **faire tourner** ne demandent pas les mêmes outils. Compiler exige un SDK, un compilateur, les dépendances de développement, les sources ; exécuter ne demande souvent qu'un binaire ou quelques fichiers statiques.

Un `Dockerfile` peut contenir **plusieurs `FROM`** : chacun ouvre une nouvelle étape, repartie de zéro. On travaille dans les premières, et on ne garde que la dernière — en y copiant explicitement ce dont on a besoin.

```text
  ÉTAPE 1 « builder »              ÉTAPE 2 « runtime »
 ┌───────────────────────┐        ┌───────────────────────┐
 │ node:22-alpine        │        │ nginx:alpine          │
 │ + npm, node_modules   │        │                       │
 │ + code source         │        │                       │
 │ + /app/dist ──────────┼───────►│ /usr/share/nginx/html │
 └───────────────────────┘ COPY   └───────────────────────┘
       jetée à la fin           --from=builder    l'image livrée
            235 Mo                                   93 Mo
```

> [!IMPORTANT]
> Ce qui n'est pas explicitement copié avec `COPY --from=` **n'existe pas** dans l'image finale. Le compilateur, les sources, les identifiants d'un dépôt privé utilisés pendant le build : tout cela reste dans l'étape intermédiaire, qui n'est jamais publiée.

### Étape par étape

L'exemple complet est dans [`07_docker/02_multistage_node/`](07_docker/02_multistage_node/) :

```dockerfile
# ============ ÉTAPE 1/2 · builder ============
# `AS builder` nomme l'étape pour pouvoir y piocher ensuite.
FROM node:22-alpine AS builder

WORKDIR /app

# 1.a · les dépendances — ici on installe TOUT,
#       devDependencies comprises : on en a besoin pour compiler
COPY package.json package-lock.json ./
RUN npm ci

# 1.b · les sources
COPY build.js ./
COPY src/ ./src/

# 1.c · la compilation : produit /app/dist
RUN npm run build

# ============ ÉTAPE 2/2 · runtime ============
# Nouveau FROM = image neuve. Rien de l'étape 1 ne suit,
# sauf ce que l'on copie explicitement.
FROM nginx:alpine

# 2.a · uniquement le résultat du build
COPY --from=builder /app/dist /usr/share/nginx/html

# 2.b · notre configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
```

```bash
docker build -t demo:02 .

# On peut aussi s'arrêter à une étape, pour l'inspecter ou déboguer
docker build --target builder -t demo:02-builder .
docker images | grep demo
```

```text
demo   02-builder   235MB
demo   02          92.7MB
```

### Trois cas concrets

| Langage | Étape de build | Étape finale | Ce qu'on laisse derrière |
|---------|----------------|--------------|--------------------------|
| **Node → statique** ([exemple 02](07_docker/02_multistage_node/Dockerfile)) | `node:22-alpine` | `nginx:alpine` | Node, npm, `node_modules`, les sources — 235 Mo → 93 Mo |
| **Go** ([exemple 03](07_docker/03_multistage_go/Dockerfile)) | `golang:1.23-alpine` | `scratch` | Toute la chaîne de compilation — il ne reste qu'un binaire de 8 Mo |
| **Python** ([exemple 04](07_docker/04_python/Dockerfile)) | `python:3.12-slim` + `build-essential` | `python:3.12-slim` | `gcc`, les en-têtes de développement, le cache `pip` — 204 Mo au final |

Le cas Go est le plus spectaculaire, parce qu'un binaire statique n'a besoin de **rien** pour tourner :

```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
# CGO_ENABLED=0    → binaire statique, sans dépendance à la libc
# -ldflags "-s -w" → sans table des symboles : binaire plus petit
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/serveur ./main.go

FROM scratch
COPY --from=builder /out/serveur /serveur
USER 65534:65534
ENTRYPOINT ["/serveur"]
```

Environ **8 Mo** au total, contre plus de 300 Mo si l'on livrait l'image `golang` complète.

> [!WARNING]
> `scratch` ne contient **aucun** fichier : ni shell, ni `/etc/passwd`, ni certificats racine. Conséquences concrètes :
> - `docker exec -it … sh` est impossible — le débogage passe uniquement par les logs ;
> - `USER app` échoue (aucun nom d'utilisateur n'existe), il faut donner un **UID numérique** ;
> - tout appel HTTPS sortant échoue tant qu'on n'a pas copié `ca-certificates.crt` depuis une étape intermédiaire.
>
> L'alternative raisonnable : `gcr.io/distroless/static` ou `alpine`, qui gardent le strict minimum.

### Ce que le multi-étapes apporte vraiment

| Bénéfice | Pourquoi |
|----------|----------|
| **Une image plus petite** | Moins à transférer à chaque déploiement, démarrage plus rapide |
| **Moins de vulnérabilités** | Un compilateur absent est un compilateur qui n'a pas de CVE |
| **Pas de fuite de secrets** | Un token de dépôt privé utilisé au build ne quitte pas l'étape où il a servi |
| **Des étapes parallélisables** | BuildKit construit simultanément les étapes indépendantes |
| **Un seul fichier, plusieurs cibles** | `--target dev` ou `--target runtime` — voir ci-dessous |

### Une image de dev et une image de prod, dans le même fichier

C'est le motif utilisé par la stack d'exemple ([`07_docker/05_stack_compose/api/Dockerfile`](07_docker/05_stack_compose/api/Dockerfile)) : une étape `base` commune, puis deux cibles.

```dockerfile
FROM node:22-alpine AS base
WORKDIR /app
COPY package.json package-lock.json ./

# --- cible de développement : outillage complet, rechargement à chaud ---
FROM base AS dev
RUN npm install
COPY src/ ./src/
CMD ["node", "--watch", "src/server.js"]

# --- cible de production : dépendances minimales, utilisateur non root ---
FROM base AS runtime
RUN npm ci --omit=dev && npm cache clean --force
COPY --chown=node:node src/ ./src/
USER node
CMD ["node", "src/server.js"]
```

```bash
docker build --target dev     -t stack-api:dev .
docker build --target runtime -t stack-api:1.0 .
```

En Compose, cela se choisit par service :

```yaml
services:
  api:
    build:
      context: ./api
      target: dev        # `runtime` dans le fichier de surcharge de production
```

---

## Construire son image

```bash
# -t : le nom (tag) de l'image ; le "." final est le contexte de build
docker build -t mon-app:1.0 .
```

```bash
# Lancer l'image construite
docker run -d -p 3000:3000 --name app mon-app:1.0
```

Quelques options utiles :

```bash
docker build -t mon-app:1.0 --no-cache .            # ignorer le cache
docker build -t mon-app:1.0 --target builder .      # s'arrêter à une étape
docker build -t mon-app:1.0 --build-arg VERSION=2 . # passer un ARG
```

> [!TIP]
> Taguez toujours deux fois : une version précise **et** un alias mouvant.
>
> ```bash
> docker build -t mon-app:1.4.2 -t mon-app:latest .
> ```

---

## Docker Compose

Une application réelle, ce n'est jamais un seul conteneur : une API, une base de données, un cache, un reverse proxy… Enchaîner cinq `docker run` avec leurs options n'est pas tenable. **Compose** décrit toute la stack dans un fichier `docker-compose.yml`.

Le fichier présent à la racine de ce dépôt, par exemple :

```yaml
services:
  db:
    image: postgres:12-alpine
    environment:
      POSTGRES_PASSWORD: 1234
      POSTGRES_USER: postgres
      POSTGRES_DB: app
    ports:
      - '5435:5432'
    volumes:
      - ./:/init_db
```

```bash
docker compose up -d
```

Une commande, et la base tourne.

### Un fichier plus complet

```yaml
services:
  api:
    build: .                    # construit à partir du Dockerfile local
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://postgres:1234@db:5432/app
      NODE_ENV: development
    volumes:
      - .:/app                  # le code de l'hôte, monté en direct
      - /app/node_modules       # …sauf node_modules, qui reste celui de l'image
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: 1234
      POSTGRES_DB: app
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5

  cache:
    image: redis:7-alpine

volumes:
  pgdata:
```

Points à retenir sur ce fichier :

- **`build: .`** construit l'image depuis le `Dockerfile` local ; **`image:`** en télécharge une toute faite.
- **Le réseau est automatique** : les services se joignent par leur **nom** (`db`, `cache`). L'API se connecte à `db:5432`, pas à `localhost`.
- **`depends_on` avec `condition`** attend que la base soit réellement *prête*, pas seulement démarrée.
- **`pgdata`** est un volume nommé : les données de la base survivent à `docker compose down`.
- **`- .:/app`** monte le code source en direct : on modifie un fichier sur l'hôte, l'application le voit immédiatement.

> [!IMPORTANT]
> Depuis Compose v2, la clé `version:` en tête de fichier est **obsolète** et ignorée (elle génère même un avertissement). Elle est encore présente dans beaucoup de fichiers, dont celui de ce dépôt.

### Les commandes Compose

| Commande | Effet |
|----------|-------|
| `docker compose up -d` | Démarre toute la stack en arrière-plan |
| `docker compose up -d --build` | …en reconstruisant les images |
| `docker compose down` | Arrête et supprime conteneurs et réseau |
| `docker compose down -v` | …**et les volumes** (donc les données) |
| `docker compose ps` | État des services |
| `docker compose logs -f api` | Suivre les logs d'un service |
| `docker compose exec api sh` | Ouvrir un shell dans un service |
| `docker compose restart api` | Redémarrer un service |
| `docker compose config` | Afficher la configuration finale résolue |

> [!CAUTION]
> `docker compose down -v` **supprime les volumes**, donc les données de votre base. C'est très pratique pour repartir de zéro en développement, et catastrophique ailleurs.

### Les variables d'environnement

Compose lit automatiquement un fichier `.env` situé à côté du `docker-compose.yml` :

```text
POSTGRES_PASSWORD=1234
API_PORT=3000
```

```yaml
services:
  api:
    ports:
      - "${API_PORT}:3000"
  db:
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
```

> [!TIP]
> Versionnez un `.env.example` documentant les variables attendues, et ajoutez `.env` au `.gitignore`.

---

## Un environnement de développement complet

Le scénario type : un nouveau développeur arrive sur le projet et doit être opérationnel en une commande.

```text
mon-projet/
├── docker-compose.yml
├── Dockerfile
├── .dockerignore
├── .env.example
└── src/
```

```bash
git clone git@github.com:org/mon-projet.git
cd mon-projet
cp .env.example .env
docker compose up -d
```

Ni Node, ni PostgreSQL, ni Redis à installer sur la machine — et la même version pour toute l'équipe.

### Les réflexes utiles au quotidien

```bash
# Lancer une commande ponctuelle dans un service
docker compose exec api npm run migrate

# Lancer une commande dans un conteneur jetable
docker compose run --rm api npm test

# Ouvrir un client psql dans la base
docker compose exec db psql -U postgres -d app

# Repartir totalement de zéro
docker compose down -v && docker compose up -d --build
```

> [!TIP]
> Ces commandes sont longues : ce sont des candidates parfaites pour des alias ou des fonctions shell, comme vu au [chapitre 10](10_shell_config.md).
>
> ```bash
> alias dcu='docker compose up -d'
> alias dcd='docker compose down'
> alias dcl='docker compose logs -f'
> dcx() { docker compose exec "$1" "${@:2}"; }
> ```

### Débogage : les trois réflexes

| Symptôme | Commande |
|----------|----------|
| Le conteneur s'arrête tout seul | `docker compose logs api` |
| « Connection refused » vers la base | Vérifier le **nom du service** (`db`, pas `localhost`) |
| Une modification du code n'apparaît pas | Vérifier le montage `-v` / reconstruire l'image |

> [!WARNING]
> `localhost` **dans** un conteneur désigne le conteneur lui-même, pas votre machine. Pour joindre un autre service, on utilise son nom Compose ; pour joindre l'hôte, `host.docker.internal` (ou l'IP de la passerelle sous Linux).

---

## Les exemples du dépôt

Le dossier [`07_docker/`](07_docker/) contient cinq projets autonomes, à construire et à lancer. Chaque `Dockerfile` y est commenté **étape par étape** : c'est la version longue de ce chapitre.

| Dossier | Ce qu'il montre | Pour aller voir |
|---------|-----------------|-----------------|
| [`01_simple/`](07_docker/01_simple/) | Les 9 étapes d'un `Dockerfile`, le `.dockerignore`, le cache des couches | `docker history` après une modification du code |
| [`02_multistage_node/`](07_docker/02_multistage_node/) | Multi-étapes : Node compile, `nginx` sert — 235 Mo → 93 Mo | `docker build --target builder` pour comparer |
| [`03_multistage_go/`](07_docker/03_multistage_go/) | Une image `scratch` de 8 Mo | Tenter un `docker exec … sh` : il n'y a pas de shell |
| [`04_python/`](07_docker/04_python/) | Le `venv` construit dans une étape, copié dans l'autre | Le rôle de `PYTHONUNBUFFERED=1` |
| [`05_stack_compose/`](07_docker/05_stack_compose/) | API + PostgreSQL + Redis, `healthcheck`, `.env`, surcharge de production | L'API joint `db` **par son nom** |

```bash
cd 07_docker/05_stack_compose
cp .env.example .env
docker compose up -d --build
curl http://localhost:3000
```

```json
{
  "message": "API de la stack de démonstration",
  "services": {
    "db":    { "host": "db",    "ip": "172.22.0.2", "joignable": true },
    "cache": { "host": "cache", "joignable": true }
  }
}
```

> [!TIP]
> Le mode d'emploi détaillé de chaque exemple, avec les manipulations à faire pour bien voir ce qui se passe, est dans [`07_docker/README.md`](07_docker/README.md).

---

## Récapitulatif

| Commande | Rôle |
|----------|------|
| `docker run -d -p 8080:80 --name web nginx` | Lancer un conteneur en arrière-plan |
| `docker ps` / `docker ps -a` | Lister les conteneurs actifs / tous |
| `docker logs -f nom` | Suivre les logs d'un conteneur |
| `docker exec -it nom bash` | Ouvrir un shell dans un conteneur qui tourne |
| `docker stop` / `start` / `rm -f` | Piloter et supprimer un conteneur |
| `docker images` / `docker rmi` | Lister / supprimer des images |
| `docker build -t nom:tag .` | Construire une image depuis un `Dockerfile` |
| `docker compose up -d --build` | Démarrer toute la stack |
| `docker compose down -v` | Tout arrêter, **volumes compris** |
| `docker compose exec svc cmd` | Exécuter une commande dans un service |

### Les cinq règles à retenir

> [!TIP]
> 1. **Un conteneur est jetable** — les données vont dans un volume.
> 2. **Une image épingle sa version** — jamais `latest` en projet.
> 3. **Du plus stable au plus volatil** dans le `Dockerfile` — pour le cache.
> 4. **Les logs vont sur stdout**, jamais dans un fichier.
> 5. **Aucun secret dans une image** — ils se passent à l'exécution.

---

⬅️ [Précédent : 06.6 · Fonctions](06_shellscript/06_fonctions/fonctions.md) · 🏠 [Sommaire](README.md) · [Suivant : 08 · Docker pour l'administrateur ➡️](08_docker_administration.md)