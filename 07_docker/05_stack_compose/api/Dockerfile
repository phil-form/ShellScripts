# =============================================================================
#  L'API de la stack — un Dockerfile, deux cibles
#
#  Développement : docker build --target dev     -t stack-api:dev .
#  Production    : docker build --target runtime -t stack-api:1.0 .
#
#  Le `--target` (ou `target:` en Compose) permet de s'arrêter à l'étape
#  voulue : même fichier, deux images différentes.
# =============================================================================

# =============================================================================
#  ÉTAPE 1/3 · base — le socle commun aux deux cibles
# =============================================================================
FROM node:22-alpine AS base
WORKDIR /app
ENV PORT=3000
COPY package.json package-lock.json ./

# =============================================================================
#  ÉTAPE 2/3 · dev — outillage complet, code monté depuis l'hôte
#  Compose monte ./api/src par-dessus /app/src : on modifie un fichier sur la
#  machine, le conteneur le voit immédiatement.
# =============================================================================
FROM base AS dev
# Ici on installe TOUT, devDependencies comprises.
RUN npm install
COPY src/ ./src/
ENV NODE_ENV=development
EXPOSE 3000
# --watch relance le processus à chaque modification de fichier.
CMD ["node", "--watch", "src/server.js"]

# =============================================================================
#  ÉTAPE 3/3 · runtime — l'image livrée
# =============================================================================
FROM base AS runtime
# Uniquement les dépendances de production, installées depuis le lockfile.
RUN npm ci --omit=dev && npm cache clean --force
COPY --chown=node:node src/ ./src/
ENV NODE_ENV=production
EXPOSE 3000
USER node
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "src/server.js"]
