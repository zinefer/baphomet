#cloud-config

apt:
  sources:
    docker.list:
      source: deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable
      keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88

packages:
  - docker-ce
  - docker-ce-cli

write_files:
  - path: /etc/systemd/system/baphomet.service
    owner: root:root
    permissions: '0755'
    content: |
        [Unit]
        Description=Run Baphomet
        Requires=docker.service
        After=docker.service

        [Service]
        Restart=always
        ExecStartPre=-/usr/bin/docker rm baphomet
        ExecStart=/usr/bin/docker run --rm -v /data:/data -e TOKEN=${token} -e PREFIX=! --name baphomet phasecorex/red-discordbot
        ExecStop=/usr/bin/docker stop -t 2 baphomet

runcmd:
  - systemctl start baphomet
  - systemctl enable baphomet