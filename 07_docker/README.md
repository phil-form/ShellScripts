# 07 · Exemples Docker

Les fichiers de travail du [chapitre 07 · Docker pour les développeurs](../07_docker.md) et du [chapitre 08 · Docker pour l'administrateur](../08_docker_administration.md).

Chaque dossier est un projet **autonome et constructible** : on s'y place, on construit, on lance. Les `Dockerfile` sont commentés **étape par étape** — c'est le support du cours autant que du code.

| Dossier | Ce qu'il montre | Image finale |
|---------|-----------------|--------------|
| [`01_simple/`](01_simple/) | Un `Dockerfile` mono-étape, les 9 instructions dans l'ordre, `.dockerignore`, `HEALTHCHECK`, `USER` | ~235 Mo |
| [`02_multistage_node/`](02_multistage_node/) | Multi-étapes classique : Node compile, `nginx` sert le résultat | ~93 Mo |
| [`03_multistage_go/`](03_multistage_go/) | Multi-étapes poussé à l'extrême : binaire statique dans une image `scratch` | ~8 Mo |
| [`04_python/`](04_python/) | Multi-étapes Python : le compilateur C reste dans l'étape de build, seul le `venv` est livré | ~204 Mo |
| [`05_stack_compose/`](05_stack_compose/) | Une stack complète API + PostgreSQL + Redis, avec surcharge de production | — |

> [!NOTE]
> Les tailles sont indicatives (linux/amd64) : elles servent à comparer les approches, pas à être reproduites au Mo près.

---

## 01 · Le Dockerfile pas à pas

```bash
cd 01_simple
docker build -t demo:01 .
docker run --rm -p 3000:3000 demo:01
curl http://localhost:3000
```

À observer :

```bash
docker history demo:01          # une couche par instruction
docker inspect demo:01 | less   # les LABEL, l'utilisateur, le HEALTHCHECK
```

Puis modifiez `src/server.js` et reconstruisez : seules les deux dernières couches sont refaites, `npm ci` reste en cache. Inversez ensuite l'ordre du `COPY` et du `RUN npm ci` dans le `Dockerfile` pour constater la différence.

---

## 02 · Le build multi-étapes

```bash
cd 02_multistage_node
docker build -t demo:02 .
docker run --rm -p 8080:80 demo:02
```

Comparez les deux étapes :

```bash
# L'image de construction, avec Node et les sources
docker build --target builder -t demo:02-builder .

docker images | grep demo
```

```text
demo    02-builder   235MB
demo    02          92.7MB
```

---

## 03 · L'image `scratch`

```bash
cd 03_multistage_go
docker build -t demo:03 .
docker run --rm -p 8081:8080 demo:03
curl http://localhost:8081
```

```bash
docker images demo:03
docker exec -it <conteneur> sh   # échoue : il n'y a AUCUN shell dans l'image
```

C'est le compromis : surface d'attaque quasi nulle, mais plus rien pour déboguer depuis l'intérieur.

---

## 04 · Python et son environnement virtuel

```bash
cd 04_python
docker build -t demo:04 .
docker run --rm -p 8000:8000 demo:04
curl http://localhost:8000
```

À retenir : `PYTHONUNBUFFERED=1`, sans quoi les `print` de l'application n'apparaissent pas dans `docker logs`.

---

## 05 · La stack complète

```bash
cd 05_stack_compose
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

L'API joint la base par le **nom du service**, pas par une IP ni par `localhost`.

Les manipulations utiles :

```bash
docker compose ps                      # l'état, avec (healthy)
docker compose logs -f api             # les logs d'un service
docker compose exec db psql -U postgres -d app -c 'TABLE utilisateurs;'
docker compose exec api sh             # un shell dans l'API

# La variante de production : autre cible de build, ressources limitées, durci
docker compose -f docker-compose.yml -f docker-compose.prod.yml config
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Nettoyage :

```bash
docker compose down       # conserve les données
docker compose down -v    # supprime aussi les volumes
```

---

⬅️ [Chapitre 07 · Docker pour les développeurs](../07_docker.md) · 🏠 [Sommaire](../README.md)
