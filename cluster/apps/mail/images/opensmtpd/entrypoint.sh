#!/bin/sh
# entrypoint.sh

# Verarbeite alle Files in /custom-config
if [ -d /custom-config ]; then
    for file in /custom-config/*; do
        [ ! -f "$file" ] && continue
        filename=$(basename "$file")

        echo "processing: $filename"
        
        case "$filename" in
            _postconf_|*.postconf)
                echo "Appending postfix settings from $filename..."
                echo "" >> /etc/postfix/main.cf
                echo "# Custom settings from $filename" >> /etc/postfix/main.cf
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