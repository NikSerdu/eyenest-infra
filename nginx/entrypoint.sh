#!/bin/sh
set -e

CERT_DIR=/etc/nginx/certs
CERT_FILE=$CERT_DIR/server.crt
KEY_FILE=$CERT_DIR/server.key

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  mkdir -p "$CERT_DIR"

  SAN="IP:127.0.0.1,DNS:localhost"
  [ -n "$PUBLIC_HOST" ] && SAN="IP:${PUBLIC_HOST},${SAN}"

  openssl req -x509 -nodes -days 3650 \
    -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/CN=${PUBLIC_HOST:-localhost}" \
    -addext "subjectAltName=${SAN}"

  echo "[nginx-entrypoint] self-signed certificate created (SAN: ${SAN})"
fi

echo "[nginx-entrypoint] starting nginx"
exec nginx -g 'daemon off;'
