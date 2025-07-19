FROM alpine:latest

# You might not need the pigeonhole (sieve) plugin or the rspamd package
RUN apk update && \
    apk add unbound && \
    rm -rf /var/cache/apk/* 

    
EXPOSE 1053/tcp

CMD [ "unbound", "-d", "-p" , "-v" ]