# 💻 D1 · Le terminal du dev

*Chapitre [01 · Les bases du terminal](../../01_base.md)*

> [!NOTE]
> **Objectifs** : poser un projet à la main, manipuler fichiers et dossiers sans quitter le clavier, rediriger
> les sorties d'un build, écrire un fichier de configuration en une fois, chaîner avec des pipes, et reprendre
> la main sur un processus qui bloque un port.

> [!TIP]
> Tout se passe dans votre *home*. À la fin de l'exercice, `ticketflow/` sera votre dossier de travail pour
> toute la suite du parcours.

---

## Exercice 1.1 — Poser le projet

Créez l'arborescence suivante :

```text
ticketflow/
├── api/
│   ├── src/
│   └── tests/
├── web/
│   └── public/
├── scripts/
├── logs/
└── docker/
```

1. Créez-la en **une seule commande**.
2. Placez-vous dans `ticketflow/api/src` et affichez le chemin absolu où vous êtes.
3. Depuis là, revenez dans `ticketflow/web/public` **sans** repasser par votre home et **sans** taper de chemin absolu.
4. Revenez à votre home avec un `cd` sans argument, puis retournez au dossier précédent avec un `cd -`.
5. Affichez le contenu complet de `ticketflow/`, fichiers cachés compris, en format détaillé, tailles lisibles.

---

## Exercice 1.2 — Les fichiers du projet

