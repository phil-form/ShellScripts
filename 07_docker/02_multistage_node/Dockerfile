# =============================================================================
#  Exemple 02 · Build multi-étapes — Node compile, nginx sert
#  Build : docker build -t demo:02 .
#  Run   : docker run --rm -p 8080:80 demo:02
#
#  Le principe : l'étape de construction a besoin de Node, de npm et des
#  sources ; l'image finale n'a besoin que du HTML généré. On sépare les deux
#  et on ne garde QUE la seconde.
#
#  Résultat : ~50 Mo (nginx:alpine) au lieu de ~250 Mo (node:22-alpine + sources)
# =============================================================================

# =============================================================================
#  ÉTAPE 1/2 · builder — tout l'outillage de construction
#  Le `AS builder` nomme l'étape pour pouvoir y piocher ensuite.
# =============================================================================
FROM node:22-alpine AS builder

WORKDIR /app

# 1.a · Les dépendances d'abord (couche mise en cache)
COPY package.json package-lock.json ./
# Ici on installe TOUT, y compris les devDependencies : on en a besoin pour builder.
RUN npm ci

# 1.b · Puis les sources
COPY build.js ./
COPY src/ ./src/

# 1.c · La compilation — produit /app/dist
RUN npm run build

# =============================================================================
#  ÉTAPE 2/2 · runtime — l'image réellement livrée
#  Nouveau FROM = nouvelle image, repartie de zéro. Rien de l'étape 1 n'est
#  conservé, sauf ce qu'on copie explicitement.
# =============================================================================
FROM nginx:alpine

# 2.a · On récupère UNIQUEMENT le résultat du build depuis l'étape `builder`.
#       Ni Node, ni npm, ni node_modules, ni le code source ne suivent.
COPY --from=builder /app/dist /usr/share/nginx/html

# 2.b · Notre configuration nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1

# L'image nginx définit déjà son CMD ; on peut donc s'arrêter là.
