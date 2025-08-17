FROM alpine:latest

# You might not need the pigeonhole (sieve) plugin or the rspamd package
RUN apk update && \
    apk add postfix postfix-pgsql gettext && \
    mkdir /custom-config && \
    chown postfix:postfix /var/lib/postfix && \
    rm -rf /var/cache/apk/* 

    
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25/tcp
EXPOSE 465/tcp
EXPOSE 587/tcp

VOLUME [ "/var/lib/postfix" ]

CMD ["/entrypoint.sh"]