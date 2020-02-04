FROM phasecorex/red-discordbot

COPY start-http-redbot.sh /app/
RUN chmod +x /app/start-http-redbot.sh

RUN git clone https://github.com/zinefer/6_6.git /var/www

CMD ["/app/start-http-redbot.sh"]