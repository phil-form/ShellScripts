# 🐳 D5 · Docker au quotidien

*Chapitre [07 · Docker pour les développeurs](../../07_docker.md) et les exemples de [`07_docker/`](../../07_docker/)*

> [!NOTE]
> **Objectifs** : manipuler conteneurs, images et volumes, écrire un `Dockerfile` correct, comprendre le cache
> de couches, faire un build multi-étapes, et monter la stack de développement complète avec Compose.

> [!IMPORTANT]
> Ces exercices demandent un **vrai démon Docker** sur votre machine (pas un conteneur Debian jetable).
> Vérifiez d'abord : `docker run --rm hello-world`.

---

## Exercice 5.1 — Premiers conteneurs

1. Lancez un conteneur `nginx` en arrière-plan, nommé `tf-web`, avec le port **8080 de l'hôte** redirigé vers
   le port 80 du conteneur. Vérifiez avec `curl` que la page répond.
2. Listez les conteneurs qui tournent, puis **tous** les conteneurs, arrêtés compris.
3. Affichez les logs de `tf-web`, puis suivez-les en direct pendant que vous rechargez la page.
4. Ouvrez un shell **dans** le conteneur qui tourne et affichez le contenu de `/usr/share/nginx/html`.
5. Copiez un fichier `index.html` de votre machine vers ce dossier dans le conteneur, et vérifiez le résultat
   dans le navigateur.
6. Arrêtez, redémarrez, puis supprimez le conteneur.
7. Lancez un shell **jetable** dans une image `debian:12` qui disparaît en sortant. Quelle option fait ça ?

---

## Exercice 5.2 — Images, couches et nettoyage

1. Listez les images présentes sur votre machine et leur taille.
2. Téléchargez `node:20-alpine` **sans** lancer de conteneur, puis comparez sa taille avec celle de `node:20`.
   Pourquoi cet écart, et quelle en est la contrepartie ?
3. Affichez l'historique des couches de `nginx` — combien y en a-t-il ?
4. Inspectez l'image et retrouvez : la commande de démarrage, les ports exposés, l'utilisateur.
5. Supprimez une image, puis faites le ménage de tout ce qui n'est plus utilisé.
   Quelle est la différence entre `docker system prune` et `docker system prune -a` ?

---

## Exercice 5.3 — Données : volumes et montages

1. Lancez un PostgreSQL (`postgres:16`) avec un mot de passe, en **volume nommé** pour ses données.
2. Créez une table dedans, détruisez le conteneur, relancez-en un neuf sur le même volume :
   vos données sont-elles là ?
3. Refaites l'expérience **sans** volume. Que constatez-vous ?
4. Lancez un conteneur `node:20-alpine` qui **monte votre dossier `api/`** dans `/app` et exécute
   `ls /app`. Quelle est la différence entre un volume nommé et un montage de dossier (*bind mount*),
   et lequel utilise-t-on pour développer avec rechargement à chaud ?
5. Listez les volumes, inspectez-en un, supprimez celui de l'exercice.

---

## Exercice 5.4 — Écrire un `Dockerfile`

Dans `ticketflow/api/`, créez une petite API Node :

```bash
mkdir -p api/src
cat > api/package.json <<'EOF'
{ "name": "ticketflow-api", "version": "1.0.0", "main": "src/server.js",
  "scripts": { "start": "node src/server.js" } }
EOF
cat > api/src/server.js <<'EOF'
const http = require('http');
const port = process.env.PORT || 3000;
http.createServer((req, res) => {
  if (req.url === '/health') { res.writeHead(200); return res.end('ok'); }
  res.writeHead(200, {'Content-Type': 'application/json'});
  res.end(JSON.stringify({ tickets: [] }));
}).listen(port, () => console.log('api on ' + port));
EOF
```

Écrivez `api/Dockerfile` en respectant l'ordre du [chapitre 07](../../07_docker.md#écrire-un-dockerfile) :

1. Partez d'une image Node **alpine** épinglée sur une version précise (jamais `latest` — pourquoi ?).
2. Définissez le dossier de travail `/app`.
3. Copiez **d'abord les manifestes de dépendances seuls**, installez-les, **puis** copiez le code source.
4. Déclarez la variable d'environnement `NODE_ENV=production` et le port exposé.
5. Ajoutez un `HEALTHCHECK` qui interroge `/health`.
6. Faites tourner l'application avec un **utilisateur non root**.
7. Déclarez la commande de démarrage.
8. Écrivez le `.dockerignore` qui va avec (`node_modules`, `.git`, `.env`, `logs`…).
9. Construisez l'image avec le tag `ticketflow/api:1.0.0`, lancez-la sur le port 3000, testez `/health`.

---

## Exercice 5.5 — Le cache de couches

