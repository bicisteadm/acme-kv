#!/bin/sh

set -e

# =============================================================================
# Configuration
# =============================================================================
DOMAIN="$1"
KEYVAULT_NAME="${KEYVAULT_NAME}"
CERT_PATH="/acme.sh/$DOMAIN/cert.pem"
KEY_PATH="/acme.sh/$DOMAIN/key.pem"
PFX_PATH="/acme.sh/$DOMAIN.pfx"
PFX_PASS="${PFX_PASS}"

# Set log file for deploy script
LOG_FILE="${LOG_FILE:-"$LOG_DIR/deploy-$(date +%Y%m%d-%H%M%S).log"}"

# Load shared logging functions
. /scripts/logging.sh

# =============================================================================
# Validation
# =============================================================================
# Check if domain is provided
if [ -z "$DOMAIN" ]; then
    log_error "Domain name is required as first argument"
    exit 1
fi

# Check if certificate files exist
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    log_error "Certificate files not found for domain: $DOMAIN"
    log_error "  Expected: $CERT_PATH and $KEY_PATH"
    exit 1
fi

# =============================================================================
# Azure Authentication
# =============================================================================
log_info "Authenticating with Azure using Managed Identity..."
# Login using managed identity (works automatically in Azure Container Apps)
if ! run_cmd "AZ" az login --identity; then
    log_error "Failed to authenticate with Azure"
    exit 1
fi

# =============================================================================
# Certificate Processing
# =============================================================================
log_info "Creating PFX for domain: $DOMAIN..."

cat $CERT_PATH $KEY_PATH > /acme.sh/$DOMAIN/$DOMAIN.pem
if ! run_cmd "OPENSSL" openssl pkcs12 -export -in /acme.sh/$DOMAIN/$DOMAIN.pem -out $DOMAIN.pfx -password pass:$PFX_PASS; then
    log_error "Failed to create PFX file for domain: $DOMAIN"
    exit 1
fi

log_info "PFX file created successfully: $DOMAIN.pfx"

log_info "PFX file created successfully: $DOMAIN.pfx"

# =============================================================================
# Key Vault Upload (commented out)
# =============================================================================
#log_info "Importing certificate into Azure Key Vault: $KEYVAULT_NAME..."
#if ! run_cmd "AZ" az keyvault certificate import \
#  --vault-name "$KEYVAULT_NAME" \
#  --name "${DOMAIN//\./-}-cert" \
#  --file "$PFX_PATH" \
#  --password "$PFX_PASS"; then
#    log_error "Failed to upload certificate to Key Vault"
#    exit 1
#fi

# Clean up temporary PFX file
#rm -f "$PFX_PATH"

log_info "Certificate processing completed successfully for domain: $DOMAIN"
