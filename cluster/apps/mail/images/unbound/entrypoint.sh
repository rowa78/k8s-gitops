#!/bin/sh
set -e

# Create necessary directories if they don't exist
mkdir -p /etc/unbound/
mkdir -p /var/lib/unbound

# Download root hints file
echo "Downloading root hints file..."
curl -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache || {
  echo "Failed to download root hints, checking for existing file..."
  if [ ! -f /etc/unbound/root.hints ]; then
    echo "No existing root hints file found. Using fallback method..."
    dig +nocomments . NS > /etc/unbound/root.hints || {
      echo "WARNING: Could not create root hints file. DNS resolution may be affected."
    }
  else
    echo "Using existing root hints file."
  fi
}

# Check if we have a valid root hints file
if [ -f /etc/unbound/root.hints ]; then
  echo "Root hints file is ready."
  # Display some stats about the root hints file
  echo "Root hints file contains $(grep -c "NS" /etc/unbound/root.hints) NS records."
else
  echo "WARNING: No root hints file available!"
fi

# Set proper permissions
chown -R unbound:unbound /etc/unbound /var/lib/unbound 2>/dev/null || true

echo "Starting Unbound DNS server..."
exec "$@"
