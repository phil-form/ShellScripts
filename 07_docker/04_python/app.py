"""Petite application Flask servie par gunicorn.

`app` est l'objet WSGI référencé par la commande du Dockerfile :
    gunicorn --bind 0.0.0.0:8000 app:app
             (module ─┘  └─ variable)
"""
import os
import socket

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/health")
def health():
    """Point de terminaison interrogé par le HEALTHCHECK."""
    return jsonify(status="ok")


@app.get("/")
def index():
    return jsonify(
        message="Bonjour depuis le conteneur Python",
        hostname=socket.gethostname(),
        uid=os.getuid(),
        env=os.environ.get("APP_ENV", "production"),
    )


if __name__ == "__main__":
    # Uniquement pour lancer l'application hors conteneur, en développement.
    # En conteneur, c'est gunicorn qui pilote (voir CMD dans le Dockerfile).
    app.run(host="0.0.0.0", port=8000)
