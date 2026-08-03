# 🐧 Formation Linux — Administration système & Shell scripting

> Support de formation **BStorm** : les bases de l'administration Linux, puis l'écriture de scripts shell, du premier `pwd` jusqu'à la configuration avancée de son environnement de travail.

---

## 📚 Programme

| # | Chapitre | Contenu |
|---|----------|---------|
| 01 | [Les bases du terminal](01_base.md) | Navigation, fichiers, redirections, éditeurs, processus |
| 02 | [Les permissions](02_file_permissions.md) | POSIX, `chmod`, `chown`, permissions spéciales |
| 02.1 | [Utilisateurs et groupes](02.1_user_management.md) | `useradd`, groupes, mots de passe, `su` / `sudo` |
| 03 | [Commandes essentielles](03_commandes_essentielles.md) | `tree`, `grep`, `sed`, `awk`, `cut` / `sort` / `uniq`, `find`, `xargs`, `du`, `df`, `tar` |
| 04 | [Paquets, services et cron](04_installation_et_services.md) | `apt` / `dnf`, `systemctl`, services custom, `journalctl`, `cron` |
| 05 | [Sécurité](05_securite.md) | ACL, `sudoers`, pare-feu, SSH, AppArmor / SELinux |
| 06 | [**Shell scripting**](#-06--shell-scripting) | *voir le détail ci-dessous* |
| 07 | [Docker — les développeurs](07_docker.md) | Images, conteneurs, volumes, `Dockerfile`, `docker compose` |
| 08 | [Docker — l'administrateur](08_docker_administration.md) | Démon, réseaux, logs, ressources, durcissement, sauvegardes |
| 09 | [tmux](09_tmux.md) | Sessions, fenêtres, panneaux, travail à distance |
| 10 | [Configuration du shell](10_shell_config.md) | `.bashrc`, `.zshrc`, `PATH`, prompt, alias, dotfiles |
| 11 | [Configuration avancée](11_advanced_config.md) | Oh My Zsh, Powerlevel10k, Starship, Oh My Tmux, outils modernes |

### 🐚 06 · Shell scripting

| # | Chapitre | Contenu |
|---|----------|---------|
| 06.1 | [Les bases](06_shellscript/01_Base/base.md) | Shebang, variables, tableaux, `read` |
| 06.2 | [Conditions et opérateurs logiques](06_shellscript/02_operateur_logique/exemple.md) | `if` / `elif` / `else`, tests, `&&`, `\|\|`, `!` |
| 06.3 | [Les boucles](06_shellscript/03_boucles/exemple.md) | `for`, `while`, `until`, lecture de fichier |
| 06.4 | [La gestion des erreurs](06_shellscript/04_gestion_des_erreurs/gestion_des_erreurs.md) | `$?`, `set -euo pipefail`, `trap` |
| 06.5 | [Les arguments](06_shellscript/05_Arguments/args.md) | `$1`, `$@`, `getopts` |
| 06.6 | [Les fonctions](06_shellscript/06_fonctions/fonctions.md) | Déclaration, arguments, `local`, `source` |

---

## ✏️ Exercices

| # | Exercice | Porte sur |
|---|----------|-----------|
| 3 | [Exercice 3](exercices/Exercice3.md) | Arborescence, fichiers, redirections — ch. 01 |
| 4 | [Exercice 4](exercices/Exercice4.md) | Utilisateurs et groupes — ch. 02.1 |
| 5 | [Exercice 5](exercices/Exercice5.md) | `grep`, `find`, `tar` — ch. 03 |
| 6 | [Exercice 6](exercices/Exercice6.md) | Création d'un service systemd — ch. 04 |
| 7 | [Exercice 7](exercices/Exercice7.md) | Tâches `cron` — ch. 04 |
| 8 | [Exercice 8](exercices/Exercice8.md) | `sudoers` et délégation de droits — ch. 05 |
| 9 | [Exercice 9](exercices/Exercice9.md) | SSH et pare-feu — ch. 05 |
| 10 | [Exercice 10](exercices/Exercice10/) | Scripts : conditions et boucles — ch. 06 |
| 11 | [Exercice 11](exercices/Exercices11/) | Scripts : arguments et création d'utilisateurs — ch. 06 |
| 12 | [Exercice 12](exercices/Exercices12/) | Scripts : fonctions et bibliothèque partagée — ch. 06 |

---

## 🗂️ Organisation du dépôt

```text
.
├── 01_base.md … 11_advanced_config.md   # les chapitres de cours
├── 06_shellscript/                      # le module scripting, un dossier par thème
│   └── NN_theme/
│       ├── theme.md                     # le cours
│       └── exemple*.sh                  # les scripts d'exemple, exécutables
├── 07_docker/                           # les projets Docker d'exemple, constructibles
│   └── NN_exemple/
│       ├── Dockerfile                   # commenté étape par étape
│       └── …                            # les sources de l'application
├── exercices/                           # énoncés et corrections
├── exemple/                             # fichiers de travail pour les manipulations
└── docker-compose.yml                   # base PostgreSQL de démonstration
```

---

## 🚀 Mise en place de l'environnement

Toutes les manipulations demandent une machine Linux sur laquelle on peut casser des choses sans conséquence. Trois options :

| Option | Pour qui |
|--------|----------|
| Une **VM** (VirtualBox, UTM, Hyper-V) avec Debian 12 | Le plus proche d'un vrai serveur — **recommandé** |
| Un **conteneur Docker** Debian | Le plus rapide à mettre en place |
| **WSL 2** (Windows) | Confortable, mais `systemd` et les services y sont particuliers |

Un bac à sable jetable en une commande :

```bash
docker run -it --rm --name lab debian:12 bash
```

```bash
# Dans le conteneur, pour disposer des outils du cours
apt update && apt install -y sudo vim nano tree htop cron tmux
```

> [!NOTE]
> Un conteneur ne fait pas tourner `systemd` par défaut : les manipulations `systemctl` du [chapitre 04](04_installation_et_services.md) demandent une vraie VM.
>
> Le `docker-compose.yml` du dépôt n'est **pas** cet environnement de travail : il ne sert qu'à lancer une base PostgreSQL utilisée en démonstration — il est décortiqué au [chapitre 07](07_docker.md#docker-compose).

> [!WARNING]
> **Ne faites jamais les exercices d'administration sur votre machine principale.** Les chapitres 02, 02.1, 04 et 05 manipulent des utilisateurs, des services, un pare-feu et la configuration SSH — autant de choses qui peuvent vous couper l'accès à votre propre système.

---

## 🧭 Conventions du support

| Élément | Signification |
|---------|---------------|
| <code>```bash</code> | Une commande à taper dans le terminal |
| <code>```text</code> | Une sortie de commande ou un extrait de fichier |
| `> [!TIP]` | Une astuce ou une bonne pratique |
| `> [!IMPORTANT]` | Un point à ne pas rater pour comprendre la suite |
| `> [!WARNING]` | Un piège fréquent |
| `> [!CAUTION]` | Une opération destructive ou dangereuse |

Chaque chapitre commence par ses **objectifs** et se termine par un **récapitulatif** des commandes vues.

---

## 🔗 Ressources

- [`man` en ligne](https://man7.org/linux/man-pages/) — le manuel de référence
- [ExplainShell](https://explainshell.com/) — décortique n'importe quelle ligne de commande
- [ShellCheck](https://www.shellcheck.net/) — analyse statique de scripts shell
- [tldr pages](https://tldr.sh/) — des exemples plutôt que des manuels
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) — conventions d'écriture

---

**➡️ Commencer la formation : [01 · Les bases du terminal](01_base.md)**
