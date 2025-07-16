#!/bin/sh
# entrypoint.sh

# Verarbeite alle Files in /etc/postfix/custom
if [ -d /etc/postfix/custom ]; then
    for file in /etc/postfix/custom/*; do
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

postfix check
exec /usr/sbin/postfix start-fg