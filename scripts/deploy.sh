#!/bin/sh

set -e

DOMAIN="$1"
KEYVAULT_NAME="${KEYVAULT_NAME:-mojekeyvault}"
CERT_PATH="/acme.sh/$DOMAIN/fullchain.pem"
KEY_PATH="/acme.sh/$DOMAIN/key.pem"
PFX_PATH="/tmp/$DOMAIN.pfx"
PFX_PASS="${PFX_PASS:-MySuperSecret123}"

echo "[INFO] Creating PFX for domain: $DOMAIN..."
openssl pkcs12 -export -out "$PFX_PATH" \
  -inkey "$KEY_PATH" \
  -in "$CERT_PATH" \
  -password pass:$PFX_PASS

echo "[INFO] Importing into Azure Key Vault: $KEYVAULT_NAME..."
az keyvault certificate import \
  --vault-name "$KEYVAULT_NAME" \
  --name "$DOMAIN-cert" \
  --file "$PFX_PATH" \
  --password "$PFX_PASS"

echo "[OK] Certificate for $DOMAIN successfully uploaded to Key Vault."