1. Dans `api/src`, créez d'un coup `server.js`, `db.js` et `routes.js`.
2. Dans `api/`, créez `package.json` et `.env.example`.
3. Copiez `.env.example` en `.env` — c'est le fichier que chaque dev remplit sur sa machine.
4. Renommez `routes.js` en `router.js`.
5. Copiez tout le dossier `api/src` en `api/src_old` (attention : c'est un dossier, pas un fichier).
6. Supprimez `api/src_old` et son contenu.
7. Créez un `.gitignore` à la racine du projet contenant `.env`, `node_modules/` et `logs/`.
   *(Une seule commande, sans éditeur.)*

> [!WARNING]
> `rm -rf` ne demande jamais confirmation et ne met rien à la corbeille. Avant de le lancer, prenez
> l'habitude de faire tourner la même commande avec `ls` à la place de `rm -rf`.

---

## Exercice 1.3 — Rediriger la sortie d'un build

On simule une commande de build qui écrit à la fois sur la sortie standard et sur la sortie d'erreur :

```bash
build() {
  echo "compilation de src/server.js"
  echo "compilation de src/db.js"
  echo "ERREUR: module 'pg' introuvable" >&2
  return 1
}
```

*(Collez cette fonction dans votre shell, elle ne survivra pas à la fermeture du terminal — c'est voulu.)*

1. Lancez `build` en envoyant **uniquement la sortie standard** dans `logs/build.log`.
   Que reste-t-il affiché à l'écran ?
2. Lancez `build` en envoyant **uniquement les erreurs** dans `logs/build-errors.log`.
3. Lancez `build` en envoyant **les deux flux** dans `logs/build-full.log`, sans écraser ce qui s'y trouve déjà.
4. Lancez `build` en jetant **complètement** sa sortie (les deux flux) — sans créer aucun fichier.
5. Affichez le contenu des trois fichiers de logs produits, chacun précédé de son nom.

---

## Exercice 1.4 — Écrire un fichier de configuration d'un coup

Avec un **heredoc**, écrivez en une seule commande le fichier `api/.env.example` :

```ini
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://ticketflow:secret@localhost:5432/ticketflow
REDIS_URL=redis://localhost:6379
LOG_LEVEL=debug
```

1. Écrivez-le tel quel.
2. Refaites l'opération avec une variable `PORT_LOCAL=4000` définie dans votre shell, de façon que la ligne
   `PORT=` reprenne **la valeur de la variable**.
3. Refaites-la une troisième fois de façon que `$PORT_LOCAL` apparaisse **littéralement** dans le fichier,
   sans être remplacé. *(Indice : la façon dont on écrit le mot-clé du heredoc change tout.)*

> [!IMPORTANT]
> Cette différence entre `<<EOF` et `<<'EOF'` est exactement celle qui vous mordra le jour où vous
> générerez un fichier de configuration contenant des `$`.

---

## Exercice 1.5 — Lire un fichier de log

Générez un log de travail :

```bash
seq 1 500 | sed 's/^/requete /' > logs/access.log
```

1. Affichez les **20 premières** lignes.
2. Affichez les **15 dernières** lignes.
3. Affichez le fichier page par page, avec la possibilité de remonter.
4. Affichez le fichier **numéroté**.
5. Suivez le fichier **en direct** : dans un second terminal, ajoutez-y une ligne et vérifiez qu'elle s'affiche
   toute seule. *(C'est le réflexe de base pour regarder tourner une appli.)*

---

## Exercice 1.6 — Chaîner avec des pipes

1. Comptez le nombre de lignes de `logs/access.log`.
2. Comptez le nombre de fichiers et dossiers directement contenus dans `ticketflow/`.
3. Affichez les **5 premières** lignes de `ls -l ticketflow/api/src` sans créer de fichier intermédiaire.
4. Affichez la liste triée par **ordre alphabétique inverse** des fichiers de `api/src`.
5. Écrivez une ligne qui affiche à l'écran **et** enregistre dans `logs/inventaire.txt` la liste détaillée
   du projet. *(Indice : une commande du chapitre 03 sert exactement à ça — cherchez-la, on la reverra en D2.)*

---

## Exercice 1.7 — Le processus qui squatte le port

Le scénario le plus fréquent d'une journée de dev : « le port 3000 est déjà utilisé ».

1. Lancez en **arrière-plan** une commande qui dort 600 secondes.
2. Retrouvez son PID dans la liste des processus, en filtrant avec un pipe.
3. Arrêtez-la **proprement** à partir de son PID.
4. Relancez-en une, puis arrêtez-la cette fois **par son nom** plutôt que par son PID.
5. Lancez une commande longue en **premier plan**, suspendez-la sans la tuer, renvoyez-la en arrière-plan,
   puis ramenez-la au premier plan. *(Indice : `CTRL+Z`, puis deux commandes intégrées du shell.)*
6. Quelle est la différence entre le signal envoyé par défaut et `kill -9` ? Dans quel cas un dev doit-il
   se méfier de `kill -9` sur son serveur applicatif ?

---

## Exercice 1.8 — L'éditeur, sans souris

1. Ouvrez `api/src/server.js` dans **nano**, écrivez trois lignes, enregistrez, quittez.
2. Ouvrez le même fichier dans **vim**, ajoutez une ligne au début, enregistrez et quittez.
3. Dans vim : allez à la dernière ligne du fichier, supprimez-la, annulez la suppression, puis quittez
   **sans enregistrer**.
4. Vous ouvrez un fichier en lecture seule et vous êtes bloqué dans vim. Quelle est la commande pour sortir
   sans rien casser ?

> [!TIP]
> Vous n'avez pas besoin d'aimer vim. Vous avez besoin d'en sortir : sur un serveur, `git commit` ou
> `crontab -e` vous y déposeront sans prévenir.

---

## ✅ Vérification

Vous avez terminé D1 si :

- `tree ticketflow/` (ou `ls -R`) montre l'arborescence complète de l'exercice 1.1 ;
- `ticketflow/.gitignore` et `api/.env.example` existent et ont le bon contenu ;
- `logs/` contient `build.log`, `build-errors.log`, `build-full.log` et `access.log`, chacun avec **exactement**
  ce que la redirection demandée devait y mettre ;
- vous savez expliquer, sans relire le cours, la différence entre `>`, `>>`, `2>` et `&>` ;
- plus aucun `sleep` ne tourne dans votre liste de processus.
