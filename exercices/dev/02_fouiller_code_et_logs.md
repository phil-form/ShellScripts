# 🔎 D2 · Fouiller le code et les logs

*Chapitre [03 · Commandes essentielles](../../03_commandes_essentielles.md)*

> [!NOTE]
> **Objectifs** : retrouver une aiguille dans une base de code, refactorer en masse avec `sed`, analyser un
> log d'accès avec `awk`, trouver des fichiers avec `find`, enchaîner avec `xargs`, archiver, comparer.
> Autrement dit : ce que votre IDE fait à votre place, mais en SSH sur un serveur où il n'y a pas d'IDE.

---

## 🧰 Jeu de données

Depuis `ticketflow/`, exécutez ce bloc — il pose le code et les logs sur lesquels tout le chapitre travaille :

```bash
mkdir -p api/src api/tests web/public logs archives conf node_modules/express

cat > api/src/server.js <<'EOF'
const express = require('express');
const { getTickets } = require('./db');
const app = express();
const API_URL = 'http://localhost:3000';

app.get('/tickets', async (req, res) => {
  console.log('GET /tickets');
  res.json(await getTickets());
});

// TODO: gérer la pagination
app.listen(3000, () => console.log('API up on ' + API_URL));
EOF

cat > api/src/db.js <<'EOF'
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function getTickets() {
  console.log('query tickets');
  const r = await pool.query('SELECT * FROM tickets');
  return r.rows;
}

// FIXME: pas de gestion d'erreur ici
module.exports = { getTickets };
EOF

cat > api/tests/db.test.js <<'EOF'
const { getTickets } = require('../src/db');
test('getTickets renvoie un tableau', async () => {
  const API_URL = 'http://localhost:3000';
  expect(Array.isArray(await getTickets())).toBe(true);
});
EOF

cat > web/public/app.js <<'EOF'
const API_URL = 'http://localhost:3000';
fetch(API_URL + '/tickets').then(r => r.json()).then(console.log);
// TODO: afficher une erreur si l'API ne répond pas
EOF

cat > conf/app.conf <<'EOF'
host = localhost
port = 3000
#debug = true

log_level = debug
EOF

cat > logs/app.log <<'EOF'
2024-03-01T09:00:01Z INFO  boot api version=1.4.2
2024-03-01T09:00:02Z INFO  db connected pool=10
2024-03-01T09:04:11Z WARN  slow query duration=1450ms route=/tickets
2024-03-01T09:05:00Z ERROR unhandled rejection route=/tickets code=500
2024-03-01T09:06:31Z INFO  GET /health 200
2024-03-01T09:12:02Z ERROR db timeout route=/tickets code=500
2024-03-01T09:13:45Z WARN  slow query duration=980ms route=/search
2024-03-01T09:20:00Z INFO  GET /health 200
EOF

cat > logs/access.log <<'EOF'
10.0.0.5 - GET /tickets 200 120
10.0.0.5 - GET /tickets 200 95
192.168.1.31 - POST /tickets 201 340
10.0.0.5 - GET /tickets 500 1450
203.0.113.9 - GET /admin 404 12
192.168.1.31 - GET /health 200 4
10.0.0.5 - GET /search 500 980
203.0.113.9 - GET /admin 404 11
192.168.1.31 - PUT /tickets/7 200 210
EOF

head -c 3M /dev/zero > node_modules/express/bundle.js
touch api/src/.DS_Store logs/debug.tmp web/public/index.html
```

---

## Exercice 2.1 — Voir la forme du projet

1. Affichez l'arborescence de `ticketflow/` limitée à **2 niveaux**.
2. Affichez-la **sans** le dossier `node_modules` — la question que se pose tout dev JS.
3. Affichez uniquement les **dossiers**.
4. Affichez l'arborescence avec la **taille** de chaque fichier.

---

## Exercice 2.2 — `grep`, la recherche dans le code

1. Trouvez toutes les lignes contenant `API_URL` dans tout le projet, **récursivement**, avec le
   **nom du fichier et le numéro de ligne**.
