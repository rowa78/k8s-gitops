FROM alpine:latest

# You might not need the pigeonhole (sieve) plugin or the rspamd package
RUN apk update && \
    apk add rspamd && \
    rm -rf /var/cache/apk/* 

USER rspamd
    
#EXPOSE 1053/tcp

#CMD [ "unbound", "-d", "-p" , "-v" ]