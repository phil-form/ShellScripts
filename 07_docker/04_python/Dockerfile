# =============================================================================
#  Exemple 04 · Python — multi-étapes avec environnement virtuel
#  Build : docker build -t demo:04 .
#  Run   : docker run --rm -p 8000:8000 demo:04
#
#  Le piège Python : `pip install` traîne souvent un compilateur C et des
#  en-têtes de développement. On les garde dans l'étape de build et on ne
#  copie que le venv terminé dans l'image finale.
# =============================================================================

# =============================================================================
#  ÉTAPE 1/2 · builder — installation des dépendances
# =============================================================================
FROM python:3.12-slim AS builder

# 1.a · Les outils de compilation, nécessaires à certains paquets (psycopg,
#       cryptography…). Ils resteront dans CETTE étape uniquement.
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential gcc && \
    rm -rf /var/lib/apt/lists/*
#   ↑ `rm -rf /var/lib/apt/lists/*` DANS le même RUN : sur un RUN séparé,
#     le cache apt resterait dans la couche précédente, donc dans l'image.

# 1.b · Un environnement virtuel, facile à copier d'un bloc
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 1.c · Les dépendances, avant le code (cache)
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# =============================================================================
#  ÉTAPE 2/2 · runtime — sans compilateur
# =============================================================================
FROM python:3.12-slim

# 2.a · Un utilisateur non privilégié
RUN groupadd --system app && useradd --system --gid app --home /app app

# 2.b · Le venv complet, récupéré tel quel depuis l'étape builder
ENV VIRTUAL_ENV=/opt/venv
COPY --from=builder "$VIRTUAL_ENV" "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 2.c · Les réglages Python usuels en conteneur
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
#   PYTHONUNBUFFERED=1 est IMPORTANT : sans lui, les `print` sont mis en tampon
#   et n'apparaissent pas dans `docker logs` avant plusieurs kilo-octets.

WORKDIR /app
COPY --chown=app:app app.py ./

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]
