// API de démonstration : elle ne fait rien d'autre que prouver qu'elle sait
// joindre les autres services de la stack par leur NOM (db, cache), grâce au
// DNS interne du réseau Compose. Toujours aucune dépendance externe.
const http = require('node:http');
const net = require('node:net');
const dns = require('node:dns').promises;
const os = require('node:os');

const PORT = process.env.PORT || 3000;
const DB_HOST = process.env.DB_HOST || 'db';
const DB_PORT = Number(process.env.DB_PORT || 5432);
const REDIS_HOST = process.env.REDIS_HOST || 'cache';

/** Teste l'ouverture d'une connexion TCP, avec un délai maximal. */
function tcpCheck(host, port, timeout = 1000) {
    return new Promise((resolve) => {
        const socket = net.createConnection({ host, port });
        const done = (ok) => { socket.destroy(); resolve(ok); };
        socket.setTimeout(timeout);
        socket.once('connect', () => done(true));
        socket.once('timeout', () => done(false));
        socket.once('error', () => done(false));
    });
}

const server = http.createServer(async (req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        return res.end(JSON.stringify({ status: 'ok' }));
    }

    // Résolution DNS : `db` n'existe pas sur l'hôte, mais existe
    // dans le réseau Compose.
    const dbIp = await dns.lookup(DB_HOST).then((r) => r.address).catch(() => null);

    const body = {
        message: 'API de la stack de démonstration',
        hostname: os.hostname(),
        env: process.env.NODE_ENV,
        services: {
            db: { host: DB_HOST, ip: dbIp, joignable: await tcpCheck(DB_HOST, DB_PORT) },
            cache: { host: REDIS_HOST, joignable: await tcpCheck(REDIS_HOST, 6379) },
        },
    };

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body, null, 2));
});

server.listen(PORT, '0.0.0.0', () => console.log(`API prête sur le port ${PORT}`));

process.on('SIGTERM', () => server.close(() => process.exit(0)));
