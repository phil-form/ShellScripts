1) Installer nodejs
```shell
sudo apt install nodejs
```

2) Créer un service qui fera tourné le fichier test.js (trouvable dans le dossier exemple)

Contenu du "service" :
```js
console.log("Hello World");

let i = 0;
while(true) {
    if(i === 1000000000) {
        console.log("Service running");
        i = 0;
    }
    i++;
}

```

Commande d'exécution :
```shell
node test.js
```

Configuration du service :
```shell
vim testservice.service
```
```txt
[Unit]
Description=Example de service
After=multi-user.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=debian
ExecStart=/usr/bin/node /home/debian/test.js

[Install]
RequiredBy=multi-user.target
```

```shell
sudo cp testservice.service /etc/systemd/system/
```

3) Activer et lancer ce service
```shell
sudo systemctl enable testservice.service
sudo systemctl start testservice.service
```
4) Arrêter et désactiver le service.
```shell
sudo systemctl stop testservice.service
sudo systemctl disable testservice.service
```
