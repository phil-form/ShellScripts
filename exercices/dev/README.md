# 👩‍💻 Parcours développeur — exercices

> Une série d'exercices **sans corrigé**, orientée développement : le terminal, la fouille de code et de logs,
> le strict minimum d'administration qu'un dev utilise tous les jours, le shell scripting, Docker, tmux et la
> configuration de son environnement de travail.
>
> Des chapitres **02 · Permissions**, **02.1 · Utilisateurs** et **04 · Services & cron**, on ne garde ici que
> la part qui sert à un dev qui travaille sous Linux au quotidien (D3) : rendre un script exécutable, réparer
> un fichier appartenant à root, rejoindre le groupe `docker`, installer un paquet, piloter et lire les logs
> du service dont dépend l'application. Le traitement complet de ces chapitres — ainsi que **05 · Sécurité**
> et **08 · Docker administration** — reste dans les jeux d'exercices d'administration du dossier `exercices/`.

---

## 🧵 Le fil rouge — `ticketflow`

Vous venez d'arriver dans l'équipe qui développe **`ticketflow`**, une petite application de gestion de tickets :

```text
ticketflow/
├── api/            # une API Node.js
├── web/            # un front statique
├── scripts/        # les scripts d'outillage de l'équipe — c'est vous qui allez les écrire
├── logs/           # les logs applicatifs
└── docker/         # les images et la stack de dev
```

Le dépôt n'existe pas : **vous le construisez au fil des exercices**. Chaque chapitre part de ce qu'a produit
le précédent, mais chaque fichier reste jouable indépendamment (l'énoncé fournit alors le jeu de données de départ).

---

## 📋 Les exercices

| # | Fichier | Porte sur |
|---|---------|-----------|
| D1 | [Le terminal du dev](01_terminal_du_dev.md) | ch. [01](../../01_base.md) — navigation, fichiers, redirections, heredoc, pipes, processus |
| D2 | [Fouiller le code et les logs](02_fouiller_code_et_logs.md) | ch. [03](../../03_commandes_essentielles.md) — `grep`, `sed`, `awk`, `find`, `xargs`, `tar`, `diff` |
| D3 | [Le minimum d'admin](03_admin_minimal.md) | ch. [02](../../02_file_permissions.md), [02.1](../../02.1_user_management.md) et [04](../../04_installation_et_services.md) — `chmod`, `chown`, groupes, `sudo`, `apt`, `systemctl`, `journalctl`, `cron` |
| D4 | [Shell scripting](04_shell_scripting.md) | ch. [06](../../06_shellscript/) — variables, conditions, boucles, erreurs, arguments, fonctions |
| D5 | [Docker au quotidien](05_docker.md) | ch. [07](../../07_docker.md) — conteneurs, `Dockerfile`, cache de couches, multi-étapes, Compose |
| D6 | [tmux](06_tmux.md) | ch. [09](../../09_tmux.md) — sessions, fenêtres, panneaux |
| D7 | [Son environnement de travail](07_environnement_de_travail.md) | ch. [10](../../10_shell_config.md) et [11](../../11_advanced_config.md) — alias, fonctions, `PATH`, prompt, dotfiles, outils modernes |
| D8 | [Projet final : `tf`](08_projet_final.md) | tout ce qui précède — la CLI d'outillage de l'équipe |

> [!IMPORTANT]
> Ces exercices **n'ont volontairement pas de corrigé**. La compétence visée n'est pas de retrouver *la*
> commande attendue, mais de savoir la chercher : `man`, `--help`, [ExplainShell](https://explainshell.com/),
> [tldr](https://tldr.sh/). Chaque exercice se termine par des **critères de vérification** : si vous les
> remplissez, votre solution est bonne — même si elle ne ressemble pas à celle du voisin.

---

## 🚀 Environnement

Tout se fait sur une VM, un conteneur ou WSL 2 — pas sur votre machine principale (voir le
[README du dépôt](../../README.md#-mise-en-place-de-lenvironnement)).

Un bac à sable suffisant pour D1, D2, D4 et D6 :

```bash
docker run -it --rm --name tf-lab -v "$PWD/ticketflow:/root/ticketflow" debian:12 bash
apt update && apt install -y vim nano tree htop tmux git curl jq
```

> [!NOTE]
> Les exercices **D3** (services, `systemctl`, `journalctl`) demandent une **vraie VM** : un conteneur ne fait
> pas tourner `systemd`. Les exercices **D5 (Docker)** demandent un vrai démon Docker sur la machine hôte.
> Les exercices **D7** se font dans le shell que vous utilisez tous les jours.

---

## ✅ Comment travailler

1. Lisez l'énoncé **en entier** avant de taper quoi que ce soit.
2. Cherchez la commande avant de demander : `man commande`, `commande --help`, `tldr commande`.
3. Faites passer chaque script écrit dans [ShellCheck](https://www.shellcheck.net/) — c'est le linter du shell,
   au même titre qu'ESLint ou Ruff pour vos langages.
4. Versionnez : `git init` dans `ticketflow/` dès le premier exercice, un commit par exercice.
   Vous relirez vos propres diffs, c'est la meilleure relecture.
