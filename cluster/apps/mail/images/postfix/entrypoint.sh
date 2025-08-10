#!/bin/sh
# entrypoint.sh

# Verarbeite alle Files in /custom-config
if [ -d /custom-config ]; then
    rm -f /etc/postfix/main.cf
    for file in /custom-config/*; do
        [ ! -f "$file" ] && continue
        filename=$(basename "$file")

        echo "processing: $filename"
        case "$filename" in
            *.postconf)
                echo "Replacing postfix main.cf with $filename..."
                # Simply replace the entire main.cf file - much simpler!
                envsubst < "$file" >> /etc/postfix/main.cf
                ;;
            *.cf)
                echo "Copying config file: $filename"
                envsubst < "$file" > "/etc/postfix/$filename"
                ;;
        esac
    done
fi

echo "non default settings: "
postconf -n
echo "**********************"

postfix check
echo "Starting ....."
exec /usr/sbin/postfix start-fg