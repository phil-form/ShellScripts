# 11 · Configuration avancée (`oh-my-*`, thèmes et outillage)

> [!NOTE]
> **Objectifs du chapitre**
> - Installer et configurer **Oh My Zsh**, ses thèmes et ses plugins
> - Connaître les alternatives : **Oh My Bash**, **Starship**
> - Configurer **Oh My Tmux**
> - Installer les polices nécessaires (**Nerd Fonts**)
> - Remplacer les outils historiques par des équivalents modernes
> - Déployer sa configuration proprement sur plusieurs machines

> [!IMPORTANT]
> Ce chapitre suppose le [chapitre 10](10_shell_config.md) acquis : tout ce qui suit ne fait que **générer** ou **remplir** les fichiers `.zshrc`, `.bashrc` et `.tmux.conf` que vous savez maintenant lire.

## Sommaire

1. [Avant de commencer : où installer tout ça ?](#avant-de-commencer--où-installer-tout-ça-)
2. [Oh My Zsh](#oh-my-zsh)
3. [Les plugins indispensables](#les-plugins-indispensables)
4. [Les thèmes et Powerlevel10k](#les-thèmes-et-powerlevel10k)
5. [Starship — l'alternative universelle](#starship--lalternative-universelle)
6. [Oh My Bash](#oh-my-bash)
7. [Oh My Tmux](#oh-my-tmux)
8. [Les Nerd Fonts](#les-nerd-fonts)
9. [Outils CLI modernes](#outils-cli-modernes)
10. [fzf — la recherche floue](#fzf--la-recherche-floue)
11. [Déployer sa configuration sur plusieurs serveurs](#déployer-sa-configuration-sur-plusieurs-serveurs)
12. [Récapitulatif](#récapitulatif)

---

## Avant de commencer : où installer tout ça ?

> [!CAUTION]
> **Sur un serveur de production, on n'installe pas de framework de shell.**
>
> | Machine | Recommandation |
> |---------|----------------|
> | **Poste de travail / machine de dev** | Oui — le confort et la vitesse gagnés sont réels |
> | **Serveur de production** | Non — au mieux un `.bashrc` minimal, versionné et relu |
>
> Les raisons : un framework ajoute des dizaines de millisecondes au démarrage de **chaque** shell (y compris ceux ouverts par vos scripts), introduit des dépendances non gérées par le gestionnaire de paquets, et un `.zshrc` cassé sur un serveur distant peut vous couper l'accès.

> [!WARNING]
> **Sur les installations en `curl | bash`.**
> La plupart des outils de ce chapitre s'installent avec une commande du type `curl -fsSL https://… | sh`. Cela revient à exécuter du code arbitraire téléchargé sur Internet, avec vos droits.
> Le réflexe minimal : télécharger le script d'abord, le lire, puis l'exécuter.
>
> ```bash
> curl -fsSL https://exemple.com/install.sh -o install.sh
> less install.sh          # on lit ce qu'on s'apprête à lancer
> sh install.sh
> ```

---

## Oh My Zsh

[Oh My Zsh](https://ohmyz.sh/) est un framework de configuration pour zsh : il fournit un `.zshrc` structuré, ~300 plugins et ~150 thèmes.

### Prérequis

```bash
sudo apt install zsh git curl
```

```bash
zsh --version
```

### Installation

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

L'installateur :

1. clone le dépôt dans `~/.oh-my-zsh` ;
2. sauvegarde votre `.zshrc` existant en `~/.zshrc.pre-oh-my-zsh` ;
3. génère un nouveau `~/.zshrc` ;
4. propose de faire de zsh votre shell par défaut (`chsh`).

### Anatomie du `.zshrc` généré

```bash
# Chemin de l'installation
export ZSH="$HOME/.oh-my-zsh"

# Le thème utilisé
ZSH_THEME="robbyrussell"

# Les plugins activés (attention : séparés par des ESPACES, pas des virgules)
plugins=(git docker sudo)

# Charge le framework — tout ce qui précède doit être défini AVANT cette ligne
source $ZSH/oh-my-zsh.sh

# ── Votre configuration personnelle vient ici ──
alias ll='ls -alh'
export EDITOR=vim
```

> [!IMPORTANT]
> Les variables `ZSH_THEME` et `plugins` doivent être définies **avant** le `source $ZSH/oh-my-zsh.sh`. Placées après, elles sont sans effet — c'est l'erreur la plus fréquente.

Recharger après modification :

```bash
source ~/.zshrc
```

### Mise à jour et désinstallation

```bash
omz update           # mettre à jour Oh My Zsh
```

```bash
uninstall_oh_my_zsh  # désinstaller et restaurer l'ancien .zshrc
```

### Quelques plugins intégrés utiles

Ils sont déjà présents dans `~/.oh-my-zsh/plugins/`, il suffit de les ajouter à la liste.

| Plugin | Apport |
|--------|--------|
| `git` | Des dizaines d'alias (`gst`, `gco`, `gp`…) et la branche dans le prompt |
| `sudo` | **Double `ESC`** : préfixe la commande courante par `sudo` |
| `docker` / `docker-compose` | Complétion des conteneurs, images, services |
| `systemd` | Alias `sc-start`, `sc-status`, `sc-restart`… |
| `history` | Alias `h`, `hs` pour chercher dans l'historique |
| `command-not-found` | Suggère le paquet à installer quand la commande n'existe pas |
| `extract` | La commande `x fichier.tar.gz` — extrait n'importe quel format |
| `colored-man-pages` | Des pages de manuel en couleur |

```bash
plugins=(git sudo docker systemd extract colored-man-pages command-not-found)
```

> [!TIP]
> Chaque plugin est chargé au démarrage du shell. Une liste de 30 plugins rend l'ouverture d'un terminal perceptiblement lente — restez sur ceux que vous utilisez réellement.

---

## Les plugins indispensables

Deux plugins ne sont **pas** inclus et doivent être clonés. Ce sont, de loin, les plus utiles.

### zsh-autosuggestions

Propose en gris la fin de la commande d'après votre historique — `→` pour accepter.

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
```

### zsh-syntax-highlighting

Colore la commande pendant la frappe : vert si elle existe, rouge sinon. On voit ses fautes de frappe **avant** de valider.

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
```

### Activation

```bash
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)
```

> [!WARNING]
> `zsh-syntax-highlighting` doit être **le dernier** de la liste : il redéfinit les widgets de saisie et doit passer après tous les autres.

```bash
source ~/.zshrc
```

---

## Les thèmes et Powerlevel10k

### Changer de thème

```bash
ZSH_THEME="agnoster"
```

Les thèmes disponibles sont dans `~/.oh-my-zsh/themes/`. Quelques classiques :

| Thème | Style |
|-------|-------|
| `robbyrussell` | Le défaut — sobre et rapide |
| `agnoster` | Style *powerline* (nécessite une Nerd Font) |
| `af-magic` | Chemin complet, branche git à droite |
| `random` | Un thème différent à chaque ouverture — pratique pour choisir |

### Powerlevel10k

[Powerlevel10k](https://github.com/romkatv/powerlevel10k) est le thème de référence : très rapide, très configurable, avec un assistant de configuration.

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

Dans `~/.zshrc` :

```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
```

Puis :

```bash
source ~/.zshrc
```

Un assistant se lance à la première ouverture et écrit vos réponses dans `~/.p10k.zsh`. Pour le relancer :

```bash
p10k configure
```

> [!NOTE]
> Powerlevel10k demande une police compatible pour afficher ses icônes et ses séparateurs — voir [Les Nerd Fonts](#les-nerd-fonts). Sans elle, le prompt affiche des carrés ou des points d'interrogation.

---

## Starship — l'alternative universelle

[Starship](https://starship.rs/) n'est pas un framework mais **uniquement un prompt**. Son intérêt : il est écrit en Rust (démarrage quasi instantané) et fonctionne à l'identique sous **bash, zsh, fish et PowerShell**.

```bash
curl -sS https://starship.rs/install.sh | sh
```

Activation — une seule ligne à la **fin** du fichier de config :

```bash
# ~/.bashrc
eval "$(starship init bash)"
```

```bash
# ~/.zshrc
eval "$(starship init zsh)"
```

Configuration dans `~/.config/starship.toml` :

```toml
add_newline = true

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3

[git_branch]
symbol = " "
```

| | Oh My Zsh + p10k | Starship |
|---|---|---|
| Portée | zsh uniquement | Tous les shells |
| Fournit | Prompt + plugins + alias | Prompt uniquement |
| Configuration | `.zshrc` (shell) | `starship.toml` (déclaratif) |
| Bon choix si… | Vous vivez dans zsh | Vous alternez bash/zsh, ou voulez rester léger |

---

## Oh My Bash

[Oh My Bash](https://github.com/ohmybash/oh-my-bash) est l'équivalent d'Oh My Zsh pour ceux qui restent sur bash.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
```

La structure du `.bashrc` généré est la même :

```bash
export OSH="$HOME/.oh-my-bash"

OSH_THEME="font"

completions=(git ssh)
aliases=(general)
plugins=(git bashmarks)

source "$OSH/oh-my-bash.sh"
```

> [!NOTE]
> Oh My Bash est nettement moins riche qu'Oh My Zsh — bash n'offre pas les mêmes possibilités d'extension. Si le confort du shell est un objectif, passer à zsh est le choix le plus rentable ; sinon, `bash-completion` + `starship` couvre déjà l'essentiel.

---

## Oh My Tmux

[Oh My Tmux](https://github.com/gpakosz/.tmux) est une configuration tmux prête à l'emploi : barre de statut lisible, support de la souris, raccourcis cohérents. Elle complète le [chapitre 09](09_tmux.md).

### Installation

```bash
cd ~
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
```

> [!IMPORTANT]
> **Ne modifiez jamais `~/.tmux.conf`** : c'est un lien symbolique vers le dépôt, vos changements seraient perdus à la prochaine mise à jour.
> Toute personnalisation va dans **`~/.tmux.conf.local`**, qui est votre fichier.

### Personnalisations courantes

Dans `~/.tmux.conf.local` :

```bash
# Activer la souris (redimensionner, sélectionner, scroller)
set -g mouse on

# Numéroter les fenêtres à partir de 1 plutôt que 0
set -g base-index 1
setw -g pane-base-index 1

# Historique plus long
set -g history-limit 20000

# Thème de la barre de statut
tmux_conf_theme_status_left=' ❐ #S '
tmux_conf_theme_status_right='#{prefix}#{pairing} %R , %d %b | #{username}@#{hostname} '

# Copier vers le presse-papier système
tmux_conf_copy_to_os_clipboard=true
```

Recharger la configuration sans quitter tmux :

```text
CTRL + b  =>  r
```

ou

```bash
tmux source-file ~/.tmux.conf
```

### Rappel : la souris

Une fois `set -g mouse on` actif, on peut scroller, cliquer pour changer de panneau et redimensionner à la souris. Le raccourci de bascule fourni par oh-my-tmux :

```text
CTRL + b  =>  m
```

---

## Les Nerd Fonts

Les thèmes modernes (Powerlevel10k, agnoster, starship) affichent des icônes qui n'existent pas dans les polices standard. Les [Nerd Fonts](https://www.nerdfonts.com/) sont des polices classiques **enrichies** de ces milliers de glyphes.

> [!IMPORTANT]
> La police s'installe **sur votre machine locale** — celle où tourne l'émulateur de terminal — et **pas** sur le serveur distant. Le serveur envoie des caractères ; c'est votre terminal qui les dessine.

### Installation sous Linux

```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

curl -fLo "MesloLGS NF Regular.ttf" \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf

fc-cache -fv
```

Il reste à sélectionner la police dans les préférences de votre terminal (GNOME Terminal, Konsole, Windows Terminal, iTerm2…).

Polices les plus utilisées : **MesloLGS NF**, **FiraCode Nerd Font**, **JetBrainsMono Nerd Font**, **Hack Nerd Font**.

---

## Outils CLI modernes

Une bonne partie du confort ne vient pas du shell, mais du remplacement des outils historiques.

| Classique | Alternative | Apport |
|-----------|-------------|--------|
| `cat` | **bat** | Coloration syntaxique, numéros de ligne, intégration git |
| `ls` | **eza** (ex-`exa`) | Couleurs, icônes, arborescence, statut git |
| `find` | **fd** | Syntaxe simple, rapide, respecte `.gitignore` |
| `grep` | **ripgrep** (`rg`) | Beaucoup plus rapide, récursif par défaut |
| `du` | **ncdu** | Explorateur interactif d'occupation disque |
| `top` | **btop** / **htop** | Interface lisible, graphiques |
| `cd` | **zoxide** | Se déplacer par fréquence d'usage : `z projet` |
| `man` | **tldr** | Des exemples concrets plutôt qu'un manuel complet |
| — | **jq** | Manipuler du JSON en ligne de commande |

### Installation (Debian / Ubuntu)

```bash
sudo apt install bat fd-find ripgrep ncdu btop jq tldr
```

> [!NOTE]
> Sur Debian et Ubuntu, `bat` s'installe sous le nom **`batcat`** et `fd` sous le nom **`fdfind`** (conflits de noms avec d'autres paquets). D'où des alias dans le `.bashrc` :
>
> ```bash
> alias bat='batcat'
> alias fd='fdfind'
> ```

`eza` et `zoxide` ne sont pas toujours dans les dépôts :

```bash
# eza
sudo apt install eza    # ou : cargo install eza

# zoxide
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

Puis, dans `~/.bashrc` / `~/.zshrc` :

```bash
alias ls='eza --icons --group-directories-first'
alias ll='eza -alh --icons --git'
alias tree='eza --tree'

eval "$(zoxide init bash)"   # ou zsh
```

---

## fzf — la recherche floue

[fzf](https://github.com/junegunn/fzf) mérite sa propre section : c'est probablement l'outil qui change le plus la façon de travailler dans un terminal.

```bash
sudo apt install fzf
```

Une fois intégré au shell, il remplace trois choses :

| Raccourci | Effet |
|-----------|-------|
| `CTRL + R` | Recherche **floue** dans l'historique (remplace la recherche native) |
| `CTRL + T` | Insérer un chemin de fichier trouvé interactivement |
| `ALT + C` | Se déplacer dans un dossier choisi interactivement |

Intégration :

```bash
# ~/.bashrc
source /usr/share/doc/fzf/examples/key-bindings.bash
source /usr/share/doc/fzf/examples/completion.bash
```

```bash
# ~/.zshrc — ou simplement le plugin Oh My Zsh :
plugins=(git fzf)
```

Il se combine avec tout ce qui produit une liste :

```bash
# Choisir un service systemd à redémarrer
sudo systemctl restart "$(systemctl list-units --type=service --plain --no-legend | awk '{print $1}' | fzf)"

# Tuer un processus choisi à la souris… enfin, au clavier
kill -9 "$(ps aux | fzf | awk '{print $2}')"
```

---

## Déployer sa configuration sur plusieurs serveurs

Reproduire tout cela à la main sur 20 machines n'est pas viable. Trois approches, par ordre de sérieux :

### 1. Un dépôt de dotfiles + un script d'installation

```bash
git clone https://github.com/moi/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

Le `install.sh` crée les liens symboliques (voir [chapitre 10](10_shell_config.md#organiser-et-versionner-ses-dotfiles)) et installe les paquets manquants.

### 2. GNU Stow

```bash
sudo apt install stow
cd ~/dotfiles
stow bash tmux zsh     # crée automatiquement les liens dans ~
```

### 3. Un outil de gestion de configuration

Ansible, Salt ou Puppet, dès qu'il s'agit d'un vrai parc de serveurs. C'est aussi ce qui garantit que la configuration reste **identique et reproductible** — un `curl | bash` lancé à la main il y a six mois ne l'est jamais.

> [!TIP]
> Sur un serveur où l'on ne veut rien installer, il reste possible d'emporter sa config le temps d'une session :
>
> ```bash
> ssh serveur -t "bash --rcfile <(curl -fsSL https://mon.site/bashrc)"
> ```

---

## Récapitulatif

| Outil | Rôle | Fichier de config |
|-------|------|-------------------|
| **Oh My Zsh** | Framework zsh (plugins, thèmes, alias) | `~/.zshrc` |
| **Powerlevel10k** | Thème de prompt zsh | `~/.p10k.zsh` |
| **Starship** | Prompt universel multi-shell | `~/.config/starship.toml` |
| **Oh My Bash** | Framework bash | `~/.bashrc` |
| **Oh My Tmux** | Configuration tmux | `~/.tmux.conf.local` |
| **Nerd Fonts** | Polices avec icônes | Préférences du terminal local |
| **fzf** | Recherche floue interactive | `~/.bashrc` / `~/.zshrc` |
| **bat, eza, fd, rg, zoxide** | Remplaçants modernes des outils de base | alias dans le fichier `rc` |

**Une configuration confortable en cinq étapes :**

1. `zsh` + Oh My Zsh
2. Plugins `zsh-autosuggestions` et `zsh-syntax-highlighting`
3. Une Nerd Font + Powerlevel10k (ou Starship)
4. `fzf` et `zoxide`
5. Le tout dans un dépôt git de dotfiles

> [!CAUTION]
> **Et le rappel qui compte** : tout ceci vaut pour votre machine de travail. Sur un serveur, la valeur d'un shell tient à sa prévisibilité, pas à son esthétique. Vous devez rester efficace sur un `bash` nu, avec le seul `vi` disponible — c'est exactement ce que vous trouverez le jour d'un incident.

---

⬅️ [Précédent : 10 · Configuration du shell](10_shell_config.md) · 🏠 [Sommaire](README.md)
