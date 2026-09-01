# 🛠️ Parcours administrateur système — exercices

> Une série d'exercices **sans corrigé**, orientée administration : prendre en main un serveur, tenir ses
> permissions et ses comptes, exploiter ses logs, gérer ses paquets, ses services et ses tâches planifiées,
> le durcir, l'outiller avec des scripts, y faire tourner Docker proprement et industrialiser l'environnement
> de tous ses utilisateurs.
>
> Le parcours couvre les chapitres **01 à 06**, **08**, **09**, **10** et **11**. Le chapitre
> **07 · Docker pour les développeurs** n'est abordé ici que sous l'angle de l'exploitation (chapitre 08) :
> l'écriture des `Dockerfile` est traitée dans le [parcours développeur](../dev/) — le pendant de celui-ci,
> côté application.

---

## 🧵 Le fil rouge — `srv-tickets`

Vous reprenez l'administration de **`srv-tickets`**, la VM Debian 12 exposée sur Internet qui héberge
l'application `ticketflow` (une API + une base PostgreSQL) écrite par l'équipe de développement.

L'existant qu'on vous laisse :

| Élément | État à votre arrivée |
|---------|----------------------|
| Comptes | tout le monde se connecte en `root`, mot de passe partagé |
| SSH | port 22, authentification par mot de passe, `PermitRootLogin yes` |
| Pare-feu | inexistant |
| Sauvegardes | « il y a un `.tar.gz` quelque part dans `/root` » |
| Supervision | aucune : on apprend les pannes par les utilisateurs |
| Docker | installé « à l'arrache », les logs remplissent le disque |

**Votre mission, au fil des exercices : en faire un serveur tenable.** Chaque chapitre reprend le serveur
là où le précédent l'a laissé, mais chaque fichier reste jouable indépendamment.

---

## 📋 Les exercices

| # | Fichier | Porte sur |
|---|---------|-----------|
| A1 | [Prise en main du serveur](01_prise_en_main.md) | ch. [01](../../01_base.md) et [09](../../09_tmux.md) — arborescence système, logs, processus, redirections, tmux |
| A2 | [Permissions et propriété](02_permissions.md) | ch. [02](../../02_file_permissions.md) — octal, symbolique, SUID / SGID / sticky, `chown`, `umask` |
| A3 | [Utilisateurs, groupes et comptes](03_utilisateurs_et_groupes.md) | ch. [02.1](../../02.1_user_management.md) — cycle de vie des comptes, `/etc/passwd`, `/etc/shadow`, comptes de service |
| A4 | [La boîte à outils](04_boite_a_outils.md) | ch. [03](../../03_commandes_essentielles.md) — `grep`, `sed`, `awk`, `find`, `xargs`, `du` / `df`, `tar` |
| A5 | [Paquets, services et cron](05_paquets_services_cron.md) | ch. [04](../../04_installation_et_services.md) — `apt`, `systemctl`, unité custom, `journalctl`, `cron` |
| A6 | [ACL et délégation `sudo`](06_acl_et_sudo.md) | ch. [05](../../05_securite.md) — ACL, masque, héritage, `sudoers`, `sudoedit`, audit |
| A7 | [SSH et pare-feu](07_ssh_et_pare_feu.md) | ch. [05](../../05_securite.md) — clés, durcissement `sshd`, `Match`, tunnels, `ufw` / `nftables`, `fail2ban` |
| A8 | [AppArmor / SELinux](08_mac_apparmor_selinux.md) | ch. [05](../../05_securite.md) — DAC vs MAC, modes, profils, contextes, booléens, diagnostic |
| A9 | [Scripts d'administration](09_scripts_administration.md) | ch. [06](../../06_shellscript/) — audit, sauvegarde avec rotation, supervision, `getopts`, `trap`, bibliothèque |
| A10 | [Docker pour l'administrateur](10_docker_administration.md) | ch. [08](../../08_docker_administration.md) — démon, volumes, réseaux, logs, ressources, durcissement, sauvegardes |
| A11 | [L'environnement des utilisateurs](11_environnement_utilisateurs.md) | ch. [10](../../10_shell_config.md) et [11](../../11_advanced_config.md) — `/etc/profile.d`, `/etc/skel`, dotfiles multi-serveurs |
| A12 | [Projet final : durcir et exploiter `srv-tickets`](12_projet_final.md) | tout ce qui précède |

> [!IMPORTANT]
> Ces exercices **n'ont volontairement pas de corrigé**. Un administrateur ne travaille pas de mémoire :
> il travaille avec `man`, la documentation de la distribution et une VM de test. Chaque exercice se termine
> par des **critères de vérification** — si vous les remplissez, votre solution tient.

---

## 🚀 Environnement

> [!CAUTION]
> **Rien de tout cela ne se fait sur une machine dont vous avez besoin.** Ce parcours coupe des accès SSH,
> ferme des ports, verrouille des comptes et modifie `sudoers` : les trois quarts des exercices peuvent vous
> enfermer dehors. C'est précisément l'intérêt — mais sur une VM jetable dont vous avez un instantané.

| Élément | Recommandation |
|---------|----------------|
| Machine | Une **VM** Debian 12 (VirtualBox, UTM, Proxmox, Hyper-V) — `systemd`, SSH et le pare-feu doivent être réels |
| Instantané | Prenez un **snapshot** avant chaque chapitre. Vous vous en servirez. |
| Accès | Deux terminaux ouverts en permanence : un pour travailler, **un second déjà connecté** que vous ne fermez jamais |

> [!WARNING]
> **La règle qui traverse tout le parcours** : avant de recharger `sshd`, `sudoers` ou le pare-feu, gardez une
> session privilégiée **déjà ouverte** et testez la nouvelle configuration **depuis une troisième connexion**.
> Tant que le test n'est pas passé, on ne ferme pas la session de secours.

---

## ✅ Comment travailler

1. Lisez l'énoncé en entier, **puis** vérifiez la commande dans `man` avant de l'exécuter en tant que root.
2. Sauvegardez systématiquement un fichier de configuration avant de le modifier — et gardez le `.bak`
   jusqu'à ce que le service ait redémarré sans erreur.
3. Vérifiez la syntaxe avant d'appliquer : `visudo -c`, `sshd -t`, `nft -c -f`, `dockerd --validate`.
4. Notez ce que vous faites. Un chapitre sur deux vous demandera de rendre compte de l'état du serveur :
   tenez un fichier `journal.md` au fil de l'eau, c'est le réflexe du métier.
5. Versionnez vos fichiers de configuration (`/etc` dans un dépôt Git, ou au minimum vos fragments à vous).
