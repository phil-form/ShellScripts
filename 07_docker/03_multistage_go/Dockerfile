# =============================================================================
#  Exemple 03 · Multi-étapes poussé à l'extrême — une image de ~7 Mo
#  Build : docker build -t demo:03 .
#  Run   : docker run --rm -p 8081:8080 demo:03
#
#  Un binaire Go compilé statiquement n'a besoin de RIEN pour tourner : ni
#  bibliothèque C, ni shell, ni gestionnaire de paquets. L'image finale peut
#  donc partir de `scratch`, l'image vide.
# =============================================================================

# =============================================================================
#  ÉTAPE 1/3 · builder — la chaîne de compilation
# =============================================================================
FROM golang:1.23-alpine AS builder

WORKDIR /src

# 1.a · Les dépendances d'abord : go.mod / go.sum changent rarement,
#       la couche `go mod download` reste donc en cache.
COPY go.mod ./
RUN go mod download

# 1.b · Les sources
COPY . .

# 1.c · La compilation
#   CGO_ENABLED=0  → binaire statique, aucune dépendance à la libc
#   -trimpath      → retire les chemins de build (reproductibilité)
#   -ldflags "-s -w" → supprime la table des symboles : binaire plus petit
RUN CGO_ENABLED=0 GOOS=linux go build \
        -trimpath \
        -ldflags="-s -w" \
        -o /out/serveur ./main.go

# =============================================================================
#  ÉTAPE 2/3 · certs — récupérer de quoi faire du HTTPS sortant
#  `scratch` ne contient aucun certificat racine : sans cette étape, tout appel
#  HTTPS depuis l'application échouerait avec « x509: certificate signed by
#  unknown authority ».
# =============================================================================
FROM alpine:3.20 AS certs
RUN apk add --no-cache ca-certificates

# =============================================================================
#  ÉTAPE 3/3 · runtime — l'image vide
#  `scratch` = zéro fichier. Pas de shell, donc pas de `docker exec … sh`
#  possible : le débogage se fait via les logs. C'est le prix de la surface
#  d'attaque minimale.
# =============================================================================
FROM scratch

# 3.a · Les certificats racine
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 3.b · Le binaire, et rien d'autre
COPY --from=builder /out/serveur /serveur

# 3.c · Un UID non privilégié. Pas de /etc/passwd dans `scratch` :
#       on donne donc le numéro directement, pas un nom.
USER 65534:65534

EXPOSE 8080

ENTRYPOINT ["/serveur"]
