FROM phasecorex/red-discordbot

# RUN apt-get update \
#      && apt-get install -y --no-install-recommends openssh-server \
#      && echo "root:Docker!" | chpasswd 

#COPY sshd_config /etc/ssh/

#RUN mkdir -p /var/run/sshd

COPY start-http-redbot.sh /app/
RUN chmod +x /app/start-http-redbot.sh

RUN git clone --depth 1 https://github.com/zinefer/6_6.git /var/www

#EXPOSE 2222 80
CMD ["/app/start-http-redbot.sh"]
