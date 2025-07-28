#!/bin/sh

set -e

DOMAIN="$1"
KEYVAULT_NAME="${KEYVAULT_NAME:-mojekeyvault}"
CERT_PATH="/acme.sh/$DOMAIN/fullchain.pem"
KEY_PATH="/acme.sh/$DOMAIN/key.pem"
PFX_PATH="/tmp/$DOMAIN.pfx"
PFX_PASS="${PFX_PASS:-MySuperSecret123}"

# Check if domain is provided
if [ -z "$DOMAIN" ]; then
    echo "[ERROR] Domain name is required as first argument"
    exit 1
fi

# Check if certificate files exist
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo "[ERROR] Certificate files not found for domain: $DOMAIN"
    echo "  Expected: $CERT_PATH and $KEY_PATH"
    exit 1
fi

echo "[INFO] Authenticating with Azure using Managed Identity..."
# Login using managed identity (works automatically in Azure Container Apps)
az login --identity

echo "[INFO] Creating PFX for domain: $DOMAIN..."
openssl pkcs12 -export -out "$PFX_PATH" \
  -inkey "$KEY_PATH" \
  -in "$CERT_PATH" \
  -password pass:$PFX_PASS

echo "[INFO] Importing certificate into Azure Key Vault: $KEYVAULT_NAME..."
az keyvault certificate import \
  --vault-name "$KEYVAULT_NAME" \
  --name "${DOMAIN//\./-}-cert" \
  --file "$PFX_PATH" \
  --password "$PFX_PASS"

# Clean up temporary PFX file
rm -f "$PFX_PATH"

echo "[OK] Certificate for $DOMAIN successfully uploaded to Key Vault."
