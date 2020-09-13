#!/bin/bash

#/usr/sbin/sshd

cd /var/www
python3 -m http.server 80 &

echo 'Deleting stuff'
rm -f /data/venv/bin/pip
rm -f /data/venv/bin/pip3
rm -f /data/venv/bin/pip3.8
rm -f /data/venv/bin/easy_install
rm -f /data/venv/bin/easy_install-3.8
rm -f /data/venv/lib/python3.8/site-packages/easy_install.py

/app/start-redbot.sh