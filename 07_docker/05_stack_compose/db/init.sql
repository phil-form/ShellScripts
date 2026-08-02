-- Tout fichier .sql placé dans /docker-entrypoint-initdb.d est exécuté par
-- l'image postgres AU PREMIER DÉMARRAGE UNIQUEMENT, c'est-à-dire quand le
-- volume de données est vide. Modifier ce fichier ensuite n'a aucun effet :
-- il faut supprimer le volume (docker compose down -v) pour le rejouer.

CREATE TABLE IF NOT EXISTS utilisateurs (
    id         SERIAL PRIMARY KEY,
    login      TEXT NOT NULL UNIQUE,
    cree_le    TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO utilisateurs (login) VALUES
    ('alice'),
    ('bob'),
    ('charlie')
ON CONFLICT (login) DO NOTHING;
