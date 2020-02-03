#!/usr/bin/env sh

cd /var/www
python3 -m http.server 80 &

/app/start-redbot.sh