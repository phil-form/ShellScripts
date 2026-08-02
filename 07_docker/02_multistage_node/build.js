// Un « build » volontairement minimaliste : il remplace des variables dans un
// gabarit HTML et écrit le résultat dans dist/. Il tient lieu de webpack / vite
// pour l'exemple — l'important est qu'il produise un dossier `dist`.
const fs = require('node:fs');
const path = require('node:path');

const SRC = path.join(__dirname, 'src');
const DIST = path.join(__dirname, 'dist');

fs.rmSync(DIST, { recursive: true, force: true });
fs.mkdirSync(DIST, { recursive: true });

const template = fs.readFileSync(path.join(SRC, 'index.html'), 'utf8');

const html = template
    .replaceAll('{{TITRE}}', 'Build multi-étapes')
    .replaceAll('{{DATE}}', new Date().toISOString().slice(0, 10))
    .replaceAll('{{NODE}}', process.version);

fs.writeFileSync(path.join(DIST, 'index.html'), html);
fs.copyFileSync(path.join(SRC, 'style.css'), path.join(DIST, 'style.css'));

console.log('Build terminé → dist/');