C'est l'exercice qui change vos temps de build.

1. Reconstruisez l'image sans rien modifier : combien de temps ? Que dit la sortie de `docker build` ?
2. Modifiez une ligne de `src/server.js` et reconstruisez. **Quelles couches** sont refaites ?
3. Inversez maintenant l'ordre : copiez tout le code **avant** d'installer les dépendances.
   Reconstruisez après une modification du code. Que se passe-t-il ?
4. Remettez le bon ordre, et expliquez la règle en une phrase.
5. Ajoutez une dépendance dans `package.json` et reconstruisez : quelles couches sont invalidées cette fois ?
6. Comparez avec l'exemple [`07_docker/01_simple/`](../../07_docker/01_simple/) : y a-t-il des étapes que vous
   avez oubliées ?

---

## Exercice 5.6 — Le build multi-étapes

1. Regardez [`07_docker/02_multistage_node/`](../../07_docker/02_multistage_node/) et construisez-le.
   Construisez ensuite **uniquement l'étape `builder`** et comparez les deux tailles d'image.
2. Écrivez un `Dockerfile` multi-étapes pour un front statique : une étape Node qui « compile »
   (une simple copie de `web/public` vers `dist/` suffit), une étape `nginx` qui ne récupère que `dist/`.
3. Vérifiez que l'image finale **ne contient ni Node ni les sources** : ouvrez un shell dedans et cherchez-les.
4. Ajoutez dans le même fichier deux cibles : `dev` (outillage complet, montage du code) et `prod`
   (minimale, utilisateur non root). Construisez chacune avec `--target`.
5. Ouvrez [`07_docker/03_multistage_go/`](../../07_docker/03_multistage_go/) : comment obtient-on une image de
   ~8 Mo ? Pourquoi cette approche est-elle impossible en Node ou en Python ?

---

## Exercice 5.7 — Compose : la stack de dev

Objectif : `docker compose up` et toute l'équipe a le même environnement.

Écrivez `docker/docker-compose.yml` avec trois services :

| Service | Image / build | Détails |
|---------|---------------|---------|
| `api` | construit depuis `../api` | port 3000, dépend de `db`, variables depuis un `.env` |
| `db` | `postgres:16` | volume nommé, utilisateur/mot de passe/base via variables |
| `cache` | `redis:7-alpine` | pas de port exposé sur l'hôte |

1. Écrivez le fichier et lancez la stack en arrière-plan.
2. Affichez l'état des services, puis les logs de `api` uniquement, en direct.
3. Ouvrez un `psql` dans le service `db` et créez une table.
4. Lancez une commande ponctuelle dans le service `api` (par exemple `node -v`) **sans** ouvrir de shell.
5. Ajoutez un montage du code de `api/` pour développer avec rechargement à chaud, et vérifiez qu'une
   modification est prise en compte sans reconstruire l'image.
6. Ajoutez une **dépendance sur l'état de santé** de `db` : l'API ne doit démarrer que quand la base répond.
7. Arrêtez la stack. Quelle commande arrête **et** supprime les volumes ? Dans quel cas ne faut-il surtout
   pas la taper ?
8. Écrivez un `docker-compose.prod.yml` de surcharge qui retire les montages de code et fixe
   `NODE_ENV=production`. Lancez la stack avec les deux fichiers.
   *(Comparez avec [`07_docker/05_stack_compose/`](../../07_docker/05_stack_compose/).)*

---

## Exercice 5.8 — Déboguer

1. Votre conteneur `api` s'arrête immédiatement au démarrage. Citez les **trois** commandes à lancer, dans
   l'ordre, pour comprendre pourquoi.
2. Le port 3000 est « déjà utilisé » : comment trouver qui l'occupe (conteneur ou processus de l'hôte) ?
3. L'API ne joint pas la base avec `localhost:5432` alors que la stack tourne. Pourquoi, et quelle valeur
   faut-il mettre à la place ?
4. Vous avez modifié le `Dockerfile` mais le build semble ignorer votre changement : quelle option force la
   reconstruction sans cache ?
5. Vous voulez inspecter le contenu d'une image dont le conteneur crashe au démarrage : comment ouvrir un
   shell dedans en **remplaçant** sa commande de démarrage ?

---

## ✅ Vérification

- `docker compose up -d` depuis `ticketflow/docker/` monte les trois services, et `curl localhost:3000/health`
  répond `ok`.
- `docker images` montre votre image d'API **et** vous savez expliquer sa taille.
- Une modification de `src/server.js` reconstruit l'image en quelques secondes, pas en quelques minutes.
- L'image de production ne contient ni sources ni outils de build, et ne tourne pas en root.
- Vous savez, sans relire le cours, ce que font `docker compose down`, `down -v` et `down --rmi all`.
