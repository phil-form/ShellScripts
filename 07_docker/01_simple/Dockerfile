# =============================================================================
#  Exemple 01 · Un Dockerfile simple, étape par étape
#  Build : docker build -t demo:01 .
#  Run   : docker run --rm -p 3000:3000 demo:01
# =============================================================================

# --- ÉTAPE 1 · L'image de base ------------------------------------------------
# Toujours la première instruction. On épingle une version précise et une
# variante `alpine` (~50 Mo au lieu de ~400 Mo pour l'image Debian complète).
FROM node:22-alpine

# --- ÉTAPE 2 · Les métadonnées ------------------------------------------------
# Purement documentaire, mais lisible via `docker inspect`.
LABEL org.opencontainers.image.title="demo-api" \
      org.opencontainers.image.description="Exemple minimal du chapitre 07" \
      org.opencontainers.image.authors="BStorm"

# --- ÉTAPE 3 · Le répertoire de travail ---------------------------------------
# Créé s'il n'existe pas. Toutes les instructions suivantes (COPY, RUN, CMD)
# s'exécutent depuis ce dossier : plus besoin de chemins absolus.
WORKDIR /app

# --- ÉTAPE 4 · Les dépendances, AVANT le code ---------------------------------
# On copie d'abord les seuls manifestes. Cette couche n'est reconstruite que si
# package.json ou package-lock.json changent — pas à chaque modification du code.
COPY package.json package-lock.json ./

# `npm ci` installe exactement ce que décrit le lockfile (reproductible),
# contrairement à `npm install` qui peut le mettre à jour.
RUN npm ci --omit=dev

# --- ÉTAPE 5 · Le code source -------------------------------------------------
# Ce qui change le plus souvent vient en dernier : seule cette couche
# est reconstruite à chaque commit.
COPY src/ ./src/

# --- ÉTAPE 6 · La configuration d'exécution -----------------------------------
ENV NODE_ENV=production \
    PORT=3000

# Documente le port utilisé. N'ouvre RIEN : c'est `-p` qui publie.
EXPOSE 3000

# --- ÉTAPE 7 · L'utilisateur --------------------------------------------------
# L'image node fournit déjà un utilisateur `node` non privilégié (UID 1000).
# Sans cette ligne, le processus tournerait en root.
USER node

# --- ÉTAPE 8 · Le contrôle de santé -------------------------------------------
# Docker interroge cette commande : `docker ps` affiche (healthy) / (unhealthy).
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3000/health || exit 1

# --- ÉTAPE 9 · La commande de démarrage ---------------------------------------
# Forme "exec" (tableau JSON) : le processus devient PID 1 et reçoit
# directement les signaux — indispensable pour un arrêt propre.
# À ne pas écrire : CMD node src/server.js  (forme "shell", passe par /bin/sh)
CMD ["node", "src/server.js"]
