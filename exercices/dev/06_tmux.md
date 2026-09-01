# 🪟 D6 · tmux

*Chapitre [09 · tmux](../../09_tmux.md)*

> [!NOTE]
> **Objectifs** : garder une session de travail vivante malgré une déconnexion SSH, découper son terminal
> pour voir tourner l'API, les logs et les tests en même temps, et retrouver son environnement au retour.

> [!TIP]
> Le préfixe par défaut est `CTRL + b`. Dans tout ce qui suit, « préfixe » signifie : appuyer sur `CTRL + b`,
> **relâcher**, puis appuyer sur la touche indiquée.

---

## Exercice 6.1 — Sessions

1. Installez tmux, puis démarrez une session **nommée** `ticketflow`.
2. Détachez-vous de la session **sans la fermer**, puis vérifiez qu'elle tourne toujours dans la liste des sessions.
3. Rejoignez-la.
4. Créez une seconde session nommée `scratch`, listez les deux, puis basculez de l'une à l'autre **sans
   passer par le shell**.
5. Renommez `scratch` en `tests`.
6. Détruisez la session `tests` depuis la ligne de commande, sans y entrer.
7. Vous êtes en SSH sur un serveur, votre connexion tombe pendant un build de 20 minutes. Que se passe-t-il
   selon que vous ayez lancé le build dans tmux ou non ?

---

## Exercice 6.2 — Panneaux

Objectif : reproduire ce poste de travail dans la session `ticketflow`.

```text
┌───────────────────────┬───────────────────────┐
│  éditeur (vim)        │  logs de l'API        │
│                       │  (tail -f)            │
│                       ├───────────────────────┤
│                       │  shell libre          │
└───────────────────────┴───────────────────────┘
```

1. Découpez le terminal **verticalement** (deux colonnes).
2. Dans la colonne de droite, découpez **horizontalement**.
3. Déplacez-vous d'un panneau à l'autre, dans les quatre directions.
4. Agrandissez le panneau de gauche.
5. Mettez le panneau des logs en **plein écran** (zoom), puis revenez à la disposition normale.
6. Fermez le panneau du bas, puis recréez-le.
7. Affichez le **numéro** de chaque panneau à l'écran.

---

## Exercice 6.3 — Fenêtres

1. Créez une nouvelle fenêtre et renommez-la `api`.
2. Créez-en deux autres : `db` et `git`.
3. Passez de l'une à l'autre par leur **numéro**, puis avec les raccourcis « suivante / précédente ».
4. Listez toutes les fenêtres et choisissez-en une dans la liste.
5. Fermez la fenêtre `git`.
6. Quand utilise-t-on une **fenêtre** plutôt qu'un **panneau** ? (une phrase)

---

## Exercice 6.4 — Naviguer et copier

1. Lancez une commande produisant beaucoup de sortie (par exemple `seq 1 5000`), puis **remontez** dans
   l'historique du panneau. Quel mode faut-il activer ?
2. Recherchez le mot `4242` dans cet historique.
3. Sélectionnez quelques lignes, copiez-les, et collez-les dans un autre panneau.
4. Sortez du mode copie.
5. Comment activer la souris (sélection, redimensionnement, molette) ?
   *(Voir aussi le [chapitre 11](../../11_advanced_config.md#oh-my-tmux).)*

---

## Exercice 6.5 — Sa session de travail en une commande

1. Écrivez `scripts/dev-session.sh` qui, en une exécution :
   - crée (ou rejoint, si elle existe déjà) une session `ticketflow` ;
   - ouvre une fenêtre `api` avec deux panneaux : l'un lançant la stack Docker, l'autre suivant ses logs ;
   - ouvre une fenêtre `code` positionnée dans `api/src` ;
   - s'attache à la session à la fin.
2. Le script doit être **idempotent** : le relancer deux fois ne doit pas créer deux sessions ni dupliquer
   les fenêtres. *(Indice : `tmux has-session` et son code de retour, vu au [chapitre 06.4](../../06_shellscript/04_gestion_des_erreurs/gestion_des_erreurs.md).)*
3. Ajoutez une option `-k` qui détruit la session au lieu de l'ouvrir *(chapitre [06.5](../../06_shellscript/05_Arguments/args.md))*.

---

## ✅ Vérification

- Vous pouvez fermer brutalement votre terminal et retrouver votre travail exactement où il était.
- Vous découpez, naviguez et zoomez sans regarder l'aide-mémoire.
- `./scripts/dev-session.sh` vous dépose dans un environnement de travail complet, deux fois de suite,
  sans rien casser.
