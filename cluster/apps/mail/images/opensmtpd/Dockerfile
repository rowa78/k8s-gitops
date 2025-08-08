FROM alpine:latest

ARG OPENSMTPD_VER="7.7.0"

ENV OPENSMTPD_VER="${OPENSMTPD_VER}"

# You might not need the pigeonhole (sieve) plugin or the rspamd package
RUN apk update && \
    apk add opensmtpd~${OPENSMTPD_VER} opensmtpd-table-postgres~1.1.1 opensmtpd-filter-rspamd~0.1.8 && \    
    rm -rf /var/cache/apk/* && \
    mkdir -p /var/spool/smtpd

EXPOSE 25/tcp
EXPOSE 465/tcp
EXPOSE 587/tcp

VOLUME [ "/var/spool/smtpd" ]
WORKDIR /var/spool/smtpd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]