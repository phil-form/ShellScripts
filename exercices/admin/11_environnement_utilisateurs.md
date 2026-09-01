# ⚙️ A11 · L'environnement des utilisateurs

*Chapitres [10 · Configuration du shell](../../10_shell_config.md) et [11 · Configuration avancée](../../11_advanced_config.md)*

> [!NOTE]
> **Objectifs** : cesser de configurer chaque *home* à la main. Comprendre quel fichier est lu et quand,
> imposer une configuration à toute la machine, préparer le squelette des nouveaux comptes, et déployer sa
> propre configuration d'administrateur sur un parc de serveurs.

---

## Exercice 11.1 — Qui lit quoi, et quand

1. Quel shell est le shell par défaut sur ce serveur ? Quels shells sont installés ?
2. Établissez le tableau **complet** : pour un shell de login, un shell interactif non-login, un `ssh serveur`,
   un `ssh serveur 'commande'` et un script, **quels fichiers sont lus, dans quel ordre** ?
   Vérifiez-le expérimentalement avec des `echo` temporaires dans chaque fichier, puis retirez-les.
3. Pourquoi une variable définie dans `~/.bashrc` n'est-elle pas vue par une tâche `cron`
   *(chapitre [04](../../04_installation_et_services.md))* ? Et par un `ssh serveur 'commande'` ?
4. Où placez-vous : un alias ? une modification du `PATH` ? une variable nécessaire à un service ?
   Justifiez chaque réponse.
5. Comment appliquer une modification sans fermer sa session — deux méthodes.

---

## Exercice 11.2 — La configuration système

1. Quelle est la différence entre `/etc/profile`, `/etc/profile.d/*.sh`, `/etc/bash.bashrc` et `~/.bashrc` ?
2. Écrivez `/etc/profile.d/ticketflow.sh` qui, **pour tous les utilisateurs** :
   - ajoute `/srv/ticketflow/scripts` au `PATH` ;
   - définit `TICKETFLOW_HOME` ;
   - fixe un `umask` à `027` *(chapitre [02](../../02_file_permissions.md))*.
3. Vérifiez qu'un nouvel utilisateur en hérite, et qu'un utilisateur existant aussi.
4. Écrivez `/etc/profile.d/prompt-root.sh` qui donne un **prompt rouge et explicite** aux sessions root.
   Pourquoi est-ce plus qu'une coquetterie ?
5. Ajoutez une bannière système (`/etc/motd` ou `/etc/issue.net`) rappelant que la machine est en production
   et journalisée. Quelle différence entre les deux fichiers, et lequel s'affiche avant l'authentification ?
6. Une configuration système doit-elle empêcher un utilisateur de la surcharger dans son *home* ?
   Discutez, en distinguant confort et contrainte de sécurité.

---

## Exercice 11.3 — Le squelette des nouveaux comptes

1. Que contient `/etc/skel` ? Ces fichiers s'appliquent-ils aux comptes déjà créés ?
2. Complétez-le : un `.bashrc` avec les alias maison, un `.vimrc` minimal, un `.tmux.conf`, un
   `README-serveur.txt`.
3. Créez un compte de test et vérifiez qu'il hérite de tout, avec les bons droits et le bon propriétaire.
4. Écrivez un script qui applique une nouvelle version du `.bashrc` **à tous les comptes existants**,
   en sauvegardant l'ancien et sans écraser une personnalisation
   *(chapitre [06](../../06_shellscript/) — c'est un exercice de scripting complet)*.
5. Pourquoi un `cp /etc/skel/.bashrc /home/*/` brutal est-il une mauvaise idée ? Citez trois problèmes.

---

## Exercice 11.4 — Alias et fonctions de l'administrateur

Écrivez-les dans **votre** configuration, puis décidez lesquelles méritent d'aller dans `/etc/profile.d`.

1. `ll`, `..`, `...`, et la sécurisation de `rm`, `cp`, `mv`.
2. `ports` — les ports en écoute avec le processus associé.
3. `failed` — les services en échec.
4. `logsvc <service>` — suit les logs d'un service.
5. `psg <motif>` — cherche un processus.
6. `bigfiles [chemin]` — les 10 plus gros fichiers d'un chemin.
7. `backup <fichier>` — copie horodatée d'un fichier avant modification. Pourquoi celle-ci **doit** être
   une fonction et non un alias ?
8. Comment lancer la **vraie** commande `rm` en contournant votre alias sécurisé ?

---

## Exercice 11.5 — `PATH`, historique et confort

1. Affichez le `PATH`, un dossier par ligne. Le `PATH` de `root` est-il le même que le vôtre ? Pourquoi ?
2. Ajoutez `/srv/ticketflow/scripts` au `PATH`, **uniquement s'il n'y est pas déjà**, de façon permanente.
3. Faut-il l'ajouter au début ou à la fin ? Quel risque dans chaque cas ?
4. Configurez l'historique : 10 000 entrées, pas de doublons, **horodatage**, partage entre plusieurs
   terminaux. Pourquoi l'horodatage de l'historique est-il utile après un incident ?
5. Faites en sorte que l'historique de `root` soit lui aussi horodaté et conservé. Est-ce une bonne
   pratique de sécurité, ou un risque ? Discutez.
6. Retrouvez dans l'historique la dernière commande contenant `systemctl` — avec `grep`, puis avec `CTRL+r`.

---

## Exercice 11.6 — Sa configuration, sur tout le parc

1. Créez un dépôt `dotfiles-admin` contenant votre `.bashrc`, `.vimrc`, `.tmux.conf`, `.ssh/config`
   *(sans clés ni secrets !)* et vos scripts.
2. Remplacez les fichiers de votre *home* par des **liens symboliques** vers le dépôt.
3. Écrivez `install.sh` : il crée les liens, **sauvegarde** tout fichier existant avant de le remplacer,
   est idempotent, et dispose d'un `--dry-run`.
4. Sortez du dépôt tout ce qui est propre à une machine ou confidentiel : chargez-le depuis un
   `~/.bashrc.local` s'il existe, ignoré par Git.
5. Déployez votre configuration sur une seconde VM en une commande. Chronométrez.
6. Comparez trois approches — un dépôt + script, GNU Stow, un outil de gestion de configuration
   (Ansible) — et dites laquelle vous choisiriez pour 2 serveurs, pour 20, pour 200.
7. *(Bonus)* Installez `fzf` et `tmux` avec votre configuration, et écrivez une fonction qui choisit un
   service systemd avec `fzf` pour le redémarrer.

> [!WARNING]
> Sur un serveur de production, chaque outil ajouté est une dépendance de plus à maintenir et une surface
> d'attaque de plus. La configuration d'un serveur n'est pas celle d'un poste de travail :
> justifiez chaque ajout.

---

## ✅ Vérification

- Un nouveau compte créé aujourd'hui hérite automatiquement du `PATH`, du `umask`, des alias et des fichiers
  de `/etc/skel`, sans intervention manuelle.
- Une session root est visuellement impossible à confondre avec une session normale.
- `install.sh` reconstruit votre environnement d'administrateur sur une VM neuve, sans écraser quoi que ce
  soit sans sauvegarde.
- Aucun secret ni aucune clé privée n'est parti dans le dépôt de dotfiles.
- Vous savez dire, pour n'importe quelle ligne de configuration, **dans quel fichier** elle doit vivre
  et **pourquoi**.
