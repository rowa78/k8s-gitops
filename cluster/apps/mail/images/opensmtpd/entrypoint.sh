#!/bin/sh
# entrypoint.sh

# Verarbeite alle Files in /custom-config
if [ -d /custom-config ]; then
    for file in /custom-config/*; do
        [ ! -f "$file" ] && continue
        filename=$(basename "$file")

        echo "processing: $filename"
        echo "Copying config file: $filename"
        envsubst < "$file" > "/etc/mail/$filename"
        ;;        
    done
fi

echo "Starting ....."
exec smtpd -dv