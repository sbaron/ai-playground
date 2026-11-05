#!/usr/bin/env bash
# Serve this folder over HTTPS on 0.0.0.0:8443 with a self-signed certificate.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

# The key must stay outside this folder, or the server would expose it.
tls_dir="${XDG_STATE_HOME:-$HOME/.local/state}/solar-system-tls"
cert="$tls_dir/cert.pem"
key="$tls_dir/key.pem"

san="DNS:localhost,IP:127.0.0.1"
for ip in $(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1); do
  san="$san,IP:$ip"
done

# Regenerate when the cert is missing, expires within a day, or the IPs changed.
stored_san="$tls_dir/san.txt"
if [[ ! -f "$cert" || ! -f "$key" || "$(cat "$stored_san" 2>/dev/null)" != "$san" ]] \
   || ! openssl x509 -in "$cert" -noout -checkend 86400 >/dev/null; then
  mkdir -p "$tls_dir"
  chmod 700 "$tls_dir"
  openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
    -keyout "$key" -out "$cert" -subj "/CN=localhost" \
    -addext "subjectAltName=$san" 2>/dev/null
  chmod 600 "$key"
  echo "$san" > "$stored_san"
fi

echo "Serving $PWD at https://0.0.0.0:8443/ (names: $san)"
exec python3 -m http.server 8443 --bind 0.0.0.0 --tls-cert "$cert" --tls-key "$key"
