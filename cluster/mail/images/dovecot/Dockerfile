FROM alpine:latest

ARG VMAIL_UID=1000
ARG VMAIL_GID=1000

# You might not need the pigeonhole (sieve) plugin or the rspamd package
RUN apk update && \
    apk add dovecot dovecot-lmtpd dovecot-pgsql dovecot-pigeonhole-plugin rspamd-client dovecot-fts-solr && \
    rm -rf /var/cache/apk/* && \
    addgroup -g $VMAIL_GID -S vmail && \
    adduser -u $VMAIL_UID -D -G vmail -h /srv/mail -s /bin/sh vmail

COPY config/dovecot.conf /etc/dovecot/dovecot.conf
COPY config/conf.d/10-logging.conf /etc/dovecot/conf.d/10-logging.conf

EXPOSE 24/tcp
EXPOSE 143/tcp
EXPOSE 993/tcp

CMD ["/usr/sbin/dovecot","-F"]