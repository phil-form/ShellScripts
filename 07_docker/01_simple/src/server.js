// Une petite API sans aucune dépendance : uniquement la bibliothèque standard
// de Node. Le but est de pouvoir construire l'image sans rien télécharger.
const http = require('node:http');
const os = require('node:os');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
    // Point de terminaison interrogé par le HEALTHCHECK du Dockerfile
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        return res.end(JSON.stringify({ status: 'ok' }));
    }

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
        message: 'Bonjour depuis le conteneur',
        hostname: os.hostname(),   // l'ID du conteneur, par défaut
        user: os.userInfo().username,
        node: process.version,
    }, null, 2));
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`API à l'écoute sur le port ${PORT}`);
});

// Sans ceci, `docker stop` attendrait 10 s avant de tuer le processus :
// PID 1 doit gérer lui-même SIGTERM.
process.on('SIGTERM', () => {
    console.log('SIGTERM reçu, arrêt du serveur…');
    server.close(() => process.exit(0));
});
