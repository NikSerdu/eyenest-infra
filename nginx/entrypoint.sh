#!/bin/sh
set -e

CERT_DIR=/etc/nginx/certs
CERT_FILE=$CERT_DIR/server.crt
KEY_FILE=$CERT_DIR/server.key
LE_DIR=/etc/letsencrypt

mkdir -p "$CERT_DIR" /var/www/certbot

is_domain() {
  case "$1" in
    localhost|"") return 1 ;;
    *[!0-9.]*.*) return 0 ;;
    *) return 1 ;;
  esac
}

generate_self_signed() {
  SAN="IP:127.0.0.1,DNS:localhost"
  if is_domain "$PUBLIC_HOST"; then
    SAN="DNS:${PUBLIC_HOST},${SAN}"
  elif [ -n "$PUBLIC_HOST" ]; then
    SAN="IP:${PUBLIC_HOST},${SAN}"
  fi

  openssl req -x509 -nodes -days 3650 \
    -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/CN=${PUBLIC_HOST:-localhost}" \
    -addext "subjectAltName=${SAN}"

  echo "[entrypoint] self-signed certificate created (SAN: ${SAN})"
}

install_le_cert() {
  LE_LIVE=$LE_DIR/live/$PUBLIC_HOST
  if [ -f "$LE_LIVE/fullchain.pem" ]; then
    cp "$LE_LIVE/fullchain.pem" "$CERT_FILE"
    cp "$LE_LIVE/privkey.pem" "$KEY_FILE"
    return 0
  fi
  return 1
}

if is_domain "${PUBLIC_HOST:-}"; then
  LE_LIVE=$LE_DIR/live/$PUBLIC_HOST

  if [ -n "${LETSENCRYPT_EMAIL:-}" ]; then
    EMAIL_FLAGS="-m $LETSENCRYPT_EMAIL"
  else
    EMAIL_FLAGS="--register-unsafely-without-email"
  fi

  if [ -d "$LE_LIVE" ]; then
    echo "[entrypoint] renewing Let's Encrypt certificate..."
    certbot renew --standalone --non-interactive 2>&1 || true
  else
    echo "[entrypoint] requesting Let's Encrypt certificate for $PUBLIC_HOST..."
    certbot certonly --standalone \
      -d "$PUBLIC_HOST" \
      $EMAIL_FLAGS \
      --agree-tos --non-interactive 2>&1 || true
  fi

  if install_le_cert; then
    echo "[entrypoint] Let's Encrypt certificate installed for $PUBLIC_HOST"
  else
    echo "[entrypoint] WARNING: Let's Encrypt failed, falling back to self-signed"
    generate_self_signed
  fi

  # Background renewal: every 12 h check via webroot (nginx serves /.well-known/)
  (
    while true; do
      sleep 43200
      certbot renew --webroot -w /var/www/certbot --non-interactive 2>&1 || true
      if install_le_cert; then
        nginx -s reload 2>/dev/null || true
        echo "[entrypoint] certificate renewed and nginx reloaded"
      fi
    done
  ) &

else
  if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    generate_self_signed
  else
    echo "[entrypoint] using existing certificate"
  fi
fi

echo "[entrypoint] starting nginx"
exec nginx -g 'daemon off;'
