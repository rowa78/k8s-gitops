FROM alpine:latest

# Install unbound, bind-tools and curl for downloading root hints
RUN apk update && \
    apk add unbound bind-tools curl && \
    rm -rf /var/cache/apk/* && \
    # Create unbound user if it doesn't exist
    addgroup -S unbound 2>/dev/null || true && \
    adduser -S -D -H -h /var/lib/unbound -s /sbin/nologin -G unbound -g unbound unbound 2>/dev/null || true && \
    mkdir -p /etc/unbound /var/lib/unbound && \
    chown -R unbound:unbound /etc/unbound /var/lib/unbound && \
    curl -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose DNS port
EXPOSE 1053/tcp
EXPOSE 1053/udp

# Set entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["unbound", "-d", "-p", "-v"]