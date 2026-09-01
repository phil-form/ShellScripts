# ⚙️ D7 · Son environnement de travail

*Chapitres [10 · Configuration du shell](../../10_shell_config.md) et [11 · Configuration avancée](../../11_advanced_config.md)*

> [!NOTE]
> **Objectifs** : comprendre quel fichier de configuration est chargé et quand, se fabriquer des alias et des
> fonctions utiles, mettre ses propres scripts dans le `PATH`, un prompt qui affiche la branche Git, et
> versionner tout ça pour le réinstaller en une commande sur le serveur suivant.

> [!TIP]
> Ces exercices se font dans **votre** shell de tous les jours. Avant de commencer :
> `cp ~/.bashrc ~/.bashrc.avant-formation` (ou `.zshrc`). On ne modifie pas sa config sans filet.

---

## Exercice 7.1 — Comprendre ce qui est chargé

1. Quel shell utilisez-vous réellement ? Quels shells sont installés sur la machine ?
2. Votre terminal ouvre-t-il un shell **de login** ? un shell **interactif** ? Prouvez-le.
3. Mettez `echo "→ .bashrc chargé"` (adaptez à votre shell) en fin de `~/.bashrc` et en fin de
   `~/.bash_profile` / `~/.profile`. Ouvrez : un nouveau terminal, un `bash -l`, un `ssh localhost`,
   un script. **Notez à chaque fois ce qui s'affiche**, puis expliquez le tableau obtenu.
4. Retirez ces `echo`. Où faut-il mettre un alias ? Où faut-il mettre une modification du `PATH` ? Pourquoi ?
5. Appliquez une modification de configuration **sans fermer votre terminal** — donnez deux façons de faire.

---

## Exercice 7.2 — Des alias qui servent

Ajoutez à votre configuration, puis testez :

1. `ll` — listing détaillé, lisible, fichiers cachés compris.
2. `gs`, `gd`, `gl` — `git status`, `git diff`, un `git log` en une ligne par commit et graphe.
3. `dcu`, `dcd`, `dcl` — `docker compose up -d`, `down`, `logs -f`.
4. `..` et `...` — remonter d'un et de deux niveaux.
5. Sécurisez `rm`, `cp` et `mv` avec une demande de confirmation.
6. Un alias `ports` qui liste les ports en écoute sur la machine.
7. Listez tous vos alias actifs. Comment lancer la **vraie** commande `rm` en ignorant votre alias ?

---

## Exercice 7.3 — Des fonctions, quand l'alias ne suffit plus

1. `mkcd <dossier>` — crée un dossier et s'y déplace.
2. `extract <archive>` — extrait `.tar.gz`, `.tar.bz2`, `.zip` ou `.gz` selon l'extension
   *(un `case` du [chapitre 06.2](../../06_shellscript/02_operateur_logique/exemple.md))*.
3. `backup <fichier>` — copie le fichier en `<fichier>.AAAAMMJJ-HHMMSS.bak`.
4. `dsh <conteneur>` — ouvre un shell dans un conteneur Docker qui tourne.
5. `serve [port]` — sert le dossier courant en HTTP sur le port donné (3000 par défaut).
6. En une phrase : pourquoi `mkcd` **ne peut pas** être un alias ni un script séparé ?

---

## Exercice 7.4 — Le `PATH` et ses propres outils

1. Affichez votre `PATH`, un dossier par ligne (un pipe, chapitre 03).
2. Créez `~/bin`, ajoutez-y un lien vers `ticketflow/scripts/deploy.sh`, et faites en sorte de pouvoir taper
   `deploy.sh` depuis n'importe où.
3. Dans quel fichier faut-il écrire cette modification du `PATH` pour qu'elle survive à une reconnexion ?
4. Ajoutez le dossier **au début** du `PATH` plutôt qu'à la fin. Quelle conséquence si un exécutable du même
   nom existe déjà dans `/usr/bin` ?
5. Vérifiez quel exécutable est réellement pris. `deploy.sh` est-il un binaire, un alias, une fonction ?
6. Écrivez la ligne qui n'ajoute `~/bin` au `PATH` **que s'il n'y est pas déjà** — pour éviter de l'empiler
   à chaque `source ~/.bashrc`.

