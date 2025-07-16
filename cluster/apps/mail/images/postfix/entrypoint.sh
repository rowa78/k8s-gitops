#!/bin/sh
# entrypoint.sh

# Verarbeite alle Files in /etc/postfix/custom
if [ -d /etc/postfix/custom ]; then
    for file in /custom-config/*; do
        [ ! -f "$file" ] && continue
        
        filename=$(basename "$file")
        
        case "$filename" in
            *postconf*|*.postconf)
                echo "Appending postfix settings from $filename..."
                echo "" >> /etc/postfix/main.cf
                echo "# Custom settings from $filename" >> /etc/postfix/main.cf
                cat "$file" >> /etc/postfix/main.cf
                ;;
            *.cf)
                echo "Copying config file: $filename"
                cp "$file" "/etc/postfix/$filename"
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