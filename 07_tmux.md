# 07 · tmux (Terminal Multiplexer)

C'est un outil très intéressant quand on fait de l'administration système à distance : il permet de gérer des **sessions** sur le serveur et de les **récupérer** en cas de déconnexion.

> [!NOTE]
> **Objectifs du chapitre**
> - Créer, quitter et rejoindre une session tmux
> - Découper un terminal en panneaux et gérer plusieurs fenêtres
> - Naviguer et chercher dans l'historique du terminal

> [!TIP]
> **Le concept en une phrase :** votre travail tourne sur le **serveur**, pas dans votre terminal. Si votre connexion SSH tombe, la session tmux continue de tourner et vous la retrouvez intacte en vous reconnectant.
>
> Hiérarchie : une **session** contient des **fenêtres**, qui contiennent des **panneaux** (*panes*).

## Sommaire

1. [Gestion des sessions](#gestion-des-sessions)
2. [Découper le terminal (panneaux)](#découper-le-terminal-panneaux)
3. [Les fenêtres](#les-fenêtres)
4. [Navigation et recherche](#navigation-et-recherche)
5. [Oh my tmux](#oh-my-tmux)
6. [Aide-mémoire](#aide-mémoire)

---

## Le préfixe

Presque tous les raccourcis tmux commencent par la combinaison `CTRL + b` : on l'appelle le **préfixe**. On appuie sur `CTRL + b`, on **relâche**, puis on appuie sur la touche de l'action.

Dans tout ce chapitre, cette séquence est notée :

```text
CTRL + b  =>  touche
```

---

## Gestion des sessions

### 1. Installation

```bash
sudo apt install tmux
```

### 2. Démarrer une session

```bash
tmux
```

```bash
tmux new -s session-name
```

> [!TIP]
> Nommez toujours vos sessions (`-s`). Retrouver `session-name` est bien plus simple que de deviner à quoi correspond la session `0`.

### 3. Sortir d'une session en la gardant active (*detach*)

```text
CTRL + b  =>  d
```

### 4. Lister les sessions actives

```bash
tmux ls
```

ou, depuis tmux :

```text
CTRL + b  =>  s
```

### 5. Rejoindre une session (*attach*)

```bash
tmux a -t session-name
```

```bash
tmux attach -t session-name
```

### 6. Détruire une session

```bash
tmux kill-session -t session-name
```

```bash
tmux kill -t session-name
```

```bash
tmux k -t session-name
```

### 7. Renommer une session

```text
CTRL + b  =>  $
```

### 8. Changer le répertoire de travail par défaut

Quand on ouvre un nouveau terminal dans une session, il se positionne dans un CWD (*current working directory*) par défaut.

```text
CTRL + b  =>  :
```

puis on saisit la commande :

```text
attach -c /new/directory
```

L'idée est de se positionner automatiquement dans le bon dossier en ouvrant de nouveaux terminaux dans une session tmux — par exemple le dossier de travail d'un projet.

---

## Découper le terminal (panneaux)

Je peux diviser le terminal en plusieurs parties :

| Raccourci | Action |
|-----------|--------|
| `CTRL + b  =>  %` | Split **vertical** (côte à côte) |
| `CTRL + b  =>  "` | Split **horizontal** (l'un au-dessus de l'autre) |

> [!NOTE]
> Les noms prêtent à confusion : `%` sépare l'écran par une barre verticale, `"` par une barre horizontale.

### Se déplacer entre les panneaux

| Raccourci | Action |
|-----------|--------|
| `CTRL + b  =>  ←↑↓→` | Aller au panneau dans cette direction |
| `CTRL + b  =>  o` | Circuler dans le sens des aiguilles d'une montre |
| `CTRL + b  =>  {` | Circuler dans le sens inverse |
| `CTRL + b  =>  ;` | Basculer vers le dernier panneau utilisé |
| `CTRL + b  =>  z` | Zoomer / dézoomer le panneau courant (plein écran) |
| `CTRL + b  =>  x` | Fermer le panneau courant |

---

## Les fenêtres

| Raccourci | Action |
|-----------|--------|
| `CTRL + b  =>  c` | **C**réer une fenêtre |
| `CTRL + b  =>  ,` | Renommer la fenêtre courante |
| `CTRL + b  =>  !` | Extraire le panneau courant dans sa propre fenêtre |
| `CTRL + b  =>  &` | Fermer la fenêtre active |
| `CTRL + b  =>  n` | Fenêtre suiva**n**te |
| `CTRL + b  =>  p` | Fenêtre **p**récédente |
| `CTRL + b  =>  w` | Lister les fenêtres |
| `CTRL + b  =>  0-9` | Aller directement à la fenêtre n° X |

---

## Navigation et recherche

### Activer le scrolling (mode copie)

```text
CTRL + b  =>  [
```

Sortir du mode scrolling :

```text
q
```

### Rechercher dans l'historique du terminal

Il faut d'abord être en mode scrolling :

```text
CTRL + b  =>  [
```

Ensuite :

```text
CTRL + r
```

et taper ce que l'on cherche.

> [!TIP]
> En mode copie, on peut aussi sélectionner du texte (`ESPACE` pour commencer, `ENTRÉE` pour copier) et le recoller avec `CTRL + b  =>  ]`.

---

## Oh my tmux

Avec [oh-my-tmux](https://github.com/gpakosz/.tmux), on peut notamment utiliser la souris :

```text
CTRL + b  =>  m
```

`oh-my-tmux` améliore tmux et ajoute le support de la souris, une barre de statut lisible et de nombreux réglages par défaut sensés. Sa configuration est détaillée dans le [chapitre 09 · Configuration avancée](09_advanced_config.md#oh-my-tmux).

---

## Aide-mémoire

### En ligne de commande

| Commande | Action |
|----------|--------|
| `tmux` | Nouvelle session anonyme |
| `tmux new -s nom` | Nouvelle session nommée |
| `tmux ls` | Lister les sessions |
| `tmux a -t nom` | Rejoindre une session |
| `tmux kill-session -t nom` | Détruire une session |

### Dans tmux (préfixe `CTRL + b`)

| Touche | Action | | Touche | Action |
|--------|--------|---|--------|--------|
| `d` | Se détacher | | `c` | Nouvelle fenêtre |
| `s` | Lister les sessions | | `,` | Renommer la fenêtre |
| `$` | Renommer la session | | `n` / `p` | Fenêtre suivante / précédente |
| `%` | Split vertical | | `w` | Lister les fenêtres |
| `"` | Split horizontal | | `&` | Fermer la fenêtre |
| `←↑↓→` | Changer de panneau | | `[` | Mode scroll / copie |
| `z` | Zoomer un panneau | | `?` | **Afficher tous les raccourcis** |

---

⬅️ [Précédent : 06.6 · Fonctions](06_shellscript/06_fonctions/fonctions.md) · 🏠 [Sommaire](README.md) · [Suivant : 08 · Configuration du shell ➡️](08_shell_config.md)