---

## Exercice 7.5 — Le prompt

1. Affichez la valeur actuelle de votre prompt.
2. Fabriquez un prompt qui affiche `utilisateur@machine:dossier$`, avec l'utilisateur en vert et le dossier en bleu.
3. Ajoutez-y la **branche Git courante**, uniquement quand vous êtes dans un dépôt.
4. Ajoutez un indicateur qui change de couleur selon que la dernière commande a réussi ou échoué
   *(le `$?` du [chapitre 06.4](../../06_shellscript/04_gestion_des_erreurs/gestion_des_erreurs.md))*.
5. Passez le prompt sur deux lignes : les informations sur la première, le curseur sur la seconde.
   Pourquoi est-ce confortable quand on travaille dans des chemins profonds ?

---

## Exercice 7.6 — L'historique

1. Faites en sorte que votre historique conserve 10 000 commandes.
2. Ne conservez pas les doublons, ni les commandes commençant par une espace.
3. Ajoutez la **date et l'heure** à chaque entrée d'historique.
4. Faites en sorte que plusieurs terminaux ouverts **partagent** le même historique sans s'écraser.
5. Retrouvez, dans l'historique, la dernière commande contenant `docker` — d'abord avec `grep`,
   puis avec la recherche incrémentale (`CTRL + r`).
6. Relancez la commande précédente **en root** sans la retaper.

---

## Exercice 7.7 — Confort : les outils modernes

*(Chapitre [11](../../11_advanced_config.md) — choisissez au moins trois des cinq.)*

1. Installez `fzf` et activez la recherche floue dans l'historique (`CTRL + r`). Écrivez une fonction qui
   choisit un conteneur Docker avec `fzf` et ouvre un shell dedans.
2. Installez `zoxide` et remplacez `cd` par son équivalent intelligent.
3. Installez `bat` et `eza` (ou `fd` et `ripgrep`) et alias-ez-les sur `cat` et `ls`.
   Quel piège y a-t-il à écraser `cat` par un alias dans un script ?
4. Installez `starship` et activez-le dans votre shell. Comparez avec le prompt de l'exercice 7.5 :
   qu'avez-vous gagné, qu'avez-vous perdu (portabilité, dépendances, vitesse de démarrage) ?
5. Si vous êtes en zsh : installez Oh My Zsh avec `zsh-autosuggestions` et `zsh-syntax-highlighting`.
6. Mesurez le temps de démarrage de votre shell avant et après. Au-delà de combien devient-il gênant ?

---

## Exercice 7.8 — Ses dotfiles, versionnés

1. Créez un dépôt `~/dotfiles` contenant vos `.bashrc` / `.zshrc`, `.tmux.conf`, `.gitconfig` et votre `~/bin`.
2. Remplacez les fichiers de votre *home* par des **liens symboliques** vers ceux du dépôt. Vérifiez que tout
   fonctionne toujours.
3. Écrivez `install.sh` qui, sur une machine neuve, crée tous ces liens — **sans écraser** un fichier existant
   sans l'avoir sauvegardé au préalable. *(C'est un exercice de scripting complet : arguments, conditions,
   boucles, gestion des erreurs.)*
4. Sortez de vos fichiers versionnés tout ce qui est **propre à une machine** ou **secret** (tokens, chemins
   absolus, configuration d'entreprise) : mettez-le dans un `~/.bashrc.local` chargé en fin de `.bashrc`
   s'il existe, et ignoré par Git.
5. Testez `install.sh` dans un conteneur Debian neuf, en partant de zéro. Combien de temps pour retrouver
   votre environnement ?

---

## ✅ Vérification

- Vous savez dire, pour n'importe quelle ligne de config, **dans quel fichier** elle doit aller et **pourquoi**.
- Un nouveau terminal charge vos alias, vos fonctions, votre `PATH` et votre prompt sans erreur.
- `deploy.sh` est appelable depuis n'importe quel dossier.
- Un `git clone` de vos dotfiles + `./install.sh` reconstruit votre environnement sur une machine neuve.
- Aucun secret n'est parti dans le dépôt de dotfiles.