2. Refaites la recherche en excluant `node_modules`.
3. Listez **uniquement les noms des fichiers** qui contiennent `console.log`.
4. Trouvez tous les `TODO` **et** les `FIXME` en une seule commande. *(Indice : une expression régulière étendue.)*
5. Affichez les lignes contenant `error`, **quelle que soit la casse**.
6. Affichez chaque occurrence de `getTickets` avec les **2 lignes de contexte** avant et après.
7. Comptez le nombre de lignes contenant `console.log` dans `api/`.
8. Affichez toutes les lignes de `conf/app.conf` qui ne sont **ni vides ni commentées**.
   *(Un classique pour lire une config de 400 lignes.)*

---

## Exercice 2.3 — `sed`, le refactor en masse

Le port de l'API passe de `3000` à `8080`, et l'URL de base devient une variable d'environnement.

1. Affichez à l'écran `api/src/server.js` avec `3000` remplacé par `8080` — **sans** toucher au fichier.
2. Faites réellement le remplacement dans **tous** les fichiers `.js` de `api/` et `web/`, en gardant une
   **sauvegarde `.bak`** de chaque fichier modifié.
3. Dans `conf/app.conf`, **décommentez** la ligne `debug`.
4. Dans `conf/app.conf`, **commentez** la ligne qui commence par `log_level`.
5. En une seule commande `sed`, supprimez de `conf/app.conf` les lignes vides **et** les lignes commentées.
6. Remplacez `http://localhost:3000` par `https://api.ticketflow.be` dans `web/public/app.js`.
   *(Attention aux `/` de l'URL : changez le séparateur de `sed`.)*
7. Affichez uniquement les lignes 3 à 6 de `api/src/db.js`.

> [!CAUTION]
> Avant tout `sed -i`, lancez la commande **sans** `-i` : `sed` écrase sans confirmation et sans `undo`.
> Sur un dépôt versionné, votre vrai filet de sécurité s'appelle `git diff`.

---

## Exercice 2.4 — `awk`, l'analyse de logs

Sur `logs/access.log` (colonnes : IP, `-`, méthode, chemin, code HTTP, durée en ms) :

1. Affichez uniquement les **adresses IP**.
2. Affichez le **chemin et la durée** des requêtes dont la durée dépasse **500 ms**.
3. Affichez l'**IP et le chemin** des requêtes en erreur (code ≥ 400).
4. Produisez le **top des IP** par nombre de requêtes, de la plus active à la moins active.
5. Comptez le **nombre de requêtes par méthode HTTP**, dans un bloc `END`.
6. Calculez la **durée moyenne** de toutes les requêtes.
7. Sur `logs/app.log`, affichez le nombre de lignes par **niveau de log** (`INFO`, `WARN`, `ERROR`).
8. Affichez, pour chaque ligne `ERROR` de `logs/app.log`, uniquement **l'heure et la route**.

---

## Exercice 2.5 — `cut`, `sort`, `uniq`, `wc`, `tr`

1. Avec `cut`, extrayez la liste des **codes HTTP** de `access.log`.
2. Affichez cette liste **triée, dédoublonnée, avec le nombre d'occurrences de chacun**.
3. Combien de requêtes distinctes d'IP le log contient-il ? (une seule ligne)
4. Extrayez la liste des **routes** appelées, triée et sans doublon.
5. Mettez le contenu de `conf/app.conf` en majuscules avec `tr`.
6. `docker ps` (ou `ps aux`) aligne ses colonnes avec des espaces multiples. Compressez ces espaces avec
   `tr -s` puis extrayez deux colonnes avec `cut`. Pourquoi `awk` fait-il ça mieux ?

---

## Exercice 2.6 — `find`, retrouver des fichiers

Depuis `ticketflow/` :

1. Trouvez tous les fichiers `.js`, **sans** ceux de `node_modules`.
2. Trouvez tous les fichiers de **test** (nom contenant `.test.`).
3. Trouvez les fichiers de plus de **1 Mo** — qui est le coupable ?
4. Trouvez les fichiers modifiés il y a **moins d'une heure**.
5. Trouvez les fichiers cachés parasites (`.DS_Store`) et supprimez-les.
6. Trouvez tous les `.bak` créés à l'exercice 2.3 et affichez leur détail avec `-exec ls -lh`.
7. Supprimez tous les fichiers `.tmp` du projet.
8. Trouvez les fichiers **vides**.

---

## Exercice 2.7 — `xargs`, enchaîner les résultats

1. Cherchez le mot `require` **uniquement dans les fichiers `.js`** de `api/`, en combinant `find` et `xargs grep`.
2. Copiez tous les fichiers `.js` de `api/src` vers `archives/js/` (à créer) avec `xargs -I {}`.
3. Comptez le nombre total de lignes de code de tous les `.js` du projet (hors `node_modules`)
   en enchaînant `find` et `wc -l`.
4. Un fichier nommé `mon composant.js` (avec une espace) casse un `find … | xargs rm` naïf.
   Créez-en un, constatez la casse, puis écrivez la version **robuste**.
5. Supprimez tous les `.bak` du projet avec la version robuste.

---

## Exercice 2.8 — Poids et archives

1. Affichez le poids de chaque sous-dossier de `ticketflow/`, sur **un seul niveau**, en lisible.
2. Classez-les du **plus lourd au plus léger**.
3. Affichez l'espace disponible sur vos partitions.
4. Créez une archive compressée `archives/api-src.tar.gz` du dossier `api/src`.
5. **Listez** son contenu sans l'extraire.
6. Extrayez-la dans `archives/restore/` (à créer).
7. Créez une archive `archives/code.tar.gz` contenant **exactement** les fichiers `.js` trouvés par `find`
   (hors `node_modules`). *(Indice : `tar … -T -`.)*
8. Créez une archive du projet en **excluant** `node_modules/` et `logs/`.

---

## Exercice 2.9 — Les utilitaires qui sauvent la journée

1. Comparez `api/src/server.js` et sa sauvegarde `.bak` avec `diff`, en version lisible avec du contexte.
2. Écrivez la sortie de `du -sh *` **à l'écran et** dans `logs/poids.txt`, en une seule commande.
3. Affichez le **vrai type** de `node_modules/express/bundle.js`. L'extension dit-elle la vérité ?
4. Affichez la date de dernière modification de `api/src/db.js` avec `stat`.
5. `npm` est-il un binaire, un alias ou une fonction ? Où se trouve son exécutable ?
6. *(À décrire, pas à laisser tourner)* : quelle commande réafficherait toutes les 2 secondes le nombre de
   lignes `ERROR` du log, en surlignant ce qui change ?

---

## Exercice 2.10 — Tout combiner

Une ligne de commande par question, pipes autorisés (et attendus).

1. Le **top 3 des routes** qui renvoient une erreur 500 dans `access.log`.
2. Le nombre de `TODO` et `FIXME` restants dans le code, hors `node_modules`.
3. La liste des fichiers `.js` contenant un `console.log`, triée par nombre d'occurrences décroissant.
4. Une archive `archives/incident.tar.gz` contenant tous les fichiers de `logs/` qui contiennent au moins
   une ligne `ERROR`.
5. La durée moyenne des requêtes, **par route**, triée de la plus lente à la plus rapide.

---

## ✅ Vérification

- Vous savez retrouver n'importe quelle chaîne dans un dépôt **sans ouvrir d'IDE**.
- Vous n'avez plus aucun `.bak`, `.tmp` ni `.DS_Store` dans `ticketflow/`.
- `archives/` contient `api-src.tar.gz`, `code.tar.gz`, `incident.tar.gz` et le dossier `restore/`.
- Vous savez dire, pour chacune de vos lignes de l'exercice 2.10, **ce que fait chaque étage du pipe**.
- Vous savez pourquoi on relit toujours un `sed` avant de lui donner `-i`.
