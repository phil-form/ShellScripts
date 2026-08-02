# 10 · Configuration du shell (`.bashrc`, `.zshrc`, …)

> [!NOTE]
> **Objectifs du chapitre**
> - Savoir quel shell on utilise et comment en changer
> - Comprendre la différence entre shell **de login** et shell **interactif**
> - Savoir **quel fichier** modifier, et pourquoi
> - Créer des alias, des fonctions et des variables d'environnement persistants
> - Personnaliser son `PATH`, son prompt et son historique
> - Organiser et versionner ses fichiers de configuration (*dotfiles*)

## Sommaire

1. [Quel shell est-ce que j'utilise ?](#quel-shell-est-ce-que-jutilise-)
2. [Login, interactif : comprendre les quatre cas](#login-interactif--comprendre-les-quatre-cas)
3. [Quel fichier est chargé, et quand ?](#quel-fichier-est-chargé-et-quand-)
4. [Où dois-je mettre ma configuration ?](#où-dois-je-mettre-ma-configuration-)
5. [Appliquer ses modifications](#appliquer-ses-modifications)
6. [Les alias](#les-alias)
7. [Les fonctions](#les-fonctions)
8. [Les variables d'environnement](#les-variables-denvironnement)
9. [Le PATH](#le-path)
10. [Personnaliser le prompt](#personnaliser-le-prompt)
11. [Maîtriser l'historique](#maîtriser-lhistorique)
12. [Options du shell](#options-du-shell)
13. [Configuration système et /etc/skel](#configuration-système-et-etcskel)
14. [Organiser et versionner ses dotfiles](#organiser-et-versionner-ses-dotfiles)
15. [Pièges classiques](#pièges-classiques)
16. [Récapitulatif](#récapitulatif)

---

## Quel shell est-ce que j'utilise ?

Le shell est le programme qui interprète ce que vous tapez dans le terminal. Plusieurs coexistent sur une même machine.

| Shell | Chemin | Remarque |
|-------|--------|----------|
| **sh** | `/bin/sh` | Le shell POSIX minimal. Sur Debian, c'est en réalité `dash`. |
| **bash** | `/bin/bash` | *Bourne Again Shell* — le standard de fait sur Linux |
| **zsh** | `/usr/bin/zsh` | Compatible bash, plus riche (complétion, globbing, thèmes) |
| **fish** | `/usr/bin/fish` | Très convivial, mais **non** compatible POSIX |

Connaître son shell de connexion :

```bash
echo $SHELL
```

Connaître le shell **réellement en cours d'exécution** :

```bash
ps -p $$
```

Lister les shells installés :

```bash
cat /etc/shells
```

### Changer de shell

```bash
chsh -s /usr/bin/zsh
```

Pour un autre utilisateur (en root) :

```bash
sudo chsh -s /usr/bin/zsh username
```

> [!IMPORTANT]
> Le changement ne prend effet qu'à la **prochaine connexion**. Vérifiez d'abord que le shell fonctionne en le lançant simplement (`zsh`) : un shell de login cassé peut rendre le compte inutilisable.
> Le shell d'un utilisateur est stocké dans le dernier champ de sa ligne dans `/etc/passwd`.

---

## Login, interactif : comprendre les quatre cas

C'est **le** point qui explique 90 % des « pourquoi mon alias ne marche pas ». Un shell est caractérisé par deux propriétés indépendantes.

| Type de shell | Définition | Exemple concret |
|---------------|------------|-----------------|
| **Login + interactif** | Ouvert après une authentification | Connexion SSH, `su - user`, console TTY |
| **Non-login + interactif** | Ouvert depuis une session déjà authentifiée | Un nouvel onglet de terminal graphique, `bash`, un panneau tmux |
| **Non-login + non-interactif** | Exécute un script, sans humain devant | `./mon_script.sh`, une tâche cron |
| **Login + non-interactif** | Rare | `ssh serveur 'commande'`, certains scripts de déploiement |

Vérifier dans quel cas on se trouve :

```bash
# Shell interactif ? (la sortie contient un "i")
echo $-

# Shell de login ?
shopt -q login_shell && echo "login" || echo "non-login"
```

---

## Quel fichier est chargé, et quand ?

### Bash

```text
┌─ SHELL DE LOGIN ────────────────────┐   ┌─ SHELL INTERACTIF (non-login) ──┐
│ 1. /etc/profile                     │   │ 1. /etc/bash.bashrc             │
│ 2. /etc/profile.d/*.sh              │   │ 2. ~/.bashrc                    │
│ 3. le PREMIER trouvé parmi :        │   └─────────────────────────────────┘
│      ~/.bash_profile                │
│      ~/.bash_login                  │   ┌─ SCRIPT (non-interactif) ───────┐
│      ~/.profile                     │   │ Aucun fichier chargé            │
│                                     │   │ (sauf si $BASH_ENV est défini)  │
│ …et à la déconnexion :              │   └─────────────────────────────────┘
│      ~/.bash_logout                 │
└─────────────────────────────────────┘
```

| Fichier | Portée | Chargé pour |
|---------|--------|-------------|
| `/etc/profile` | Tous les utilisateurs | Shells de login |
| `/etc/profile.d/*.sh` | Tous les utilisateurs | Shells de login — **l'endroit propre** pour ajouter de la config système |
| `/etc/bash.bashrc` | Tous les utilisateurs | Shells interactifs |
| `~/.bash_profile` | Un utilisateur | Shells de login |
| `~/.profile` | Un utilisateur | Shells de login, **si** `.bash_profile` n'existe pas |
| `~/.bashrc` | Un utilisateur | Shells interactifs non-login |
| `~/.bash_logout` | Un utilisateur | À la fin d'un shell de login |

> [!CAUTION]
> **Bash ne lit PAS `~/.bashrc` dans un shell de login.**
> C'est pour cela que la plupart des `~/.bash_profile` contiennent ce pont :
>
> ```bash
> # Charger ~/.bashrc si on est en interactif
> if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
>     . "$HOME/.bashrc"
> fi
> ```
>
> Sans ce bloc, vos alias fonctionnent dans un terminal local mais disparaissent en SSH.

### Zsh

Zsh est plus régulier : le nom du fichier indique quand il est lu.

| Ordre | Fichier | Chargé pour |
|-------|---------|-------------|
| 1 | `/etc/zshenv` puis `~/.zshenv` | **Tous** les shells, y compris les scripts |
| 2 | `/etc/zprofile` puis `~/.zprofile` | Shells de login |
| 3 | `/etc/zshrc` puis `~/.zshrc` | Shells interactifs |
| 4 | `/etc/zlogin` puis `~/.zlogin` | Shells de login (après `.zshrc`) |
| 5 | `~/.zlogout` | À la déconnexion |

> [!TIP]
> **Correspondance mentale bash → zsh :**
> `~/.bashrc` → `~/.zshrc` · `~/.bash_profile` → `~/.zprofile` · *(pas d'équivalent en bash)* → `~/.zshenv`

---

## Où dois-je mettre ma configuration ?

C'est la question pratique. Le tableau ci-dessous répond dans la quasi-totalité des cas.

| Ce que je veux configurer | Bash | Zsh |
|---------------------------|------|-----|
| Un **alias** | `~/.bashrc` | `~/.zshrc` |
| Une **fonction** | `~/.bashrc` | `~/.zshrc` |
| Le **prompt** (`PS1`) | `~/.bashrc` | `~/.zshrc` |
| Les **couleurs**, la complétion | `~/.bashrc` | `~/.zshrc` |
| Une **variable d'environnement** (`EDITOR`, `LANG`) | `~/.bash_profile` ou `~/.profile` | `~/.zprofile` |
| Le **`PATH`** | `~/.bash_profile` ou `~/.profile` | `~/.zprofile` (ou `~/.zshenv`) |
| Quelque chose que les **scripts** doivent voir | `/etc/profile.d/` | `~/.zshenv` |
| Une config **pour tous les utilisateurs** | `/etc/profile.d/mon_fichier.sh` | idem |

**Règle simple à retenir :**

> Ce qui est **hérité** par les processus enfants (variables exportées, `PATH`) → fichier de **profile**.
> Ce qui concerne le **confort de frappe** (alias, prompt, complétion) → fichier **rc**.

---

## Appliquer ses modifications

Après avoir édité un fichier de configuration, il n'est **pas** rechargé automatiquement. Trois options :

```bash
# 1. Recharger dans le shell courant (le plus courant)
source ~/.bashrc
```

```bash
# 2. Syntaxe équivalente, plus portable
. ~/.bashrc
```

```bash
# 3. Remplacer le shell courant par un shell neuf
exec bash -l
```

> [!IMPORTANT]
> `source fichier` exécute le fichier **dans le shell courant** — c'est ce qui permet aux alias et aux variables de rester.
> `./fichier` l'exécute dans un **sous-processus** : le shell courant n'en garde rien. C'est exactement la distinction vue au [chapitre 06.6](06_shellscript/06_fonctions/fonctions.md#importer-des-fonctions-dun-autre-script).

> [!TIP]
> Faites une sauvegarde avant de modifier un fichier de config :
> ```bash
> cp ~/.bashrc ~/.bashrc.bak
> ```

---

## Les alias

Un alias est un raccourci de commande.

```bash
# Syntaxe : alias nom='commande'
alias ll='ls -alh'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'

# Sécuriser les commandes destructives (demande confirmation)
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Raccourcis d'administration
alias ports='ss -tulpn'
alias myip='ip -4 addr show scope global | grep inet'
alias maj='sudo apt update && sudo apt upgrade'
alias services='systemctl list-units --type=service --state=running'
```

Gérer ses alias :

```bash
alias                  # lister tous les alias définis
alias ll               # voir la définition d'un alias
unalias ll             # supprimer un alias (pour la session en cours)
\ls                    # exécuter la vraie commande en ignorant l'alias
command ls             # idem
```

> [!WARNING]
> **Les alias ne fonctionnent que dans les shells interactifs.** Ils ne sont **pas** disponibles dans vos scripts, ni dans un cron.
> Ne comptez donc jamais sur un alias dans un script : écrivez la commande complète.
>
> Attention aussi à l'effet pervers de `alias rm='rm -i'` : on prend l'habitude d'une confirmation qui n'existera pas sur un serveur où l'alias n'est pas défini.

---

## Les fonctions

Quand un alias ne suffit plus (besoin d'arguments, de logique), on écrit une fonction dans son `.bashrc` / `.zshrc`.

```bash
# Créer un dossier et s'y déplacer immédiatement
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extraire n'importe quelle archive
extract() {
  case "$1" in
    *.tar.gz|*.tgz)  tar -xzvf "$1" ;;
    *.tar.bz2)       tar -xjvf "$1" ;;
    *.tar)           tar -xvf  "$1" ;;
    *.zip)           unzip     "$1" ;;
    *.gz)            gunzip    "$1" ;;
    *) echo "Format non supporté : $1" >&2; return 1 ;;
  esac
}

# Sauvegarder un fichier avant de le modifier
bak() {
  cp -- "$1" "$1.$(date +%Y%m%d-%H%M%S).bak"
}
```

> [!TIP]
> Différence pratique : un **alias** substitue du texte en début de commande, une **fonction** peut recevoir et manipuler des arguments. Dès qu'il vous faut `$1`, c'est une fonction.

---

## Les variables d'environnement

```bash
# Variable de shell : visible uniquement dans le shell courant
MA_VAR="valeur"

# Variable d'environnement : héritée par tous les processus enfants
export MA_VAR="valeur"

# Les deux en une ligne
export EDITOR=vim
```

Variables les plus utiles à définir dans son profile :

```bash
export EDITOR=vim               # éditeur par défaut (git, crontab -e, visudo)
export VISUAL=vim
export PAGER=less
export LANG=fr_BE.UTF-8         # langue et encodage
export LESS='-R'                # préserver les couleurs dans less
```

Inspecter l'environnement :

```bash
printenv                # toutes les variables d'environnement
printenv PATH           # une seule
env                     # équivalent
set                     # variables d'environnement ET variables de shell
unset MA_VAR            # supprimer une variable
```

Quelques variables standard :

| Variable | Contenu |
|----------|---------|
| `$HOME` | Dossier personnel de l'utilisateur |
| `$USER` | Nom de l'utilisateur courant |
| `$PWD` | Dossier courant |
| `$SHELL` | Shell de connexion |
| `$PATH` | Où chercher les exécutables |
| `$?` | Code de retour de la dernière commande |
| `$$` | PID du shell courant |

> [!CAUTION]
> Ne stockez **jamais** de secret (mot de passe, token d'API) dans un `.bashrc` versionné. Les variables d'environnement sont héritées par tous les processus enfants et se retrouvent souvent dans les logs de debug.
> Utilisez un fichier séparé, non versionné et en `chmod 600` :
>
> ```bash
> [ -f ~/.secrets ] && source ~/.secrets
> ```

---

## Le PATH

Le `PATH` est la liste des dossiers dans lesquels le shell cherche les exécutables, séparés par des `:`.

```bash
echo $PATH
```

```text
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

Ajouter un dossier — typiquement celui de ses propres scripts :

```bash
# À placer dans ~/.bash_profile, ~/.profile ou ~/.zprofile
export PATH="$HOME/bin:$PATH"
```

| Forme | Effet |
|-------|-------|
| `export PATH="$HOME/bin:$PATH"` | Mon dossier est **prioritaire** sur le système |
| `export PATH="$PATH:$HOME/bin"` | Le système est prioritaire sur mon dossier |

> [!WARNING]
> **N'oubliez jamais de réinjecter `$PATH`.** Écrire `export PATH="$HOME/bin"` remplace tout le `PATH` : plus aucune commande système n'est trouvée.
>
> **N'ajoutez jamais `.` (le dossier courant) au `PATH`** : un fichier malveillant nommé `ls` déposé dans un dossier partagé serait exécuté à votre place.

Savoir quel exécutable sera réellement lancé :

```bash
which ls
type -a ls
command -v ls
```

---

## Personnaliser le prompt

Le prompt est défini par la variable `PS1` en bash, `PROMPT` en zsh.

### Bash

```bash
# Prompt par défaut de Debian
PS1='\u@\h:\w\$ '
```

| Séquence | Affiche |
|----------|---------|
| `\u` | Le nom d'utilisateur |
| `\h` | Le nom de la machine (court) — `\H` pour le FQDN |
| `\w` | Le chemin complet — `\W` pour le dossier seul |
| `\$` | `#` si root, `$` sinon |
| `\t` | L'heure (HH:MM:SS) |
| `\n` | Un retour à la ligne |

Avec des couleurs :

```bash
PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
```

> [!IMPORTANT]
> Les codes couleur doivent être encadrés par `\[` et `\]`. Ces marqueurs indiquent à bash que ces caractères ne prennent **pas** de place à l'écran. Sans eux, le shell calcule mal la longueur du prompt et la ligne s'affiche de travers dès que vous éditez une commande longue.

Un prompt utile en administration — rouge quand on est root :

```bash
if [ "$(id -u)" -eq 0 ]; then
  PS1='\[\e[1;31m\]\u@\h\[\e[0m\]:\w# '     # rouge = attention, je suis root
else
  PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\w\$ '    # vert = utilisateur normal
fi
```

### Zsh

```bash
PROMPT='%n@%m %~ %# '
```

| Séquence | Affiche |
|----------|---------|
| `%n` | Utilisateur |
| `%m` | Machine |
| `%~` | Chemin (avec `~` pour le home) |
| `%#` | `#` si root, `%` sinon |
| `%F{green}…%f` | Couleur |

> [!TIP]
> Configurer à la main un prompt riche (branche git, durée d'exécution, statut de la dernière commande) est fastidieux. Des outils le font pour vous : voir le [chapitre 11 · Configuration avancée](11_advanced_config.md).

---

## Maîtriser l'historique

L'historique est l'outil le plus rentable du shell — encore faut-il le configurer.

### Bash

```bash
# À placer dans ~/.bashrc

HISTSIZE=10000                    # commandes gardées en mémoire
HISTFILESIZE=20000                # commandes gardées dans le fichier
HISTCONTROL=ignoreboth:erasedups  # ignore les doublons et les lignes commençant par un espace
HISTIGNORE="ls:cd:pwd:exit:clear:history"
HISTTIMEFORMAT="%F %T "           # horodater chaque commande

shopt -s histappend               # ajouter à l'historique au lieu de l'écraser
```

### Zsh

```bash
# À placer dans ~/.zshrc

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=20000

setopt HIST_IGNORE_ALL_DUPS       # pas de doublons
setopt HIST_IGNORE_SPACE          # ignore les lignes commençant par un espace
setopt SHARE_HISTORY              # historique partagé entre les terminaux ouverts
setopt EXTENDED_HISTORY           # horodatage
```

### Utiliser l'historique

| Raccourci / commande | Effet |
|----------------------|-------|
| `CTRL + R` | Recherche incrémentale dans l'historique |
| `↑` / `↓` | Commande précédente / suivante |
| `history` | Afficher l'historique numéroté |
| `!42` | Rejouer la commande n° 42 |
| `!!` | Rejouer la dernière commande — `sudo !!` |
| `!$` | Dernier argument de la commande précédente |
| `history -c` | Vider l'historique |

> [!TIP]
> `HISTCONTROL=ignorespace` (inclus dans `ignoreboth`) est très pratique : une commande précédée d'un **espace** n'est pas enregistrée dans l'historique. Idéal pour une commande contenant un mot de passe.

---

## Options du shell

### Bash — `shopt`

```bash
shopt -s autocd          # taper "Documents" équivaut à "cd Documents"
shopt -s cdspell         # corrige les fautes de frappe dans les cd
shopt -s checkwinsize    # recalcule la taille du terminal après chaque commande
shopt -s globstar        # active ** pour la recherche récursive : ls **/*.md
shopt -s nocaseglob      # globbing insensible à la casse
```

Lister toutes les options : `shopt`

### Zsh — `setopt`

```bash
setopt AUTO_CD
setopt CORRECT           # propose une correction en cas de faute de frappe
setopt EXTENDED_GLOB
setopt NO_BEEP
```

### La complétion

Sur bash, la complétion avancée (options des commandes, noms de services, branches git…) vient d'un paquet à installer :

```bash
sudo apt install bash-completion
```

Puis, dans `~/.bashrc` :

```bash
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi
```

Sur zsh :

```bash
autoload -Uz compinit && compinit
```

---

## Configuration système et `/etc/skel`

### Appliquer une configuration à tous les utilisateurs

On ne modifie **pas** `/etc/profile` directement : on dépose un fichier dans `/etc/profile.d/`.

```bash
sudo tee /etc/profile.d/entreprise.sh > /dev/null <<'EOF'
export EDITOR=vim
export TZ="Europe/Brussels"
alias ll='ls -alh'
EOF
```

Tout fichier `.sh` de ce dossier est chargé pour chaque shell de login. C'est propre, réversible, et cela survit aux mises à jour du système.

### `/etc/skel` — le squelette des nouveaux comptes

Quand on crée un utilisateur avec `useradd -m` (ou `adduser`), le contenu de `/etc/skel` est **copié** dans sa *home directory*.

```bash
ls -la /etc/skel
```

```text
.bash_logout
.bashrc
.profile
```

C'est donc là qu'on place la configuration par défaut que doivent recevoir les nouveaux comptes :

```bash
sudo cp mon_bashrc_type /etc/skel/.bashrc
```

> [!NOTE]
> `/etc/skel` n'affecte que les comptes **créés après** la modification. Les utilisateurs existants gardent leurs fichiers.

---

## Organiser et versionner ses dotfiles

Un `.bashrc` de 400 lignes devient vite ingérable. La bonne pratique est de le découper :

```bash
# À la fin de ~/.bashrc
for f in "$HOME"/.bashrc.d/*.sh; do
  [ -r "$f" ] && . "$f"
done
unset f
```

```text
~/.bashrc.d/
├── 10-aliases.sh
├── 20-functions.sh
├── 30-prompt.sh
└── 40-docker.sh
```

Et surtout : **versionnez vos dotfiles**.

```bash
mkdir ~/dotfiles && cd ~/dotfiles
git init
mv ~/.bashrc ~/dotfiles/bashrc
ln -s ~/dotfiles/bashrc ~/.bashrc
git add . && git commit -m "Initial dotfiles"
```

Les fichiers de votre home ne sont plus que des liens symboliques vers le dépôt : une seule source de vérité, réutilisable sur toutes vos machines. Des outils comme **GNU stow** ou **chezmoi** automatisent cette mise en place.

---

## Pièges classiques

> [!CAUTION]
> **1. Une commande qui affiche du texte dans `.bashrc` casse `scp` et `sftp`.**
> Ces outils ouvrent un shell non interactif et interprètent toute sortie inattendue comme un protocole invalide. Protégez toujours ce genre de ligne :
>
> ```bash
> # En tout début de .bashrc
> case $- in
>   *i*) ;;       # interactif : on continue
>     *) return;; # non interactif : on sort immédiatement
> esac
> ```

> [!CAUTION]
> **2. Une erreur de syntaxe dans `.bashrc` casse tous vos nouveaux terminaux.**
> Testez avant de vous déconnecter, depuis un **second terminal** :
>
> ```bash
> bash -n ~/.bashrc     # vérifie la syntaxe sans exécuter
> source ~/.bashrc      # teste réellement
> ```
>
> Si vous êtes déjà bloqué : `ssh user@serveur 'bash --norc -i'`, ou `bash --norc` en console.

> [!CAUTION]
> **3. `export PATH="/mon/dossier"` sans `:$PATH`** — plus aucune commande ne fonctionne.
> Solution de secours dans le shell courant :
>
> ```bash
> export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
> ```

> [!CAUTION]
> **4. Croire que les alias sont disponibles dans les scripts et les crons.** Ils ne le sont pas. Cron n'exécute ni `.bashrc` ni `.profile` : utilisez des chemins absolus (voir le [chapitre 04](04_installation_et_services.md#cron)).

---

## Récapitulatif

| Fichier | Shell | Quand |
|---------|-------|-------|
| `~/.bashrc` | bash | Chaque shell interactif → alias, fonctions, prompt |
| `~/.bash_profile` / `~/.profile` | bash | Login → variables d'environnement, `PATH` |
| `~/.bash_logout` | bash | Déconnexion |
| `~/.zshrc` | zsh | Chaque shell interactif |
| `~/.zprofile` | zsh | Login |
| `~/.zshenv` | zsh | **Tous** les shells, scripts compris |
| `/etc/profile.d/*.sh` | tous | Login, pour tous les utilisateurs |
| `/etc/skel/` | — | Copié dans la home des nouveaux comptes |

| Commande | Rôle |
|----------|------|
| `echo $SHELL` / `ps -p $$` | Quel shell ? |
| `chsh -s /usr/bin/zsh` | Changer de shell |
| `source ~/.bashrc` | Recharger la configuration |
| `alias` / `unalias` | Gérer les alias |
| `export VAR=valeur` | Définir une variable d'environnement |
| `printenv` | Lister l'environnement |
| `shopt -s` / `setopt` | Activer une option du shell |
| `bash -n ~/.bashrc` | Vérifier la syntaxe avant de casser sa session |

---

⬅️ [Précédent : 09 · tmux](09_tmux.md) · 🏠 [Sommaire](README.md) · [Suivant : 11 · Configuration avancée ➡️](11_advanced_config.md)
