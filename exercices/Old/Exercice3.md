1) Créer l'arborescence suivante :
   projet/
   ├── docs/
   └── src/
   Dans docs/, crée un fichier readme.txt.
   Dans src/, crée trois fichiers : main.sh, config.cfg, data.txt.

```bash
mkdir -p projet/docs projet/src
touch projet/docs/readme.txt
touch projet/src/main.sh projet/src/data.txt projet/src/config.cfg
```

2) Créer une une seule commande l'arborescence suivante :
      cours/
      └── bash/
          ├── jour1/
          ├── jour2/
          └── jour3/
      Ajoute un fichier notes.txt dans chaque dossier jourX.

```bash
mkdir -p cours/bash/jour{1,3}
touch cours/bash/jour{1,3}/note.txt
```

3) Créer les fichiers suivants :
   image1.jpg
   image2.jpg
   video1.mp4
   script.sh
   notes.txt

et ensuite cr´éer les dossiers suivants :
    images/
    videos/
    scripts/
    textes/

```bash
mkdir images video scripts textes
touch image{1,2}.jpg video1.mp4 script.sh notes.txt
mv *.jpg ./images/
mv *.mp4 ./video
mv script.sh ./scripts
mv notes.txt ./textes
```

4) Créer un dossier backup contenant l'état courant du dossier projet créer précédement

```bash
mkdir backup
cp -R ./projet ./backup
```
